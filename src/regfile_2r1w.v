/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/


module regfile_2r1w(
    input         clk,
	input         resetn,

    input  [ 4:0] ra1,
    output [31:0] rd1,

    input  [ 4:0] ra2,
    output [31:0] rd2,

    input  [ 3:0] we1,
    input  [ 4:0] wa1,
    input  [31:0] wd1
);

reg  [31:0] heap [31:0];
wire [ 7:0] wdata0, wdata1, wdata2, wdata3;
wire [31:0] wdata;

assign rd1 = heap[ra1];
assign rd2 = heap[ra2];
assign wdata  = heap[wa1];
assign wdata0 = (we1[0])?wd1[7:0] : wdata[7:0];
assign wdata1 = (we1[1])?wd1[15:8] : wdata[15:8];
assign wdata2 = (we1[2])?wd1[23:16] : wdata[23:16];
assign wdata3 = (we1[3])?wd1[31:24] : wdata[31:24];

always @(posedge clk)
begin
	if(resetn)
	begin
		heap[0] <= 32'b0;
		if ((|we1) && (|wa1)) begin
			heap[wa1] <= {wdata3, wdata2, wdata1, wdata0};
		end
	end else begin
		heap[0] <= 32'd0;
		heap[1] <= 32'd0;
		heap[2] <= 32'd0;
		heap[3] <= 32'd0;
		heap[4] <= 32'd0;
		heap[5] <= 32'd0;
		heap[6] <= 32'd0;
		heap[7] <= 32'd0;
		heap[8] <= 32'd0;
		heap[9] <= 32'd0;
		heap[10] <= 32'd0;
		heap[11] <= 32'd0;
		heap[12] <= 32'd0;
		heap[13] <= 32'd0;
		heap[14] <= 32'd0;
		heap[15] <= 32'd0;
		heap[16] <= 32'd0;
		heap[17] <= 32'd0;
		heap[18] <= 32'd0;
		heap[19] <= 32'd0;
		heap[20] <= 32'd0;
		heap[21] <= 32'd0;
		heap[22] <= 32'd0;
		heap[23] <= 32'd0;
		heap[24] <= 32'd0;
		heap[25] <= 32'd0;
		heap[26] <= 32'd0;
		heap[27] <= 32'd0;
		heap[28] <= 32'd0;
		heap[29] <= 32'd0;
		heap[30] <= 32'd0;
		heap[31] <= 32'd0;
	end
end

endmodule //regfile_2r1w

