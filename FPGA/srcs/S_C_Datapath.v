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
    //exception
    input system_instr,
    input illegal_instr,
    input csr_we, 
   // input BranchFlagD,
//    input [1:0] ForwardA,
//    input [1:0] ForwardB,
    output [31:0] Instr_OUT,
//    output Zero_Out
    output [3:0] OutToBoard,
    output ExceptionFlag
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
    //wire PCSrcE;
    wire BranchTaken;
    wire Mispred_Sel;
    wire Predict_Sel;
    wire [63:0]Predict_Target;
    wire [63:0]Mispred_CorrectTarget;
    
    wire [63:0] PCF_Dash_pre;
    wire [63:0] PCExceptionTarget;
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
    // Exception Handler 
    //=============================
    wire mret;
    wire [63:0] mtvec;
    wire [63:0] mepc;
    wire exception_en;
    wire csr_flagD;
    wire csr_flagE;
    wire csr_flagM;
    wire csr_flagW;
    wire csr_pc_en;
    assign csr_flagD = exception_en | csr_we;
    assign csr_pc_en = mret | exception_en;
    wire [63:0]ResultCSR_D;
    wire [63:0]ResultCSR_E;
    wire [63:0]ResultCSR_M;
    wire [63:0]ResultCSR_W;
    wire exceptionF;
    wire exceptionD;
    wire exceptionE;
    
    wire [11:0] csr_addrD;
    wire [11:0] csr_addrE;
   
    wire csr_weD;
    wire csr_weE;
    assign csr_weD = csr_we;
   

    //=============================
    // Hazard Unit Wires
    //=============================
   
    wire StallF, StallD;
    wire FlushF, FlushD, FlushE;
    wire [1:0] ForwardAE, ForwardBE;
    wire [4:0] Rs1D, Rs2D, RdD;
    
    //=============================
    // Pipeline Register Wires
    //=============================
    // Decode Stage
    //------------------------------------
    wire [31:0] InstrD;
    wire [63:0] PCD, PCPlus4D;
   
    assign csr_addrD = InstrD[31:20];
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
    wire [63:0] ResultRF_W;

    assign Rs1D=InstrD[19:15];
    assign Rs2D=InstrD[24:20];
    assign RdD=InstrD[11:7];
    //------------------------------------
    // ========== FETCH STAGE ==========
    //------------------------------------
    //branch prediction unit 
    Branch_Prediction_Top BPT_UNIT(
    .Clk(clk), 
    .reset_n(reset_n),
    .BranchE(BranchE), 
    .JumpE(JumpE),
    .TargetE(TargetE),
    .BranchTaken(BranchTaken),
    .PCF(PCF), 
    .PCE(PCE), 
    .PCPlus4E(PCPlus4E),
    .PC_targetE(PCTargetE),
    .Mispred_Sel(Mispred_Sel),
    .Predict_Sel(Predict_Sel),
    .Predict_Target(Predict_Target), 
    .Mispred_CorrectTarget(Mispred_CorrectTarget)
    );
    
    
    
    
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
    wire [63:0] predict_mux_out;
    // PC Source MUX (PC+4 or Target)
    mux2x1 PC_MUX_UNIT1(
        .sel(Predict_Sel),
        .in1(PCPlus4F),
        .in2(Predict_Target),
        .out(predict_mux_out)
    );
    
    mux2x1 PC_MUX_UNIT2(
        .sel(Mispred_Sel),
        .in1(predict_mux_out),
        .in2(Mispred_CorrectTarget),
        .out(PCF_Dash_pre)
    );
    
    mux2x1 PC_MUX_UNIT3(
        .sel(mret),
        .in1(mtvec),
        .in2(mepc),
        .out(PCExceptionTarget)
    );
    
     mux2x1 PC_MUX_UNIT4(
        .sel(csr_pc_en),
        .in1(PCF_Dash_pre),
        .in2(PCExceptionTarget),
        .out(PCF_Dash)
    );
    
    // PC Register
    PC PC_UNIT(
        .clk(clk),
        .reset_n(reset_n),
        .PCNext(PCF_Dash),
        .PC(PCF),
        .CLR(FlushF),
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
        .RD2(RD2),
        .OutToBoard(OutToBoard)
    );

    // Immediate Extension
    Extend EXTEND_UNIT(
        .Instr(InstrD[31:7]),
        .ImmSrc(ImmSrcD),
        .ImmExt(ImmExtD)
    );
    
     // Exception handling
    Exception_Handler Exception_Handler_UNIT (
    .clk(clk),
    .reset_n(reset_n),
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .MemAddr(ALUResultE),
    .funct3(funct3ControlE),
    .PCF(PCF),
    .PCD(PCD),
    .PCE(PCE),
    .instrD(InstrD),
    .csr_rdata(ResultCSR_E),
    .csr_wdata(OutToMuxA),
    .exception_en(exception_en),
    .csr_we(csr_weE),
   // .csr_addrD(),
    .csr_addrE(csr_addrE),
    .mret(mret),
    .mepc(mepc),
    .mtvec(mtvec),
    .exceptionF(exceptionF),
    .exceptionD(exceptionD),
    .exceptionE(exceptionE)
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
       // .ResultCSR_D(ResultCSR_D),
        .csr_flagD(csr_flagD),
        .csr_addrD(csr_addrD),
        .csr_weD(csr_weD),
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
        .CLR(FlushE),
        .csr_flagE(csr_flagE),
       .csr_addrE(csr_addrE),
        .csr_weE(csr_weE)
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
        .ResultCSR_E(ResultCSR_E),
        .csr_flagE(csr_flagE),
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
        .funct3ControlM(funct3ControlM),
        .ResultCSR_M(ResultCSR_M),
        .csr_flagM(csr_flagM)
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
        .ResultCSR_M(ResultCSR_M),
        .csr_flagM(csr_flagM),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .ResultCSR_W(ResultCSR_W),
        .csr_flagW(csr_flagW)
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
        .out(ResultRF_W)
    );
    
    mux2x1 RESULT_RF_CSR(
    .sel(csr_flagW),
    .in1(ResultRF_W),
    .in2(ResultCSR_W),
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
    .Mispred(Mispred_Sel),
    .FlushF(FlushF),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE), 
    .ForwardBE(ForwardBE),
    .StallD(StallD), 
    .StallF(StallF),
    .reset_n(reset_n),
    .mret_Flush(mret),
    .exceptionF(exceptionF),
    .exceptionD(exceptionD),
    .exceptionE(exceptionE)
    );
    //------------------------------------
    // ========== OUTPUT ASSIGNMENTS ==========
    //------------------------------------

    assign WriteDataE = OutToMuxB;
    //assign PCSrcE = (JumpE | (BranchE & BranchFlagE));
    assign BranchTaken = ((BranchE & BranchFlagE));
    assign Instr_OUT = InstrD;
//    assign Zero_Out = Zero;

       assign ExceptionFlag = exception_en;

endmodule