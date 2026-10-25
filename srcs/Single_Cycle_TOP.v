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
    input reset_n ,
    output [3:0] OutToBoard,
    output reg ExcFlag
    );
   
    //Wires
    wire ExceptionFlag;
    wire [31:0] Instr;
//    wire Zero;
    wire RegWrite;
    wire [2:0]ImmSrc;
    wire ALUSrcA;
    wire ALUSrcB;
    wire MemWrite;
    wire [1:0]ResultSrc;
//    wire PCSrc;
    wire [3:0] ALUControl;
    wire [2:0] funct3Control;
    wire SignExtension;
    wire OP3;
    wire Target;
//    wire BranchFlagD;
    wire Branch;
    wire Jump;
    
    wire system_instr;
    wire illegal_instr;
    wire csr_we;

    
    
    S_C_Control CONTROL_TOP(
    .Instr_In(Instr) ,
//    .Zero(Zero) ,
    .RegWrite(RegWrite) ,
    .ImmSrc(ImmSrc) ,
    .ALUSrcA(ALUSrcA) ,
    .ALUSrcB(ALUSrcB) ,
    .MemWrite(MemWrite) ,
    .ResultSrc(ResultSrc) ,
//    .PCSrc(PCSrc),
    .ALUControl(ALUControl),
    .funct3Control(funct3Control),
    .SignExtension(SignExtension),
    .OP3(OP3),
    .Target(Target),
    .Branch(Branch),
//    .BranchFlag(BranchFlagD),
    .Jump(Jump),
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .csr_we(csr_we)
    );
    
    S_C_Datapath DATAPATH_TOP(
    .clk(clk) ,
    .reset_n(reset_n) ,
    //.PCSrc(PCSrc) ,
    .MemWriteD(MemWrite) ,
    .funct3ControlD(funct3Control) ,
    .SignExtensionD(SignExtension) ,
    .OP3D(OP3),
    .RegWriteD(RegWrite) ,
    .ResultSrcD(ResultSrc),
    .ALUSrcAD(ALUSrcA) ,
    .ALUSrcBD(ALUSrcB) ,
    .ALUControlD(ALUControl) ,
    .ImmSrcD(ImmSrc) ,
    .Instr_OUT(Instr) ,
//    .Zero_Out(Zero),
    .TargetD(Target),
    .JumpD(Jump),
    .BranchD(Branch),
//    .BranchFlagD(BranchFlagD)
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .csr_we(csr_we),
    .OutToBoard(OutToBoard),
    .ExceptionFlag(ExceptionFlag)
    );

 always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
        ExcFlag <= 1'b0;
    else if (ExceptionFlag)
        ExcFlag <= 1'b1;
    else
        ExcFlag <= ExcFlag; // can also be omitted
end

    
endmodule
