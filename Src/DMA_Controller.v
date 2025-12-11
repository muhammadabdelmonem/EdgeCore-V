`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 12:36:15 AM
// Design Name: 
// Module Name: DMA_Controller
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


module DMA_Controller(
    input clk,
    input reset_n,

    // DMA regs interface
    input [63:0] src,
    input [63:0] dst,
    input [63:0] size,
    input start,
    output reg dma_busy,
    output reg dma_done,

    // AXI interface 
    output reg mem_re,
    output reg mem_we,
    output reg [63:0] mem_addr,
    input  [63:0] mem_rdata,
    output reg [63:0] mem_wdata,
    
    // SPM interface
    output reg [63:0] spm_addr,
    output reg [63:0] spm_wdata,
    input [63:0] spm_rdata,
    // to enable read/ write of spm 
    output reg dma_ctrl_re,
    output reg dma_ctrl_we
    );
    
    reg [63:0] counter;
    reg [63:0] cur_src, cur_dst;
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    wire direction; 

    localparam SPM_BASE = 64'h80000000;
    localparam SPM_SIZE = 64'd8192; // 8 KB
    
    // direction = 1 SPM is the destination which means main memory → SPM which means activate the spm_we
    // direction = 0 SPM is the destination which means main memory ← SPM which means activate the spm_re
    assign direction = ((dst >= SPM_BASE) && (dst < SPM_BASE + SPM_SIZE))? 1 : 0; 
    
    // State Definitions 
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam DONE = 2'b10;

    
    // STATE REGISTER
    always @(posedge clk or negedge reset_n) 
    begin
        if (!reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // NEXT STATE LOGIC
    always @(*) begin
        case (current_state)
            IDLE:  next_state = start ? BUSY : IDLE;
            BUSY: next_state = (counter == 0) ? DONE : BUSY;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ------------------------------
    // CONTROL LOGIC
    // ------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dma_done <= 0;
            dma_busy <= 0;
        end else begin
            case (current_state)

                IDLE: begin
                    dma_done <= 0;
                    dma_busy <= 0;
                    mem_re <= 0;
                    mem_we <= 0;
                    dma_ctrl_re <= 0;
                    dma_ctrl_we <= 0;
                    if (start) begin
                        dma_busy <= 1;
                        cur_src  <= src;
                        cur_dst  <= dst;
                        counter  <= size;
                    end
                end

                BUSY: begin 
                    if (direction)  // write to SPM: main memory → SPM
                    begin
                    mem_re   <= 1;
                    mem_addr <= cur_src;
                    
                    dma_ctrl_we <= 1;
                    spm_addr <= cur_dst;
                    
                    spm_wdata <= mem_rdata; 
                    end  
                    else // read from SPM: SPM → main memory
                    begin
                    mem_we   <= 1;
                    mem_addr <= cur_dst;
                    
                    dma_ctrl_re <= 1;
                    spm_addr <= cur_src;
                    
                    mem_wdata <= spm_rdata;
                    end

                    cur_src <= cur_src + 8;
                    cur_dst <= cur_dst + 8;
                    counter <= counter - 8;
                end

                DONE: begin
                    mem_re <= 0;
                    mem_we <= 0;
                    dma_ctrl_re <= 0;
                    dma_ctrl_we <= 0;
                    dma_busy <= 0;
                    dma_done <= 1;
                end
            endcase
        end
    end

endmodule
