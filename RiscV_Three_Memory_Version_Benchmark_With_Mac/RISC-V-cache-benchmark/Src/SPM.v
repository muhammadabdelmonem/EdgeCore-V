`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 11:14:11 PM
// Design Name: 
// Module Name: SPM
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


module SPM 
#(
    parameter depth = 8192, 
    parameter SPM_BASE = 64'h8000_0000
    )(  
    input  clk,
    input reset_n,
    
    // CPU Port (byte-addressable)
    input [2:0] DataSizeCon,
    input  [12:0] addr,          
    input  [63:0] wdata,
    output reg [63:0] rdata,
    input  we,
    input  re,
    input  valid,
    output reg ready,
    output reg rready,
    
    // DMA Port (128 bit-addressable)
    input dma_we,
    input dma_re,
    input [12:0] dma_addr,
    input [127:0] dma_wdata,  // two words from AXI
    output reg [127:0] dma_rdata,
    input dma_busy, dma_start
    );
    // ============================================================
    // Memory
    // ============================================================
    reg  [7:0] ScratchPadMem [0:depth-1] ;   // example: 8KB SPM
    
     // Convert absolute address → local SPM address
    wire [12:0] spm_addr; // 8KB = 2^13
    assign spm_addr = addr;
    // ========================================================
    // DMA Port (Memory Mapped) 
    // ========================================================  
    // DMA → SPM port
    always @(posedge clk) 
    begin
        if (dma_we) begin
            // first data 64 bit
            ScratchPadMem[dma_addr] <= dma_wdata[7:0];
            ScratchPadMem[dma_addr+1] <= dma_wdata[15:8];
            ScratchPadMem[dma_addr+2] <= dma_wdata[23:16];
            ScratchPadMem[dma_addr+3] <= dma_wdata[31:24];
            ScratchPadMem[dma_addr+4] <= dma_wdata[39:32];
            ScratchPadMem[dma_addr+5] <= dma_wdata[47:40];
            ScratchPadMem[dma_addr+6] <= dma_wdata[55:48];
            ScratchPadMem[dma_addr+7] <= dma_wdata[63:56];
            
            // second data 64 bit 
            ScratchPadMem[dma_addr+8] <= dma_wdata[71:64];
            ScratchPadMem[dma_addr+9] <= dma_wdata[79:72];
            ScratchPadMem[dma_addr+10] <= dma_wdata[87:80];
            ScratchPadMem[dma_addr+11] <= dma_wdata[95:88];
            ScratchPadMem[dma_addr+12] <= dma_wdata[103:96];
            ScratchPadMem[dma_addr+13] <= dma_wdata[111:104];
            ScratchPadMem[dma_addr+14] <= dma_wdata[119:112];
            ScratchPadMem[dma_addr+15] <= dma_wdata[127:120];
            end
            end
         always @(*) begin
            if (dma_re) begin
            // read first word
            dma_rdata[63:0] <= {ScratchPadMem[dma_addr+7],ScratchPadMem[dma_addr+6],ScratchPadMem[dma_addr+5],ScratchPadMem[dma_addr+4],ScratchPadMem[dma_addr+3],ScratchPadMem[dma_addr+2],ScratchPadMem[dma_addr+1],ScratchPadMem[dma_addr]};
            dma_rdata[127:64]  <= {ScratchPadMem[dma_addr+15],ScratchPadMem[dma_addr+14],ScratchPadMem[dma_addr+13],ScratchPadMem[dma_addr+12],ScratchPadMem[dma_addr+11],ScratchPadMem[dma_addr+10],ScratchPadMem[dma_addr+9],ScratchPadMem[dma_addr+8]};
            end
        end
        
    integer i;
    
    // ========================================================
    // CPU Port (Lower Priority than DMA)
    // ========================================================
    // Simple Handshake Request "WRITE"
    // ========================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ready <= 0;
            rready <= 0;
            rdata <= 0;
        end else begin
            ready <= ~(dma_busy || dma_start); 
//            rready <= !dma_busy;
            // DMA has priority
            if (valid && ready && we) begin
                        case (DataSizeCon)
                            3'b000: ScratchPadMem[spm_addr] <= wdata[7:0]; // SB

                            3'b001: begin // SH
                                ScratchPadMem[spm_addr]   <= wdata[7:0];
                                ScratchPadMem[spm_addr+1] <= wdata[15:8];
                            end

                            3'b010: begin // SW
                                for (i = 0; i < 4; i = i + 1)
                                    ScratchPadMem[spm_addr+i] <= wdata[8*i +: 8];
                            end

                            3'b011: begin // SD
                                for (i = 0; i < 8; i = i + 1)
                                    ScratchPadMem[spm_addr+i] <= wdata[8*i +: 8];
                            end
                        endcase
                    end
                    end
                end
            
    // ========================================================
    // Simple Handshake Response "READ"
    // ========================================================
        always @(*) begin
         rready <= ~(dma_busy || dma_start);
         //rdata <= 0;
            //rready <= 1; // default
            if (valid && rready && re) begin
                  case (DataSizeCon)
                            3'b000: rdata <= {{56{ScratchPadMem[spm_addr][7]}}, ScratchPadMem[spm_addr]}; // LB
                            3'b001: rdata <= {{48{ScratchPadMem[spm_addr+1][7]}},
                                               ScratchPadMem[spm_addr+1],
                                               ScratchPadMem[spm_addr]};
                            3'b010: rdata <= {{32{ScratchPadMem[spm_addr+3][7]}},
                                               ScratchPadMem[spm_addr+3],
                                               ScratchPadMem[spm_addr+2],
                                               ScratchPadMem[spm_addr+1],
                                               ScratchPadMem[spm_addr]};
                            3'b011: rdata <= {ScratchPadMem[spm_addr+7],
                                               ScratchPadMem[spm_addr+6],
                                               ScratchPadMem[spm_addr+5],
                                               ScratchPadMem[spm_addr+4],
                                               ScratchPadMem[spm_addr+3],
                                               ScratchPadMem[spm_addr+2],
                                               ScratchPadMem[spm_addr+1],
                                               ScratchPadMem[spm_addr]};
                            3'b100: rdata <= {56'b0, ScratchPadMem[spm_addr]}; // LBU
                            3'b101: rdata <= {48'b0,
                                               ScratchPadMem[spm_addr+1],
                                               ScratchPadMem[spm_addr]};
                            3'b110: rdata <= {32'b0,
                                               ScratchPadMem[spm_addr+3],
                                               ScratchPadMem[spm_addr+2],
                                               ScratchPadMem[spm_addr+1],
                                               ScratchPadMem[spm_addr]};
                            default: ;
                        endcase 
                end
       end 
  
//initial begin

//    // -------------------------
//    // DOUBLEWORD at address 0
//    // value = 0x1122334455667788
//    // -------------------------
//    ScratchPadMem[0] = 8'h88;
//    ScratchPadMem[1] = 8'h77;
//    ScratchPadMem[2] = 8'h66;
//    ScratchPadMem[3] = 8'h55;
//    ScratchPadMem[4] = 8'h44;
//    ScratchPadMem[5] = 8'h33;
//    ScratchPadMem[6] = 8'h22;
//    ScratchPadMem[7] = 8'h11;

//    // -------------------------
//    // WORD at address 16
//    // value = 0xAABBCCDD
//    // -------------------------
//    ScratchPadMem[16] = 8'hDD;
//    ScratchPadMem[17] = 8'hCC;
//    ScratchPadMem[18] = 8'hBB;
//    ScratchPadMem[19] = 8'hAA;

//end         
endmodule

