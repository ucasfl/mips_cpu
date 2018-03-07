/*************************************************************************
    > Filename: exception.v
    > Author: Lv Feng
    > Mail: lvfeng97@outlook.com
    > Date: 2017-11-18
 ************************************************************************/

module exception(
	input         clk,
	input         resetn,
	output        is_exc,
	input         stall,

	input         syscall,
	input         break,
	input         de_badaddr,
	input         ex_rbadaddr,
	input         ex_wbadaddr,
	input         instu,
	input         overf,
    input  [5 :0] int_n_i,
	input  [5 :0] tlb_exce,
	input         is_store,

	input         exce_isbr,
	input         eret,
	input  [4 :0] addr,
	input  [31:0] inc0,

	input  [31:0] fe_pc,
	input  [31:0] de_pc,
	input  [31:0] inst_sram_addr,
	input  [31:0] data_sram_addr,
	input  [31:0] de_vaddr,
	input  [31:0] exe_vaddr,
	input  [31:0] exe_pc,
	input         c0_wen,
	output        excep,
	output        exe_exc,
	output [31:0] exce_c0,
	output [31:0] epc
);

reg  [31:0] EPC, CAUSE, STATUS, COMPARE, COUNT, BadVAddr;
reg         step;
reg         softint, hardint;
reg         last_br, llast_br;
wire [ 4:0] Ecode;
wire mtepc, mtcas, mtsts, mtcpr, mtcot;
wire mfepc, mfcas, mfsts, mfcpr, mfbva;
wire clkin, de_exc;

assign is_exc = STATUS[1];
assign mtepc = c0_wen && (addr == 5'd14);
assign mtcas = c0_wen && (addr == 5'd13);
assign mtsts = c0_wen && (addr == 5'd12);
assign mtcpr = c0_wen && (addr == 5'd11);
assign mtcot = c0_wen && (addr == 5'd9);
assign Ecode = (exe_exc || (|tlb_exce))?
			   ({5{ex_rbadaddr}} & 5'd4) |
			   ({5{ex_wbadaddr}} & 5'd5) |
			   ({5{overf}} & 5'd12) |
			   ({5{tlb_exce[4]|tlb_exce[5]}} & 5'd1) |
			   (is_store?({5{|tlb_exce[3:0]}}&5'd3):({5{|tlb_exce[3:0]}}&5'd2)) :
			   ({5{de_badaddr}} & 5'd4) |
			   ({5{syscall}} & 5'd8) |
			   ({5{break}} & 5'd9) |
			   ({5{instu}} & 5'd10);

always @ (posedge clk)
begin
	if(stall) begin
		EPC <= EPC;
		CAUSE <= CAUSE;
		STATUS <= STATUS;
		COMPARE <= COMPARE;
		COUNT <= (COUNT == COMPARE) ? COUNT :
				 (step)? COUNT + 1 : COUNT;
		BadVAddr <= BadVAddr;
		step <= ~step;
		softint <= softint;
		hardint <= hardint;
		last_br <= last_br;
		llast_br <= llast_br;
	end else if (resetn)
	begin
		EPC <= (softint | hardint)?de_pc :
			   (clkin | exe_exc | de_exc) ? (last_br?exe_pc-4 : exe_pc) :
			   (tlb_exce[0] | tlb_exce[2] | tlb_exce[4]) ? exe_pc-4 :
			   (tlb_exce[1] | tlb_exce[3] | tlb_exce[5]) ? fe_pc :
			   (de_badaddr) ? de_vaddr :
			   //(de_exc)? (last_br? exe_pc-4 : exe_pc) :
			   (mtepc)?inc0 : EPC;
		CAUSE <= (excep)?(last_br?{1'b1, clkin, CAUSE[29:16], clkin, ~int_n_i[4:0], CAUSE[9:7], Ecode, CAUSE[1:0]} : 
		         {CAUSE[31], clkin, CAUSE[29:16], clkin, ~int_n_i[4:0], CAUSE[9:7], Ecode, CAUSE[1:0]}) : 
				 (mtcas)?inc0 : {CAUSE[31:15], ~int_n_i[4:0], CAUSE[9:0]};
		STATUS <= (excep)? {STATUS[31:2], 1'b1, STATUS[0]} : 
				  (eret)? {STATUS[31:2], 1'b0, STATUS[0]} :
				  (mtsts) ? inc0 : STATUS;
		COMPARE <= (mtcpr) ? inc0 : COMPARE;
		COUNT <= (mtcot) ? inc0 :
				 (COUNT == COMPARE) ? 32'd0 :
				 (step)? COUNT + 1 : COUNT;
		BadVAddr <= (de_badaddr)? de_vaddr :
					(ex_rbadaddr | ex_wbadaddr)? exe_vaddr :
					(tlb_exce[0] | tlb_exce[2] | tlb_exce[4])? data_sram_addr :
					(tlb_exce[1] | tlb_exce[3] | tlb_exce[5])? inst_sram_addr : BadVAddr;
		step <= (mtcpr || COUNT == COMPARE)? 0 : ~step;
		softint <= (softint | STATUS[1])? 0 : (CAUSE[8] | CAUSE[9]);
		hardint <= (hardint | STATUS[1])? 0 : ~int_n_i[0];
		last_br <= exce_isbr;
		llast_br <= last_br;
	end
	else
	begin
		EPC <= 32'd0;
		CAUSE <= 32'd0;
		STATUS <= 32'h00400000;
		COMPARE <= 32'd0;
		COUNT <= 32'd0;
		BadVAddr <= 32'd0;
		step <= 0;
		softint <= 0;
		hardint <= 0;
		last_br <= 0;
		llast_br <= 0;
	end
end
assign clkin = (|COUNT) && (COUNT == COMPARE) && ~STATUS[1];
assign de_exc = syscall | break | de_badaddr | instu;
assign exe_exc = overf | ex_rbadaddr | ex_wbadaddr;
assign excep = (softint | hardint)? 1 :
			   STATUS[1]? 0 :
			   clkin? 1 :
			   (exe_exc || (|tlb_exce))? 1 : de_exc;

assign mfepc = addr == 5'd14;
assign mfcas = addr == 5'd13;
assign mfsts = addr == 5'd12;
assign mfcpr = addr == 5'd11;
assign mfbva = addr == 5'd8;
assign exce_c0 = ({32{mfepc}} & EPC) | 
			({32{mfcas}} & CAUSE) |
			({32{mfsts}} & STATUS) |
			({32{mfcpr}} & COMPARE) |
			({32{mfbva}} & BadVAddr);
assign epc = EPC;
endmodule
