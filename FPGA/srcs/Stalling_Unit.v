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
    output reg StallF, StallD, lwStall
    );
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
            StallF = lwStall;
            StallD = lwStall;
            
            end
        end
    
   
//always@(*)begin
//if(ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE)))begin
//lwStall=1;
//end
//else begin
//lwStall=1;
//end
//if(lwStall)begin


//end
 
endmodule
