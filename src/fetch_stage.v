
`define SIMU_DEBUG

module fetch_stage(
    input  wire        clk,
    input  wire        resetn,
    input  wire        fe_en,
	input  wire        stall,

    input  wire [31:0] nextpc,

    output wire        inst_sram_en,
    output wire [31:0] inst_sram_addr,

    output reg  [31:0] fe_pc            //fetch_stage pc
);

always @(posedge clk)
	begin
		if(~resetn) fe_pc <= 32'hbfc00000;
		else if(fe_en && ~stall) fe_pc <= nextpc;
		else fe_pc <= fe_pc;
	end
	
assign inst_sram_en = fe_en; //1'b1;
assign inst_sram_addr = (~stall)?nextpc : fe_pc;

endmodule //fetch_stage
