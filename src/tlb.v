module tlb(
	input  wire        clk,
	input  wire        resetn,
	input  wire        stall,

	input  wire        inst_sram_en,
	input  wire [31:0] inst_sram_addr,

	input  wire        data_sram_en,
	input  wire [3 :0] data_sram_wen,
	input  wire [31:0] data_sram_addr,

	input  wire        tlbr,
	input  wire        tlbwi,
	input  wire        tlbp,

	input  wire        c0_wen,
	input  wire [4 :0] addr,
	input  wire [31:0] inc0,
	output wire [31:0] tlb_c0,

	output wire [31:0] inst_paddr,
	output wire [31:0] data_paddr,

	output wire        is_store,
	output wire [5 :0] tlb_exce
);

wire        inst_mapped, data_mapped, mapped;
wire        mtehi, mtlo0, mtlo1, mtpm, mtidx;
wire        mfehi, mflo0, mflo1, mfpm, mfidx;
wire        inst_refill, inst_invalid, inst_modified;
wire        data_refill, data_invalid, data_modified;
wire [31:0] inst_mpaddr, data_mpaddr;
wire [4 :0] id;
wire [31:0] inst_found, data_found, tlbp_found;
wire [31:0] inst_valid, data_valid, data_d;
reg         im_r, dm_r, ii_r, di_r, ir_r, dr_r;
reg  [5 :0] exce_reg;
reg  [31:0] EntryHi, PageMask, EntryLo0, EntryLo1, Index;
//TLB
reg  [26:0] TLB_EH[31:0];
reg  [11:0] TLB_PM[31:0];
reg         TLB_G[31:0];
reg  [24:0] TLB_L0[31:0];
reg  [24:0] TLB_L1[31:0]; 

assign inst_mapped = !inst_sram_addr[31];
assign data_mapped = !data_sram_addr[31];
assign mapped = inst_mapped || data_mapped;
assign mtidx = c0_wen && mfidx;
assign mtlo0 = c0_wen && mflo0;
assign mtlo1 = c0_wen && mflo1;
assign mtpm  = c0_wen && mfpm;
assign mtehi = c0_wen && mfehi;
assign id = Index[4:0];
assign tlbp_found[0] = EntryHi[31:13] == TLB_EH[0][26:8] && (TLB_G[0] || EntryHi[7:0] == TLB_EH[0][7:0]);
assign tlbp_found[1] = EntryHi[31:13] == TLB_EH[1][26:8] && (TLB_G[1] || EntryHi[7:0] == TLB_EH[1][7:0]);
assign tlbp_found[2] = EntryHi[31:13] == TLB_EH[2][26:8] && (TLB_G[2] || EntryHi[7:0] == TLB_EH[2][7:0]);
assign tlbp_found[3] = EntryHi[31:13] == TLB_EH[3][26:8] && (TLB_G[3] || EntryHi[7:0] == TLB_EH[3][7:0]);
assign tlbp_found[4] = EntryHi[31:13] == TLB_EH[4][26:8] && (TLB_G[4] || EntryHi[7:0] == TLB_EH[4][7:0]);
assign tlbp_found[5] = EntryHi[31:13] == TLB_EH[5][26:8] && (TLB_G[5] || EntryHi[7:0] == TLB_EH[5][7:0]);
assign tlbp_found[6] = EntryHi[31:13] == TLB_EH[6][26:8] && (TLB_G[6] || EntryHi[7:0] == TLB_EH[6][7:0]);
assign tlbp_found[7] = EntryHi[31:13] == TLB_EH[7][26:8] && (TLB_G[7] || EntryHi[7:0] == TLB_EH[7][7:0]);
assign tlbp_found[8] = EntryHi[31:13] == TLB_EH[8][26:8] && (TLB_G[8] || EntryHi[7:0] == TLB_EH[8][7:0]);
assign tlbp_found[9] = EntryHi[31:13] == TLB_EH[9][26:8] && (TLB_G[9] || EntryHi[7:0] == TLB_EH[9][7:0]);
assign tlbp_found[10] = EntryHi[31:13] == TLB_EH[10][26:8] && (TLB_G[10] || EntryHi[7:0] == TLB_EH[10][7:0]);
assign tlbp_found[11] = EntryHi[31:13] == TLB_EH[11][26:8] && (TLB_G[11] || EntryHi[7:0] == TLB_EH[11][7:0]);
assign tlbp_found[12] = EntryHi[31:13] == TLB_EH[12][26:8] && (TLB_G[12] || EntryHi[7:0] == TLB_EH[12][7:0]);
assign tlbp_found[13] = EntryHi[31:13] == TLB_EH[13][26:8] && (TLB_G[13] || EntryHi[7:0] == TLB_EH[13][7:0]);
assign tlbp_found[14] = EntryHi[31:13] == TLB_EH[14][26:8] && (TLB_G[14] || EntryHi[7:0] == TLB_EH[14][7:0]);
assign tlbp_found[15] = EntryHi[31:13] == TLB_EH[15][26:8] && (TLB_G[15] || EntryHi[7:0] == TLB_EH[15][7:0]);
assign tlbp_found[16] = EntryHi[31:13] == TLB_EH[16][26:8] && (TLB_G[16] || EntryHi[7:0] == TLB_EH[16][7:0]);
assign tlbp_found[17] = EntryHi[31:13] == TLB_EH[17][26:8] && (TLB_G[17] || EntryHi[7:0] == TLB_EH[17][7:0]);
assign tlbp_found[18] = EntryHi[31:13] == TLB_EH[18][26:8] && (TLB_G[18] || EntryHi[7:0] == TLB_EH[18][7:0]);
assign tlbp_found[19] = EntryHi[31:13] == TLB_EH[19][26:8] && (TLB_G[19] || EntryHi[7:0] == TLB_EH[19][7:0]);
assign tlbp_found[20] = EntryHi[31:13] == TLB_EH[20][26:8] && (TLB_G[20] || EntryHi[7:0] == TLB_EH[20][7:0]);
assign tlbp_found[21] = EntryHi[31:13] == TLB_EH[21][26:8] && (TLB_G[21] || EntryHi[7:0] == TLB_EH[21][7:0]);
assign tlbp_found[22] = EntryHi[31:13] == TLB_EH[22][26:8] && (TLB_G[22] || EntryHi[7:0] == TLB_EH[22][7:0]);
assign tlbp_found[23] = EntryHi[31:13] == TLB_EH[23][26:8] && (TLB_G[23] || EntryHi[7:0] == TLB_EH[23][7:0]);
assign tlbp_found[24] = EntryHi[31:13] == TLB_EH[24][26:8] && (TLB_G[24] || EntryHi[7:0] == TLB_EH[24][7:0]);
assign tlbp_found[25] = EntryHi[31:13] == TLB_EH[25][26:8] && (TLB_G[25] || EntryHi[7:0] == TLB_EH[25][7:0]);
assign tlbp_found[26] = EntryHi[31:13] == TLB_EH[26][26:8] && (TLB_G[26] || EntryHi[7:0] == TLB_EH[26][7:0]);
assign tlbp_found[27] = EntryHi[31:13] == TLB_EH[27][26:8] && (TLB_G[27] || EntryHi[7:0] == TLB_EH[27][7:0]);
assign tlbp_found[28] = EntryHi[31:13] == TLB_EH[28][26:8] && (TLB_G[28] || EntryHi[7:0] == TLB_EH[28][7:0]);
assign tlbp_found[29] = EntryHi[31:13] == TLB_EH[29][26:8] && (TLB_G[29] || EntryHi[7:0] == TLB_EH[29][7:0]);
assign tlbp_found[30] = EntryHi[31:13] == TLB_EH[30][26:8] && (TLB_G[30] || EntryHi[7:0] == TLB_EH[30][7:0]);
assign tlbp_found[31] = EntryHi[31:13] == TLB_EH[31][26:8] && (TLB_G[31] || EntryHi[7:0] == TLB_EH[31][7:0]);
always @ (posedge clk)
begin
	exce_reg <= (stall)?exce_reg : tlb_exce;
	if(resetn)
	begin
		im_r <= inst_modified;
		dm_r <= data_modified;
		ii_r <= inst_invalid;
		di_r <= data_invalid;
		ir_r <= inst_refill;
		dr_r <= data_refill;
		EntryHi  <= (mtehi)? {inc0[31:13], 5'd0, inc0[7:0]} :
					(data_refill || data_invalid || data_modified)? {data_sram_addr[31:13], EntryHi[12:0]} :
					(inst_refill || inst_invalid || inst_modified)? {inst_sram_addr[31:13], EntryHi[12:0]} :
					(tlbr)? {TLB_EH[id][26:8], 5'd0, TLB_EH[id][7:0]} : EntryHi;
		PageMask <= (mtpm )? {7'd0, inc0[24:13], 13'd0} :
					(tlbr)? {7'd0, TLB_PM[id], 13'd0} : PageMask;
		EntryLo0 <= (mtlo0)? {6'd0, inc0[25:0]} :
					(tlbr)? {6'd0, TLB_L0[id][24:0], TLB_G[id]} : EntryLo0;
		EntryLo1 <= (mtlo1)? {6'd0, inc0[25:0]} :
					(tlbr)? {6'd0, TLB_L1[id][24:0], TLB_G[id]} : EntryLo1;
		Index    <= (mtidx)? {27'd0, inc0[4:0]} :
					(tlbp)?((|tlbp_found)? {5{tlbp_found[0]}}&5'd0 | {5{tlbp_found[1]}}&5'd1 | {5{tlbp_found[2]}}&5'd2 | {5{tlbp_found[3]}}&5'd3
										 | {5{tlbp_found[4]}}&5'd4 | {5{tlbp_found[5]}}&5'd5 | {5{tlbp_found[6]}}&5'd6 | {5{tlbp_found[7]}}&5'd7
										 | {5{tlbp_found[8]}}&5'd8 | {5{tlbp_found[9]}}&5'd9 | {5{tlbp_found[10]}}&5'd10 | {5{tlbp_found[11]}}&5'd11
										 | {5{tlbp_found[12]}}&5'd12 | {5{tlbp_found[13]}}&5'd13 | {5{tlbp_found[14]}}&5'd14 | {5{tlbp_found[15]}}&5'd15
										 | {5{tlbp_found[16]}}&5'd16 | {5{tlbp_found[17]}}&5'd17 | {5{tlbp_found[18]}}&5'd18 | {5{tlbp_found[19]}}&5'd19
										 | {5{tlbp_found[20]}}&5'd20 | {5{tlbp_found[21]}}&5'd21 | {5{tlbp_found[22]}}&5'd22 | {5{tlbp_found[23]}}&5'd23
										 | {5{tlbp_found[24]}}&5'd24 | {5{tlbp_found[25]}}&5'd25 | {5{tlbp_found[26]}}&5'd26 | {5{tlbp_found[27]}}&5'd27
										 | {5{tlbp_found[28]}}&5'd28 | {5{tlbp_found[29]}}&5'd29 | {5{tlbp_found[30]}}&5'd30 | {5{tlbp_found[31]}}&5'd31
										 : {1'b1, Index[30:0]}) : Index;
		TLB_EH[0] <= (tlbwi && id == 5'd0)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[0];
		TLB_EH[1] <= (tlbwi && id == 5'd1)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[1];
		TLB_EH[2] <= (tlbwi && id == 5'd2)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[2];
		TLB_EH[3] <= (tlbwi && id == 5'd3)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[3];
		TLB_EH[4] <= (tlbwi && id == 5'd4)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[4];
		TLB_EH[5] <= (tlbwi && id == 5'd5)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[5];
		TLB_EH[6] <= (tlbwi && id == 5'd6)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[6];
		TLB_EH[7] <= (tlbwi && id == 5'd7)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[7];
		TLB_EH[8] <= (tlbwi && id == 5'd8)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[8];
		TLB_EH[9] <= (tlbwi && id == 5'd9)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[9];
		TLB_EH[10] <= (tlbwi && id == 5'd10)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[10];
		TLB_EH[11] <= (tlbwi && id == 5'd11)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[11];
		TLB_EH[12] <= (tlbwi && id == 5'd12)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[12];
		TLB_EH[13] <= (tlbwi && id == 5'd13)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[13];
		TLB_EH[14] <= (tlbwi && id == 5'd14)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[14];
		TLB_EH[15] <= (tlbwi && id == 5'd15)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[15];
		TLB_EH[16] <= (tlbwi && id == 5'd16)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[16];
		TLB_EH[17] <= (tlbwi && id == 5'd17)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[17];
		TLB_EH[18] <= (tlbwi && id == 5'd18)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[18];
		TLB_EH[19] <= (tlbwi && id == 5'd19)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[19];
		TLB_EH[20] <= (tlbwi && id == 5'd20)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[20];
		TLB_EH[21] <= (tlbwi && id == 5'd21)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[21];
		TLB_EH[22] <= (tlbwi && id == 5'd22)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[22];
		TLB_EH[23] <= (tlbwi && id == 5'd23)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[23];
		TLB_EH[24] <= (tlbwi && id == 5'd24)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[24];
		TLB_EH[25] <= (tlbwi && id == 5'd25)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[25];
		TLB_EH[26] <= (tlbwi && id == 5'd26)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[26];
		TLB_EH[27] <= (tlbwi && id == 5'd27)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[27];
		TLB_EH[28] <= (tlbwi && id == 5'd28)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[28];
		TLB_EH[29] <= (tlbwi && id == 5'd29)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[29];
		TLB_EH[30] <= (tlbwi && id == 5'd30)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[30];
		TLB_EH[31] <= (tlbwi && id == 5'd31)?{EntryHi[31:13], EntryHi[7:0]} : TLB_EH[31];
		TLB_G[0] <= (tlbwi && id == 5'd0)?EntryLo0[0] && EntryLo1[0] : TLB_G[0];
		TLB_G[1] <= (tlbwi && id == 5'd1)?EntryLo0[0] && EntryLo1[0] : TLB_G[1];
		TLB_G[2] <= (tlbwi && id == 5'd2)?EntryLo0[0] && EntryLo1[0] : TLB_G[2];
		TLB_G[3] <= (tlbwi && id == 5'd3)?EntryLo0[0] && EntryLo1[0] : TLB_G[3];
		TLB_G[4] <= (tlbwi && id == 5'd4)?EntryLo0[0] && EntryLo1[0] : TLB_G[4];
		TLB_G[5] <= (tlbwi && id == 5'd5)?EntryLo0[0] && EntryLo1[0] : TLB_G[5];
		TLB_G[6] <= (tlbwi && id == 5'd6)?EntryLo0[0] && EntryLo1[0] : TLB_G[6];
		TLB_G[7] <= (tlbwi && id == 5'd7)?EntryLo0[0] && EntryLo1[0] : TLB_G[7];
		TLB_G[8] <= (tlbwi && id == 5'd8)?EntryLo0[0] && EntryLo1[0] : TLB_G[8];
		TLB_G[9] <= (tlbwi && id == 5'd9)?EntryLo0[0] && EntryLo1[0] : TLB_G[9];
		TLB_G[10] <= (tlbwi && id == 5'd10)?EntryLo0[0] && EntryLo1[0] : TLB_G[10];
		TLB_G[11] <= (tlbwi && id == 5'd11)?EntryLo0[0] && EntryLo1[0] : TLB_G[11];
		TLB_G[12] <= (tlbwi && id == 5'd12)?EntryLo0[0] && EntryLo1[0] : TLB_G[12];
		TLB_G[13] <= (tlbwi && id == 5'd13)?EntryLo0[0] && EntryLo1[0] : TLB_G[13];
		TLB_G[14] <= (tlbwi && id == 5'd14)?EntryLo0[0] && EntryLo1[0] : TLB_G[14];
		TLB_G[15] <= (tlbwi && id == 5'd15)?EntryLo0[0] && EntryLo1[0] : TLB_G[15];
		TLB_G[16] <= (tlbwi && id == 5'd16)?EntryLo0[0] && EntryLo1[0] : TLB_G[16];
		TLB_G[17] <= (tlbwi && id == 5'd17)?EntryLo0[0] && EntryLo1[0] : TLB_G[17];
		TLB_G[18] <= (tlbwi && id == 5'd18)?EntryLo0[0] && EntryLo1[0] : TLB_G[18];
		TLB_G[19] <= (tlbwi && id == 5'd19)?EntryLo0[0] && EntryLo1[0] : TLB_G[19];
		TLB_G[20] <= (tlbwi && id == 5'd20)?EntryLo0[0] && EntryLo1[0] : TLB_G[20];
		TLB_G[21] <= (tlbwi && id == 5'd21)?EntryLo0[0] && EntryLo1[0] : TLB_G[21];
		TLB_G[22] <= (tlbwi && id == 5'd22)?EntryLo0[0] && EntryLo1[0] : TLB_G[22];
		TLB_G[23] <= (tlbwi && id == 5'd23)?EntryLo0[0] && EntryLo1[0] : TLB_G[23];
		TLB_G[24] <= (tlbwi && id == 5'd24)?EntryLo0[0] && EntryLo1[0] : TLB_G[24];
		TLB_G[25] <= (tlbwi && id == 5'd25)?EntryLo0[0] && EntryLo1[0] : TLB_G[25];
		TLB_G[26] <= (tlbwi && id == 5'd26)?EntryLo0[0] && EntryLo1[0] : TLB_G[26];
		TLB_G[27] <= (tlbwi && id == 5'd27)?EntryLo0[0] && EntryLo1[0] : TLB_G[27];
		TLB_G[28] <= (tlbwi && id == 5'd28)?EntryLo0[0] && EntryLo1[0] : TLB_G[28];
		TLB_G[29] <= (tlbwi && id == 5'd29)?EntryLo0[0] && EntryLo1[0] : TLB_G[29];
		TLB_G[30] <= (tlbwi && id == 5'd30)?EntryLo0[0] && EntryLo1[0] : TLB_G[30];
		TLB_G[31] <= (tlbwi && id == 5'd31)?EntryLo0[0] && EntryLo1[0] : TLB_G[31]; 
		TLB_PM[0] <= (tlbwi && id == 5'd0)?PageMask[24:13] : TLB_PM[0];
		TLB_PM[1] <= (tlbwi && id == 5'd1)?PageMask[24:13] : TLB_PM[1];
		TLB_PM[2] <= (tlbwi && id == 5'd2)?PageMask[24:13] : TLB_PM[2];
		TLB_PM[3] <= (tlbwi && id == 5'd3)?PageMask[24:13] : TLB_PM[3];
		TLB_PM[4] <= (tlbwi && id == 5'd4)?PageMask[24:13] : TLB_PM[4];
		TLB_PM[5] <= (tlbwi && id == 5'd5)?PageMask[24:13] : TLB_PM[5];
		TLB_PM[6] <= (tlbwi && id == 5'd6)?PageMask[24:13] : TLB_PM[6];
		TLB_PM[7] <= (tlbwi && id == 5'd7)?PageMask[24:13] : TLB_PM[7];
		TLB_PM[8] <= (tlbwi && id == 5'd8)?PageMask[24:13] : TLB_PM[8];
		TLB_PM[9] <= (tlbwi && id == 5'd9)?PageMask[24:13] : TLB_PM[9];
		TLB_PM[10] <= (tlbwi && id == 5'd10)?PageMask[24:13] : TLB_PM[10];
		TLB_PM[11] <= (tlbwi && id == 5'd11)?PageMask[24:13] : TLB_PM[11];
		TLB_PM[12] <= (tlbwi && id == 5'd12)?PageMask[24:13] : TLB_PM[12];
		TLB_PM[13] <= (tlbwi && id == 5'd13)?PageMask[24:13] : TLB_PM[13];
		TLB_PM[14] <= (tlbwi && id == 5'd14)?PageMask[24:13] : TLB_PM[14];
		TLB_PM[15] <= (tlbwi && id == 5'd15)?PageMask[24:13] : TLB_PM[15];
		TLB_PM[16] <= (tlbwi && id == 5'd16)?PageMask[24:13] : TLB_PM[16];
		TLB_PM[17] <= (tlbwi && id == 5'd17)?PageMask[24:13] : TLB_PM[17];
		TLB_PM[18] <= (tlbwi && id == 5'd18)?PageMask[24:13] : TLB_PM[18];
		TLB_PM[19] <= (tlbwi && id == 5'd19)?PageMask[24:13] : TLB_PM[19];
		TLB_PM[20] <= (tlbwi && id == 5'd20)?PageMask[24:13] : TLB_PM[20];
		TLB_PM[21] <= (tlbwi && id == 5'd21)?PageMask[24:13] : TLB_PM[21];
		TLB_PM[22] <= (tlbwi && id == 5'd22)?PageMask[24:13] : TLB_PM[22];
		TLB_PM[23] <= (tlbwi && id == 5'd23)?PageMask[24:13] : TLB_PM[23];
		TLB_PM[24] <= (tlbwi && id == 5'd24)?PageMask[24:13] : TLB_PM[24];
		TLB_PM[25] <= (tlbwi && id == 5'd25)?PageMask[24:13] : TLB_PM[25];
		TLB_PM[26] <= (tlbwi && id == 5'd26)?PageMask[24:13] : TLB_PM[26];
		TLB_PM[27] <= (tlbwi && id == 5'd27)?PageMask[24:13] : TLB_PM[27];
		TLB_PM[28] <= (tlbwi && id == 5'd28)?PageMask[24:13] : TLB_PM[28];
		TLB_PM[29] <= (tlbwi && id == 5'd29)?PageMask[24:13] : TLB_PM[29];
		TLB_PM[30] <= (tlbwi && id == 5'd30)?PageMask[24:13] : TLB_PM[30];
		TLB_PM[31] <= (tlbwi && id == 5'd31)?PageMask[24:13] : TLB_PM[31]; 
		TLB_L0[0] <= (tlbwi && id == 5'd0)?EntryLo0[25:1] : TLB_L0[0];
		TLB_L0[1] <= (tlbwi && id == 5'd1)?EntryLo0[25:1] : TLB_L0[1];
		TLB_L0[2] <= (tlbwi && id == 5'd2)?EntryLo0[25:1] : TLB_L0[2];
		TLB_L0[3] <= (tlbwi && id == 5'd3)?EntryLo0[25:1] : TLB_L0[3];
		TLB_L0[4] <= (tlbwi && id == 5'd4)?EntryLo0[25:1] : TLB_L0[4];
		TLB_L0[5] <= (tlbwi && id == 5'd5)?EntryLo0[25:1] : TLB_L0[5];
		TLB_L0[6] <= (tlbwi && id == 5'd6)?EntryLo0[25:1] : TLB_L0[6];
		TLB_L0[7] <= (tlbwi && id == 5'd7)?EntryLo0[25:1] : TLB_L0[7];
		TLB_L0[8] <= (tlbwi && id == 5'd8)?EntryLo0[25:1] : TLB_L0[8];
		TLB_L0[9] <= (tlbwi && id == 5'd9)?EntryLo0[25:1] : TLB_L0[9];
		TLB_L0[10] <= (tlbwi && id == 5'd10)?EntryLo0[25:1] : TLB_L0[10];
		TLB_L0[11] <= (tlbwi && id == 5'd11)?EntryLo0[25:1] : TLB_L0[11];
		TLB_L0[12] <= (tlbwi && id == 5'd12)?EntryLo0[25:1] : TLB_L0[12];
		TLB_L0[13] <= (tlbwi && id == 5'd13)?EntryLo0[25:1] : TLB_L0[13];
		TLB_L0[14] <= (tlbwi && id == 5'd14)?EntryLo0[25:1] : TLB_L0[14];
		TLB_L0[15] <= (tlbwi && id == 5'd15)?EntryLo0[25:1] : TLB_L0[15];
		TLB_L0[16] <= (tlbwi && id == 5'd16)?EntryLo0[25:1] : TLB_L0[16];
		TLB_L0[17] <= (tlbwi && id == 5'd17)?EntryLo0[25:1] : TLB_L0[17];
		TLB_L0[18] <= (tlbwi && id == 5'd18)?EntryLo0[25:1] : TLB_L0[18];
		TLB_L0[19] <= (tlbwi && id == 5'd19)?EntryLo0[25:1] : TLB_L0[19];
		TLB_L0[20] <= (tlbwi && id == 5'd20)?EntryLo0[25:1] : TLB_L0[20];
		TLB_L0[21] <= (tlbwi && id == 5'd21)?EntryLo0[25:1] : TLB_L0[21];
		TLB_L0[22] <= (tlbwi && id == 5'd22)?EntryLo0[25:1] : TLB_L0[22];
		TLB_L0[23] <= (tlbwi && id == 5'd23)?EntryLo0[25:1] : TLB_L0[23];
		TLB_L0[24] <= (tlbwi && id == 5'd24)?EntryLo0[25:1] : TLB_L0[24];
		TLB_L0[25] <= (tlbwi && id == 5'd25)?EntryLo0[25:1] : TLB_L0[25];
		TLB_L0[26] <= (tlbwi && id == 5'd26)?EntryLo0[25:1] : TLB_L0[26];
		TLB_L0[27] <= (tlbwi && id == 5'd27)?EntryLo0[25:1] : TLB_L0[27];
		TLB_L0[28] <= (tlbwi && id == 5'd28)?EntryLo0[25:1] : TLB_L0[28];
		TLB_L0[29] <= (tlbwi && id == 5'd29)?EntryLo0[25:1] : TLB_L0[29];
		TLB_L0[30] <= (tlbwi && id == 5'd30)?EntryLo0[25:1] : TLB_L0[30];
		TLB_L0[31] <= (tlbwi && id == 5'd31)?EntryLo0[25:1] : TLB_L0[31]; 
		TLB_L1[0] <= (tlbwi && id == 5'd0)?EntryLo1[25:1] : TLB_L1[0];
		TLB_L1[1] <= (tlbwi && id == 5'd1)?EntryLo1[25:1] : TLB_L1[1];
		TLB_L1[2] <= (tlbwi && id == 5'd2)?EntryLo1[25:1] : TLB_L1[2];
		TLB_L1[3] <= (tlbwi && id == 5'd3)?EntryLo1[25:1] : TLB_L1[3];
		TLB_L1[4] <= (tlbwi && id == 5'd4)?EntryLo1[25:1] : TLB_L1[4];
		TLB_L1[5] <= (tlbwi && id == 5'd5)?EntryLo1[25:1] : TLB_L1[5];
		TLB_L1[6] <= (tlbwi && id == 5'd6)?EntryLo1[25:1] : TLB_L1[6];
		TLB_L1[7] <= (tlbwi && id == 5'd7)?EntryLo1[25:1] : TLB_L1[7];
		TLB_L1[8] <= (tlbwi && id == 5'd8)?EntryLo1[25:1] : TLB_L1[8];
		TLB_L1[9] <= (tlbwi && id == 5'd9)?EntryLo1[25:1] : TLB_L1[9];
		TLB_L1[10] <= (tlbwi && id == 5'd10)?EntryLo1[25:1] : TLB_L1[10];
		TLB_L1[11] <= (tlbwi && id == 5'd11)?EntryLo1[25:1] : TLB_L1[11];
		TLB_L1[12] <= (tlbwi && id == 5'd12)?EntryLo1[25:1] : TLB_L1[12];
		TLB_L1[13] <= (tlbwi && id == 5'd13)?EntryLo1[25:1] : TLB_L1[13];
		TLB_L1[14] <= (tlbwi && id == 5'd14)?EntryLo1[25:1] : TLB_L1[14];
		TLB_L1[15] <= (tlbwi && id == 5'd15)?EntryLo1[25:1] : TLB_L1[15];
		TLB_L1[16] <= (tlbwi && id == 5'd16)?EntryLo1[25:1] : TLB_L1[16];
		TLB_L1[17] <= (tlbwi && id == 5'd17)?EntryLo1[25:1] : TLB_L1[17];
		TLB_L1[18] <= (tlbwi && id == 5'd18)?EntryLo1[25:1] : TLB_L1[18];
		TLB_L1[19] <= (tlbwi && id == 5'd19)?EntryLo1[25:1] : TLB_L1[19];
		TLB_L1[20] <= (tlbwi && id == 5'd20)?EntryLo1[25:1] : TLB_L1[20];
		TLB_L1[21] <= (tlbwi && id == 5'd21)?EntryLo1[25:1] : TLB_L1[21];
		TLB_L1[22] <= (tlbwi && id == 5'd22)?EntryLo1[25:1] : TLB_L1[22];
		TLB_L1[23] <= (tlbwi && id == 5'd23)?EntryLo1[25:1] : TLB_L1[23];
		TLB_L1[24] <= (tlbwi && id == 5'd24)?EntryLo1[25:1] : TLB_L1[24];
		TLB_L1[25] <= (tlbwi && id == 5'd25)?EntryLo1[25:1] : TLB_L1[25];
		TLB_L1[26] <= (tlbwi && id == 5'd26)?EntryLo1[25:1] : TLB_L1[26];
		TLB_L1[27] <= (tlbwi && id == 5'd27)?EntryLo1[25:1] : TLB_L1[27];
		TLB_L1[28] <= (tlbwi && id == 5'd28)?EntryLo1[25:1] : TLB_L1[28];
		TLB_L1[29] <= (tlbwi && id == 5'd29)?EntryLo1[25:1] : TLB_L1[29];
		TLB_L1[30] <= (tlbwi && id == 5'd30)?EntryLo1[25:1] : TLB_L1[30];
		TLB_L1[31] <= (tlbwi && id == 5'd31)?EntryLo1[25:1] : TLB_L1[31]; 
	end else begin
		im_r <= 1'b0;
		dm_r <= 1'b0;
		ii_r <= 1'b0;
		di_r <= 1'b0;
		ir_r <= 1'b0;
		dr_r <= 1'b0;
		EntryHi  <= 32'd0;
		PageMask <= 32'd0;
		EntryLo0 <= 32'd0;
		EntryLo1 <= 32'd0;
		Index    <= 32'd0;
		TLB_EH[0] <= 27'h5000000;
		TLB_EH[1] <= 27'h5000000;
		TLB_EH[2] <= 27'h5000000;
		TLB_EH[3] <= 27'h5000000;
		TLB_EH[4] <= 27'h5000000;
		TLB_EH[5] <= 27'h5000000;
		TLB_EH[6] <= 27'h5000000;
		TLB_EH[7] <= 27'h5000000;
		TLB_EH[8] <= 27'h5000000;
		TLB_EH[9] <= 27'h5000000;
		TLB_EH[10] <= 27'h5000000;
		TLB_EH[11] <= 27'h5000000;
		TLB_EH[12] <= 27'h5000000;
		TLB_EH[13] <= 27'h5000000;
		TLB_EH[14] <= 27'h5000000;
		TLB_EH[15] <= 27'h5000000;
		TLB_EH[16] <= 27'h5000000;
		TLB_EH[17] <= 27'h5000000;
		TLB_EH[18] <= 27'h5000000;
		TLB_EH[19] <= 27'h5000000;
		TLB_EH[20] <= 27'h5000000;
		TLB_EH[21] <= 27'h5000000;
		TLB_EH[22] <= 27'h5000000;
		TLB_EH[23] <= 27'h5000000;
		TLB_EH[24] <= 27'h5000000;
		TLB_EH[25] <= 27'h5000000;
		TLB_EH[26] <= 27'h5000000;
		TLB_EH[27] <= 27'h5000000;
		TLB_EH[28] <= 27'h5000000;
		TLB_EH[29] <= 27'h5000000;
		TLB_EH[30] <= 27'h5000000;
		TLB_EH[31] <= 27'h5000000;
		TLB_G[0] <= 1'd0;
		TLB_G[1] <= 1'd0;
		TLB_G[2] <= 1'd0;
		TLB_G[3] <= 1'd0;
		TLB_G[4] <= 1'd0;
		TLB_G[5] <= 1'd0;
		TLB_G[6] <= 1'd0;
		TLB_G[7] <= 1'd0;
		TLB_G[8] <= 1'd0;
		TLB_G[9] <= 1'd0;
		TLB_G[10] <= 1'd0;
		TLB_G[11] <= 1'd0;
		TLB_G[12] <= 1'd0;
		TLB_G[13] <= 1'd0;
		TLB_G[14] <= 1'd0;
		TLB_G[15] <= 1'd0;
		TLB_G[16] <= 1'd0;
		TLB_G[17] <= 1'd0;
		TLB_G[18] <= 1'd0;
		TLB_G[19] <= 1'd0;
		TLB_G[20] <= 1'd0;
		TLB_G[21] <= 1'd0;
		TLB_G[22] <= 1'd0;
		TLB_G[23] <= 1'd0;
		TLB_G[24] <= 1'd0;
		TLB_G[25] <= 1'd0;
		TLB_G[26] <= 1'd0;
		TLB_G[27] <= 1'd0;
		TLB_G[28] <= 1'd0;
		TLB_G[29] <= 1'd0;
		TLB_G[30] <= 1'd0;
		TLB_G[31] <= 1'd0;
		TLB_PM[0] <= 12'd0;
		TLB_PM[1] <= 12'd0;
		TLB_PM[2] <= 12'd0;
		TLB_PM[3] <= 12'd0;
		TLB_PM[4] <= 12'd0;
		TLB_PM[5] <= 12'd0;
		TLB_PM[6] <= 12'd0;
		TLB_PM[7] <= 12'd0;
		TLB_PM[8] <= 12'd0;
		TLB_PM[9] <= 12'd0;
		TLB_PM[10] <= 12'd0;
		TLB_PM[11] <= 12'd0;
		TLB_PM[12] <= 12'd0;
		TLB_PM[13] <= 12'd0;
		TLB_PM[14] <= 12'd0;
		TLB_PM[15] <= 12'd0;
		TLB_PM[16] <= 12'd0;
		TLB_PM[17] <= 12'd0;
		TLB_PM[18] <= 12'd0;
		TLB_PM[19] <= 12'd0;
		TLB_PM[20] <= 12'd0;
		TLB_PM[21] <= 12'd0;
		TLB_PM[22] <= 12'd0;
		TLB_PM[23] <= 12'd0;
		TLB_PM[24] <= 12'd0;
		TLB_PM[25] <= 12'd0;
		TLB_PM[26] <= 12'd0;
		TLB_PM[27] <= 12'd0;
		TLB_PM[28] <= 12'd0;
		TLB_PM[29] <= 12'd0;
		TLB_PM[30] <= 12'd0;
		TLB_PM[31] <= 12'd0;
		TLB_L0[0] <= 24'd0;
		TLB_L0[1] <= 24'd0;
		TLB_L0[2] <= 24'd0;
		TLB_L0[3] <= 24'd0;
		TLB_L0[4] <= 24'd0;
		TLB_L0[5] <= 24'd0;
		TLB_L0[6] <= 24'd0;
		TLB_L0[7] <= 24'd0;
		TLB_L0[8] <= 24'd0;
		TLB_L0[9] <= 24'd0;
		TLB_L0[10] <= 24'd0;
		TLB_L0[11] <= 24'd0;
		TLB_L0[12] <= 24'd0;
		TLB_L0[13] <= 24'd0;
		TLB_L0[14] <= 24'd0;
		TLB_L0[15] <= 24'd0;
		TLB_L0[16] <= 24'd0;
		TLB_L0[17] <= 24'd0;
		TLB_L0[18] <= 24'd0;
		TLB_L0[19] <= 24'd0;
		TLB_L0[20] <= 24'd0;
		TLB_L0[21] <= 24'd0;
		TLB_L0[22] <= 24'd0;
		TLB_L0[23] <= 24'd0;
		TLB_L0[24] <= 24'd0;
		TLB_L0[25] <= 24'd0;
		TLB_L0[26] <= 24'd0;
		TLB_L0[27] <= 24'd0;
		TLB_L0[28] <= 24'd0;
		TLB_L0[29] <= 24'd0;
		TLB_L0[30] <= 24'd0;
		TLB_L0[31] <= 24'd0;
		TLB_L1[0] <= 24'd0;
		TLB_L1[1] <= 24'd0;
		TLB_L1[2] <= 24'd0;
		TLB_L1[3] <= 24'd0;
		TLB_L1[4] <= 24'd0;
		TLB_L1[5] <= 24'd0;
		TLB_L1[6] <= 24'd0;
		TLB_L1[7] <= 24'd0;
		TLB_L1[8] <= 24'd0;
		TLB_L1[9] <= 24'd0;
		TLB_L1[10] <= 24'd0;
		TLB_L1[11] <= 24'd0;
		TLB_L1[12] <= 24'd0;
		TLB_L1[13] <= 24'd0;
		TLB_L1[14] <= 24'd0;
		TLB_L1[15] <= 24'd0;
		TLB_L1[16] <= 24'd0;
		TLB_L1[17] <= 24'd0;
		TLB_L1[18] <= 24'd0;
		TLB_L1[19] <= 24'd0;
		TLB_L1[20] <= 24'd0;
		TLB_L1[21] <= 24'd0;
		TLB_L1[22] <= 24'd0;
		TLB_L1[23] <= 24'd0;
		TLB_L1[24] <= 24'd0;
		TLB_L1[25] <= 24'd0;
		TLB_L1[26] <= 24'd0;
		TLB_L1[27] <= 24'd0;
		TLB_L1[28] <= 24'd0;
		TLB_L1[29] <= 24'd0;
		TLB_L1[30] <= 24'd0;
		TLB_L1[31] <= 24'd0;
	end
end

assign inst_found[0] = (TLB_EH[0][26:8] & ~{7'd0, TLB_PM[0]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[0]}) && (TLB_G[0] || TLB_EH[0][7:0] == EntryHi[7:0]);
assign inst_found[1] = (TLB_EH[1][26:8] & ~{7'd0, TLB_PM[1]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[1]}) && (TLB_G[1] || TLB_EH[1][7:0] == EntryHi[7:0]);
assign inst_found[2] = (TLB_EH[2][26:8] & ~{7'd0, TLB_PM[2]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[2]}) && (TLB_G[2] || TLB_EH[2][7:0] == EntryHi[7:0]);
assign inst_found[3] = (TLB_EH[3][26:8] & ~{7'd0, TLB_PM[3]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[3]}) && (TLB_G[3] || TLB_EH[3][7:0] == EntryHi[7:0]);
assign inst_found[4] = (TLB_EH[4][26:8] & ~{7'd0, TLB_PM[4]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[4]}) && (TLB_G[4] || TLB_EH[4][7:0] == EntryHi[7:0]);
assign inst_found[5] = (TLB_EH[5][26:8] & ~{7'd0, TLB_PM[5]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[5]}) && (TLB_G[5] || TLB_EH[5][7:0] == EntryHi[7:0]);
assign inst_found[6] = (TLB_EH[6][26:8] & ~{7'd0, TLB_PM[6]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[6]}) && (TLB_G[6] || TLB_EH[6][7:0] == EntryHi[7:0]);
assign inst_found[7] = (TLB_EH[7][26:8] & ~{7'd0, TLB_PM[7]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[7]}) && (TLB_G[7] || TLB_EH[7][7:0] == EntryHi[7:0]);
assign inst_found[8] = (TLB_EH[8][26:8] & ~{7'd0, TLB_PM[8]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[8]}) && (TLB_G[8] || TLB_EH[8][7:0] == EntryHi[7:0]);
assign inst_found[9] = (TLB_EH[9][26:8] & ~{7'd0, TLB_PM[9]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[9]}) && (TLB_G[9] || TLB_EH[9][7:0] == EntryHi[7:0]);
assign inst_found[10] = (TLB_EH[10][26:8] & ~{7'd0, TLB_PM[10]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[10]}) && (TLB_G[10] || TLB_EH[10][7:0] == EntryHi[7:0]);
assign inst_found[11] = (TLB_EH[11][26:8] & ~{7'd0, TLB_PM[11]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[11]}) && (TLB_G[11] || TLB_EH[11][7:0] == EntryHi[7:0]);
assign inst_found[12] = (TLB_EH[12][26:8] & ~{7'd0, TLB_PM[12]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[12]}) && (TLB_G[12] || TLB_EH[12][7:0] == EntryHi[7:0]);
assign inst_found[13] = (TLB_EH[13][26:8] & ~{7'd0, TLB_PM[13]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[13]}) && (TLB_G[13] || TLB_EH[13][7:0] == EntryHi[7:0]);
assign inst_found[14] = (TLB_EH[14][26:8] & ~{7'd0, TLB_PM[14]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[14]}) && (TLB_G[14] || TLB_EH[14][7:0] == EntryHi[7:0]);
assign inst_found[15] = (TLB_EH[15][26:8] & ~{7'd0, TLB_PM[15]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[15]}) && (TLB_G[15] || TLB_EH[15][7:0] == EntryHi[7:0]);
assign inst_found[16] = (TLB_EH[16][26:8] & ~{7'd0, TLB_PM[16]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[16]}) && (TLB_G[16] || TLB_EH[16][7:0] == EntryHi[7:0]);
assign inst_found[17] = (TLB_EH[17][26:8] & ~{7'd0, TLB_PM[17]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[17]}) && (TLB_G[17] || TLB_EH[17][7:0] == EntryHi[7:0]);
assign inst_found[18] = (TLB_EH[18][26:8] & ~{7'd0, TLB_PM[18]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[18]}) && (TLB_G[18] || TLB_EH[18][7:0] == EntryHi[7:0]);
assign inst_found[19] = (TLB_EH[19][26:8] & ~{7'd0, TLB_PM[19]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[19]}) && (TLB_G[19] || TLB_EH[19][7:0] == EntryHi[7:0]);
assign inst_found[20] = (TLB_EH[20][26:8] & ~{7'd0, TLB_PM[20]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[20]}) && (TLB_G[20] || TLB_EH[20][7:0] == EntryHi[7:0]);
assign inst_found[21] = (TLB_EH[21][26:8] & ~{7'd0, TLB_PM[21]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[21]}) && (TLB_G[21] || TLB_EH[21][7:0] == EntryHi[7:0]);
assign inst_found[22] = (TLB_EH[22][26:8] & ~{7'd0, TLB_PM[22]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[22]}) && (TLB_G[22] || TLB_EH[22][7:0] == EntryHi[7:0]);
assign inst_found[23] = (TLB_EH[23][26:8] & ~{7'd0, TLB_PM[23]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[23]}) && (TLB_G[23] || TLB_EH[23][7:0] == EntryHi[7:0]);
assign inst_found[24] = (TLB_EH[24][26:8] & ~{7'd0, TLB_PM[24]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[24]}) && (TLB_G[24] || TLB_EH[24][7:0] == EntryHi[7:0]);
assign inst_found[25] = (TLB_EH[25][26:8] & ~{7'd0, TLB_PM[25]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[25]}) && (TLB_G[25] || TLB_EH[25][7:0] == EntryHi[7:0]);
assign inst_found[26] = (TLB_EH[26][26:8] & ~{7'd0, TLB_PM[26]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[26]}) && (TLB_G[26] || TLB_EH[26][7:0] == EntryHi[7:0]);
assign inst_found[27] = (TLB_EH[27][26:8] & ~{7'd0, TLB_PM[27]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[27]}) && (TLB_G[27] || TLB_EH[27][7:0] == EntryHi[7:0]);
assign inst_found[28] = (TLB_EH[28][26:8] & ~{7'd0, TLB_PM[28]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[28]}) && (TLB_G[28] || TLB_EH[28][7:0] == EntryHi[7:0]);
assign inst_found[29] = (TLB_EH[29][26:8] & ~{7'd0, TLB_PM[29]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[29]}) && (TLB_G[29] || TLB_EH[29][7:0] == EntryHi[7:0]);
assign inst_found[30] = (TLB_EH[30][26:8] & ~{7'd0, TLB_PM[30]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[30]}) && (TLB_G[30] || TLB_EH[30][7:0] == EntryHi[7:0]);
assign inst_found[31] = (TLB_EH[31][26:8] & ~{7'd0, TLB_PM[31]}) == (inst_sram_addr[31:13] & ~{7'd0, TLB_PM[31]}) && (TLB_G[31] || TLB_EH[31][7:0] == EntryHi[7:0]);
assign data_found[0] = (TLB_EH[0][26:8] & ~{7'd0, TLB_PM[0]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[0]}) && (TLB_G[0] || TLB_EH[0][7:0] == EntryHi[7:0]);
assign data_found[1] = (TLB_EH[1][26:8] & ~{7'd0, TLB_PM[1]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[1]}) && (TLB_G[1] || TLB_EH[1][7:0] == EntryHi[7:0]);
assign data_found[2] = (TLB_EH[2][26:8] & ~{7'd0, TLB_PM[2]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[2]}) && (TLB_G[2] || TLB_EH[2][7:0] == EntryHi[7:0]);
assign data_found[3] = (TLB_EH[3][26:8] & ~{7'd0, TLB_PM[3]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[3]}) && (TLB_G[3] || TLB_EH[3][7:0] == EntryHi[7:0]);
assign data_found[4] = (TLB_EH[4][26:8] & ~{7'd0, TLB_PM[4]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[4]}) && (TLB_G[4] || TLB_EH[4][7:0] == EntryHi[7:0]);
assign data_found[5] = (TLB_EH[5][26:8] & ~{7'd0, TLB_PM[5]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[5]}) && (TLB_G[5] || TLB_EH[5][7:0] == EntryHi[7:0]);
assign data_found[6] = (TLB_EH[6][26:8] & ~{7'd0, TLB_PM[6]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[6]}) && (TLB_G[6] || TLB_EH[6][7:0] == EntryHi[7:0]);
assign data_found[7] = (TLB_EH[7][26:8] & ~{7'd0, TLB_PM[7]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[7]}) && (TLB_G[7] || TLB_EH[7][7:0] == EntryHi[7:0]);
assign data_found[8] = (TLB_EH[8][26:8] & ~{7'd0, TLB_PM[8]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[8]}) && (TLB_G[8] || TLB_EH[8][7:0] == EntryHi[7:0]);
assign data_found[9] = (TLB_EH[9][26:8] & ~{7'd0, TLB_PM[9]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[9]}) && (TLB_G[9] || TLB_EH[9][7:0] == EntryHi[7:0]);
assign data_found[10] = (TLB_EH[10][26:8] & ~{7'd0, TLB_PM[10]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[10]}) && (TLB_G[10] || TLB_EH[10][7:0] == EntryHi[7:0]);
assign data_found[11] = (TLB_EH[11][26:8] & ~{7'd0, TLB_PM[11]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[11]}) && (TLB_G[11] || TLB_EH[11][7:0] == EntryHi[7:0]);
assign data_found[12] = (TLB_EH[12][26:8] & ~{7'd0, TLB_PM[12]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[12]}) && (TLB_G[12] || TLB_EH[12][7:0] == EntryHi[7:0]);
assign data_found[13] = (TLB_EH[13][26:8] & ~{7'd0, TLB_PM[13]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[13]}) && (TLB_G[13] || TLB_EH[13][7:0] == EntryHi[7:0]);
assign data_found[14] = (TLB_EH[14][26:8] & ~{7'd0, TLB_PM[14]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[14]}) && (TLB_G[14] || TLB_EH[14][7:0] == EntryHi[7:0]);
assign data_found[15] = (TLB_EH[15][26:8] & ~{7'd0, TLB_PM[15]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[15]}) && (TLB_G[15] || TLB_EH[15][7:0] == EntryHi[7:0]);
assign data_found[16] = (TLB_EH[16][26:8] & ~{7'd0, TLB_PM[16]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[16]}) && (TLB_G[16] || TLB_EH[16][7:0] == EntryHi[7:0]);
assign data_found[17] = (TLB_EH[17][26:8] & ~{7'd0, TLB_PM[17]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[17]}) && (TLB_G[17] || TLB_EH[17][7:0] == EntryHi[7:0]);
assign data_found[18] = (TLB_EH[18][26:8] & ~{7'd0, TLB_PM[18]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[18]}) && (TLB_G[18] || TLB_EH[18][7:0] == EntryHi[7:0]);
assign data_found[19] = (TLB_EH[19][26:8] & ~{7'd0, TLB_PM[19]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[19]}) && (TLB_G[19] || TLB_EH[19][7:0] == EntryHi[7:0]);
assign data_found[20] = (TLB_EH[20][26:8] & ~{7'd0, TLB_PM[20]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[20]}) && (TLB_G[20] || TLB_EH[20][7:0] == EntryHi[7:0]);
assign data_found[21] = (TLB_EH[21][26:8] & ~{7'd0, TLB_PM[21]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[21]}) && (TLB_G[21] || TLB_EH[21][7:0] == EntryHi[7:0]);
assign data_found[22] = (TLB_EH[22][26:8] & ~{7'd0, TLB_PM[22]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[22]}) && (TLB_G[22] || TLB_EH[22][7:0] == EntryHi[7:0]);
assign data_found[23] = (TLB_EH[23][26:8] & ~{7'd0, TLB_PM[23]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[23]}) && (TLB_G[23] || TLB_EH[23][7:0] == EntryHi[7:0]);
assign data_found[24] = (TLB_EH[24][26:8] & ~{7'd0, TLB_PM[24]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[24]}) && (TLB_G[24] || TLB_EH[24][7:0] == EntryHi[7:0]);
assign data_found[25] = (TLB_EH[25][26:8] & ~{7'd0, TLB_PM[25]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[25]}) && (TLB_G[25] || TLB_EH[25][7:0] == EntryHi[7:0]);
assign data_found[26] = (TLB_EH[26][26:8] & ~{7'd0, TLB_PM[26]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[26]}) && (TLB_G[26] || TLB_EH[26][7:0] == EntryHi[7:0]);
assign data_found[27] = (TLB_EH[27][26:8] & ~{7'd0, TLB_PM[27]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[27]}) && (TLB_G[27] || TLB_EH[27][7:0] == EntryHi[7:0]);
assign data_found[28] = (TLB_EH[28][26:8] & ~{7'd0, TLB_PM[28]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[28]}) && (TLB_G[28] || TLB_EH[28][7:0] == EntryHi[7:0]);
assign data_found[29] = (TLB_EH[29][26:8] & ~{7'd0, TLB_PM[29]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[29]}) && (TLB_G[29] || TLB_EH[29][7:0] == EntryHi[7:0]);
assign data_found[30] = (TLB_EH[30][26:8] & ~{7'd0, TLB_PM[30]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[30]}) && (TLB_G[30] || TLB_EH[30][7:0] == EntryHi[7:0]);
assign data_found[31] = (TLB_EH[31][26:8] & ~{7'd0, TLB_PM[31]}) == (data_sram_addr[31:13] & ~{7'd0, TLB_PM[31]}) && (TLB_G[31] || TLB_EH[31][7:0] == EntryHi[7:0]);

assign inst_valid = inst_sram_addr[12]? inst_found & {TLB_L1[31][0], TLB_L1[30][0], TLB_L1[29][0], TLB_L1[28][0], TLB_L1[27][0], TLB_L1[26][0], TLB_L1[25][0], TLB_L1[24][0], TLB_L1[23][0], TLB_L1[22][0], TLB_L1[21][0], TLB_L1[20][0], TLB_L1[19][0], TLB_L1[18][0], TLB_L1[17][0], TLB_L1[16][0], TLB_L1[15][0], TLB_L1[14][0], TLB_L1[13][0], TLB_L1[12][0], TLB_L1[11][0], TLB_L1[10][0], TLB_L1[9][0], TLB_L1[8][0], TLB_L1[7][0],TLB_L1[6][0], TLB_L1[5][0], TLB_L1[4][0], TLB_L1[3][0], TLB_L1[2][0], TLB_L1[1][0], TLB_L1[0][0]} : 
										inst_found & {TLB_L0[31][0], TLB_L0[30][0], TLB_L0[29][0], TLB_L0[28][0], TLB_L0[27][0], TLB_L0[26][0], TLB_L0[25][0], TLB_L0[24][0], TLB_L0[23][0], TLB_L0[22][0], TLB_L0[21][0], TLB_L0[20][0], TLB_L0[19][0], TLB_L0[18][0], TLB_L0[17][0], TLB_L0[16][0], TLB_L0[15][0], TLB_L0[14][0], TLB_L0[13][0], TLB_L0[12][0], TLB_L0[11][0], TLB_L0[10][0], TLB_L0[9][0], TLB_L0[8][0], TLB_L0[7][0],TLB_L0[6][0], TLB_L0[5][0], TLB_L0[4][0], TLB_L0[3][0], TLB_L0[2][0], TLB_L0[1][0], TLB_L0[0][0]};

assign data_valid = data_sram_addr[12]? data_found & {TLB_L1[31][0], TLB_L1[30][0], TLB_L1[29][0], TLB_L1[28][0], TLB_L1[27][0], TLB_L1[26][0], TLB_L1[25][0], TLB_L1[24][0], TLB_L1[23][0], TLB_L1[22][0], TLB_L1[21][0], TLB_L1[20][0], TLB_L1[19][0], TLB_L1[18][0], TLB_L1[17][0], TLB_L1[16][0], TLB_L1[15][0], TLB_L1[14][0], TLB_L1[13][0], TLB_L1[12][0], TLB_L1[11][0], TLB_L1[10][0], TLB_L1[9][0], TLB_L1[8][0], TLB_L1[7][0],TLB_L1[6][0], TLB_L1[5][0], TLB_L1[4][0], TLB_L1[3][0], TLB_L1[2][0], TLB_L1[1][0], TLB_L1[0][0]} : 
										data_found & {TLB_L0[31][0], TLB_L0[30][0], TLB_L0[29][0], TLB_L0[28][0], TLB_L0[27][0], TLB_L0[26][0], TLB_L0[25][0], TLB_L0[24][0], TLB_L0[23][0], TLB_L0[22][0], TLB_L0[21][0], TLB_L0[20][0], TLB_L0[19][0], TLB_L0[18][0], TLB_L0[17][0], TLB_L0[16][0], TLB_L0[15][0], TLB_L0[14][0], TLB_L0[13][0], TLB_L0[12][0], TLB_L0[11][0], TLB_L0[10][0], TLB_L0[9][0], TLB_L0[8][0], TLB_L0[7][0],TLB_L0[6][0], TLB_L0[5][0], TLB_L0[4][0], TLB_L0[3][0], TLB_L0[2][0], TLB_L0[1][0], TLB_L0[0][0]};

assign data_d = data_sram_addr[12]? data_found & {TLB_L1[31][1], TLB_L1[30][1], TLB_L1[29][1], TLB_L1[28][1], TLB_L1[27][1], TLB_L1[26][1], TLB_L1[25][1], TLB_L1[24][1], TLB_L1[23][1], TLB_L1[22][1], TLB_L1[21][1], TLB_L1[20][1], TLB_L1[19][1], TLB_L1[18][1], TLB_L1[17][1], TLB_L1[16][1], TLB_L1[15][1], TLB_L1[14][1], TLB_L1[13][1], TLB_L1[12][1], TLB_L1[11][1], TLB_L1[10][1], TLB_L1[9][1], TLB_L1[8][1], TLB_L1[7][1],TLB_L1[6][1], TLB_L1[5][1], TLB_L1[4][1], TLB_L1[3][1], TLB_L1[2][1], TLB_L1[1][1], TLB_L1[0][1]} :
									data_found & {TLB_L0[31][1], TLB_L0[30][1], TLB_L0[29][1], TLB_L0[28][1], TLB_L0[27][1], TLB_L0[26][1], TLB_L0[25][1], TLB_L0[24][1], TLB_L0[23][1], TLB_L0[22][1], TLB_L0[21][1], TLB_L0[20][1], TLB_L0[19][1], TLB_L0[18][1], TLB_L0[17][1], TLB_L0[16][1], TLB_L0[15][1], TLB_L0[14][1], TLB_L0[13][1], TLB_L0[12][1], TLB_L0[11][1], TLB_L0[10][1], TLB_L0[9][1], TLB_L0[8][1], TLB_L0[7][1],TLB_L0[6][1], TLB_L0[5][1], TLB_L0[4][1], TLB_L0[3][1], TLB_L0[2][1], TLB_L0[1][1], TLB_L0[0][1]};

assign mfidx = addr == 5'd0;
assign mflo0 = addr == 5'd2;
assign mflo1 = addr == 5'd3;
assign mfpm  = addr == 5'd5;
assign mfehi = addr == 5'd10;
assign tlb_c0 = ({32{mfidx}} & Index) |
				({32{mflo0}} & EntryLo0) |
				({32{mflo1}} & EntryLo1) |
				({32{mfpm }} & PageMask) |
				({32{mfehi}} & EntryHi);
			
assign inst_mpaddr = inst_sram_addr[12]? {{{20{inst_found[0]}}&TLB_L1[0][24:5] | {20{inst_found[1]}}&TLB_L1[1][24:5] | {20{inst_found[2]}}&TLB_L1[2][24:5] | {20{inst_found[3]}}&TLB_L1[3][24:5] | {20{inst_found[4]}}&TLB_L1[4][24:5]  | {20{inst_found[5]}}&TLB_L1[5][24:5] | {20{inst_found[6]}}&TLB_L1[6][24:5] | {20{inst_found[7]}}&TLB_L1[7][24:5] | {20{inst_found[8]}}&TLB_L1[8][24:5] | {20{inst_found[9]}}&TLB_L1[9][24:5] | {20{inst_found[10]}}&TLB_L1[10][24:5] | {20{inst_found[11]}}&TLB_L1[11][24:5] | {20{inst_found[12]}}&TLB_L1[12][24:5] | {20{inst_found[13]}}&TLB_L1[13][24:5] | {20{inst_found[14]}}&TLB_L1[14][24:5] | {20{inst_found[15]}}&TLB_L1[15][24:5] | {20{inst_found[16]}}&TLB_L1[16][24:5] | {20{inst_found[17]}}&TLB_L1[17][24:5] | {20{inst_found[18]}}&TLB_L1[18][24:5] | {20{inst_found[19]}}&TLB_L1[19][24:5] | {20{inst_found[20]}}&TLB_L1[20][24:5] | {20{inst_found[21]}}&TLB_L1[21][24:5] | {20{inst_found[22]}}&TLB_L1[22][24:5] | {20{inst_found[23]}}&TLB_L1[23][24:5] | {20{inst_found[24]}}&TLB_L1[24][24:5] | {20{inst_found[25]}}&TLB_L1[25][24:5] | {20{inst_found[26]}}&TLB_L1[26][24:5] | {20{inst_found[27]}}&TLB_L1[27][24:5] | {20{inst_found[28]}}&TLB_L1[28][24:5] | {20{inst_found[29]}}&TLB_L1[29][24:5] | {20{inst_found[30]}}&TLB_L1[30][24:5] | {20{inst_found[31]}}&TLB_L1[31][24:5]}, inst_sram_addr[11:0]} :
										{{{20{inst_found[0]}}&TLB_L0[0][24:5] | {20{inst_found[1]}}&TLB_L0[1][24:5] | {20{inst_found[2]}}&TLB_L0[2][24:5] | {20{inst_found[3]}}&TLB_L0[3][24:5] | {20{inst_found[4]}}&TLB_L0[4][24:5]  | {20{inst_found[5]}}&TLB_L0[5][24:5] | {20{inst_found[6]}}&TLB_L0[6][24:5] | {20{inst_found[7]}}&TLB_L0[7][24:5] | {20{inst_found[8]}}&TLB_L0[8][24:5] | {20{inst_found[9]}}&TLB_L0[9][24:5] | {20{inst_found[10]}}&TLB_L0[10][24:5] | {20{inst_found[11]}}&TLB_L0[11][24:5] | {20{inst_found[12]}}&TLB_L0[12][24:5] | {20{inst_found[13]}}&TLB_L0[13][24:5] | {20{inst_found[14]}}&TLB_L0[14][24:5] | {20{inst_found[15]}}&TLB_L0[15][24:5] | {20{inst_found[16]}}&TLB_L0[16][24:5] | {20{inst_found[17]}}&TLB_L0[17][24:5] | {20{inst_found[18]}}&TLB_L0[18][24:5] | {20{inst_found[19]}}&TLB_L0[19][24:5] | {20{inst_found[20]}}&TLB_L0[20][24:5] | {20{inst_found[21]}}&TLB_L0[21][24:5] | {20{inst_found[22]}}&TLB_L0[22][24:5] | {20{inst_found[23]}}&TLB_L0[23][24:5] | {20{inst_found[24]}}&TLB_L0[24][24:5] | {20{inst_found[25]}}&TLB_L0[25][24:5] | {20{inst_found[26]}}&TLB_L0[26][24:5] | {20{inst_found[27]}}&TLB_L0[27][24:5] | {20{inst_found[28]}}&TLB_L0[28][24:5] | {20{inst_found[29]}}&TLB_L0[29][24:5] | {20{inst_found[30]}}&TLB_L0[30][24:5] | {20{inst_found[31]}}&TLB_L0[31][24:5]}, inst_sram_addr[11:0]};

assign data_mpaddr = data_sram_addr[12]? {{{20{data_found[0]}}&TLB_L1[0][24:5] | {20{data_found[1]}}&TLB_L1[1][24:5] | {20{data_found[2]}}&TLB_L1[2][24:5] | {20{data_found[3]}}&TLB_L1[3][24:5] | {20{data_found[4]}}&TLB_L1[4][24:5]  | {20{data_found[5]}}&TLB_L1[5][24:5] | {20{data_found[6]}}&TLB_L1[6][24:5] | {20{data_found[7]}}&TLB_L1[7][24:5] | {20{data_found[8]}}&TLB_L1[8][24:5] | {20{data_found[9]}}&TLB_L1[9][24:5] | {20{data_found[10]}}&TLB_L1[10][24:5] | {20{data_found[11]}}&TLB_L1[11][24:5] | {20{data_found[12]}}&TLB_L1[12][24:5] | {20{data_found[13]}}&TLB_L1[13][24:5] | {20{data_found[14]}}&TLB_L1[14][24:5] | {20{data_found[15]}}&TLB_L1[15][24:5] | {20{data_found[16]}}&TLB_L1[16][24:5] | {20{data_found[17]}}&TLB_L1[17][24:5] | {20{data_found[18]}}&TLB_L1[18][24:5] | {20{data_found[19]}}&TLB_L1[19][24:5] | {20{data_found[20]}}&TLB_L1[20][24:5] | {20{data_found[21]}}&TLB_L1[21][24:5] | {20{data_found[22]}}&TLB_L1[22][24:5] | {20{data_found[23]}}&TLB_L1[23][24:5] | {20{data_found[24]}}&TLB_L1[24][24:5] | {20{data_found[25]}}&TLB_L1[25][24:5] | {20{data_found[26]}}&TLB_L1[26][24:5] | {20{data_found[27]}}&TLB_L1[27][24:5] | {20{data_found[28]}}&TLB_L1[28][24:5] | {20{data_found[29]}}&TLB_L1[29][24:5] | {20{data_found[30]}}&TLB_L1[30][24:5] | {20{data_found[31]}}&TLB_L1[31][24:5]}, data_sram_addr[11:0]} :
										{{{20{data_found[0]}}&TLB_L0[0][24:5] | {20{data_found[1]}}&TLB_L0[1][24:5] | {20{data_found[2]}}&TLB_L0[2][24:5] | {20{data_found[3]}}&TLB_L0[3][24:5] | {20{data_found[4]}}&TLB_L0[4][24:5]  | {20{data_found[5]}}&TLB_L0[5][24:5] | {20{data_found[6]}}&TLB_L0[6][24:5] | {20{data_found[7]}}&TLB_L0[7][24:5] | {20{data_found[8]}}&TLB_L0[8][24:5] | {20{data_found[9]}}&TLB_L0[9][24:5] | {20{data_found[10]}}&TLB_L0[10][24:5] | {20{data_found[11]}}&TLB_L0[11][24:5] | {20{data_found[12]}}&TLB_L0[12][24:5] | {20{data_found[13]}}&TLB_L0[13][24:5] | {20{data_found[14]}}&TLB_L0[14][24:5] | {20{data_found[15]}}&TLB_L0[15][24:5] | {20{data_found[16]}}&TLB_L0[16][24:5] | {20{data_found[17]}}&TLB_L0[17][24:5] | {20{data_found[18]}}&TLB_L0[18][24:5] | {20{data_found[19]}}&TLB_L0[19][24:5] | {20{data_found[20]}}&TLB_L0[20][24:5] | {20{data_found[21]}}&TLB_L0[21][24:5] | {20{data_found[22]}}&TLB_L0[22][24:5] | {20{data_found[23]}}&TLB_L0[23][24:5] | {20{data_found[24]}}&TLB_L0[24][24:5] | {20{data_found[25]}}&TLB_L0[25][24:5] | {20{data_found[26]}}&TLB_L0[26][24:5] | {20{data_found[27]}}&TLB_L0[27][24:5] | {20{data_found[28]}}&TLB_L0[28][24:5] | {20{data_found[29]}}&TLB_L0[29][24:5] | {20{data_found[30]}}&TLB_L0[30][24:5] | {20{data_found[31]}}&TLB_L0[31][24:5]}, data_sram_addr[11:0]};

assign inst_paddr = (inst_mapped)? inst_mpaddr : inst_sram_addr;
assign data_paddr = (data_mapped)? data_mpaddr : data_sram_addr;
assign is_store = (data_mapped)? |data_sram_wen : 1'b0;
assign inst_modified = 0;
assign data_modified = (data_refill | data_invalid)?1'b0 : is_store && ~|data_d;
assign inst_invalid = (inst_refill)?1'b0 : inst_sram_en && inst_mapped && ~|inst_valid;
assign data_invalid = (data_refill)?1'b0 : data_sram_en && data_mapped && ~|data_valid;
assign inst_refill = inst_sram_en && inst_mapped && ~|inst_found;
assign data_refill = data_sram_en && data_mapped && ~|data_found;
assign tlb_exce = {im_r, dm_r, ii_r, di_r, ir_r, dr_r};
endmodule
