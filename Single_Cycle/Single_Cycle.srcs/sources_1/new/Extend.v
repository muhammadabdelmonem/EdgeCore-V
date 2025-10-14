`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 02:44:31 PM
// Design Name: 
// Module Name: Extend
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


module Extend(
    input  [31:7] Instr ,
    input  [1:0] ImmSrc ,
    output [63:0] ImmExt
    );
    reg [63:0] extrended ;
    
    always@(*)
    begin
       casex(ImmSrc)
       2'b00: extrended = {{52{Instr[31]}},Instr[31:20]}; //I-type
       2'b01: extrended = {{52{Instr[31]}},Instr[31:25],Instr[11:7]}; //S-type
       2'b10: extrended = {{52{Instr[31]}},Instr[7],Instr[30:25],Instr[11:8],1'b0}; //B-type
       2'b11: extrended = {{44{Instr[31]}},Instr[19:12],Instr[20],Instr[30:21],1'b0}; //J-type
       default: extrended = 64'bx; 
       endcase
    end
    assign ImmExt= extrended ;
endmodule
