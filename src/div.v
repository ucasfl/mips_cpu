module div(
	input  wire        div_clk,
	input  wire        resetn,
	input  wire        div,
	input  wire        div_signed,
	input  wire [31:0] x,
	input  wire [31:0] y,
	output wire [31:0] s,
	output wire [31:0] r,
	output wire        complete
);

reg  [ 3:0] count;
reg  [31:0] x_uns, y_uns;
reg         s_sign, r_sign;
reg  [63:0] A;
wire [63:0] B;
reg  [31:0] Q;
wire [63:0] diff, diff2;
wire [63:0] next_A;
wire        q, q2;
wire [63:0] A2;
wire [31:0] Q2;
wire [31:0] s_s, r_s, s_us, r_us;

wire [63:0] diff3, diff4;
wire [63:0] A3, A4;
wire [31:0] Q3, Q4;
wire        q3, q4;

assign diff = A - B;
assign diff2 = A2 - B;
assign diff3 = A3 - B;
assign diff4 = A4 - B;
assign A2 = (q)? {diff[62:31], A[30:0], 1'b0} : {A[62:0], 1'b0};
assign A3 = (q2)? {diff2[62:31], A2[30:0], 1'b0} : {A2[62:0], 1'b0};
assign A4 = (q3)? {diff3[62:31], A3[30:0], 1'b0} : {A3[62:0], 1'b0};
assign Q2 = {Q[30:0], q};
assign Q3 = {Q2[30:0], q2};
assign Q4 = {Q3[30:0], q3};
assign q = ~diff[63];
assign q2 = ~diff2[63];
assign q3 = ~diff3[63];
assign q4 = ~diff4[63];

assign B = {1'b0, y_uns, 31'b0};

assign next_A = (count == 5'd1)?{32'd0, x_uns} :
				(q4)? {diff4[62:31], A4[30:0], 1'b0} : {A4[62:0], 1'b0};

always @ (posedge div_clk)
begin
	if(~resetn)
	begin
		A      <= 64'd0;
		Q      <= 32'd0;
		count  <= 5'd0;
		x_uns  <= 32'd0;
		y_uns  <= 32'd0;
		s_sign <= 1'd0;
		r_sign <= 1'd0;
	end else begin
		A <= next_A;
		Q <= {Q4[30:0], q4};
		count <= (div)? 1 : 
				 (count == 5'd0)?0 : count + 1;
		x_uns <= (~div)?x_uns : 
				 (div_signed & x[31])?(~x + 1) : x;
		y_uns <= (~div)?y_uns : 
				 (div_signed & y[31])?(~y + 1) : y;
		s_sign <= (~div)?s_sign : 
				  (div_signed)?(x[31] ^ y[31]) : 0;
		r_sign <= (~div)?r_sign : 
				  (div_signed)?x[31] : 0;
	end
end

assign complete = count == 10;

assign s_us = Q;
assign r_us = A[63:32];

assign s_s = ~Q + 1;
assign r_s = ~r_us + 1;

assign s = (s_sign)?s_s : s_us;
assign r = (r_sign)?r_s : r_us;

endmodule
