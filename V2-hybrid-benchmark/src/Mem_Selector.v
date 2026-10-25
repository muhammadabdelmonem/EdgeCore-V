`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2026 03:25:12 AM
// Design Name: 
// Module Name: Mem_Selector
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


module Mem_Selector(
    input clk,
    input reset_n,
    
    input  [1:0] TargetMem,       
    input  dma_ready,
    input  spm_ready,
    output ready,

    input  dma_rready,
    input  spm_rready,
    output rready,

    input  [63:0] dma_rdata_cpu,
    input  [63:0] spm_rdata_cpu,
    output [63:0] external_rdata,

    input req_re,
    output reg dma_re,
    output reg spm_re,
    
    input req_we,
    output reg dma_we,
    output reg spm_we
    
    );

    reg Target;
    
    always @(*) begin 
        case(TargetMem) 
        2'b10: begin
                dma_re = req_re;
                dma_we = req_we;
                Target = 0;
            end
            2'b11: begin
                spm_re = req_re;
                spm_we = req_we;
                Target = 1;
            end
            default: begin
                dma_re = 0;
                dma_we = 0;
                spm_re = 0;
                spm_we = 0;
                Target = 0;
            end
        endcase 
        end
        
    
    //  Ready selector
    mux2x1 Ready_sel(
        .sel(Target),
        .in1(dma_ready),
        .in2(spm_ready),
        .out(ready)
    );
    
    // RReady selector
    mux2x1 RReady_sel(
        .sel(Target),
        .in1(dma_rready),
        .in2(spm_rready),
        .out(rready)
    ); 
    
    // external_rdata selector
    mux2x1 rdata_sel(
        .sel(Target),
        .in1(dma_rdata_cpu),
        .in2(spm_rdata_cpu),
        .out(external_rdata)
    );
endmodule
