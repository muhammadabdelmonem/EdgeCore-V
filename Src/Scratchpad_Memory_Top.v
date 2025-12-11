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


module Scratchpad_Memory_Top(
    input  clk,
    input  reset_n,

    // CPU interface 
    input  [63:0] cpu_addr,
    input  [63:0] cpu_wdata,
    
    output [63:0] dma_rdata,
    output [63:0] spm_rdata,

    input         cpu_spm_we,
    input         cpu_spm_re,
    
    input         cpu_dma_we,
    input         cpu_dma_re,

    // AXI Memory interface
    output        mem_re,
    output        mem_we,
    output [63:0] mem_addr,
    output [63:0] mem_wdata,
    input  [63:0] mem_rdata
    );
    
    // DMA Register File
    wire [63:0] dma_src, dma_dst, dma_size;
    wire dma_start, dma_busy, dma_done;
    wire [63:0] dma_reg_rdata;
    
    // DMA Controller
    wire dma_ctrl_we, dma_ctrl_re;
    wire [63:0] dma_spm_addr;
    wire [63:0] dma_spm_wdata; 
    
    // SPM 
    wire spm_we = cpu_spm_we || dma_ctrl_we;
    wire spm_re = cpu_spm_re || dma_ctrl_re;

    // DMA takes priority when busy
    wire [63:0] spm_addr = dma_busy ? dma_spm_addr : cpu_addr;
    wire [63:0] spm_wdata = dma_busy ? dma_spm_wdata : cpu_wdata;
     
    DMA_Register DMA_REG(
        .clk(clk),
        .reset_n(reset_n),
        .we(cpu_dma_we),
        .re(cpu_dma_re),
        .dma_addr(cpu_addr),
        .wdata(cpu_wdata),
        .rdata(dma_rdata),
        .dma_src(dma_src),
        .dma_dst(dma_dst),
        .dma_size(dma_size),
        .dma_start(dma_start),
        .dma_busy(dma_busy),
        .dma_done(dma_done)
    );
    
    DMA_Controller DMA_CTRL(
        .clk(clk),
        .reset_n(reset_n),
        .src(dma_src),
        .dst(dma_dst),
        .size(dma_size),
        .start(dma_start),
        .dma_busy(dma_busy),
        .dma_done(dma_done),
        .mem_re(mem_re),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_rdata(mem_rdata),
        .mem_wdata(mem_wdata),
        .spm_addr(dma_spm_addr),
        .spm_wdata(dma_spm_wdata),
        .spm_rdata(spm_rdata),
        .dma_ctrl_re(dma_ctrl_re),
        .dma_ctrl_we(dma_ctrl_we)
    );

    SPM SPM_unit(
        .clk(clk),
        .we(spm_we),
        .re(spm_re),
        .spm_addr(spm_addr),
        .wdata(spm_wdata),
        .rdata(spm_rdata)
    );
    
endmodule
