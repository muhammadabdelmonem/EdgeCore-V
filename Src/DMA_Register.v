`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 11:42:03 PM
// Design Name: 
// Module Name: DMA_Register
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


module DMA_Register(
    input clk,
    input reset_n,
    input we, 
    input re,              
    input [63:0] dma_addr,
    input [63:0] wdata,
    output reg [63:0] rdata,

    output reg [63:0] dma_src,  // DMA source address
    output reg [63:0] dma_dst,  // DMA destination address
    output reg [63:0] dma_size, // DMA transfer size
    output reg dma_start,        // DMA start signal (bit 0 of CTRL reg)

    input dma_busy,          // From DMA controller: indicates DMA is working
    input dma_done           // From DMA controller: indicates DMA finished
    );
    
    wire [63:0] dma_status;
    
    // -----------------------------
    // DMA Registers Addresses
    // -----------------------------
    // 0x00 -> SRC
    // 0x08 -> DST
    // 0x10 -> SIZE
    // 0x18 -> CTRL (bit 0 = START)
    // 0x20 -> STATUS (bit1 = busy, bit0 = done)
      
    always @(posedge clk) 
    begin
        if (!reset_n)
                begin
                dma_src <= 64'b0;
                dma_dst <= 64'b0;
                dma_size <= 64'b0;
                dma_start <= 0;
                end 
        
            if (we) begin
            case (dma_addr[5:0])
                6'h00: dma_src   <= wdata;      
                6'h08: dma_dst   <= wdata;      
                6'h10: dma_size  <= wdata;        
                default: ;                     
            endcase
        end
        
         // Auto-start on either write or read
            if (we || re)
                dma_start <= 1'b1;
        
         // Auto-clear start once DMA begins
        if (dma_start && dma_busy)
            dma_start <= 1'b0;
    end

    always @(*) 
    begin
    rdata = 64'b0;
    if (re) begin
        case (dma_addr[5:0])
            6'h00: rdata = dma_src;
            6'h08: rdata = dma_dst;
            6'h10: rdata = dma_size;
            6'h18: rdata = {63'b0, dma_start};          
            6'h20: rdata = dma_status;
            default: rdata = 64'b0;                 
        endcase
    end
    end
    
     assign dma_status = {62'b0, dma_busy, dma_done}; 
     
endmodule
