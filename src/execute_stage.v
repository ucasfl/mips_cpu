
`include "cpu.h"
`define SIMU_DEBUG

module execute_stage(
    input  wire        clk,
    input  wire        resetn,
	input  wire        excp,
	input  wire        exe_en,
	input  wire        stall,

    input  wire [38:0] de_out_op,       //control signals used in EXE, MEM, WB stages
    input  wire [ 4:0] de_dest,         //reg No. of dest operand, zero if no dest
    input  wire [31:0] de_vsrc1,        //value of source operand 1
    input  wire [31:0] de_vsrc2,        //value of source operand 2
    input  wire [31:0] de_st_value,     //value stored to memory
	input  wire [31:0] c0,

	output wire        tlbr,
	output wire        tlbwi,
	output wire        tlbp,
    
	output wire [38:0] exe_out_op,      //control signals used in MEM, WB stages
    output wire [ 4:0] exe_dest,        //reg num of dest operand
    output wire [31:0] exe_value,       //alu result from exe_stage or other intermediate 
                                        //value for the following stages
    output             ex_rbadaddr,
    output             ex_wbadaddr,
	output      [ 4:0] addr,
	output             overf,
	output      [31:0] inc0,
	output      [31:0] exe_vaddr,
    output             c0_wen,

    output wire        data_sram_en,
    output wire [ 3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
	output wire        exe_out_en,
	output wire [ 1:0] two_dest,
    input  wire [31:0] de_inst,          //instr code @decode_stage
    input  wire [31:0] de_pc,           //pc @decode_stage
    output reg  [31:0] exe_pc,         //pc @execute_stage
    output reg  [31:0] exe_inst         //instr code @execute_stage
);

reg  [63:0] md_reg;
reg  [38:0] exe_op, last_op;
reg  [31:0] exe_vsrc1;
reg  [31:0] exe_vsrc2;
reg  [31:0] exe_st_value;
reg  [31:0] high, low;
reg  [ 4:0] exe_dest_r;

wire [31:0] cp0_value;
wire [63:0] md_result;
wire [31:0] ALU_result;
wire [31:0] ALU_srcA, ALU_srcB;
wire [12:0] ALUop;
wire [ 3:0] md_op;
wire high_en, low_en, en;
wire [31:0] SB_value, SH_value, SWL_value, SWR_value;
wire        plus;
wire        overflow;

assign md_op = ({4{exe_op[`_DIV]  }} & 4'b0001) 
             | ({4{exe_op[`_DIVU] }} & 4'b0010) 
			 | ({4{exe_op[`_MULT] }} & 4'b0100)
			 | ({4{exe_op[`_MULTU]}} & 4'b1000);

parameter TLBR    = 32'h42000001;
parameter TLBWI   = 32'h42000002;
parameter TLBP    = 32'h42000008;
assign tlbr  = (exe_inst == TLBR);
assign tlbwi = (exe_inst == TLBWI);
assign tlbp  = (exe_inst == TLBP);

assign high_en = en | exe_op[`_MTHI];
assign low_en  = en | exe_op[`_MTLO];
//ALU
assign ALU_srcA = exe_vsrc1;
assign ALU_srcB = exe_vsrc2;
assign plus = exe_op[`_ADD] || exe_op[`_LW] || exe_op[`_SW] || exe_op[`_JAL] || exe_op[`_LB] || exe_op[`_LBU] || exe_op[`_LH] || exe_op[`_LHU] || exe_op[`_LWL] || exe_op[`_LWR] || exe_op[`_SW] || exe_op[`_SB] || exe_op[`_SH] || exe_op[`_SWL] || exe_op[`_SWR] || exe_op[`_ADDU];
assign ALUop = {exe_op[`_SRA], exe_op[`_SRL], exe_op[`_NOR], exe_op[`_XOR], exe_op[`_AND], exe_op[`_SLT], exe_op[`_SUB] | exe_op[`_SUBU], exe_op[`EMPTY], exe_op[`_LUI], exe_op[`_SLL], plus, exe_op[`_OR], exe_op[`_SLTU]};

assign data_sram_en    = (exe_op[`_SW] || exe_op[`_LW] || exe_op[`_LB]
|| exe_op[`_LBU] || exe_op[`_LH] || exe_op[`_LHU] || exe_op[`_LWL] ||
exe_op[`_LWR] || exe_op[`_SB] || exe_op[`_SH] | exe_op[`_SWL] | exe_op[`_SWR])?1:0;
assign data_sram_wen   = (ex_wbadaddr)?4'd0 : 
						 ({4{exe_op[`_SW]}} & 4'b1111) |
	                     ({4{exe_op[`_SB]}} & (({4{two_dest == 2'b00}} & 4'b0001) | 
											   ({4{two_dest == 2'b01}} & 4'b0010) | 
											   ({4{two_dest == 2'b10}} & 4'b0100) | 
											   ({4{two_dest == 2'b11}} & 4'b1000))) |
						 ({4{exe_op[`_SH]}} & (({4{two_dest == 2'b00}} & 4'b0011) | 
											   ({4{two_dest == 2'b10}} & 4'b1100))) |
						 ({4{exe_op[`_SWL]}} & (({4{two_dest == 2'b00}} & 4'b0001) | 
												({4{two_dest == 2'b01}} & 4'b0011) | 
												({4{two_dest == 2'b10}} & 4'b0111) | 
												({4{two_dest == 2'b11}} & 4'b1111))) |
						 ({4{exe_op[`_SWR]}} & (({4{two_dest == 2'b00}} & 4'b1111) | 
												({4{two_dest == 2'b01}} & 4'b1110) | 
												({4{two_dest == 2'b10}} & 4'b1100) | 
												({4{two_dest == 2'b11}} & 4'b1000)));


assign SB_value = ({32{two_dest == 2'b00}} & {24'd0, exe_st_value[7:0]})
                | ({32{two_dest == 2'b01}} & {16'd0, exe_st_value[7:0], 8'd0})
				| ({32{two_dest == 2'b10}} & {8'd0, exe_st_value[7:0],16'd0})
				| ({32{two_dest == 2'b11}} & {exe_st_value[7:0], 24'd0});

assign SH_value = ({32{two_dest == 2'b00}} & {16'd0, exe_st_value[15:0]})
                | ({32{two_dest == 2'b10}} & {exe_st_value[15:0], 16'd0});

assign SWL_value = ({32{two_dest == 2'b00}} & {24'd0, exe_st_value[31:24]})
                |  ({32{two_dest == 2'b01}} & {16'd0, exe_st_value[31:16]})
				|  ({32{two_dest == 2'b10}} & {8'd0, exe_st_value[31:8]})             
				|  ({32{two_dest == 2'b11}} & exe_st_value);

assign SWR_value = ({32{two_dest == 2'b00}} & exe_st_value)
                |  ({32{two_dest == 2'b01}} & {exe_st_value[23:0], 8'd0})
				|  ({32{two_dest == 2'b10}} & {exe_st_value[15:0], 16'd0})
				|  ({32{two_dest == 2'b11}} & {exe_st_value[7:0], 24'd0});
assign data_sram_wdata = ({32{exe_op[`_SW]}} & exe_st_value) |
	                     ({32{exe_op[`_SB]}} & SB_value)     |
						 ({32{exe_op[`_SH]}} & SH_value)     |
						 ({32{exe_op[`_SWL]}} &SWL_value)    |
						 ({32{exe_op[`_SWR]}} &SWR_value);
assign data_sram_addr  = {ALU_result[31:2], 2'b00};
assign two_dest = ALU_result[1:0];

assign exe_out_op = exe_op;
assign exe_value = 	((last_op[`_DIV] | last_op[`_DIVU] | last_op[`_MULT] | last_op[`_MULTU]) & exe_op[`_MFHI]) ? md_reg[63:32] ://md_result[63:32]:
					((last_op[`_DIV] | last_op[`_DIVU] | last_op[`_MULT] | last_op[`_MULTU]) & exe_op[`_MFLO]) ? md_reg[31:0] ://md_result[31:0]:
					(exe_op[`_MFHI])? high:
					(exe_op[`_MFLO])? low : 
					(exe_op[`_MFC0])? c0  :
					ALU_result;
assign exe_dest = (overf | ex_rbadaddr)?5'd0 : exe_dest_r;
assign ex_rbadaddr = ((exe_op[`_LH] | exe_op[`_LHU] ) & ALU_result[0] ) | 
	                ((exe_op[`_LW] ) & (|ALU_result[1:0]));
assign ex_wbadaddr = ((exe_op[`_SH]) & ALU_result[0] ) |
	                 ((exe_op[`_SW]) & ( |ALU_result[1:0] ));
assign exe_vaddr  = ALU_result;
assign overf      = (exe_op[`_ADD] | exe_op[`_SUB]) & overflow;
assign addr       = (exe_op[`_MFC0])?exe_vsrc2[15:11] : exe_dest;
assign c0_wen     = exe_op[`_MTC0];
assign inc0       = exe_vsrc1;

reg   [1:0] de_en;
assign exe_out_en = (de_en == 2)?0 : 1;
always @(posedge clk)
begin
	if (stall) begin
		exe_op       <= exe_op;
		exe_vsrc1    <= exe_vsrc1;
		exe_vsrc2    <= exe_vsrc2;
		exe_st_value <= exe_st_value;
		exe_dest_r   <= exe_dest_r;
		last_op      <= last_op;
		high         <= high;
		low          <= low;
		de_en        <= de_en;
		md_reg       <= md_reg;
		`ifdef SIMU_DEBUG
		exe_pc       <= exe_pc;
		exe_inst     <= exe_inst;
		`endif
	end else if(resetn)	begin
		exe_op <= (exe_en & ~excp)?de_out_op : 38'd1;
		exe_vsrc1 <= de_vsrc1;
		exe_vsrc2 <= de_vsrc2;
		exe_st_value <= de_st_value;
		exe_dest_r <= de_dest;
		last_op <= exe_op;
		high <= (high_en)?({32{en}} & md_result[63:32]) | ({32{exe_op[`_MTHI]}} & exe_vsrc1) : high;
		low <= (low_en)?({32{en}} & md_result[31:0]) | ({32{exe_op[`_MTLO]}} & exe_vsrc1) : low;
		de_en <= (~excp && (de_out_op[`_DIV]) || (de_out_op[`_DIVU]))?2 : 
				 (en)?1 : de_en;
		md_reg <= md_result;
		`ifdef SIMU_DEBUG
		exe_pc <= de_pc;
		exe_inst <= de_inst;
		`endif
	end else begin
		exe_op       <= 5'd0;
		exe_vsrc1    <= 32'd0;
		exe_vsrc2    <= 32'd0;
		exe_st_value <= 32'd0;
		exe_dest_r   <= 32'd0;
		last_op      <= 5'd0;
		high         <= 32'd0;
		low          <= 32'd0;
		de_en        <= 32'd0;
		`ifdef SIMU_DEBUG
		exe_pc       <= 32'd0;
		exe_inst     <= 32'd0;
		`endif
	end
end 

alu alu0
    (
    .aluop  ( ALUop ), //I, ??
    .vsrc1  ( ALU_srcA ), //I, 32
    .vsrc2  ( ALU_srcB ), //I, 32
    .result ( ALU_result ),  //O, 32
	.overflow(overflow)
    );
	
md md0
    (
	.clk(clk),
	.resetn(resetn),
	.md_op(md_op),
	.src1 (ALU_srcA),
	.src2 (ALU_srcB),
	.result(md_result),
	.en(en)
	);

endmodule //execute_stage
