
`include "cpu.h"
`define SIMU_DEBUG

module memory_stage(
    input  wire        clk,
    input  wire        resetn,
	input  wire        stall,

    input  wire [38:0] exe_out_op,      //control signals used in MEM, WB stages
    input  wire [ 4:0] exe_dest,        //reg num of dest operand
    input  wire [31:0] exe_value,       //alu result from exe_stage or other intermediate 
                                        //value for the following stages

	input  wire [ 1:0] two_dest,
    input  wire [31:0] data_sram_rdata,

    output wire [ 4:0] mem_out_op,      //control signals used in WB stage
    output reg  [ 4:0] mem_dest,        //reg num of dest operand
    output wire [31:0] mem_value,        //mem_stage final result
	output wire [ 1:0] mem_two_dest

  `ifdef SIMU_DEBUG
   ,input  wire [31:0] exe_pc,          //pc @execute_stage
    input  wire [31:0] exe_inst,        //instr code @execute_stage
    output reg  [31:0] mem_pc,          //pc @memory_stage
    output reg  [31:0] mem_inst         //instr code @memory_stage
  `endif
);

reg  [38:0] mem_op;
reg  [31:0] mem_final_value;
reg  [ 1:0] mem_two;
reg  [31:0] sram_reg;

wire [31:0] LB_value, LBU_value, LH_value, LHU_value, LWL_value, LWR_value;
wire        exe_to_mem;

assign LB_value = ({32{mem_two == 2'b00}} & {{24{sram_reg[7]}}, sram_reg[7:0]}) |
				  ({32{mem_two == 2'b01}} & {{24{sram_reg[15]}}, sram_reg[15:8]}) |
				  ({32{mem_two == 2'b10}} & {{24{sram_reg[23]}}, sram_reg[23:16]}) |
				  ({32{mem_two == 2'b11}} & {{24{sram_reg[31]}}, sram_reg[31:24]});

assign LBU_value = ({32{mem_two == 2'b00}} & {24'd0, sram_reg[7:0]}) |
				   ({32{mem_two == 2'b01}} & {24'd0, sram_reg[15:8]}) |
				   ({32{mem_two == 2'b10}} & {24'd0, sram_reg[23:16]}) |
				   ({32{mem_two == 2'b11}} & {24'd0, sram_reg[31:24]});

assign LH_value = ({32{~mem_two[1]}} & {{16{sram_reg[15]}}, sram_reg[15:0]}) |
				  ({32{ mem_two[1]}} & {{16{sram_reg[31]}}, sram_reg[31:16]});

assign LHU_value = ({32{~mem_two[1]}} & {16'd0, sram_reg[15:0]}) |
				   ({32{ mem_two[1]}} & {16'd0, sram_reg[31:16]});

assign mem_two_dest = mem_two;
assign mem_out_op = {mem_op[`_MTC0], mem_op[`_LWR], mem_op[`_LWL],  mem_op[`_SW], mem_op[`EMPTY]};
assign exe_to_mem = ~(mem_op[`_LW] | mem_op[`_LWL] | mem_op[`_LWR] | mem_op[`_LB] | mem_op[`_LBU] | mem_op[`_LH] | mem_op[`_LHU]);
assign mem_value = ({32{mem_op[`_LW] | mem_op[`_LWL] | mem_op[`_LWR]}} & sram_reg) | //data_sram_rdata) |
				   ({32{mem_op[`_LB]}}  & LB_value) |
				   ({32{mem_op[`_LBU]}} & LBU_value) |
				   ({32{mem_op[`_LH]}}  & LH_value) |
				   ({32{mem_op[`_LHU]}} & LHU_value) |
				   ({32{exe_to_mem}} & mem_final_value);

always @(posedge clk)
	if(stall)
	begin
		mem_dest <= mem_dest;
		mem_op <= mem_op;
		mem_two <= mem_two;
		mem_final_value <= mem_final_value;
		sram_reg <= sram_reg;
		`ifdef SIMU_DEBUG
		mem_pc <= mem_pc;
		mem_inst <= mem_inst;
		`endif
	end else begin
	mem_dest <= exe_dest;
	mem_op <= exe_out_op;
	mem_two <= two_dest;
	mem_final_value <= exe_value;
	sram_reg <= data_sram_rdata;
	`ifdef SIMU_DEBUG
	mem_pc <= exe_pc;
	mem_inst <= exe_inst;
	`endif
end 

endmodule //memory_stage
