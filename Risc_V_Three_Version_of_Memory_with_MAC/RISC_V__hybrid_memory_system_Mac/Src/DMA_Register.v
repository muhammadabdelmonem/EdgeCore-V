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

module DMA_Register #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 64
)(
    input clk,
    input reset_n,
    
    // =============================
    // Simple Memory-Mapped Interface
    // =============================
    input  [ADDR_WIDTH-1:0]  addr,
    input  [DATA_WIDTH-1:0]  wdata,
    output reg [DATA_WIDTH-1:0] rdata,

    input  we,        
    input  re,        
    input  valid,     
    output reg ready, 
    output reg rready,
    
    // =============================
    // DMA Controller interface
    // =============================
    // Outputs to the DMA Controller
    output [63:0] dma_src,  
    output [63:0] dma_dst,  
    output [63:0] dma_size, 
    output dma_start,    
    output dma_dir, 
  
    // Inputs from the DMA Controller
    input dma_busy,          
    input dma_done,          
    input dma_bus_error,
    input dma_confg_error,
    input dma_start_ack      
    );
    
    // Register address constants 
    localparam [5:0] ADDR_SRC     = 6'h00;
    localparam [5:0] ADDR_DST     = 6'h08;
    localparam [5:0] ADDR_SIZE    = 6'h10;
    localparam [5:0] ADDR_CTRL    = 6'h18;
    localparam [5:0] ADDR_STATUS  = 6'h20;
    
    // Registers
    reg [63:0] SRC;  
    reg [63:0] DST;  
    reg [63:0] SIZE;
    reg [63:0] CTRL;
    reg [63:0] STATUS;

    // ========================================================
    // Simple Handshake Request "WRITE"
    // ========================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            SRC   <= 0;
            DST   <= 0;
            SIZE  <= 0;
            CTRL  <= 0;
            STATUS<= 0;
            
            ready <= 0;
        end else begin
            //ready <= 1; // default
            ready <= !dma_busy; // so valid is 1 only when dma is not busy
            if (valid && ready && we) begin
                    case (addr)
                        ADDR_SRC:   SRC  <= wdata;
                        ADDR_DST:   DST  <= wdata;
                        ADDR_SIZE:  SIZE <= wdata;
                        ADDR_CTRL:  CTRL <= wdata;
                        default: ;
                    endcase
                end
                if (dma_start_ack) begin
                CTRL[0] <= 1'b0;
            end
            end
        end
        
   // ========================================================
   // Status Register Update 
   // ========================================================  
 
    always @(posedge clk) 
   begin 
        STATUS[0] <= dma_done;
        STATUS[1] <= dma_busy;
        STATUS[2] <= dma_bus_error;
        STATUS[3] <= dma_confg_error;
    end

    // ========================================================
    // Simple Handshake Response "READ"
    // ========================================================
     reg re_reg;
    always @(*) begin
            rready <= ~(dma_start || dma_start_ack); // default
            if (valid && rready && re) begin
                    case (addr)
                        ADDR_SRC:    rdata <= SRC;
                        ADDR_DST:    rdata <= DST;
                        ADDR_SIZE:   rdata <= SIZE;
                        ADDR_CTRL:   rdata <= CTRL;
                        ADDR_STATUS: rdata <= STATUS;
                        default: rdata <= rdata;
                    endcase
                end
       end 
      
//       always @(posedge clk)
//        begin
//        if (!rready)
//        re_reg <= re;
//        else 
//        re_reg <= 0;
//        end
    // ========================================================
    // DMA outputs
    // ========================================================
    assign dma_src   = SRC;
    assign dma_dst   = DST;
    assign dma_size  = SIZE;
    assign dma_start = (CTRL[0] && ~dma_busy);
    assign dma_dir   = CTRL[1];
    
endmodule
