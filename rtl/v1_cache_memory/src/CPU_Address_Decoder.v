`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2026 01:31:21 AM
// Design Name: 
// Module Name: CPU_Address_Decoder
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


module CPU_Address_Decoder(
    input MemReadM,
    input MemWriteM,
    
    input [63:0] addr,
    
    // Target enables
    output reg inside_re,
    output reg inside_we,
    output reg outside_re,
    output reg outside_we,
    
    // Encoded target memory
    output reg [1:0] TargetMemM
    );
    
    // ==============================
    // Address Map
    // ==============================

    // 16 KB D-Cache
    localparam DCACHE_BASE = 64'h0000_0000;
    localparam DCACHE_SIZE = 64'd16384;      // 16 KB

    // 8 KB SPM
    localparam SPM_BASE    = 64'h8000_0000;
    localparam SPM_SIZE    = 64'd8192;       // 8 KB

    // DMA Registers
    localparam DMA_BASE    = 64'hFFFF_0000;
    localparam DMA_SIZE    = 64'h0000_0028;

    // ==============================
    // Target Decode
    // ==============================

    always @(*) begin
        //TargetMemM = 2'b01; // default: invalid

        if (MemReadM || MemWriteM) begin
            if (addr >= DCACHE_BASE && addr < DCACHE_BASE + DCACHE_SIZE)
                TargetMemM = 2'b00; // D-Cache

            else if (addr >= SPM_BASE && addr < SPM_BASE + SPM_SIZE)
                TargetMemM = 2'b11; // SPM

            else if (addr >= DMA_BASE && addr < DMA_BASE + DMA_SIZE)
                TargetMemM = 2'b10; // DMA
        end
    end

    // ==============================
    // Enable Generation
    // ==============================
    always @(*) begin
    // Default values
    inside_re  = 1'b0;
    inside_we  = 1'b0;
    outside_re = 1'b0;
    outside_we = 1'b0;
    
        case(TargetMemM)
            2'b00: begin 
                inside_re = MemReadM;
                inside_we = MemWriteM;
            end
            2'b11, 2'b10: begin 
                outside_re = MemReadM;
                outside_we = MemWriteM;
            end
            2'b01: ;
            endcase
    end
   
endmodule
