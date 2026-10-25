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

    // ========================================
    // AXI3 Master Interface 
    // ========================================
    // AXI3 Write Address Channel
    output wire [64-1:0]                CACHE_AXI_AWADDR,
    output wire [3:0]                   CACHE_AXI_AWLEN,     // AXI3: 4 bits
    output wire [2:0]                   CACHE_AXI_AWSIZE,
    output wire [1:0]                   CACHE_AXI_AWBURST,
    output wire [1:0]                   CACHE_AXI_AWLOCK,    // AXI3: 2 bits
    output wire [3:0]                   CACHE_AXI_AWCACHE,
    output wire [2:0]                   CACHE_AXI_AWPROT,
    output wire                         CACHE_AXI_AWVALID,
    input  wire                         CACHE_AXI_AWREADY,
    
    // AXI3 Write Data Channel (WID removed - in-order writes only)
    output wire [128-1:0]               CACHE_AXI_WDATA,
    output wire [128/8-1:0]             CACHE_AXI_WSTRB,
    output wire                         CACHE_AXI_WLAST,
    output wire                         CACHE_AXI_WVALID,
    input wire                          CACHE_AXI_WREADY,
    
    // AXI3 Write Response Channel
    input wire  [1:0]                   CACHE_AXI_BRESP,
    input wire                          CACHE_AXI_BVALID,
    output wire                         CACHE_AXI_BREADY,
    
    // AXI3 Read Address Channel
    output wire [64-1:0]                CACHE_AXI_ARADDR,
    output wire [3:0]                   CACHE_AXI_ARLEN,     // AXI3: 4 bits
    output wire [2:0]                   CACHE_AXI_ARSIZE,
    output wire [1:0]                   CACHE_AXI_ARBURST,
    output wire [1:0]                   CACHE_AXI_ARLOCK,    // AXI3: 2 bits
    output wire [3:0]                   CACHE_AXI_ARCACHE,
    output wire [2:0]                   CACHE_AXI_ARPROT,
    output wire                         CACHE_AXI_ARVALID,
    input  wire                         CACHE_AXI_ARREADY,
    
    // AXI3 Read Data Channel
    input wire  [128-1:0]               CACHE_AXI_RDATA,
    input wire  [1:0]                   CACHE_AXI_RRESP,
    input wire                          CACHE_AXI_RLAST,
    input wire                          CACHE_AXI_RVALID,
    output wire                         CACHE_AXI_RREADY
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
    
    // AXI3 Master Interface 
        .CACHE_AXI_AWADDR(CACHE_AXI_AWADDR),
        .CACHE_AXI_AWLEN(CACHE_AXI_AWLEN),
        .CACHE_AXI_AWSIZE(CACHE_AXI_AWSIZE),
        .CACHE_AXI_AWBURST(CACHE_AXI_AWBURST),
        .CACHE_AXI_AWLOCK(CACHE_AXI_AWLOCK),
        .CACHE_AXI_AWCACHE(CACHE_AXI_AWCACHE),
        .CACHE_AXI_AWPROT(CACHE_AXI_AWPROT),
        .CACHE_AXI_AWVALID(CACHE_AXI_AWVALID),
        .CACHE_AXI_AWREADY(CACHE_AXI_AWREADY),
        
        .CACHE_AXI_WDATA(CACHE_AXI_WDATA),
        .CACHE_AXI_WSTRB(CACHE_AXI_WSTRB),
        .CACHE_AXI_WLAST(CACHE_AXI_WLAST),
        .CACHE_AXI_WVALID(CACHE_AXI_WVALID),
        .CACHE_AXI_WREADY(CACHE_AXI_WREADY),
        
        .CACHE_AXI_BRESP(CACHE_AXI_BRESP),
        .CACHE_AXI_BVALID(CACHE_AXI_BVALID),
        .CACHE_AXI_BREADY(CACHE_AXI_BREADY),
        
        .CACHE_AXI_ARADDR(CACHE_AXI_ARADDR),
        .CACHE_AXI_ARLEN(CACHE_AXI_ARLEN),
        .CACHE_AXI_ARSIZE(CACHE_AXI_ARSIZE),
        .CACHE_AXI_ARBURST(CACHE_AXI_ARBURST),
        .CACHE_AXI_ARLOCK(CACHE_AXI_ARLOCK),
        .CACHE_AXI_ARCACHE(CACHE_AXI_ARCACHE),
        .CACHE_AXI_ARPROT(CACHE_AXI_ARPROT),
        .CACHE_AXI_ARVALID(CACHE_AXI_ARVALID),
        .CACHE_AXI_ARREADY(CACHE_AXI_ARREADY),
        
        .CACHE_AXI_RDATA(CACHE_AXI_RDATA),
        .CACHE_AXI_RRESP(CACHE_AXI_RRESP),
        .CACHE_AXI_RLAST(CACHE_AXI_RLAST),
        .CACHE_AXI_RVALID(CACHE_AXI_RVALID),
        .CACHE_AXI_RREADY(CACHE_AXI_RREADY)
    
    );
    
endmodule
