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
    input reset_n
    );
    localparam AXI_ADDR_WIDTH = 64;
    localparam AXI_DATA_WIDTH = 128;
    
    // ========================================
    // CPU
    // ======================================== 
    wire cpu_stall;
    wire [2:0] req_DataSizeCon;
    
    wire [63:0] req_addr, req_wdata, external_rdata;
    wire req_re, req_we, valid, ready, rready;
    wire [1:0] req_targetmem;
    
    // AXI3 Master Interface 
    // ========================================
     //Write Address Channel
     wire [AXI_ADDR_WIDTH-1:0] CACHE_AXI_AWADDR;
     wire [3:0] CACHE_AXI_AWLEN;    
     wire [2:0] CACHE_AXI_AWSIZE;
     wire [1:0] CACHE_AXI_AWBURST;
     wire CACHE_AXI_AWVALID;
     wire CACHE_AXI_AWREADY;
    // Write Data Channel 
     wire [AXI_DATA_WIDTH-1:0] CACHE_AXI_WDATA;
     wire [AXI_DATA_WIDTH/8-1:0] CACHE_AXI_WSTRB;
     wire CACHE_AXI_WLAST;
     wire CACHE_AXI_WVALID;
     wire CACHE_AXI_WREADY;
    // Write Response Channel
     wire  [1:0] CACHE_AXI_BRESP;
     wire CACHE_AXI_BVALID;
     wire CACHE_AXI_BREADY;
    // Read Address Channel
     wire [AXI_ADDR_WIDTH-1:0] CACHE_AXI_ARADDR;
     wire [3:0] CACHE_AXI_ARLEN;     // AXI3: 4 bits
     wire [2:0] CACHE_AXI_ARSIZE;
     wire [1:0] CACHE_AXI_ARBURST;
     wire CACHE_AXI_ARVALID;
     wire CACHE_AXI_ARREADY;
    // Read Data Channel
     wire  [AXI_DATA_WIDTH-1:0] CACHE_AXI_RDATA;
     wire  [1:0] CACHE_AXI_RRESP;
     wire  CACHE_AXI_RLAST;
     wire  CACHE_AXI_RVALID;
     wire  CACHE_AXI_RREADY;

    // ========================================   
    // DMA & Main Memory
    // ========================================
    // Write Address Channel
    wire [AXI_ADDR_WIDTH-1:0] DMA_M_AXI_AWADDR;
    wire [3:0] DMA_M_AXI_AWLEN;  
    wire [2:0] DMA_M_AXI_AWSIZE;   
    wire [1:0]DMA_M_AXI_AWBURST;   
    wire DMA_M_AXI_AWVALID, DMA_M_AXI_AWREADY;
    // Write Data Channel 
    wire [AXI_DATA_WIDTH-1:0] DMA_M_AXI_WDATA;
    wire [AXI_DATA_WIDTH/8-1:0] DMA_M_AXI_WSTRB;
    wire DMA_M_AXI_WLAST, DMA_M_AXI_WVALID, DMA_M_AXI_WREADY;
    // Write Response Channel
    wire [1:0] DMA_M_AXI_BRESP;
    wire DMA_M_AXI_BVALID, DMA_M_AXI_BREADY;
    // Read Address Channel
    wire [AXI_ADDR_WIDTH-1:0] DMA_M_AXI_ARADDR;
    wire [3:0] DMA_M_AXI_ARLEN; 
    wire [2:0] DMA_M_AXI_ARSIZE;  
    wire [1:0] DMA_M_AXI_ARBURST;  
    wire DMA_M_AXI_ARVALID,DMA_M_AXI_ARREADY;
    // Read Data Channel
    wire [AXI_DATA_WIDTH-1:0] DMA_M_AXI_RDATA;
    wire [1:0] DMA_M_AXI_RRESP;
    wire DMA_M_AXI_RLAST, DMA_M_AXI_RVALID,DMA_M_AXI_RREADY;
   
    //---------------------------------------
    // AXI SLAVE
    //---------------------------------------
     //Write Address Channel
     wire [AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR;
     wire [3:0] S_AXI_AWLEN;    
     wire [2:0] S_AXI_AWSIZE;
     wire [1:0] S_AXI_AWBURST;
     wire S_AXI_AWVALID;
     wire S_AXI_AWREADY;
    // Write Data Channel 
     wire [AXI_DATA_WIDTH-1:0] S_AXI_WDATA;
     wire [AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB;
     wire S_AXI_WLAST;
     wire S_AXI_WVALID;
     wire S_AXI_WREADY;
    // Write Response Channel
     wire  [1:0] S_AXI_BRESP;
     wire S_AXI_BVALID;
     wire S_AXI_BREADY;
    // Read Address Channel
     wire [AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR;
     wire [3:0] S_AXI_ARLEN;     // AXI3: 4 bits
     wire [2:0] S_AXI_ARSIZE;
     wire [1:0] S_AXI_ARBURST;
     wire S_AXI_ARVALID;
     wire S_AXI_ARREADY;
    // Read Data Channel
     wire  [AXI_DATA_WIDTH-1:0] S_AXI_RDATA;
     wire  [1:0] S_AXI_RRESP;
     wire  S_AXI_RLAST;
     wire  S_AXI_RVALID;
     wire  S_AXI_RREADY;    
    
    
    // CPU 
    Single_Cycle_TOP CPU(
    .clk(clk),
    .reset_n(reset_n),
    
     // ========================================
    // Scratchpad Memory Interface
    // ========================================
    .cpu_stall(cpu_stall),
    .req_DataSizeCon(req_DataSizeCon),
    .req_addr(req_addr),
    .req_wdata(req_wdata),
    .external_rdata(external_rdata),
    .req_re(req_re),
    .req_we(req_we),
    .valid(valid),
    .ready(ready),
    .rready(rready),
    .req_targetmem(req_targetmem),
    
    // =============================
    // Main Memory Interface
    // =============================
    .CACHE_AXI_AWADDR(CACHE_AXI_AWADDR),
    .CACHE_AXI_AWLEN(CACHE_AXI_AWLEN),
    .CACHE_AXI_AWSIZE(CACHE_AXI_AWSIZE),
    .CACHE_AXI_AWBURST(CACHE_AXI_AWBURST),
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
    .CACHE_AXI_ARVALID(CACHE_AXI_ARVALID),
    .CACHE_AXI_ARREADY(CACHE_AXI_ARREADY),
        
    .CACHE_AXI_RDATA(CACHE_AXI_RDATA),
    .CACHE_AXI_RRESP(CACHE_AXI_RRESP),
    .CACHE_AXI_RLAST(CACHE_AXI_RLAST),
    .CACHE_AXI_RVALID(CACHE_AXI_RVALID),
    .CACHE_AXI_RREADY(CACHE_AXI_RREADY)
    );
    

    
    
    // SPM UNIT
    Scratchpad_Memory_Top #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) SPM_UNIT (
    .clk(clk),
    .reset_n(reset_n),
    // =============================
    // Main Memory interface
    // =============================
    // AXI4 Memory interface
    // Write Address Channel
    .DMA_M_AXI_AWADDR(DMA_M_AXI_AWADDR),
    .DMA_M_AXI_AWLEN(DMA_M_AXI_AWLEN),     
    .DMA_M_AXI_AWSIZE(DMA_M_AXI_AWSIZE),    
    .DMA_M_AXI_AWBURST(DMA_M_AXI_AWBURST),   
    .DMA_M_AXI_AWVALID(DMA_M_AXI_AWVALID),
    .DMA_M_AXI_AWREADY(DMA_M_AXI_AWREADY),       
    // Write Data Channel 
    .DMA_M_AXI_WDATA(DMA_M_AXI_WDATA),
    .DMA_M_AXI_WSTRB(DMA_M_AXI_WSTRB),
    .DMA_M_AXI_WLAST(DMA_M_AXI_WLAST),
    .DMA_M_AXI_WVALID(DMA_M_AXI_WVALID),
    .DMA_M_AXI_WREADY(DMA_M_AXI_WREADY),
    // Write Response Channel
    .DMA_M_AXI_BRESP(DMA_M_AXI_BRESP),
    .DMA_M_AXI_BVALID(DMA_M_AXI_BVALID),
    .DMA_M_AXI_BREADY(DMA_M_AXI_BREADY),
    // Read Address Channel
    .DMA_M_AXI_ARADDR(DMA_M_AXI_ARADDR),
    .DMA_M_AXI_ARLEN(DMA_M_AXI_ARLEN),    
    .DMA_M_AXI_ARSIZE(DMA_M_AXI_ARSIZE),    
    .DMA_M_AXI_ARBURST(DMA_M_AXI_ARBURST),
    .DMA_M_AXI_ARVALID(DMA_M_AXI_ARVALID),
    .DMA_M_AXI_ARREADY(DMA_M_AXI_ARREADY),
    // Read Data Channel
    .DMA_M_AXI_RDATA(DMA_M_AXI_RDATA),
    .DMA_M_AXI_RRESP(DMA_M_AXI_RRESP),
    .DMA_M_AXI_RLAST(DMA_M_AXI_RLAST),
    .DMA_M_AXI_RVALID(DMA_M_AXI_RVALID),
    .DMA_M_AXI_RREADY(DMA_M_AXI_RREADY), 
    // =============================
    // CPU interface
    // =============================
    .cpu_stall(cpu_stall),
    .req_DataSizeCon(req_DataSizeCon),
    .req_addr(req_addr),
    .req_wdata(req_wdata),
    .external_rdata(external_rdata),
    .req_re(req_re),
    .req_we(req_we),
    .valid(valid),
    .ready(ready),
    .rready(rready),
    .req_targetmem(req_targetmem)  
    
    );
    
    
    Arbiter #(
    .AXI_ADDR_WIDTH(64),
    .AXI_DATA_WIDTH(128)
             ) u_arbiter (
    .clk(clk),
    .reset_n(reset_n),

    // ================= CPU (Master 0) =================
    .cpu_axi_awaddr(CACHE_AXI_AWADDR),
    .cpu_axi_awlen(CACHE_AXI_AWLEN),
    .cpu_axi_awsize(CACHE_AXI_AWSIZE),
    .cpu_axi_awburst(CACHE_AXI_AWBURST),
    .cpu_axi_awvalid(CACHE_AXI_AWVALID),
    .cpu_axi_awready(CACHE_AXI_AWREADY),

    .cpu_axi_wdata(CACHE_AXI_WDATA),
    .cpu_axi_wstrb(CACHE_AXI_WSTRB),
    .cpu_axi_wlast(CACHE_AXI_WLAST),
    .cpu_axi_wvalid(CACHE_AXI_WVALID),
    .cpu_axi_wready(CACHE_AXI_WREADY),

    .cpu_axi_bresp(CACHE_AXI_BRESP),
    .cpu_axi_bvalid(CACHE_AXI_BVALID),
    .cpu_axi_bready(CACHE_AXI_BREADY),

    .cpu_axi_araddr(CACHE_AXI_ARADDR),
    .cpu_axi_arlen(CACHE_AXI_ARLEN),
    .cpu_axi_arsize(CACHE_AXI_ARSIZE),
    .cpu_axi_arburst(CACHE_AXI_ARBURST),
    .cpu_axi_arvalid(CACHE_AXI_ARVALID),
    .cpu_axi_arready(CACHE_AXI_ARREADY),

    .cpu_axi_rdata(CACHE_AXI_RDATA),
    .cpu_axi_rresp(CACHE_AXI_RRESP),
    .cpu_axi_rlast(CACHE_AXI_RLAST),
    .cpu_axi_rvalid(CACHE_AXI_RVALID),
    .cpu_axi_rready(CACHE_AXI_RREADY),

    // ================= DMA (Master 1) =================
    .dma_axi_awaddr(DMA_M_AXI_AWADDR),
    .dma_axi_awlen(DMA_M_AXI_AWLEN),
    .dma_axi_awsize(DMA_M_AXI_AWSIZE),
    .dma_axi_awburst(DMA_M_AXI_AWBURST),
    .dma_axi_awvalid(DMA_M_AXI_AWVALID),
    .dma_axi_awready(DMA_M_AXI_AWREADY),
        
    .dma_axi_wdata(DMA_M_AXI_WDATA),
    .dma_axi_wstrb(DMA_M_AXI_WSTRB),
    .dma_axi_wlast(DMA_M_AXI_WLAST),
    .dma_axi_wvalid(DMA_M_AXI_WVALID),
    .dma_axi_wready(DMA_M_AXI_WREADY),

    .dma_axi_bresp(DMA_M_AXI_BRESP),
    .dma_axi_bvalid(DMA_M_AXI_BVALID),
    .dma_axi_bready(DMA_M_AXI_BREADY),

    .dma_axi_araddr(DMA_M_AXI_ARADDR),
    .dma_axi_arlen(DMA_M_AXI_ARLEN),
    .dma_axi_arsize(DMA_M_AXI_ARSIZE),
    .dma_axi_arburst(DMA_M_AXI_ARBURST),
    .dma_axi_arvalid(DMA_M_AXI_ARVALID),
    .dma_axi_arready(DMA_M_AXI_ARREADY),

    .dma_axi_rdata(DMA_M_AXI_RDATA),
    .dma_axi_rresp(DMA_M_AXI_RRESP),
    .dma_axi_rlast(DMA_M_AXI_RLAST),
    .dma_axi_rvalid(DMA_M_AXI_RVALID),
    .dma_axi_rready(DMA_M_AXI_RREADY),

    // ================= Slave (Memory) =================
    .s_axi_awaddr(S_AXI_AWADDR),
    .s_axi_awlen(S_AXI_AWLEN),
    .s_axi_awsize(S_AXI_AWSIZE),
    .s_axi_awburst(S_AXI_AWBURST),
    .s_axi_awvalid(S_AXI_AWVALID),
    .s_axi_awready(S_AXI_AWREADY),

    .s_axi_wdata(S_AXI_WDATA),
    .s_axi_wstrb(S_AXI_WSTRB),
    .s_axi_wlast(S_AXI_WLAST),
    .s_axi_wvalid(S_AXI_WVALID),
    .s_axi_wready(S_AXI_WREADY),

    .s_axi_bresp(S_AXI_BRESP),
    .s_axi_bvalid(S_AXI_BVALID),
    .s_axi_bready(S_AXI_BREADY),  

    .s_axi_araddr(S_AXI_ARADDR),
    .s_axi_arlen(S_AXI_ARLEN),
    .s_axi_arsize(S_AXI_ARSIZE),
    .s_axi_arburst(S_AXI_ARBURST),
    .s_axi_arvalid(S_AXI_ARVALID),
    .s_axi_arready(S_AXI_ARREADY),

    .s_axi_rdata(S_AXI_RDATA),
    .s_axi_rresp(S_AXI_RRESP),
    .s_axi_rlast(S_AXI_RLAST),
    .s_axi_rvalid(S_AXI_RVALID),
    .s_axi_rready(S_AXI_RREADY)
);
    
    Main_Memory_AXI_Slave #(
    .AXI_ADDR_WIDTH (64),
    .AXI_DATA_WIDTH (128),
    .MEM_DEPTH      (65536)
    ) Main_Memory (
    // Global
    .ACLK        (clk),
    .ARESETn    (reset_n),

          // DMA & Main Memory
     // ===============================
     // Write Address Channel
     // ===============================
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWLEN(S_AXI_AWLEN),     
    .S_AXI_AWSIZE(S_AXI_AWSIZE),    
    .S_AXI_AWBURST(S_AXI_AWBURST),   
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    
    // ===============================       
    // Write Data Channel 
    // ===============================
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WLAST(S_AXI_WLAST),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    
    // ===============================
    // Write Response Channel
    // ===============================
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    
    // ===============================
    // Read Address Channel
    // ===============================
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARLEN(S_AXI_ARLEN),    
    .S_AXI_ARSIZE(S_AXI_ARSIZE),    
    .S_AXI_ARBURST(S_AXI_ARBURST),  
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    
    // ===============================
    // Read Data Channel
    // ===============================
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RLAST(S_AXI_RLAST),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY)     
);

    
endmodule
