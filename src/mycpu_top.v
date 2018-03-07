
`define SIMU_DEBUG

module mycpu_top(
    input  wire        clk,
    input  wire        resetn,            //low active
	input  wire [ 5:0] int_n_i,

    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
  //`ifdef SIMU_DEBUG
   ,output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
  //`endif
);
//nextpc_gen
wire [31:0] nextpc;
//fetch
wire [31:0] fe_pc, inst_sram_addr;
wire        inst_sram_en;
//decode
wire        de_br_taken, de_br_is_br, de_br_is_j, de_br_is_jr, eret, syscall, break, de_badaddr, instu, exce_isbr, de_excp, tlbr, tlbwi, tlbp;
wire [ 4:0] de_rf_raddr1, de_rf_raddr2, de_dest;         
wire [15:0] de_br_offset;
wire [25:0] de_br_index;
wire [31:0] de_pc, de_br_target, de_vsrc1, de_vsrc2, de_st_value, de_vaddr;
wire [38:0] de_out_op;
//execute
wire        ex_rbadaddr, ex_wbadaddr, overf, c0_wen, exe_out_en, data_sram_en;
wire [ 1:0] two_dest;
wire [ 3:0] data_sram_wen;
wire [ 4:0] exe_dest, addr;
wire [31:0] exe_pc, exe_value, inc0, exe_vaddr, data_sram_addr, data_sram_wdata, c0;
wire [38:0] exe_out_op;
//memory
wire [ 1:0] mem_two_dest;
wire [ 4:0] mem_out_op, mem_dest;
wire [31:0] mem_value;
//writeback
wire [ 3:0] wb_rf_wen;
wire [ 4:0] wb_out_op, wb_rf_waddr;
wire [31:0] wb_rf_wdata;
//forward
wire        fe_en, de_en, exe_en;
wire [31:0] de_data1, de_data2;
//exception
wire        excp, exe_exc, is_exc;
wire [31:0] exce_c0, epc;
//regfile
wire [31:0] de_rf_rdata1, de_rf_rdata2;
//sram2like
wire        stall, inst_req, inst_wr, data_req, data_wr;
wire [ 1:0] inst_size, data_size;
wire [31:0] inst_sram_rdata, data_sram_rdata, inst_addr, inst_wdata, data_addr, data_wdata;
//like2axi
wire        inst_addr_ok, inst_data_ok, data_addr_ok, data_data_ok;
wire [31:0] inst_rdata, data_rdata;
//tlb
wire        is_store;
wire [5 :0] tlb_exce;
wire [31:0] inst_paddr, data_paddr, tlb_c0;

`ifdef SIMU_DEBUG
wire [31:0] de_inst;
wire [31:0] exe_inst;
wire [31:0] mem_pc;
wire [31:0] mem_inst;
wire [31:0] wb_pc;
`endif

wire [ 3:0] inst_sram_wen;
wire [31:0] inst_sram_wdata;
// we only need an inst ROM now
assign inst_sram_wen   = 4'b0;
assign inst_sram_wdata = 32'b0;


nextpc_gen nextpc_gen
    (
    .clk            (clk            ),
    .resetn         (resetn         ), //I, 1
	.eret           (eret           ),
	.stall          (stall          ),

	.epc            (epc            ),
    .fe_pc          (fe_pc          ), //I, 32
    .exe_out_en     (exe_out_en     ),

    .de_br_taken    (de_br_taken    ), //I, 1 
    .de_br_is_br    (de_br_is_br    ), //I, 1
    .de_br_is_j     (de_br_is_j     ), //I, 1
    .de_br_is_jr    (de_br_is_jr    ), //I, 1
    .de_br_offset   (de_br_offset   ), //I, 16
    .de_br_index    (de_br_index    ), //I, 26
    .de_br_target   (de_br_target   ), //I, 32
	.excp           (excp           ),
	.tlb_exce       (tlb_exce       ),

    .nextpc         (nextpc         )  //O, 32
    );


fetch_stage fe_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
    .fe_en          (fe_en          ),
	.stall          (stall          ),
                                   
    .nextpc         (nextpc         ), //I, 32
                                    
    .inst_sram_en   (inst_sram_en   ), //O, 1
    .inst_sram_addr (inst_sram_addr ), //O, 32
                                    
    .fe_pc          (fe_pc          )  //O, 32  
    );


decode_stage de_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
	.excp           (excp           ),
	.exe_exc        (exe_exc        ),
	.de_en          (de_en          ),
	.nextpc         (nextpc         ),
	.epc            (epc            ),
	.de_excp        (de_excp        ),

	.stall          (stall          ),
                                    
    .de_rf_raddr1   (de_rf_raddr1   ), //O, 5
    .de_rf_rdata1   (de_data1       ), //I, 32
    .de_rf_raddr2   (de_rf_raddr2   ), //O, 5
    .de_rf_rdata2   (de_data2       ), //I, 32
    .inst_sram_rdata(inst_sram_rdata), //I, 32
                                    
    .de_br_taken    (de_br_taken    ), //O, 1
    .de_br_is_br    (de_br_is_br    ), //O, 1
    .de_br_is_j     (de_br_is_j     ), //O, 1
    .de_br_is_jr    (de_br_is_jr    ), //O, 1
    .de_br_offset   (de_br_offset   ), //O, 16
    .de_br_index    (de_br_index    ), //O, 26
    .de_br_target   (de_br_target   ), //O, 32

	.syscall        (syscall        ),
	.break          (break          ),
	.de_badaddr     (de_badaddr     ),
	.instu          (instu          ),
	.exce_isbr      (exce_isbr      ),
	.de_vaddr       (de_vaddr       ),
	.eret           (eret           ),

    .de_out_op      (de_out_op      ), //O, 4
    .de_dest        (de_dest        ), //O, 5 
    .de_vsrc1       (de_vsrc1       ), //O, 32
    .de_vsrc2       (de_vsrc2       ), //O, 32
    .de_st_value    (de_st_value    ), //O, 32
    .de_pc          (de_pc          )  //O, 32

  `ifdef SIMU_DEBUG
   ,.fe_pc          (fe_pc          ), //I, 32
    .de_inst        (de_inst        )  //O, 32 
 `endif
    );

assign c0 = (!addr[3] || addr == 5'd10)?tlb_c0 : exce_c0;
execute_stage exe_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
	.excp           (excp           ),
    .exe_en         (exe_en         ),
	.c0             (c0             ),

	.stall          (stall          ),

    .de_out_op      (de_out_op      ), //I, 4
    .de_dest        (de_dest        ), //I, 5 
    .de_vsrc1       (de_vsrc1       ), //I, 32
    .de_vsrc2       (de_vsrc2       ), //I, 32
    .de_st_value    (de_st_value    ), //I, 32
                                    
	.tlbr           (tlbr           ),
	.tlbwi          (tlbwi          ),
	.tlbp           (tlbp           ),
                                    
    .exe_out_op     (exe_out_op     ), //O, 4
    .exe_dest       (exe_dest       ), //O, 5
    .exe_value      (exe_value      ), //O, 32
	
	.ex_rbadaddr    (ex_rbadaddr    ),
	.ex_wbadaddr    (ex_wbadaddr    ),
	.addr           (addr           ),
	.overf          (overf          ),
	.inc0           (inc0           ),
	.exe_vaddr      (exe_vaddr      ),
 	.c0_wen         (c0_wen         ),

    .data_sram_en   (data_sram_en   ), //O, 1
    .data_sram_wen  (data_sram_wen  ), //O, 4
    .data_sram_addr (data_sram_addr ), //O, 32
    .data_sram_wdata(data_sram_wdata), //O, 32
	.exe_out_en     (exe_out_en     ),
	.two_dest       (two_dest       ),
    .de_inst        (de_inst        ), //I, 32
    .de_pc          (de_pc          ), //I, 32
    .exe_pc         (exe_pc         ), //O, 32
    .exe_inst       (exe_inst       )  //O, 32
    );

memory_stage mem_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
	.stall          (stall          ),
                                    
    .exe_out_op     (exe_out_op     ), //I, 4
    .exe_dest       (exe_dest       ), //I, 5
    .exe_value      (exe_value      ), //I, 32
	.two_dest       (two_dest       ),
                                    
    .data_sram_rdata(data_sram_rdata), //I, 32
                                    
    .mem_out_op     (mem_out_op     ), //O, 1
    .mem_dest       (mem_dest       ), //O, 5
    .mem_value      (mem_value      ),  //O, 32
	.mem_two_dest   (mem_two_dest   )

  `ifdef SIMU_DEBUG
   ,.exe_pc         (exe_pc         ), //I, 32
    .exe_inst       (exe_inst       ), //I, 32
    .mem_pc         (mem_pc         ), //O, 32
    .mem_inst       (mem_inst       )  //O, 32
  `endif
    );


writeback_stage wb_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
	.stall          (stall          ),
                                    
    .mem_out_op     (mem_out_op     ), //I, 1
    .mem_dest       (mem_dest       ), //I, 5
    .mem_value      (mem_value      ), //I, 32
    .mem_two_dest   (mem_two_dest   ),

	.wb_out_op      (wb_out_op      ),
    .wb_rf_wen      (wb_rf_wen      ), //O, 4
    .wb_rf_waddr    (wb_rf_waddr    ), //O, 5
    .wb_rf_wdata    (wb_rf_wdata    )  //O, 32

  `ifdef SIMU_DEBUG
   ,.mem_pc         (mem_pc         ), //I, 32
    .mem_inst       (mem_inst       ), //I, 32
    .wb_pc          (wb_pc          )  //O, 32
  `endif
    );


regfile_2r1w regfile
    (
    .clk    (clk            ), //I, 1
	.resetn (resetn         ),

    .ra1    (de_rf_raddr1   ), //I, 5
    .rd1    (de_rf_rdata1   ), //O, 32

    .ra2    (de_rf_raddr2   ), //I, 5
    .rd2    (de_rf_rdata2   ), //O, 32

    .we1    (wb_rf_wen      ), //I, 4
    .wa1    (wb_rf_waddr    ), //I, 5
    .wd1    (wb_rf_wdata    )  //O, 32
    );

forward fwd
	(
	.de_out_op       (de_out_op       ),
	.exe_out_en      (exe_out_en      ),
	.de_excp         (de_excp         ),
	.is_exc          (is_exc          ),

	.exe_out_op      (exe_out_op      ),
	.exe_dest        (exe_dest        ),
	.exe_value       (exe_value       ),
	.mem_out_op      (mem_out_op      ),
	.mem_dest        (mem_dest        ),
	.mem_value       (mem_value       ),
	.wb_out_op       (wb_out_op       ),
	.wb_rf_waddr     (wb_rf_waddr     ),
	.wb_rf_wdata     (wb_rf_wdata     ),
	.de_rf_raddr1    (de_rf_raddr1    ),
	.de_rf_rdata1    (de_rf_rdata1    ),
	.de_rf_raddr2    (de_rf_raddr2    ),
	.de_rf_rdata2    (de_rf_rdata2    ),
	
	.fe_en           (fe_en           ),
	.de_en           (de_en           ),
	.exe_en          (exe_en          ),
	.de_data1        (de_data1        ),
	.de_data2        (de_data2        )
	);

exception excpti
    (
	.clk             (clk             ),
	.resetn          (resetn          ),
	.is_exc          (is_exc          ),
	.stall           (stall           ),

	.syscall         (syscall         ),
	.break           (break           ),
	.de_badaddr      (de_badaddr      ),
	.ex_rbadaddr     (ex_rbadaddr     ),
	.ex_wbadaddr     (ex_wbadaddr     ),
	.instu           (instu           ),
	.overf           (overf           ),
	.int_n_i         (int_n_i         ),
	.tlb_exce        (tlb_exce        ),
	.is_store        (is_store        ),

	.exce_isbr       (exce_isbr       ),
	.eret            (eret            ),
	.addr            (addr            ),
	.inc0            (inc0            ),

    .fe_pc           (fe_pc           ),  
	.de_pc           (de_pc           ),
	.inst_sram_addr  (inst_sram_addr  ),
	.data_sram_addr  (data_sram_addr  ),
	.de_vaddr        (de_vaddr        ),
	.exe_vaddr       (exe_vaddr       ),
	.exe_pc          (exe_pc          ),
	.c0_wen          (c0_wen          ),
	.excep           (excp            ),
	.exe_exc         (exe_exc         ),
	.exce_c0         (exce_c0         ),
	.epc             (epc             )
);
cpu_axi_interface like2axi
(
	.clk             (clk             ),
    .resetn          (resetn          ), 

	.data_sram_wen   (data_sram_wen   ),
    //inst sram-like 
    .inst_req        (inst_req        ),
    .inst_wr         (inst_wr         ),
    .inst_size       (inst_size       ),
    .inst_addr       (inst_addr       ),
    .inst_wdata      (inst_wdata      ),
    .inst_rdata      (inst_rdata      ),
    .inst_addr_ok    (inst_addr_ok    ),
    .inst_data_ok    (inst_data_ok    ),
    
    //data sram-like 
    .data_req        (data_req        ),
    .data_wr         (data_wr         ),
    .data_size       (data_size       ),
    .data_addr       (data_addr       ),
    .data_wdata      (data_wdata      ),
    .data_rdata      (data_rdata      ),
    .data_addr_ok    (data_addr_ok    ),
    .data_data_ok    (data_data_ok    ),

    //axi
    //ar
    .arid            (arid            ),
    .araddr          (araddr          ),
    .arlen           (arlen           ),
    .arsize          (arsize          ),
    .arburst         (arburst         ),
    .arlock          (arlock          ),
    .arcache         (arcache         ),
    .arprot          (arprot          ),
    .arvalid         (arvalid         ),
    .arready         (arready         ),
    //r           
    .rid             (rid             ),
    .rdata           (rdata           ),
    .rresp           (rresp           ),
    .rlast           (rlast           ),
    .rvalid          (rvalid          ),
    .rready          (rready          ),
    //aw          
    .awid            (awid            ),
    .awaddr          (awaddr          ),
    .awlen           (awlen           ),
    .awsize          (awsize          ),
    .awburst         (awburst         ),
    .awlock          (awlock          ),
    .awcache         (awcache         ),
    .awprot          (awprot          ),
    .awvalid         (awvalid         ),
    .awready         (awready         ),
    //w          
    .wid             (wid             ),
    .wdata           (wdata           ),
    .wstrb           (wstrb           ),
    .wlast           (wlast           ),
    .wvalid          (wvalid          ),
    .wready          (wready          ),
    //b           
    .bid             (bid             ),
    .bresp           (bresp           ),
    .bvalid          (bvalid          ),
    .bready          (bready          )
);
sram2like sram2like(
	.clk             (clk             ),
	.resetn          (resetn          ),
	.tlb_exce        (tlb_exce        ),

	.stall           (stall           ),

	.inst_sram_en    (inst_sram_en    ),
	.inst_sram_wen   (inst_sram_wen   ),
	.inst_sram_addr  (inst_paddr      ),
	.inst_sram_wdata (inst_sram_wdata ),
	.inst_sram_rdata (inst_sram_rdata ),

	.data_sram_en    (data_sram_en    ),
	.data_sram_wen   (data_sram_wen   ),
	.data_sram_addr  (data_paddr      ),
	.data_sram_wdata (data_sram_wdata ),
	.data_sram_rdata (data_sram_rdata ),

	.inst_req        (inst_req        ),
	.inst_wr         (inst_wr         ),
	.inst_size       (inst_size       ),
	.inst_addr       (inst_addr       ),
	.inst_wdata      (inst_wdata      ),
    .inst_rdata      (inst_rdata      ),
    .inst_addr_ok    (inst_addr_ok    ),
    .inst_data_ok    (inst_data_ok    ),

    .data_req        (data_req        ),
    .data_wr         (data_wr         ),
    .data_size       (data_size       ),
    .data_addr       (data_addr       ),
	.data_wdata      (data_wdata      ),  
    .data_rdata      (data_rdata      ),
    .data_addr_ok    (data_addr_ok    ),
    .data_data_ok    (data_data_ok    )
);
tlb tlb(
	.clk             (clk             ),
	.resetn          (resetn          ),
	.stall           (stall           ),

	.inst_sram_en    (inst_sram_en    ),
	.inst_sram_addr  (inst_sram_addr  ),

	.data_sram_en    (data_sram_en    ),
	.data_sram_wen   (data_sram_wen   ),
	.data_sram_addr  (data_sram_addr  ),

	.tlbr            (tlbr            ),
	.tlbwi           (tlbwi           ),
	.tlbp            (tlbp            ),

	.c0_wen          (c0_wen          ),
	.addr            (addr            ),
	.inc0            (inc0            ),
	.tlb_c0          (tlb_c0          ),

	.inst_paddr      (inst_paddr      ),
	.data_paddr      (data_paddr      ),

	.is_store        (is_store        ),
	.tlb_exce        (tlb_exce        )
);
//`ifdef SIMU_DEBUG
assign debug_wb_pc       = wb_pc;
assign debug_wb_rf_wen   = wb_rf_wen;
assign debug_wb_rf_wnum  = wb_rf_waddr;
assign debug_wb_rf_wdata = wb_rf_wdata;
//`endif

endmodule //mycpu_top
