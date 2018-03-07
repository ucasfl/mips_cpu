`include "cpu.h"
module forward(
	input  wire [38:0] de_out_op,
	input  wire        exe_out_en,
	input  wire        de_excp,
	input  wire        is_exc,

	input  wire [38:0] exe_out_op,
	input  wire [ 4:0] exe_dest,
	input  wire [31:0] exe_value,
	input  wire [ 4:0] mem_out_op,
    input  wire [ 4:0] mem_dest,
    input  wire [31:0] mem_value,
	input  wire [ 4:0] wb_out_op,
	input  wire [ 4:0] wb_rf_waddr,
	input  wire [31:0] wb_rf_wdata,
	input  wire [ 4:0] de_rf_raddr1,
	input  wire [31:0] de_rf_rdata1,
	input  wire [ 4:0] de_rf_raddr2,
	input  wire [31:0] de_rf_rdata2,
	
	output wire        fe_en,
	output wire        de_en,
	output wire        exe_en,
	output wire [31:0] de_data1,
	output wire [31:0] de_data2
);
wire        _2exec, _2lw;
wire        _3exec;
wire        _4exec;

wire exe_to_de1, exe_to_de2, mem_to_de1, mem_to_de2, wb_to_de1, wb_to_de2;

assign _2exec = ~(exe_out_op[`EMPTY] || exe_out_op[`_SW] || exe_out_op[`_SB] || exe_out_op[`_SH] || exe_out_op[`_SWL] || exe_out_op[`_SWR]);
assign _3exec = ~(|mem_out_op);
assign _4exec = ~(|wb_out_op);
assign _2lw = (exe_out_op[`_LW] | exe_out_op[`_LB] | exe_out_op[`_LBU] | exe_out_op[`_LH] | exe_out_op[`_LHU] | exe_out_op[`_LWL] | exe_out_op[`_LWR]);

//exec = add, sub, lui...
assign exe_to_de1 = _2exec && (exe_dest == de_rf_raddr1) && (|exe_dest) && ~_2lw;    //exec + exec/lw/sw/b
assign exe_to_de2 = _2exec && (exe_dest == de_rf_raddr2) && (|exe_dest) && ~_2lw;    //exec + exec/lw/sw/b
assign mem_to_de1 = _3exec && (mem_dest == de_rf_raddr1)    && (|mem_dest);    //exec/lw + nop + exec/lw/sw/b
assign mem_to_de2 = _3exec && (mem_dest == de_rf_raddr2)    && (|mem_dest);    //exec/lw + nop + exec/lw/sw/b
assign wb_to_de1  = _4exec && (wb_rf_waddr == de_rf_raddr1) && (|wb_rf_waddr); //exec/lw + nop + nop + exec/lw/sw/b
assign wb_to_de2  = _4exec && (wb_rf_waddr == de_rf_raddr2) && (|wb_rf_waddr); //exec/lw + nop + nop + exec/lw/sw/b

assign fe_en  = exe_out_en && ~(_2lw && ((exe_dest == de_rf_raddr1) || (exe_dest == de_rf_raddr2)) && (|exe_dest));
assign de_en  = fe_en;
assign exe_en = fe_en;

assign de_data1 = (exe_to_de1)?exe_value : 
                  (mem_to_de1)?mem_value : 
                  (wb_to_de1 )?wb_rf_wdata : de_rf_rdata1;
assign de_data2 = (exe_to_de2)?exe_value : 
				  (mem_to_de2)?mem_value : 
                  (wb_to_de2 )?wb_rf_wdata : de_rf_rdata2;
				  
endmodule
