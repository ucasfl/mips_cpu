module alu(
	input [31: 0] vsrc1,
	input [31: 0] vsrc2,
	input [12: 0] aluop,
	output [31:0] result,
	output        overflow
);

	wire alu_add;
	wire alu_sub;
	wire alu_or;
	wire alu_slt;
	wire alu_sltu;
	wire alu_sll;
	wire alu_lui;
	wire alu_and;
	wire alu_xor;
	wire alu_nor;
	wire alu_srl;
	wire alu_sra;
	
	assign alu_add = aluop[2];
	assign alu_sub = aluop[6];
	assign alu_or = aluop[1];
	assign alu_slt = aluop[7];
	assign alu_sltu = aluop[0];
	assign alu_sll = aluop[3];
	assign alu_lui = aluop[4];
	//4'b0101
	assign alu_and = aluop[8];
	assign alu_xor = aluop[9];
	assign alu_nor = aluop[10];
	assign alu_srl = aluop[11];
	assign alu_sra = aluop[12];

	wire [31: 0] add_sub_result;
	wire [31: 0] or_result;
	wire [31: 0] slt_result;
	wire [31: 0] sltu_result;
	wire [31: 0] sll_result;
	wire [31: 0] lui_result;
	wire [31: 0] and_result;
	wire [31: 0] xor_result;
	wire [31: 0] nor_result;
	wire [31: 0] sr_result;
	wire [63: 0] sr64_result;
	
	assign or_result = vsrc1 | vsrc2;
	assign and_result = vsrc1 & vsrc2;
	assign xor_result = vsrc1 ^ vsrc2;
	assign nor_result = ~or_result;
	assign lui_result = {vsrc2[15: 0],vsrc1[31:16]};
	assign sll_result = vsrc1 << vsrc2[4:0];
	
	wire [31: 0] adder_b;
	wire adder_c;
	wire adder_cout;
	wire sub;
	wire [31: 0] a, b, r;
	assign sub = alu_sub || alu_slt || alu_sltu;
	assign adder_b = vsrc2 ^ {32{sub}};
	assign {adder_cout, add_sub_result} = vsrc1 + adder_b + sub;
	assign a = {1'b0, vsrc1[30:0]};
	assign b = {1'b0, adder_b[30:0]};
	assign r = a + b + sub;
	assign overflow = r[31] ^ adder_cout;
	
	assign slt_result[31: 1] = 31'd0;
	assign slt_result[0] = (vsrc1[31] & ~vsrc2[31]) | (~(vsrc1[31] ^ vsrc2[31]) & add_sub_result[31]);
	
	assign sltu_result[31: 1] = 31'd0;
	assign sltu_result[0] = ~adder_cout;
	
	assign sr64_result = {{32{alu_sra & vsrc1[31]}},vsrc1[31: 0]} >> vsrc2[4:0];
	assign sr_result = sr64_result[31: 0];
	
	assign result = ({32{alu_add|alu_sub}} & add_sub_result)
				  | ({32{alu_slt  }} & slt_result)
				  | ({32{alu_sltu}} & sltu_result)
				  | ({32{alu_lui  }} & lui_result)
				  | ({32{alu_or   }} & or_result)
				  | ({32{alu_sll  }} & sll_result)
				  | ({32{alu_and  }} & and_result)
				  | ({32{alu_xor  }} & xor_result)
				  | ({32{alu_nor  }} & nor_result)
				  | ({32{alu_srl|alu_sra}} & sr_result);
endmodule
