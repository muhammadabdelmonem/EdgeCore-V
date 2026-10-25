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
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module S_C_Datapath(
    input clk ,
    input reset_n ,
    input MemWrite ,
    input RegWrite ,
    input [1:0]ResultSrc ,
    input ALUSrcA ,
    input ALUSrcB ,
    input [3:0]ALUControl ,
    input [2:0]ImmSrc ,
    input  [2:0]funct3Control,
    input SignExtension,
    input OP3,
    input Target,
    input Jump,
    input Branch,
    
    input system_instr,
    input illegal_instr,
    input csr_we,
    
    output [31:0] Instr_OUT
    
    );
    
    //PC WIRES
    wire [63:0]PCPlus4 ;
    wire [63:0]PCTarget ;
    wire [63:0]PCNext ;
    wire [63:0]PC ;
    wire [63:0]BaseTarget;
    wire PCSrc;
    
    wire [63:0] PCNext_pre;
    wire [63:0] PCExceptionTarget;
    
    
    //EXTEND WIRE
    wire [63:0]ImmExt ;
    
    //IM WIRE
    wire [31:0]Instr ;
    
    //RFWIRES
    wire [63:0]RD1;
    wire [63:0]RD2;
    wire [63:0]ResultRF;
    wire [63:0]Result ;
    
    //ALU WIRES
    wire [63:0]SrcA ;
    //assign SrcA = RD1 ;
    wire [63:0]SrcB ;
    wire [63:0]ALUResult ;
    wire BranchFlag;

    
    //DM WIRES
    wire [63:0]WriteData ;
    assign WriteData = RD2 ;
    wire [63:0]ReadData ;
    
    //EXCEPTION WIRES
    wire mret;
    wire [63:0] mtvec;
    wire [63:0] mepc;
    wire exception_en;
    wire csr_flag;
    assign csr_flag = exception_en | csr_we;
    wire [63:0]ResultCSR;
    
    PCPlus4 PC_PLUS4_UNIT(
    .PC(PC) ,
    .PCPlus4(PCPlus4)
    );
    
    mux2x1 PC_target_UNIT(    //for jal and jalr
    .sel(Target) ,
    .in1(RD1) ,
    .in2(PC) ,
    .out(BaseTarget)
    );
    
    // Normal PC flow: branch/jump or sequential
    PCTarget PC_TARGET_UNIT(
    .ImmExt(ImmExt) ,
    .BaseTarget(BaseTarget) ,
    .PCTarget(PCTarget)
    );
    
    // Select between mtvec (exception) and mepc (mret)
    mux2x1 PC_EXCEPTION_TARGET_MUX (
    .sel(mret),          
    .in1(mtvec),
    .in2(mepc),
    .out(PCExceptionTarget)
     );
     
     // Final PC selection: normal or exception
     mux2x1 PC_EXCEPTION_FINAL_MUX (
    .sel(exception_en | mret),      
    .in1(PCNext_pre),
    .in2(PCExceptionTarget),
    .out(PCNext)
     );
    
    mux2x1 PC_MUX_UNIT(
    .sel(PCSrc) ,
    .in1(PCPlus4) ,
    .in2(PCTarget) ,
    .out(PCNext_pre)
    );
    
    PC PC_UNIT(
    .clk(clk) ,
    .reset_n(reset_n) ,
    .PCNext(PCNext) ,
    .PC(PC)
    );
    
    Instruction_Memory IM_UNIT(
    .A(PC)  , //address of inistructoin
    .RD(Instr) 
    );
    
    Register_File RF_UNIT(
    .clk(clk) ,
    .WE3(RegWrite) ,
    .A1(Instr[19:15]) ,
    .A2(Instr[24:20]) ,
    .A3(Instr[11:7]) ,
    .WD3(Result) ,
    .RD1(RD1) ,
    .RD2(RD2)
    );    
    
    Extend EXTEND_UNIT(
    .Instr(Instr[31:7]) ,
    .ImmSrc(ImmSrc) ,
    .ImmExt(ImmExt)
    );
   
   mux2x1 ALU_MUX_UNITA(
    .sel(ALUSrcA) ,
    .in1(RD1) ,
    .in2(PC) ,
    .out(SrcA)
    );
     
    mux2x1 ALU_MUX_UNITB(
    .sel(ALUSrcB) ,
    .in1(RD2) ,
    .in2(ImmExt) ,
    .out(SrcB)
    );
    
    ALU ALU_UNIT(
    .SrcA(SrcA) ,
    .SrcB(SrcB) ,
    .ALUControl(ALUControl) ,
    .ALUResult(ALUResult) ,
    .SignExtension(SignExtension),
    .OP3(OP3),
    .Zero(),
    .funct3Control(funct3Control),
    .BranchFlag(BranchFlag)
    );
    
    Data_Memory DM_UNIT(
    .clk(clk), 
    .WE(MemWrite) ,
    .DataSizeCon(funct3Control),
    .A(ALUResult) , //address of inistructoin
    .WD(WriteData) ,
    .RD(ReadData) 
    );
    
    mux3x1 RESULT_MUX_UNIT(
    .sel(ResultSrc) ,
    .in1(ALUResult) ,
    .in2(ReadData) ,
    .in3(PCPlus4) ,
    .out(ResultRF)
    );
    
     mux2x1 RESULT_RF_CSR(
    .sel(csr_flag) ,
    .in1(ResultRF) ,
    .in2(ResultCSR) ,
    .out(Result)
    );
    
    
    // Exception handling
    Exception_Handler Exception_Handler_UNIT (
    .clk(clk),
    .reset_n(reset_n),
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .PCTarget(PCTarget),
    .MemAddr(ALUResult),
    .funct3(funct3Control),
    .current_pc(PC),
    .instr(Instr),
    .csr_rdata(ResultCSR),
    .csr_wdata(RD1),
    .exception_en(exception_en),
    .csr_we(csr_we),
    .mret(mret),
    .flush(),
    .mepc(mepc),
    .mtvec(mtvec)
    );
    
    //output to control unit 
    assign Instr_OUT = Instr;
    assign PCSrc = ( (BranchFlag & Branch) | Jump ) ;
endmodule
