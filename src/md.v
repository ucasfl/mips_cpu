module md(
	input         clk,
	input         resetn,
	input  [ 3:0] md_op,
    input  [31:0] src1,
	input  [31:0] src2,
	output [63:0] result,
	output        en
);

wire        vd, vd1;
wire [63:0] dresult,  mresult;
wire [63:0] umresult;
reg  [ 3:0] lastmd_op;
wire        complete;
wire        div;

assign vd = md_op[0];
assign vd1 = md_op[1];
assign en = lastmd_op[2] | lastmd_op[3] | complete;

assign result = ({64{complete}} & dresult) |
				({64{lastmd_op[2]}} & mresult) |
				({64{lastmd_op[3]}} & umresult);
assign div = vd | vd1;

always @(posedge clk)
begin
	lastmd_op <= md_op;
end 

div dd(
	.div_clk  (clk),
	.resetn   (resetn),
	.div      (div),
	.div_signed (vd),
	.x        (src1),
	.y        (src2),
	.s        (dresult[31:0]),
	.r        (dresult[63:32]),
	.complete (complete)
);

mult_gen_0 mm(
	.CLK(clk),
	.A(src1),
	.B(src2),
	.P(mresult)
);

mult_gen_1 mm1(
	.CLK(clk),
	.A(src1),
	.B(src2),
	.P(umresult)
);
endmodule
