`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 03:49:35 PM
// Design Name: 
// Module Name: S_C_Datapath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Single Cycle Datapath (with pipeline registers)
// 
// Dependencies: Other modules (PC, ALU, Instruction Memory, Data Memory, etc.)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module S_C_Datapath(
    input clk,
    input reset_n,
    //input PCSrc,
    input MemWriteD,
    input RegWriteD,
    input JumpD,
    input BranchD,
    input [1:0] ResultSrcD,
    input ALUSrcAD,
    input ALUSrcBD,
    input [3:0] ALUControlD,
    input [2:0] ImmSrcD,
    input [2:0] funct3ControlD,
    input SignExtensionD,
    input OP3D,
    input TargetD,
   // input BranchFlagD,
//    input [1:0] ForwardA,
//    input [1:0] ForwardB,
    output [31:0] Instr_OUT
//    output Zero_Out
    
    // Hazard
//    input EN
);

    //=============================
    // PC (Program Counter) Wires
    //=============================
    wire [63:0] PCPlus4F;
    wire [63:0] PCTargetE;
    wire [63:0] PCF;
    wire [63:0] PCF_Dash;
//  wire [63:0] PC;
    wire [63:0] BaseTarget;
    wire PCSrcE;

    //=============================
    // Immediate Extend Wires
    //=============================
    wire [63:0] ImmExtD;

    //=============================
    // Instruction Memory Wires
    //=============================
    wire [31:0] InstrF;

    //=============================
    // Register File Wires
    //=============================
    wire [63:0] RD1;
    wire [63:0] RD2;
    wire [63:0] Result;

    //=============================
    // ALU Wires
    //=============================
    wire [63:0] SrcA;
    wire [63:0] SrcB;
    wire [63:0] ALUResult;
    wire BranchFlag;

    //=============================
    // Data Memory Wires
    //=============================
    
    

    //=============================
    // Hazard Unit Wires
    //=============================
   
    wire StallF, StallD;
    wire FlushD, FlushE;
    wire [1:0] ForwardAE, ForwardBE;
    wire [4:0] Rs1D, Rs2D, RdD;
    
    //=============================
    // Pipeline Register Wires
    //=============================
    // Decode Stage
    //------------------------------------
    wire [31:0] InstrD;
    wire [63:0] PCD, PCPlus4D;
   
    //------------------------------------
    // Execute Stage
    //------------------------------------
    wire [63:0] RD1E, RD2E;
    wire [4:0]  Rs1E, Rs2E, RdE;
    wire [63:0] PCE, PCPlus4E, ImmExtE;

    wire RegWriteE;
    wire [1:0] ResultSrcE;
    wire MemWriteE;
    wire SignExtendE;
    wire [3:0] ALUControlE;
    wire ALUSrcAE, ALUSrcBE;
    wire TargetE, OP3E;
    wire [2:0] funct3ControlE;
    wire BranchE, JumpE, BranchFlagE;

    wire [63:0] ALUResultE, WriteDataE;
    wire [63:0] OutToMuxA, OutToMuxB;
    //------------------------------------
    // Memory Stage
    //------------------------------------
    wire [63:0] ALUResultM;
    wire [63:0] WriteDataM;
    wire [63:0] PCPlus4M;
    wire [4:0] RdM;
    wire RegWriteM;
    wire [63:0] ReadDataM;
    wire [1:0] ResultSrcM;
    wire MemWriteM;
    wire [2:0] funct3ControlM;
    //------------------------------------
    // Writeback Stage
    //------------------------------------
    wire [63:0] ALUResultW;
    wire [63:0] ReadDataW;
    wire [63:0] PCPlus4W;
    wire [4:0] RdW;
    wire RegWriteW;
    wire [1:0] ResultSrcW;
    wire [63:0] ResultW;


    assign Rs1D=InstrD[19:15];
    assign Rs2D=InstrD[24:20];
    assign RdD=InstrD[11:7];
    //------------------------------------
    // ========== FETCH STAGE ==========
    //------------------------------------

    // PC + 4 Unit
    PCPlus4 PC_PLUS4_UNIT(
        .PC(PCF),
        .PCPlus4(PCPlus4F)
    );

    // Target selection for JAL / JALR
    mux2x1 PC_target_UNIT(
        .sel(TargetE),
        .in1(OutToMuxA),
        .in2(PCE),
        .out(BaseTarget)
    );

    // PC Target calculation
    PCTarget PC_TARGET_UNIT(
        .ImmExt(ImmExtE),
        .BaseTarget(BaseTarget),
        .PCTarget(PCTargetE)
    );

    // PC Source MUX (PC+4 or Target)
    mux2x1 PC_MUX_UNIT(
        .sel(PCSrcE),
        .in1(PCPlus4F),
        .in2(PCTargetE),
        .out(PCF_Dash)
    );

    // PC Register
    PC PC_UNIT(
        .clk(clk),
        .reset_n(reset_n),
        .PCNext(PCF_Dash),
        .PC(PCF),
        .EN(~StallF)
    );

    // Instruction Memory
    Instruction_Memory IM_UNIT(
        .A(PCF),
        .RD(InstrF)
    );
    
    // Decode Register
    Decode_Register decode_register(
        .CLK(clk),
        .InstrF(InstrF),
        .PCF(PCF),
        .PCPlus4F(PCPlus4F),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .CLR(FlushD),
        .EN(~StallD)
    );
    //------------------------------------
    // ========== DECODE STAGE ==========
    //------------------------------------

    // Register File
    Register_File RF_UNIT(
        .clk(clk),
        .WE3(RegWriteW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(RdW),
        .WD3(ResultW),
        .RD1(RD1),
        .RD2(RD2)
    );

    // Immediate Extension
    Extend EXTEND_UNIT(
        .Instr(InstrD[31:7]),
        .ImmSrc(ImmSrcD),
        .ImmExt(ImmExtD)
    );
// Execute Register
    Execute_Register execute_register(
        .CLK(clk),
        .RD1(RD1),
        .RD2(RD2),
        .PCD(PCD),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdD(RdD),
        .PCPlus4D(PCPlus4D),
        .ImmExtD(ImmExtD),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .PCE(PCE),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .PCPlus4E(PCPlus4E),
        .ImmExtE(ImmExtE),
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .SignExtendD(SignExtensionD),
        .ALUControlD(ALUControlD),
        .ALUSrcAD(ALUSrcAD),
        .ALUSrcBD(ALUSrcBD),
        .TargetD(TargetD),
        .OP3D(OP3D),
        .funct3ControlD(funct3ControlD),
        .BranchD(BranchD),
        .JumpD(JumpD),
        //.BranchFlagD(Branch_flagD),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .SignExtendE(SignExtendE),
        .ALUControlE(ALUControlE),
        .ALUSrcAE(ALUSrcAE),
        .ALUSrcBE(ALUSrcBE),
        .TargetE(TargetE),
        .OP3E(OP3E),
        .funct3ControlE(funct3ControlE),
        .BranchE(BranchE),
        .JumpE(JumpE),
        //.BranchFlagE(BranchFlagE),
        .CLR(FlushE)
    );
    //------------------------------------
    // ========== EXECUTE STAGE ==========
    //------------------------------------
    // Forwarding MUXes
    mux3x1 ForwardA_MUX_UNIT(
        .sel(ForwardAE),
        .in1(RD1E),
        .in2(ResultW),
        .in3(ALUResultM),
        .out(OutToMuxA)
    );

    mux3x1 ForwardB_MUX_UNIT(
        .sel(ForwardBE),
        .in1(RD2E),
        .in2(ResultW),
        .in3(ALUResultM),
        .out(OutToMuxB)
    );

    // ALU Operand MUX A
    mux2x1 ALU_MUX_UNITA(
        .sel(ALUSrcAE),
        .in1(OutToMuxA),
        .in2(PCE),
        .out(SrcA)
    );

    // ALU Operand MUX B
    mux2x1 ALU_MUX_UNITB(
        .sel(ALUSrcBE),
        .in1(OutToMuxB),
        .in2(ImmExtE),
        .out(SrcB)
    );

    // ALU Unit
    ALU ALU_UNIT(
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUControl(ALUControlE),
        .ALUResult(ALUResultE),
        .SignExtension(SignExtendE),
        .OP3(OP3E),
        .Zero(),
        .funct3Control(funct3ControlE),
        .BranchFlag(BranchFlagE)
    );
     // Memory Register
    Memory_Register memory_register(
        .CLK(clk),
        .ALUResultE(ALUResultE),
        .WriteDataE(WriteDataE),
        .PCPlus4E(PCPlus4E),
        .RdE(RdE),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .PCPlus4M(PCPlus4M),
        .RdM(RdM),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .funct3ControlE(funct3ControlE),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .funct3ControlM(funct3ControlM)
    );

    //------------------------------------
    // ========== MEMORY STAGE ==========
    //------------------------------------

    // Data Memory
    Data_Memory DM_UNIT(
        .clk(clk),
        .WE(MemWriteM),
        .DataSizeCon(funct3ControlM),
        .A(ALUResultM),
        .WD(WriteDataM),
        .RD(ReadDataM)
    );
 // Writeback Register
    WRITEBACK_UNIT writeback_unit(
        .CLK(clk),
        .ALUResultM(ALUResultM),
        .RD(ReadDataM),
        .PCPlus4M(PCPlus4M),
        .RdM(RdM),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW)
    );
    //------------------------------------
    // ========== WRITEBACK STAGE ==========
    //------------------------------------

    // Result MUX (ALU, Memory, or PC+4)
    mux3x1 RESULT_MUX_UNIT(
        .sel(ResultSrcW),
        .in1(ALUResultW),
        .in2(ReadDataW),
        .in3(PCPlus4W),
        .out(ResultW)
    );

    // Hazard Unit
    Hazard_Unit  hazard_unit(
    .RegWriteW(RegWriteW), 
    .RegWriteM(RegWriteM),
    .ResultSrc(ResultSrcE[0]),
    .RdW(RdW), 
    .RdM(RdM),
    .Rs1E(Rs1E), 
    .Rs2E(Rs2E), 
    .RdE(RdE), 
    .Rs1D(InstrD[19:15]), 
    .Rs2D(InstrD[24:20]), 
    .PCSrcE(PCSrcE),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE), 
    .ForwardBE(ForwardBE),
    .StallD(StallD), 
    .StallF(StallF),
    .reset_n(reset_n)
    );



    //------------------------------------
    // ========== OUTPUT ASSIGNMENTS ==========
    //------------------------------------

    assign WriteDataE = OutToMuxB;
    assign PCSrcE = (JumpE | (BranchE & BranchFlagE));
    assign Instr_OUT = InstrD;
//    assign Zero_Out = Zero;

endmodule
