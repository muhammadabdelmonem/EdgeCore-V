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


module SOC_TOP(
    input clk ,
    input reset_n
    );
    wire dma_re;
    wire dma_we;
    wire spm_re;
    wire spm_we;
    
    wire [63:0] cpu_addr;
    wire [63:0] cpu_wdata;
    wire [63:0] dma_rdata;
    
    // CPU 
    Single_Cycle_TOP CPU(
    .clk(clk),
    .reset_n(reset_n),
    // SPM interface
    .dma_re(dma_re),
    .dma_we(dma_we),
    .spm_re(spm_re),
    .spm_we(spm_we),
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .dma_rdata(dma_rdata),
    .spm_rdata(spm_rdata)
    );
    
    // SPM UNIT
    Scratchpad_Memory_Top SPM_UNIT (
    .clk(clk),
    .reset_n(reset_n),
    // CPU interface
    .cpu_dma_re(dma_re),
    .cpu_dma_we(dma_we),
    .cpu_spm_re(spm_re),
    .cpu_spm_we(spm_we),
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .dma_rdata(dma_rdata),
    .spm_rdata(spm_rdata),
    // AXI interface
    .mem_re(),
    .mem_we(),
    .mem_addr(),
    .mem_wdata(),
    .mem_rdata()
    
    );
    
endmodule
