`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 02:29:33 PM
// Design Name: 
// Module Name: Main_Decoder_tb
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


module Main_Decoder_tb(
    );
    //Signals 
    reg [6:0]OP ;
    wire RegWrite ;
    wire [1:0]ImmSrc ;
    wire ALUSrc ;
    wire MemWrite ;
    wire [1:0]ResultSrc ;
    wire Branch ;
    wire [1:0] ALUOp ;
    wire Jump ;
    
    //Instantiate UUT
    Main_Decoder MD_UUT(
    .OP(OP) ,
    .RegWrite(RegWrite) ,
    .ImmSrc(ImmSrc) ,
    .ALUSrc(ALUSrc) ,
    .MemWrite(MemWrite) ,
    .ResultSrc(ResultSrc) ,
    .Branch(Branch) ,
    .ALUOp(ALUOp) ,
    .Jump(Jump)
    );
    
    //Simulation
    initial  begin
    
    OP = 7'b0000000; //initial with undefined opcode
    #10 OP = 7'b0000011; // lw
    #10 OP = 7'b0100011; // sw
    #10 OP = 7'b0110011; // R-type
    #10 OP = 7'b1100011; // beq
    #10 OP = 7'b0010011; // I-type ALU
    #10 OP = 7'b1101111; // jal
    #10 OP = 7'b1111111; // undefined opcode
    #20 $stop;

    end
    
    //Monitor
    initial begin
    $monitor("time = %0t , OP = %0b , RegWrite = %0b , ImmSrc = %0b , ALUSrc = %0b , MemWrite = %0b , ResultSrc = %0b , Branch = %0b , ALUOp = %0b , Jump = %0b",
                 $time, OP, RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump);
    end
    
endmodule
