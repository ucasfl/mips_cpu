
`define SIMU_DEBUG
`include "cpu.h"

module decode_stage(
    input  wire        clk,
    input  wire        resetn,
	input  wire        exe_exc,
	input  wire        excp,
	input  wire        de_en,
	input  wire [31:0] nextpc,
	input  wire [31:0] epc,
	output wire        de_excp,

	input  wire        stall,

    output wire [ 4:0] de_rf_raddr1,
    input  wire [31:0] de_rf_rdata1,
    output wire [ 4:0] de_rf_raddr2,
    input  wire [31:0] de_rf_rdata2,
	input  wire [31:0] inst_sram_rdata,

    output wire        de_br_taken,     //1: branch taken, go to the branch target
    output wire        de_br_is_br,     //1: target is PC+offset
    output wire        de_br_is_j,      //1: target is PC||offset
    output wire        de_br_is_jr,     //1: target is GR value
    output wire [15:0] de_br_offset,    //offset for type "br"
    output wire [25:0] de_br_index,     //instr_index for type "j"
    output wire [31:0] de_br_target,    //target for type "jr"

	output wire        syscall,
	output wire        break,
	output wire        de_badaddr,
	output wire        instu,
	output wire        exce_isbr,
	output wire [31:0] de_vaddr,

	output wire        eret,
    output wire [38:0] de_out_op,       //control signals used in EXE, MEM, WB stages
    output wire [ 4:0] de_dest,         //reg num of dest operand, zero if no dest
    output wire [31:0] de_vsrc1,        //value of source operand 1
    output wire [31:0] de_vsrc2,        //value of source operand 2
    output reg  [31:0] de_pc,
	output wire [31:0] de_st_value      //value stored to memory

  `ifdef SIMU_DEBUG
   ,input  wire [31:0] fe_pc,
	output reg  [31:0] de_inst          //instr code @decode stage

  `endif
);

`ifndef SIMU_DEBUG
reg  [31:0] de_inst;        //instr code @decode stage
`endif

wire        eq, gr, le, eq0, gez;
wire        bltzal_taken, bgezal_taken;
wire [ 5:0] op,spe;
wire [ 4:0] rs, rt, sa;
wire is380;
assign is380 = (nextpc == 32'hbfc00380) && ~de_excp;

parameter J       = 6'b000010;
parameter LUI     = 6'b001111;
parameter ADDIU   = 6'b001001;
parameter LW      = 6'b100011;
parameter SLTI    = 6'b001010;
parameter SLTIU   = 6'b001011;
parameter SW      = 6'b101011;
parameter BEQ     = 6'b000100;
parameter BNE     = 6'b000101;
parameter JAL     = 6'b000011;
parameter ADDI    = 6'b001000;
parameter ANDI    = 6'b001100;
parameter ORI     = 6'b001101;
parameter XORI    = 6'b001110;
parameter BGTZ    = 6'b000111;
parameter BLEZ    = 6'b000110;
parameter LB      = 6'b100000;
parameter LBU     = 6'b100100;
parameter LH      = 6'b100001;
parameter LHU     = 6'b100101;
parameter LWL     = 6'b100010;
parameter LWR     = 6'b100110;
parameter SB      = 6'b101000;
parameter SH      = 6'b101001;
parameter SWL     = 6'b101010;
parameter SWR     = 6'b101110;
parameter ERET    = 6'b010000;
parameter MFC0    = 5'b00000;
parameter MTC0    = 5'b00100;
parameter SPECIAL = 6'b000000;
parameter ADDU    = 6'b100001;
parameter OR      = 6'b100101;
parameter SLT     = 6'b101010;
parameter SLL     = 6'b000000;
parameter JR      = 6'b001000;
parameter ADD     = 6'b100000;
parameter SUB     = 6'b100010;
parameter SUBU    = 6'b100011;
parameter SLTU    = 6'b101011;
parameter AND     = 6'b100100;
parameter NOR     = 6'b100111;
parameter XOR     = 6'b100110;
parameter SLLV    = 6'b000100;
parameter SRA     = 6'b000011;
parameter SRAV    = 6'b000111;
parameter SRL     = 6'b000010;
parameter SRLV    = 6'b000110;
parameter DIV     = 6'b011010;
parameter DIVU    = 6'b011011;
parameter MULT    = 6'b011000;
parameter MULTU   = 6'b011001;
parameter MFHI    = 6'b010000;
parameter MFLO    = 6'b010010;
parameter MTHI    = 6'b010001;
parameter MTLO    = 6'b010011;
parameter JALR    = 6'b001001;
parameter SYSCALL = 6'b001100;
parameter BREAK   = 6'b001101;
parameter BBBBBB  = 6'b000001;
parameter BGEZ    = 5'b00001;
parameter BLTZ    = 5'b00000;
parameter BLTZAL  = 5'b10000;
parameter BGEZAL  = 5'b10001;
parameter TLBR    = 32'h42000001;
parameter TLBWI   = 32'h42000002;
parameter TLBP    = 32'h42000008;

wire _lui, _addiu, _lw, _slti, _sltiu, _sw, _jal, _addu, _or, _slt, _sll;
wire _add, _addi, _sub, _subu, _sltu, _and, _andi, _nor, _ori, _xor, _xori, _sllv, _sra, _srav, _srl, _srlv;
wire _div, _divu, _mult, _multu, _mfhi, _mflo, _mthi, _mtlo, _bgez, _bgtz, _blez, _bltz, _bltzal, _bgezal, _jalr;
wire _lb, _lbu, _lh, _lhu, _lwl, _lwr, _sb, _sh, _swl, _swr;
wire _eret, _mtc0, _mfc0, _syscall;
wire _break;
wire add_, addu_, or_, slt_, sltu_, sll_, jal_, and_, xor_, sra_, srl_, sw_, empty_;
wire tlbr, tlbwi, tlbp;

reg         syscall_reg, break_reg, de_badaddr_reg, instu_reg, exce_isbr_reg;
reg  [31:0] de_vaddr_reg;
wire next_int;
assign de_excp = syscall | break | de_badaddr | instu;
always @(posedge clk)
    begin
		if(stall || ~de_en) begin
			syscall_reg <= syscall_reg;
			break_reg <= break_reg;
			de_badaddr_reg <= de_badaddr;
			instu_reg <= instu_reg;
			exce_isbr_reg <= exce_isbr_reg;
			de_vaddr_reg <= de_vaddr_reg;
		end
		else if(resetn) begin
			syscall_reg <= _syscall;
			break_reg <= _break;
			de_badaddr_reg <= ((~next_int && (_jalr | (op == SPECIAL && spe == JR))) || _eret) && (de_br_target[1] | de_br_target[0]);
			de_vaddr_reg <= de_br_target;
			instu_reg <= ~(|de_out_op);
			exce_isbr_reg <= (op == BEQ) || (op == BNE) || _bgtz || _blez || _bgez || _bltz || _bltzal || _bgezal || de_br_is_j || (op == SPECIAL && spe == JR) || _jalr;
		end
		else begin
			syscall_reg <= 1'b0;
			break_reg <= 1'b0;
			de_badaddr_reg <= 1'b0;
			instu_reg <= 1'b0;
			exce_isbr_reg <= 1'b0;
			de_vaddr_reg <= 32'd0;
		end

		if(~resetn | excp | is380) de_inst <= 32'd0;
		else if (de_en && ~stall) de_inst <= inst_sram_rdata;
		else de_inst <= de_inst;
		if (de_en && ~stall) de_pc <= fe_pc;
		else de_pc <= de_pc;
	end
assign op = de_inst[31:26];
assign spe = de_inst[5:0];

assign eq  = (de_rf_rdata1 == de_rf_rdata2);
assign eq0 = (de_rf_rdata1 == 32'd0);
assign gez = ~de_rf_rdata1[31];
assign gr  = ~de_rf_rdata1[31] & |de_rf_rdata1;
assign le  = de_rf_rdata1[31];
assign bltzal_taken = _bltzal && le;
assign bgezal_taken = _bgezal && gez;
assign de_br_is_br = (op == BEQ & eq) | (op == BNE & ~eq) | (_bgtz & gr) | (_blez & (le | eq0)) | (_bgez & gez) | (_bltz & le) | bltzal_taken | bgezal_taken;
assign de_br_is_j  = (op == J) | (op == JAL);
assign de_br_is_jr = (op == SPECIAL && spe == JR) | _jalr | _eret;
assign de_br_taken = de_br_is_br | de_br_is_j | de_br_is_jr;
assign de_br_index = de_inst[25:0];
assign de_br_offset = de_inst[15:0];
assign de_br_target = (_syscall)?32'hbfc00380 : 
					  (_eret)?epc : de_rf_rdata1;

assign _lui   = (op == LUI);
assign _addiu = (op == ADDIU);
assign _lw    = (op == LW);
assign _slti  = (op == SLTI);
assign _sltiu = (op == SLTIU);
assign _sw    = (op == SW);
assign _jal   = (op == JAL);
assign _addu  = (op == SPECIAL && spe == ADDU);
assign _or    = (op == SPECIAL && spe == OR);
assign _slt   = (op == SPECIAL && spe == SLT);// && sa == 5'd0);
assign _sll   = (op == SPECIAL && spe == SLL);
assign _add   = (op == SPECIAL && spe == ADD);// && sa == 5'd0);
assign _addi  = (op == ADDI);
assign _sub   = (op == SPECIAL && spe == SUB);// && sa == 5'd0);
assign _subu  = (op == SPECIAL && spe == SUBU);// && sa == 5'd0);
assign _sltu  = (op == SPECIAL && spe == SLTU);
assign _and   = (op == SPECIAL && spe == AND);
assign _andi  = (op == ANDI);
assign _nor   = (op == SPECIAL && spe == NOR);
assign _ori   = (op == ORI);
assign _xor   = (op == SPECIAL && spe == XOR);
assign _xori  = (op == XORI);
assign _sllv  = (op == SPECIAL && spe == SLLV);
assign _sra   = (op == SPECIAL && spe == SRA);
assign _srav  = (op == SPECIAL && spe == SRAV);
assign _srl   = (op == SPECIAL && spe == SRL);
assign _srlv  = (op == SPECIAL && spe == SRLV);
assign _div   = (op == SPECIAL && spe == DIV) & ~exe_exc;
assign _divu  = (op == SPECIAL && spe == DIVU) & ~exe_exc;
assign _mult  = (op == SPECIAL && spe == MULT);
assign _multu = (op == SPECIAL && spe == MULTU);
assign _mfhi  = (op == SPECIAL && spe == MFHI);
assign _mflo  = (op == SPECIAL && spe == MFLO);
assign _mthi  = (op == SPECIAL && spe == MTHI);
assign _mtlo  = (op == SPECIAL && spe == MTLO);
assign _bgez  = (op == BBBBBB  && rt  == BGEZ);
assign _bgtz  = (op == BGTZ);
assign _blez   = (op == BLEZ);
assign _bltz   = (op == BBBBBB  && rt  == BLTZ);
assign _bltzal = (op == BBBBBB  && rt  == BLTZAL);
assign _bgezal = (op == BBBBBB  && rt  == BGEZAL);
assign _jalr   = (op == SPECIAL && spe == JALR);
assign _lb  = (op == LB);
assign _lbu = (op == LBU);
assign _lh  = (op == LH);
assign _lhu = (op == LHU);
assign _lwl = (op == LWL);
assign _lwr = (op == LWR);
assign _sb  = (op == SB);
assign _sh  = (op == SH);
assign _swl = (op == SWL);
assign _swr = (op == SWR);
assign _eret    = de_inst == 32'h42000018;
assign _mtc0    = (op == ERET && rs == MTC0);
assign _mfc0    = (op == ERET && rs == MFC0);
assign _syscall = (op == SPECIAL && spe == SYSCALL);
assign _break   = (op == SPECIAL && spe == BREAK);
assign tlbr  = (de_inst == TLBR);
assign tlbwi = (de_inst == TLBWI);
assign tlbp  = (de_inst == TLBP);

assign add_ = _addi | _add;
assign addu_ = _addiu | _addu;
assign or_   = _or | _ori;
assign slt_  = _slt | _slti;
assign sltu_ = _sltu | _sltiu;
assign sll_  = _sll | _sllv;
assign jal_  = _jal | _bltzal | _bgezal | _jalr;
assign and_  = _and | _andi;
assign xor_  = _xor | _xori;
assign sra_  = _sra | _srav;
assign srl_  = _srl | _srlv;
assign sw_   = _sw | _swl | _swr | _sb | _sh;
assign empty_ = (op == BEQ) | (op == BNE) | _bgtz | _blez | _bgez | _bltz | (op == J) | (op == SPECIAL && spe == JR) | _syscall | _break | tlbr | tlbwi | tlbp;

assign de_out_op = {_subu, addu_, _mtc0, _mfc0, _eret, _swr, _swl, _sh, _sb, _lwr, _lwl, _lhu, _lh, _lbu, _lb, _mtlo, _mthi, _mflo, _mfhi, _multu, _mult, _divu, _div, jal_, srl_, sra_, xor_, _nor, and_, _sub, _sw, sll_, sltu_, slt_, or_, _lw, add_, _lui, empty_};
assign de_st_value = de_rf_rdata2;

assign rs           = de_inst[25:21];
assign rt           = de_inst[20:16];
assign sa           = de_inst[10:6];
assign de_rf_raddr1 = rs;
assign de_rf_raddr2 = rt;

assign de_vsrc1 = ({32{de_br_taken|_lui}} & 32'd0)
				| ({32{_sll|_sllv|_sra|_srav|_srl|_srlv|_mtc0}} & de_rf_rdata2)
				| ({32{_jal|_jalr|_bltzal|_bgezal|_syscall}} & de_pc)
				| ({32{_addiu|_lw|_slti|_sltiu|sw_|_addu|_or|_slt|_add|_addi|_sub|_subu|_sltu|_and|_andi|_nor|_ori|_xor|_xori|_div|_divu|_mult|_multu|_mthi|_mtlo|_lb|_lbu|_lh|_lhu|_lwl|_lwr}} & de_rf_rdata1);

assign de_vsrc2 = ({32{de_br_taken}} & 32'd0)
				| ({32{_addu|_or|_slt|_add|_sub|_subu|_sltu|_and|_nor|_xor|_div|_divu|_mult|_multu}} & de_rf_rdata2)
				| ({32{_sllv|_srav|_srlv}} & de_rf_rdata1)
				| ({32{_sll|_sra|_srl}} & {27'd0,sa})
				| ({32{_jal|_jalr|_bltzal|_bgezal}} & 32'd8)
				| ({32{_andi|_ori|_xori|_mfc0}} & {16'd0,de_inst[15:0]})
				| ({32{_addiu|_lw|_slti|_sltiu|sw_|_addi|_lui|_lb|_lbu|_lh|_lhu|_lwl|_lwr}} & {{16{de_inst[15]}},de_inst[15:0]});

assign de_dest = ({5{_lui|_addiu|_lw|_slti|_sltiu|_sw|_addi|_andi|_ori|_xori|_lb|_lbu|_lh|_lhu|_lwl|_lwr|_mfc0}} & de_inst[20:16]) //rt
			   | ({5{_addu|_or|_slt|_sll|_add|_sub|_subu|_sltu|_and|_nor|_xor|_sllv|_sra|_srav|_srl|_srlv|_mfhi|_mflo|_jalr|_mtc0}} & de_inst[15:11]) //rd
			   | ({5{_jal|_bltzal|_bgezal}} & 5'd31);

assign next_int = |inst_sram_rdata;
assign syscall = syscall_reg;
assign break = break_reg;
assign de_badaddr = de_badaddr_reg;
assign de_vaddr = de_vaddr_reg;
assign instu = instu_reg;
assign exce_isbr = exce_isbr_reg;
assign eret = _eret;
endmodule //decode_stage
