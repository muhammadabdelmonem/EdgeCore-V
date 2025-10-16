`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 11:00:41 PM
// Design Name: 
// Module Name: Single_Cycle_TOP
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


module Single_Cycle_TOP(
    input clk ,
    input reset_n 
    );
    
    //Wires
    wire [31:0] Instr ;
    wire Zero ;
    wire RegWrite ;
    wire [2:0]ImmSrc ;
    wire ALUSrcA ;
    wire ALUSrcB ;
    wire MemWrite ;
    wire [1:0]ResultSrc ;
    wire PCSrc ;
    wire [3:0]ALUControl ;
    wire [2:0]DataSizeCon;
    wire SignExtension;
    wire OP3;
    
    S_C_Control CONTROL_TOP(
    .Instr_In(Instr) ,
    .Zero(Zero) ,
    .RegWrite(RegWrite) ,
    .ImmSrc(ImmSrc) ,
    .ALUSrcA(ALUSrcA) ,
    .ALUSrcB(ALUSrcB) ,
    .MemWrite(MemWrite) ,
    .ResultSrc(ResultSrc) ,
    .PCSrc(PCSrc),
    .ALUControl(ALUControl),
    .DataSizeCon(DataSizeCon),
    .SignExtension(SignExtension),
    .OP3(OP3)
    );
    
    S_C_Datapath DATAPATH_TOP(
    .clk(clk) ,
    .reset_n(reset_n) ,
    .PCSrc(PCSrc) ,
    .MemWrite(MemWrite) ,
    .DataSizeCon(DataSizeCon) ,
    .SignExtension(SignExtension) ,
    .OP3(OP3),
    .RegWrite(RegWrite) ,
    .ResultSrc(ResultSrc),
    .ALUSrcA(ALUSrcA) ,
    .ALUSrcB(ALUSrcB) ,
    .ALUControl(ALUControl) ,
    .ImmSrc(ImmSrc) ,
    .Instr_OUT(Instr) ,
    .Zero_Out(Zero)
    );
      
endmodule
