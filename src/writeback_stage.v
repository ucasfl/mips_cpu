
`include "cpu.h"
`define SIMU_DEBUG

module writeback_stage(
    input  wire        clk,
    input  wire        resetn,
	input  wire        stall,

    input  wire [ 4:0] mem_out_op,      //control signals used in WB stage
    input  wire [ 4:0] mem_dest,        //reg num of dest operand
    input  wire [31:0] mem_value,       //mem_stage final result
	input  wire [ 1:0] mem_two_dest,

    output wire [ 4:0] wb_out_op,
	output wire [ 3:0] wb_rf_wen,
    output wire [ 4:0] wb_rf_waddr,
    output wire [31:0] wb_rf_wdata 

  `ifdef SIMU_DEBUG
   ,input  wire [31:0] mem_pc,          //pc @memory_stage
    input  wire [31:0] mem_inst,        //instr code @memory_stage
    output reg  [31:0] wb_pc 
  `endif
);

reg  [ 4:0] wb_op;
reg  [ 4:0] wb_dest;
reg  [31:0] wb_value;
reg         last_stall;
reg  [ 2:0] wb_two;
`ifdef SIMU_DEBUG
reg  [31:0] wb_inst;
`endif

wire l0, l1, l2, l3, r0, r1, r2, r3;
wire rf;

assign l0 = wb_op[2] & (wb_two == 2'b00);
assign l1 = wb_op[2] & (wb_two == 2'b01);
assign l2 = wb_op[2] & (wb_two == 2'b10);
assign l3 = wb_op[2] & (wb_two == 2'b11);
assign r0 = wb_op[3] & (wb_two == 2'b00);
assign r1 = wb_op[3] & (wb_two == 2'b01);
assign r2 = wb_op[3] & (wb_two == 2'b10);
assign r3 = wb_op[3] & (wb_two == 2'b11);
assign rf = ~(|wb_op);

assign wb_rf_waddr = wb_dest;
assign wb_rf_wdata = ({32{l0}} & {wb_value[7:0], 24'd0}) |
					 ({32{l1}} & {wb_value[15:0], 16'd0}) |
					 ({32{l2}} & {wb_value[24:0], 8'd0}) |
					 ({32{r1}} & {8'd0, wb_value[31:8]}) |
					 ({32{r2}} & {16'd0, wb_value[31:16]}) |
					 ({32{r3}} & {24'd0, wb_value[31:24]}) |
					 ({32{l3 | r0 | rf}} & wb_value);
assign wb_rf_wen = ({4{l0}} & 4'b1000) |
				   ({4{l1}} & 4'b1100) |
				   ({4{l2}} & 4'b1110) |
				   ({4{r1}} & 4'b0111) |
				   ({4{r2}} & 4'b0011) |
				   ({4{r3}} & 4'b0001) |
				   ({4{l3 | r0 | rf}} & 4'b1111);
assign wb_out_op = wb_op;

always @(posedge clk)
	if(stall) begin
	wb_op <= wb_op;
	wb_dest <= 5'd0;
	wb_value <= wb_value;
	wb_two <= wb_two;
	last_stall <= last_stall;
	`ifdef SIMU_DEBUG
	wb_pc <= wb_pc;
	wb_inst <= wb_inst;
	`endif
	end else
begin
	wb_op <= mem_out_op;
	wb_dest <= mem_dest;
	wb_value <= mem_value;
	wb_two <= mem_two_dest;
	last_stall <= stall;
	`ifdef SIMU_DEBUG
	wb_pc <= mem_pc;
	wb_inst <= mem_inst;
	`endif
end 

endmodule //writeback_stage
