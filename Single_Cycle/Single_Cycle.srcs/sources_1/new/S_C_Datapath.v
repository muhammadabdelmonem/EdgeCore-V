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
    input PCSrc ,
    input MemWrite ,
    input RegWrite ,
    input [1:0]ResultSrc ,
    input ALUSrc ,
    input [3:0]ALUControl ,
    input [1:0]ImmSrc ,
    
    output [31:0] Instr_OUT ,
    output Zero_Out
    );
    
    //PC WIRES
    wire [63:0]PCPlus4 ;
    wire [63:0]PCTarget ;
    wire [63:0]PCNext ;
    wire [63:0]PC ;
    
    //EXTEND WIRE
    wire [63:0]ImmExt ;
    
    //IM WIRE
    wire [31:0]Instr ;
    
    //RFWIRES
    wire [63:0]RD1;
    wire [63:0]RD2;
    wire [63:0]Result ;
    
    //ALU WIRES
    wire [63:0]SrcA ;
    assign SrcA = RD1 ;
    wire [63:0]SrcB ;
    wire [63:0]ALUResult ;
    wire Zero ;
    
    //DM WIRES
    wire [63:0]WriteData ;
    assign WriteData = RD2 ;
    wire [63:0]ReadData ;
    
    
    PCPlus4 PC_PLUS4_UNIT(
    .PC(PC) ,
    .PCPlus4(PCPlus4)
    );
    
    PCTarget PC_TARGET_UNIT(
    .ImmExt(ImmExt) ,
    .PC(PC) ,
    .PCTarget(PCTarget)
    );
    
    mux2x1 PC_MUX_UNIT(
    .sel(PCSrc) ,
    .in1(PCPlus4) ,
    .in2(PCTarget) ,
    .out(PCNext)
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
    
    mux2x1 ALU_MUX_UNIT(
    .sel(ALUSrc) ,
    .in1(RD2) ,
    .in2(ImmExt) ,
    .out(SrcB)
    );
    
    ALU ALU_UNIT(
    .SrcA(SrcA) ,
    .SrcB(SrcB) ,
    .ALUControl(ALUControl) ,
    .ALUResult(ALUResult) ,
    .Zero(Zero)
    );
    
    Data_Memory DM_UNIT(
    .clk(clk), 
    .WE(MemWrite) ,
    .A(ALUResult) , //address of inistructoin
    .WD(WriteData) ,
    .RD(ReadData) 
    );
    
    mux3x1 RESULT_MUX_UNIT(
    .sel(ResultSrc) ,
    .in1(ALUResult) ,
    .in2(ReadData) ,
    .in3(PCPlus4) ,
    .out(Result)
    );
    
    //output to control unit 
    assign Instr_OUT = Instr ;
    assign Zero_Out = Zero ;
endmodule
