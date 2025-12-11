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
    input  [2:0] ImmSrc ,
    output [63:0] ImmExt
    );
    reg [63:0] extrended ;
    
    always@(*)
    begin
       casex(ImmSrc)
       3'b000: extrended = {{52{Instr[31]}},Instr[31:20]}; //I-type
       3'b001: extrended = {{52{Instr[31]}},Instr[31:25],Instr[11:7]}; //S-type
       3'b010: extrended = {{52{Instr[31]}},Instr[7],Instr[30:25],Instr[11:8],1'b0}; //B-type
       3'b011: extrended = {{44{Instr[31]}},Instr[19:12],Instr[20],Instr[30:21],1'b0}; //J-type
       3'b100: extrended = {{59{1'b0}}, Instr[24:20]}; // zero extension for shift operation 
       3'b101: extrended = {Instr[31:12], 12'b0}; //LUI
       default: extrended = 64'bx; 
       endcase
    end
    assign ImmExt= extrended ;
endmodule
