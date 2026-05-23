`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 12:44:43 AM
// Design Name: 
// Module Name: Stalling_Unit
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


module Stalling_Unit(
    input [4:0] Rs1D, Rs2D, RdE,
    input ResultSrcE0,reset_n,
    input ICU_Valid,
    input [1:0] Function_SelD,
    input icache_stall_F,
    input dcache_stall_M,
    output reg StallF, StallD, StallE, StallM, StallW, lwStall
    );
    wire ICU_Busy;
    assign ICU_Busy = !ICU_Valid && (Function_SelD != 2'b00);
    always@(*) 
    begin
        if(~reset_n)
            begin
             lwStall = 0;
             StallF  = 0;
             StallD  = 0;
             StallE  = 0;
             StallM  = 0;
            end
         else
            begin
            lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
            if(lwStall | ICU_Busy | icache_stall_F | dcache_stall_M)
                StallF = 1'b1;
            else
                StallF = 1'b0;
           // StallF = lwStall | ICU_Busy | icache_stall_F | dcache_stall_M;
           
           if(lwStall | ICU_Busy | icache_stall_F | dcache_stall_M)
                StallD = 1'b1;
            else
                StallD = 1'b0;
            //StallD = lwStall | ICU_Busy | icache_stall_F | dcache_stall_M;
            
            if(dcache_stall_M)
                StallE = 1'b1;
            else
                StallE = 1'b0;            
            //StallE = dcache_stall_M;
            
            if(dcache_stall_M)
                StallM = 1'b1;
            else
                StallM = 1'b0;
            //StallM = dcache_stall_M;
            if(dcache_stall_M)
                StallW = 1'b1;
            else
                StallW = 1'b0;
            //StallW = (dcache_stall_M & 1'b0);
            end
        end
    
   

 
endmodule
