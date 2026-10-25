`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 03:11:16 AM
// Design Name: 
// Module Name: SOC_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU_System_Top(
    input clk ,
    input reset_n,
    
    output icache_stall,
    output i_cache_access, i_cache_hit,i_cache_miss,
    output dir_stall, dir_write, dir_read,
    output branch, jal, jalr, mispredict, //same as what gets in to the bsm
    output exception_en,
    output mret,
    
    output read_transaction,
    output write_transaction,
    output busy
    );

    
    
    // ========================================
    // AXI3 Master Interface (In-order only, no IDs)
    // ========================================
    // AXI3 Write Address Channel
    wire [64-1:0]                M_AXI_AWADDR;
    wire [3:0]                   M_AXI_AWLEN;    // AXI3: 4 bits
    wire [2:0]                   M_AXI_AWSIZE;
    wire [1:0]                   M_AXI_AWBURST;

    wire                         M_AXI_AWVALID;
    wire                         M_AXI_AWREADY;
    
    // AXI3 Write Data Channel (WID removed - in-order writes only)
    wire [128-1:0]               M_AXI_WDATA;
    wire [128/8-1:0]             M_AXI_WSTRB;
    wire                         M_AXI_WLAST;
    wire                         M_AXI_WVALID;
    wire                         M_AXI_WREADY;
    
    // AXI3 Write Response Channel
    wire  [1:0]                  M_AXI_BRESP;
    wire                         M_AXI_BVALID;
    wire                         M_AXI_BREADY;
    
    // AXI3 Read Address Channel
    wire [64-1:0]                M_AXI_ARADDR;
    wire [3:0]                   M_AXI_ARLEN;    // AXI3: 4 bits
    wire [2:0]                   M_AXI_ARSIZE;
    wire [1:0]                   M_AXI_ARBURST;
    wire                         M_AXI_ARVALID;
    wire                         M_AXI_ARREADY;
    // AXI3 Read Data Channel
    wire  [128-1:0]               M_AXI_RDATA;
    wire  [1:0]                   M_AXI_RRESP;
    wire                          M_AXI_RLAST;
    wire                          M_AXI_RVALID;
    wire                          M_AXI_RREADY;
    
    
    // CPU 
    Single_Cycle_TOP CPU(
    .clk(clk),
    .reset_n(reset_n),

     // AXI3 Write Address Channel
    .M_AXI_AWADDR        (M_AXI_AWADDR),
    .M_AXI_AWLEN         (M_AXI_AWLEN),
    .M_AXI_AWSIZE        (M_AXI_AWSIZE),
    .M_AXI_AWBURST       (M_AXI_AWBURST),
    .M_AXI_AWVALID       (M_AXI_AWVALID),
    .M_AXI_AWREADY       (M_AXI_AWREADY),

    // AXI3 Write Data Channel
    .M_AXI_WDATA         (M_AXI_WDATA),
    .M_AXI_WSTRB         (M_AXI_WSTRB),
    .M_AXI_WLAST         (M_AXI_WLAST),
    .M_AXI_WVALID        (M_AXI_WVALID),
    .M_AXI_WREADY        (M_AXI_WREADY),

    // AXI3 Write Response Channel
    .M_AXI_BRESP         (M_AXI_BRESP),
    .M_AXI_BVALID        (M_AXI_BVALID),
    .M_AXI_BREADY        (M_AXI_BREADY),

        

    // AXI3 Read Address Channel
    .M_AXI_ARADDR        (M_AXI_ARADDR),
    .M_AXI_ARLEN         (M_AXI_ARLEN),
    .M_AXI_ARSIZE        (M_AXI_ARSIZE),
    .M_AXI_ARBURST       (M_AXI_ARBURST),
    .M_AXI_ARVALID       (M_AXI_ARVALID),
    .M_AXI_ARREADY       (M_AXI_ARREADY),

    // AXI3 Read Data Channel
    .M_AXI_RDATA         (M_AXI_RDATA),
    .M_AXI_RRESP         (M_AXI_RRESP),
    .M_AXI_RLAST         (M_AXI_RLAST),
    .M_AXI_RVALID        (M_AXI_RVALID),
    .M_AXI_RREADY        (M_AXI_RREADY),
    
    //benchmark
    .icache_stall_F(icache_stall), 
    .i_cache_access(i_cache_access), 
    .i_cache_hit(i_cache_hit),
    .i_cache_miss(i_cache_miss),
    .dir_stall(dir_stall), 
    .dir_write(dir_write), 
    .dir_read(dir_read),
    .branch(branch), 
    .jal(jal), 
    .jalr(jalr), 
    .mispredict(mispredict),
    .exception_en(exception_en),
    .mret(mret)

    );
    
    
    
    Main_Memory_AXI_Slave #(
    .AXI_ADDR_WIDTH (64),
    .AXI_DATA_WIDTH (128),
    .MEM_DEPTH      (65536)
) u_main_memory (
    // Global
    .ACLK        (clk),
    .ARESETn    (reset_n),

    // ===============================
    // Write Address Channel
    // ===============================
    .S_AXI_AWADDR   (M_AXI_AWADDR),
    .S_AXI_AWLEN    (M_AXI_AWLEN),
    .S_AXI_AWSIZE   (M_AXI_AWSIZE),
    .S_AXI_AWBURST  (M_AXI_AWBURST),
    .S_AXI_AWVALID  (M_AXI_AWVALID),
    .S_AXI_AWREADY  (M_AXI_AWREADY),

    // ===============================
    // Write Data Channel
    // ===============================
    .S_AXI_WDATA    (M_AXI_WDATA),
    .S_AXI_WSTRB    (M_AXI_WSTRB),
    .S_AXI_WLAST    (M_AXI_WLAST),
    .S_AXI_WVALID   (M_AXI_WVALID),
    .S_AXI_WREADY   (M_AXI_WREADY),

    // ===============================
    // Write Response Channel
    // ===============================
    .S_AXI_BRESP    (M_AXI_BRESP),
    .S_AXI_BVALID   (M_AXI_BVALID),
    .S_AXI_BREADY   (M_AXI_BREADY),

    // ===============================
    // Read Address Channel
    // ===============================
    .S_AXI_ARADDR   (M_AXI_ARADDR),
    .S_AXI_ARLEN    (M_AXI_ARLEN),
    .S_AXI_ARSIZE   (M_AXI_ARSIZE),
    .S_AXI_ARBURST  (M_AXI_ARBURST),
    .S_AXI_ARVALID  (M_AXI_ARVALID),
    .S_AXI_ARREADY  (M_AXI_ARREADY),

    // ===============================
    // Read Data Channel
    // ===============================
    .S_AXI_RDATA    (M_AXI_RDATA),
    .S_AXI_RRESP    (M_AXI_RRESP),
    .S_AXI_RLAST    (M_AXI_RLAST),
    .S_AXI_RVALID   (M_AXI_RVALID),
    .S_AXI_RREADY   (M_AXI_RREADY),
    
    // benchmark
    .read_transaction(read_transaction),
    .write_transaction(write_transaction),
    .busy(busy)
);

    
endmodule
