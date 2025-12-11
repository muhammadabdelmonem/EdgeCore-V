`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 06:07:56 PM
// Design Name: 
// Module Name: Memory_Decoder
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


module Memory_Decoder(
    input  [63:0] addr,
    input         cpu_r_en,
    input         cpu_w_en,
    
    output reg [1:0] mem_sel,
    
    // Read/Write enables for each target
    output        dma_re,
    output        dma_we,
    output        spm_re,
    output        spm_we,
    output        dcache_re,
    output        dcache_we
    );
    
    
    localparam DMA_BASE = 64'hFFFF0000;
    localparam DMA_SIZE = 64'h00000028;
    localparam SPM_BASE = 64'h80000000;
    localparam SPM_SIZE = 64'd8192; // 8 KB
     
    // D-cache 00
    //SPM      01
    //DMA      10
        
    always @(*) begin
    mem_sel = 0;
    if (cpu_r_en | cpu_w_en) begin   
        // DMA Register Range
        if (addr >= DMA_BASE && addr < DMA_BASE + DMA_SIZE) begin
            mem_sel = 2'b10;
        end
        // SPM Range
        else if (addr >= SPM_BASE && addr < SPM_BASE + SPM_SIZE) begin
            mem_sel = 2'b01;
        end
        // D-cache
        else begin
            mem_sel = 2'b00;
        end
    end
end

    assign dcache_we    = (mem_sel == 2'b00) & cpu_w_en;
    assign dcache_re    = (mem_sel == 2'b00) & cpu_r_en;

    assign spm_we    = (mem_sel == 2'b01) & cpu_w_en;
    assign spm_re    = (mem_sel == 2'b01) & cpu_r_en;

    assign dma_we = (mem_sel == 2'b10) & cpu_w_en;
    assign dma_re = (mem_sel == 2'b10) & cpu_r_en;
endmodule
