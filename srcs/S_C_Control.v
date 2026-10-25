`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 10:26:41 PM
// Design Name: 
// Module Name: S_C_Control
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


module S_C_Control(
    input [31:0] Instr_In,
//    input Zero,
   
    output RegWrite,
    output [2:0]ImmSrc,
    output ALUSrcA,
    output ALUSrcB,
    output MemWrite,
    output [1:0]ResultSrc,
    //output PCSrc,
    output [3:0] ALUControl,
    output [2:0] funct3Control,
    output OP3,
    output SignExtension,
    output Target,
    output Jump,
    output Branch
//    output BranchFlag
    );
    
    //Wires
//    wire BranchFlag_wire;
    
//    wire Branch_wire;
//    wire Jump_wire;
    wire [1:0] ALUOp;
    
    wire [6:0] OP;
    wire [2:0] funct3;
    wire funct7_5;
    
    assign OP = Instr_In[6:0];
    assign funct3 = Instr_In[14:12];
    assign funct7_5 = Instr_In[30];
    
    
    Main_Decoder MAIN_DECOD_UNIT(
    .OP(OP),
    .funct3(funct3),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .MemWrite(MemWrite),
    .ResultSrc(ResultSrc),
    .Branch(Branch),
    .ALUOp(ALUOp),
    .Jump(Jump),
    .SignExtension(SignExtension),
    .Target(Target)
    );
    
    ALU_Decoder ALU_DECOD_UNIT(
    .ALUOp(ALUOp),
    .funct3(funct3),
    .op_5(OP[5]),
    .op_3(OP[3]),
    .funct7_5(funct7_5),
//    .zero(Zero),
    .ALUControl(ALUControl),
//    .BranchFlag(BranchFlag),
    .funct3Control(funct3Control),
    .OP3(OP3)
    );
    
    //assign PCSrc = ( (BranchFlag & Branch) | Jump ) ;
endmodule
