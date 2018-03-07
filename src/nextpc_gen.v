
`define SIMU_DEBUG

module nextpc_gen(
    input              clk,
    input  wire        resetn,
	input  wire        eret,
	input  wire        stall,

	input  wire [31:0] epc,
    input  wire [31:0] fe_pc,
	input  wire        excp,
    input  wire        exe_out_en,

    input  wire        de_br_taken,     //1: branch taken, go to the branch target
    input  wire        de_br_is_br,     //1: target is PC+offset
    input  wire        de_br_is_j,      //1: target is PC||offset
    input  wire        de_br_is_jr,     //1: target is GR value
    input  wire [15:0] de_br_offset,    //offset for type "br"
    input  wire [25:0] de_br_index,     //instr_index for type "j"
    input  wire [31:0] de_br_target,    //target for type "jr"
	input  wire [5 :0] tlb_exce,

    output wire [31:0] nextpc
);
wire [31:0] offset,index;
reg         div_exc;
reg  [31:0] last_npc;
always @(posedge clk)
begin
	if (~resetn)
	begin
		div_exc <= 0;
		last_npc <= 32'hbfc00000;
	end
	else
	begin
	if (~exe_out_en && nextpc == 32'hbfc00380)
		div_exc <= 1;
	else div_exc <=0;
	last_npc <= nextpc;
	end
end

assign offset = {{14{de_br_offset[15]}},de_br_offset,2'b00};
assign index = {fe_pc[31:28],de_br_index,2'b00};

assign nextpc = (|tlb_exce[1:0])?32'hbfc00200 :
				(stall)?last_npc :
				(excp | (|tlb_exce[5:2]))?32'hbfc00380 :
				(div_exc)?32'hbfc00380 :
				de_br_taken?(({32{de_br_is_br}} & (fe_pc + offset))
						   | ({32{de_br_is_j }} & (index))
						   | ({32{de_br_is_jr}} & (de_br_target))) :
				fe_pc + 4;

endmodule //nextpc_gen
