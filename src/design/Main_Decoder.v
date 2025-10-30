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
    input [2:0] funct3 ,
    output RegWrite ,
    output [2:0]ImmSrc ,
    output ALUSrcA ,
    output ALUSrcB ,
    output MemWrite ,
    output [1:0]ResultSrc ,
    output Branch ,
    output [1:0] ALUOp ,
    output Jump,
    output SignExtension,
    output Target
    );
    reg [14:0] outputs ;
    always@(*)           
    begin
        case(OP)
        7'b0000011: outputs = 15'b1_000_0_1_0_01_0_00_0_0_1 ; //LW
        7'b0100011: outputs = 15'b0_001_0_1_1_xx_0_00_0_0_1 ; //SW
        7'b0110011: outputs = 15'b1_xxx_0_0_0_00_0_10_0_0_1 ; //R Type
        7'b1100011: outputs = 15'b0_010_0_0_0_xx_1_01_0_0_1 ; //Beq
        7'b0010011: begin  //I Type
                    case (funct3)
                    3'b001, 3'b101: outputs = 15'b1_100_0_1_0_00_0_10_0_0_1 ; // Shift immediate
                    default: outputs = 15'b1_000_0_1_0_00_0_10_0_0_1; //I type ALU
                    endcase 
                    end
        7'b0011011: begin
                   if(funct3==3'b000) 
                    outputs = 15'b1_000_0_1_0_00_0_10_0_1_1 ; // ADD immediate word 
                    else
                    outputs = 15'b1_100_0_1_0_00_0_10_0_1_1 ;// Shift immediate word 
                    end
        7'b0111011: outputs= 15'b1_xxx_0_0_0_00_0_10_0_1_1; // R-Type word
        7'b1101111: outputs = 15'b1_011_x_x_0_10_0_xx_1_0_1 ; //Jal
        7'b1100111: outputs = 15'b1_000_x_x_0_10_0_xx_1_0_0 ; //Jalr
        7'b0011011: outputs = 15'b1_100_0_1_0_00_0_10_0_1_1 ; // Shift immediate word 
        7'b0010111: outputs = 15'b1_101_1_1_0_00_0_00_0_0_1 ; //U type auipc 
        7'b0110111: outputs = 15'b1_101_1_1_0_00_0_11_0_0_1 ; //U type LUI
        default:    outputs = 15'b0_xxx_x_x_0_xx_0_xx_0_x_x; //don't care for any other op
        endcase  
    end
    assign {RegWrite,ImmSrc,ALUSrcA,ALUSrcB,MemWrite,ResultSrc,Branch,ALUOp,Jump, SignExtension, Target} = outputs ;
endmodule