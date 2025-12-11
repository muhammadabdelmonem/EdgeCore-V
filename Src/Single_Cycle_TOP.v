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
    input reset_n,
    // SPM Interface
    output dma_re,
    output dma_we,
    
    output spm_re,
    output spm_we,
    
    output [63:0] cpu_addr,
    output [63:0] cpu_wdata,
    input [63:0] dma_rdata,
    input [63:0] spm_rdata
    );
   
    //Wires
    wire [31:0] Instr;
//    wire Zero;
    wire RegWrite;
    wire [2:0]ImmSrc;
    wire ALUSrcA;
    wire ALUSrcB;
    wire MemWrite;
    wire MemRead;
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
    wire [2:0] Mul_Control;
    wire [3:0] Div_Control;
    wire [1:0]Function_Sel;
    wire Flag;
    
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
    .MemRead(MemRead),
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
    .Mul_Control(Mul_Control),
    .Div_Control(Div_Control),
    .Function_Sel(Function_Sel),
    .Flag(Flag),
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .csr_we(csr_we)
    );
    
    S_C_Datapath DATAPATH_TOP(
    .clk(clk) ,
    .reset_n(reset_n) ,
    //.PCSrc(PCSrc) ,
    .MemWriteD(MemWrite) ,
    .MemReadD(MemRead),
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
    .Mul_ControlD(Mul_Control),
    .Div_ControlD(Div_Control),
    .Function_SelD(Function_Sel),
    .FlagD(Flag),
//    .BranchFlagD(BranchFlagD)
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .csr_we(csr_we),
    .dma_re(dma_re),
    .dma_we(dma_we),
    .spm_re(spm_re),
    .spm_we(spm_we),
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .dma_rdata(dma_rdata),
    .spm_rdata(spm_rdata)
    );
    
endmodule
