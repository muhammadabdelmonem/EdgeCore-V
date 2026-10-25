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
    input clk, reset_n
    );
     // --dft specs -- //  
  
    // ========================================
    // AXI3 Master Interface 
    // ========================================
    // AXI3 Write Address Channel
    wire [64-1:0]                CACHE_AXI_AWADDR;
    wire [3:0]                   CACHE_AXI_AWLEN;    // AXI3: 4 bits
    wire [2:0]                   CACHE_AXI_AWSIZE;
    wire [1:0]                   CACHE_AXI_AWBURST;
    wire [1:0]                   CACHE_AXI_AWLOCK;    // AXI3: 2 bits
    wire [3:0]                   CACHE_AXI_AWCACHE;
    wire [2:0]                   CACHE_AXI_AWPROT;
    wire                         CACHE_AXI_AWVALID;
    wire                         CACHE_AXI_AWREADY;
    // AXI3 Write Data Channel 
    wire [128-1:0]               CACHE_AXI_WDATA;
    wire [128/8-1:0]             CACHE_AXI_WSTRB;
    wire                         CACHE_AXI_WLAST;
    wire                         CACHE_AXI_WVALID;
    wire                         CACHE_AXI_WREADY;
    // AXI3 Write Response Channel
    wire  [1:0]                  CACHE_AXI_BRESP;
    wire                         CACHE_AXI_BVALID;
    wire                         CACHE_AXI_BREADY;
    // AXI3 Read Address Channel
    wire [64-1:0]                CACHE_AXI_ARADDR;
    wire [3:0]                   CACHE_AXI_ARLEN;    // AXI3: 4 bits
    wire [2:0]                   CACHE_AXI_ARSIZE;
    wire [1:0]                   CACHE_AXI_ARBURST;
    wire [1:0]                   CACHE_AXI_ARLOCK;    // AXI3: 2 bits
    wire [3:0]                   CACHE_AXI_ARCACHE;
    wire [2:0]                   CACHE_AXI_ARPROT;
    wire                         CACHE_AXI_ARVALID;
    wire                         CACHE_AXI_ARREADY;
    // AXI3 Read Data Channel
    wire  [128-1:0]               CACHE_AXI_RDATA;
    wire  [1:0]                   CACHE_AXI_RRESP;
    wire                          CACHE_AXI_RLAST;
    wire                          CACHE_AXI_RVALID;
    wire                          CACHE_AXI_RREADY;
    
    
    // CPU 
    Single_Cycle_TOP CPU(
    .clk(clk),
    .reset_n(reset_n),
    //AXI INTERFACE
    .CACHE_AXI_AWADDR(CACHE_AXI_AWADDR),
        .CACHE_AXI_AWLEN(CACHE_AXI_AWLEN),
        .CACHE_AXI_AWSIZE(CACHE_AXI_AWSIZE),
        .CACHE_AXI_AWBURST(CACHE_AXI_AWBURST),
        .CACHE_AXI_AWLOCK(CACHE_AXI_AWLOCK),
        .CACHE_AXI_AWCACHE(CACHE_AXI_AWCACHE),
        .CACHE_AXI_AWPROT(CACHE_AXI_AWPROT),
        .CACHE_AXI_AWVALID(CACHE_AXI_AWVALID),
        .CACHE_AXI_AWREADY(CACHE_AXI_AWREADY),
        
        .CACHE_AXI_WDATA(CACHE_AXI_WDATA),
        .CACHE_AXI_WSTRB(CACHE_AXI_WSTRB),
        .CACHE_AXI_WLAST(CACHE_AXI_WLAST),
        .CACHE_AXI_WVALID(CACHE_AXI_WVALID),
        .CACHE_AXI_WREADY(CACHE_AXI_WREADY),
        
        .CACHE_AXI_BRESP(CACHE_AXI_BRESP),
        .CACHE_AXI_BVALID(CACHE_AXI_BVALID),
        .CACHE_AXI_BREADY(CACHE_AXI_BREADY),
        
        .CACHE_AXI_ARADDR(CACHE_AXI_ARADDR),
        .CACHE_AXI_ARLEN(CACHE_AXI_ARLEN),
        .CACHE_AXI_ARSIZE(CACHE_AXI_ARSIZE),
        .CACHE_AXI_ARBURST(CACHE_AXI_ARBURST),
        .CACHE_AXI_ARLOCK(CACHE_AXI_ARLOCK),
        .CACHE_AXI_ARCACHE(CACHE_AXI_ARCACHE),
        .CACHE_AXI_ARPROT(CACHE_AXI_ARPROT),
        .CACHE_AXI_ARVALID(CACHE_AXI_ARVALID),
        .CACHE_AXI_ARREADY(CACHE_AXI_ARREADY),
        
        .CACHE_AXI_RDATA(CACHE_AXI_RDATA),
        .CACHE_AXI_RRESP(CACHE_AXI_RRESP),
        .CACHE_AXI_RLAST(CACHE_AXI_RLAST),
        .CACHE_AXI_RVALID(CACHE_AXI_RVALID),
        .CACHE_AXI_RREADY(CACHE_AXI_RREADY)
    );
    
    
    Main_Memory_AXI_Slave #(
    .AXI_ADDR_WIDTH (64),
    .AXI_DATA_WIDTH (128),
    .MEM_DEPTH      (65536)
    ) u_main_memory (
    // Global
    .ACLK        (clk),
    .ARESETn    (reset_n),
    // Write Address Channel
    .S_AXI_AWADDR   (CACHE_AXI_AWADDR),
    .S_AXI_AWLEN    (CACHE_AXI_AWLEN),
    .S_AXI_AWSIZE   (CACHE_AXI_AWSIZE),
    .S_AXI_AWBURST  (CACHE_AXI_AWBURST),
    .S_AXI_AWLOCK   (CACHE_AXI_AWLOCK),
    .S_AXI_AWCACHE  (CACHE_AXI_AWCACHE),
    .S_AXI_AWPROT   (CACHE_AXI_AWPROT),
    .S_AXI_AWVALID  (CACHE_AXI_AWVALID),
    .S_AXI_AWREADY  (CACHE_AXI_AWREADY),
    // Write Data Channel
    .S_AXI_WDATA    (CACHE_AXI_WDATA),
    .S_AXI_WSTRB    (CACHE_AXI_WSTRB),
    .S_AXI_WLAST    (CACHE_AXI_WLAST),
    .S_AXI_WVALID   (CACHE_AXI_WVALID),
    .S_AXI_WREADY   (CACHE_AXI_WREADY),
    // Write Response Channel
    .S_AXI_BRESP    (CACHE_AXI_BRESP),
    .S_AXI_BVALID   (CACHE_AXI_BVALID),
    .S_AXI_BREADY   (CACHE_AXI_BREADY),
    // Read Address Channel
    .S_AXI_ARADDR   (CACHE_AXI_ARADDR),
    .S_AXI_ARLEN    (CACHE_AXI_ARLEN),
    .S_AXI_ARSIZE   (CACHE_AXI_ARSIZE),
    .S_AXI_ARBURST  (CACHE_AXI_ARBURST),
    .S_AXI_ARLOCK   (CACHE_AXI_ARLOCK),
    .S_AXI_ARCACHE  (CACHE_AXI_ARCACHE),
    .S_AXI_ARPROT   (CACHE_AXI_ARPROT),
    .S_AXI_ARVALID  (CACHE_AXI_ARVALID),
    .S_AXI_ARREADY  (CACHE_AXI_ARREADY),
    // Read Data Channel
    .S_AXI_RDATA    (CACHE_AXI_RDATA),
    .S_AXI_RRESP    (CACHE_AXI_RRESP),
    .S_AXI_RLAST    (CACHE_AXI_RLAST),
    .S_AXI_RVALID   (CACHE_AXI_RVALID),
    .S_AXI_RREADY   (CACHE_AXI_RREADY)
);

    
endmodule
