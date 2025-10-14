`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 12:38:56 PM
// Design Name: 
// Module Name: Instruction_Memory
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


module Instruction_Memory
     #(parameter depth = 256)(
    input  [63:0] A  , //address of inistructoin
    output [31:0] RD 
    );
    reg  [7:0] INS_MEM [0:depth-1] ; //[7:0] to be word addressable 
    initial 
    begin
    $readmemh("C:/Users/AHMED SAEED/Desktop/branch_test.mem",INS_MEM) ;
   // $readmemh("test.mem",INS_MEM) ;
    end
    assign RD = {INS_MEM [A+3],INS_MEM [A+2],INS_MEM [A+1],INS_MEM [A]} ;
endmodule
