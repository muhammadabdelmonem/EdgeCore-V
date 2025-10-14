`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 01:16:49 PM
// Design Name: 
// Module Name: Data_Memory
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


module Data_Memory
    #(parameter depth = 256)(
    input  clk, 
    input  WE ,
    input  [63:0] A  , // Address 
    input  [63:0] WD ,
    output [63:0] RD 
    );
    reg  [7:0] DATA_MEM [0:depth-1] ; //[7:0] to be word addressable 
    
//    integer i;
//    initial
//    begin
//        for(i =0 ; i<depth ; i=i+1)
//            DATA_MEM[i] = 0 ;
//    end
    
    
    always@(posedge(clk))
    begin
        if(WE)
            {DATA_MEM [A+7],DATA_MEM [A+6],DATA_MEM [A+5],DATA_MEM [A+4],DATA_MEM [A+3],DATA_MEM [A+2],DATA_MEM [A+1],DATA_MEM [A]} <= WD ;
    end
    assign  RD = {DATA_MEM [A+7],DATA_MEM [A+6],DATA_MEM [A+5],DATA_MEM [A+4],DATA_MEM [A+3],DATA_MEM [A+2],DATA_MEM [A+1],DATA_MEM [A]} ;
endmodule

