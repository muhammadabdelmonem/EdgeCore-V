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
    output reg StallF, StallD, lwStall
    );
    wire ICU_Busy;
    assign ICU_Busy = !ICU_Valid && (Function_SelD != 2'b00);
    always@(*) 
    begin
        if(~reset_n)
            begin
             lwStall = 0;
             StallF = 0;
             StallD = 0;
            end
         else
            begin
            lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
            StallF = lwStall | ICU_Busy;
            StallD = lwStall | ICU_Busy;
            
            end
        end
    
   

 
endmodule
