`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 08:27:58 PM
// Design Name: 
// Module Name: Scratchpad_Memory_Top
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


module Scratchpad_Memory_Top #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128
)(
    input  clk,
    input  reset_n,
   
    // CPU interface
    output cpu_stall,
    input [2:0] req_DataSizeCon,
   
    input [63:0] req_addr,
    input [63:0] req_wdata,
    output [63:0] external_rdata,
    
    input [1:0] req_targetmem,
    
    input req_re,
    input req_we,
    
    input valid,
    output ready,
    output rready,
    
    // AXI4 Memory interface 
    // Write Address Channel
    output  [AXI_ADDR_WIDTH-1:0]     DMA_M_AXI_AWADDR,
    output  [3:0]                    DMA_M_AXI_AWLEN,     // Burst length - 1 (AXI3: 4 bits, max 16 beats)
    output  [2:0]                    DMA_M_AXI_AWSIZE,    // Burst size (bytes per beat)
    output  [1:0]                    DMA_M_AXI_AWBURST,   // Burst type (INCR = 2'b01)
    output                           DMA_M_AXI_AWVALID,
    input                            DMA_M_AXI_AWREADY,
    // Write Data Channel 
    output   [AXI_DATA_WIDTH-1:0]    DMA_M_AXI_WDATA,
    output   [AXI_DATA_WIDTH/8-1:0]  DMA_M_AXI_WSTRB,
    output                           DMA_M_AXI_WLAST,
    output                           DMA_M_AXI_WVALID,
    input                            DMA_M_AXI_WREADY,
    // Write Response Channel
    input   [1:0]                    DMA_M_AXI_BRESP,
    input                            DMA_M_AXI_BVALID,
    output                           DMA_M_AXI_BREADY,
    // Read Address Channel
    output   [AXI_ADDR_WIDTH-1:0]    DMA_M_AXI_ARADDR,
    output   [3:0]                   DMA_M_AXI_ARLEN,     // Burst length - 1 (AXI3: 4 bits, max 16 beats)
    output   [2:0]                   DMA_M_AXI_ARSIZE,    // Burst size (bytes per beat)
    output   [1:0]                   DMA_M_AXI_ARBURST,   // Burst type (INCR = 2'b01)
    output                           DMA_M_AXI_ARVALID,
    input                            DMA_M_AXI_ARREADY,
    // Read Data Channel
    input   [AXI_DATA_WIDTH-1:0]    DMA_M_AXI_RDATA,
    input   [1:0]                   DMA_M_AXI_RRESP,
    input                           DMA_M_AXI_RLAST,
    input                           DMA_M_AXI_RVALID,
    output                          DMA_M_AXI_RREADY
    );
    
    
    // =============================
    // DMA_Register signals
    // =============================
    wire [63:0] dma_src, dma_dst, dma_size;
    wire dma_start, dma_start_ack;
    wire dma_busy, dma_done, dma_dir;
    wire dma_bus_error, dma_confg_error;
    
    //assign cpu_stall = dma_start || dma_busy;
    // =============================
    // SPM interface
    // =============================
    wire [127:0] spm_rdata;
    wire [127:0] spm_wdata;
    wire [63:0] spm_addr;
    wire dma_ctrl_we, dma_ctrl_re;
    // =============================
    // Mem_Selector signals
    // =============================
    wire dma_re, dma_we, spm_re, spm_we;
    wire dma_ready, dma_rready;
    wire spm_ready, spm_rready;
    wire [63:0] dma_rdata_cpu, spm_rdata_cpu;
    
    // Instantiate Mem_Selector
    Mem_Selector MEM_SEL(
        .clk(clk),
        .reset_n(reset_n),
    
        .TargetMem(req_targetmem),      
        .dma_ready(dma_ready),
        .spm_ready(spm_ready),
        .ready(ready),

        .dma_rready(dma_rready),
        .spm_rready(spm_rready),
        .rready(rready),

        .dma_rdata_cpu(dma_rdata_cpu),
        .spm_rdata_cpu(spm_rdata_cpu),
        .external_rdata(external_rdata),

        .req_re(req_re),
        .dma_re(dma_re),
        .spm_re(spm_re),
    
        .req_we(req_we),
        .dma_we(dma_we),
        .spm_we(spm_we)
    ); 
    
    DMA_Register #(
        .ADDR_WIDTH(6),
        .DATA_WIDTH(64)
        ) DMA_REG (
        .clk(clk),
        .reset_n(reset_n),
        
        // =============================
        // CPU Interface
        // =============================
        .addr(req_addr[5:0]),
        .wdata(req_wdata),
        .rdata(dma_rdata_cpu),

        .we(dma_we),
        .re(dma_re),
        
        .valid(valid),
        .ready(dma_ready),
        .rready(dma_rready),
        // =============================
        // DMA Controller interface
        // =============================
        // Outputs to the DMA Controller
        .dma_src(dma_src),
        .dma_dst(dma_dst),
        .dma_size(dma_size),
        .dma_start(dma_start),
        .dma_dir(dma_dir),
        
         // Inputs from the DMA Controller
        .dma_busy(dma_busy),
        .dma_done(dma_done),
        .dma_bus_error(dma_bus_error),
        .dma_confg_error(dma_confg_error),
        .dma_start_ack(dma_start_ack)
    );
    
    
    
    DMA_Controller #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
    ) DMA_CTRL(
        .clk(clk),
        .reset_n(reset_n),
        
        // =============================
        // DMA Register interface
        // =============================
        // Input from DMA Register 
        .src(dma_src),
        .dst(dma_dst),
        .size(dma_size),
        .start(dma_start),
        .dir(dma_dir),
        // Outputs to DMA Register 
        .dma_start_ack(dma_start_ack),
        .dma_busy(dma_busy),
        .dma_done(dma_done),
        .dma_bus_error(dma_bus_error),
        .dma_confg_error(dma_confg_error),
        
        // =============================
        // AXI4 Memory interface 
        // =============================
        // Write Address Channel
        .M_AXI_AWADDR(DMA_M_AXI_AWADDR),
        .M_AXI_AWLEN(DMA_M_AXI_AWLEN),     
        .M_AXI_AWSIZE(DMA_M_AXI_AWSIZE),    
        .M_AXI_AWBURST(DMA_M_AXI_AWBURST),   
        .M_AXI_AWVALID(DMA_M_AXI_AWVALID),
        .M_AXI_AWREADY(DMA_M_AXI_AWREADY),        
        // Write Data Channel 
        .M_AXI_WDATA(DMA_M_AXI_WDATA),
        .M_AXI_WSTRB(DMA_M_AXI_WSTRB),
        .M_AXI_WLAST(DMA_M_AXI_WLAST),
        .M_AXI_WVALID(DMA_M_AXI_WVALID),
        .M_AXI_WREADY(DMA_M_AXI_WREADY),
        // Write Response Channel
        .M_AXI_BRESP(DMA_M_AXI_BRESP),
        .M_AXI_BVALID(DMA_M_AXI_BVALID),
        .M_AXI_BREADY(DMA_M_AXI_BREADY),   
        // Read Address Channel
        .M_AXI_ARADDR(DMA_M_AXI_ARADDR),
        .M_AXI_ARLEN(DMA_M_AXI_ARLEN),    
        .M_AXI_ARSIZE(DMA_M_AXI_ARSIZE),    
        .M_AXI_ARBURST(DMA_M_AXI_ARBURST),
        .M_AXI_ARVALID(DMA_M_AXI_ARVALID),
        .M_AXI_ARREADY(DMA_M_AXI_ARREADY),    
        // Read Data Channel
        .M_AXI_RDATA(DMA_M_AXI_RDATA),
        .M_AXI_RRESP(DMA_M_AXI_RRESP),
        .M_AXI_RLAST(DMA_M_AXI_RLAST),
        .M_AXI_RVALID(DMA_M_AXI_RVALID),
        .M_AXI_RREADY(DMA_M_AXI_RREADY),
       
        // =============================
        // SPM interface 
        // =============================
        .spm_addr(spm_addr),
        .spm_wdata(spm_wdata),
        .spm_rdata(spm_rdata),
        .dma_ctrl_re(dma_ctrl_re),
        .dma_ctrl_we(dma_ctrl_we)
    );

    SPM #(
        .depth(8192)
    ) SPM_unit(
        .clk(clk),
        .reset_n(reset_n),
      
        // =============================
        // CPU interface
        // =============================
        .DataSizeCon(req_DataSizeCon),
        .addr(req_addr[12:0]), //SPM depth is 8192
        .wdata(req_wdata),
        .rdata(spm_rdata_cpu),
        .we(spm_we),
        .re(spm_re),
        .valid(valid),
        .ready(spm_ready),
        .rready(spm_rready),
        // =============================
        // DMA interface
        // =============================
        .dma_we(dma_ctrl_we),
        .dma_re(dma_ctrl_re),
        .dma_addr(spm_addr[12:0]),
        .dma_wdata(spm_wdata),
        .dma_rdata(spm_rdata),
        .dma_busy(dma_busy),
        .dma_start(dma_start)
    );
    
endmodule
