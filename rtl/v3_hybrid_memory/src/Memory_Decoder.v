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
    output reg mem_sel,
    // Read/Write enables for each target
    output        outside_cpu_re,
    output        outside_cpu_we,
    output        inside_cpu_re,
    output        inside_cpu_we
    );
    
    // D-Cache Address Range
    localparam DCACHE_BASE = 64'h0000_0000;
    localparam DCACHE_SIZE = 64'h8000_0000; // Example: 2GB cache? adjust as needed

    always @(*) begin
        mem_sel = 0; // default: D-Cache
        if (cpu_r_en | cpu_w_en) begin
            if (addr >= DCACHE_BASE && addr < DCACHE_BASE + DCACHE_SIZE) begin
                mem_sel = 0; // D-Cache
            end else
                mem_sel = 1; // outside
            end
        end

    assign outside_cpu_re = (mem_sel == 1) & cpu_r_en;
    assign outside_cpu_we = (mem_sel == 1) & cpu_w_en;

    assign inside_cpu_re = (mem_sel == 0) & cpu_r_en;
    assign inside_cpu_we = (mem_sel == 0) & cpu_w_en;

endmodule