`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 05:57:10 PM
// Design Name: 
// Module Name: Main_Decoder
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


module Main_Decoder(
    input [6:0]OP ,
    output RegWrite ,
    output [1:0]ImmSrc ,
    output ALUSrc ,
    output MemWrite ,
    output [1:0]ResultSrc ,
    output Branch ,
    output [1:0] ALUOp ,
    output Jump
    );
    reg [10:0] outputs ;
    always@(*)
    begin
        case(OP)
        7'b0000011: outputs = 11'b1_00_1_0_01_0_00_0 ; //lw
        7'b0100011: outputs = 11'b0_01_1_1_xx_0_00_0 ; //sw
        7'b0110011: outputs = 11'b1_xx_0_0_00_0_10_0 ; //R Type
        7'b1100011: outputs = 11'b0_10_0_0_xx_1_01_0 ; //beq
        7'b0010011: outputs = 11'b1_00_1_0_00_0_10_0 ; //I type ALU
        7'b1101111: outputs = 11'b1_11_x_0_10_0_xx_1 ; //jal
        default:    outputs = 11'bx_xx_x_x_xx_x_xx_x ; //don't care for any other op
        endcase  
    end
    assign {RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp,Jump} = outputs ;
endmodule
