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
    // AXI3 Master Interface (In-order only, no IDs)
    // ========================================
    // AXI3 Write Address Channel
    output wire [64-1:0]                M_AXI_AWADDR,
    output wire [3:0]                   M_AXI_AWLEN,     // AXI3: 4 bits
    output wire [2:0]                   M_AXI_AWSIZE,
    output wire [1:0]                   M_AXI_AWBURST,
    output wire                         M_AXI_AWVALID,
    input wire                          M_AXI_AWREADY,
    
    // AXI3 Write Data Channel (WID removed - in-order writes only)
    output wire [128-1:0]               M_AXI_WDATA,
    output wire [128/8-1:0]             M_AXI_WSTRB,
    output wire                         M_AXI_WLAST,
    output wire                         M_AXI_WVALID,
    input wire                          M_AXI_WREADY,
    
    // AXI3 Write Response Channel
    input wire  [1:0]                   M_AXI_BRESP,
    input wire                          M_AXI_BVALID,
    output wire                         M_AXI_BREADY,
    
    // AXI3 Read Address Channel
    output wire [64-1:0]                M_AXI_ARADDR,
    output wire [3:0]                   M_AXI_ARLEN,     // AXI3: 4 bits
    output wire [2:0]                   M_AXI_ARSIZE,
    output wire [1:0]                   M_AXI_ARBURST,
    output wire                         M_AXI_ARVALID,
    input wire                          M_AXI_ARREADY,
    
    // AXI3 Read Data Channel
    input wire  [128-1:0]               M_AXI_RDATA,
    input wire  [1:0]                   M_AXI_RRESP,
    input wire                          M_AXI_RLAST,
    input wire                          M_AXI_RVALID,
    output wire                         M_AXI_RREADY
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
    wire MAC_Sel;
    wire [1:0] Mode;
    wire Signed_en;
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
//  .BranchFlag(BranchFlagD),
    .Jump(Jump),
    .Mul_Control(Mul_Control),
    .Div_Control(Div_Control),
    .Function_Sel(Function_Sel),
    .Flag(Flag),
    .MAC_Sel(MAC_Sel),
    .Mode(Mode),
    .Signed_en(Signed_en),
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
    .MAC_SelD(MAC_Sel),
    .ModeD(Mode),
    .Signed_enD(Signed_en),
//  .BranchFlagD(BranchFlagD)
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .csr_we(csr_we),

       // AXI3 Write Address Channel
    .M_AXI_AWADDR        (M_AXI_AWADDR),
    .M_AXI_AWLEN         (M_AXI_AWLEN),
    .M_AXI_AWSIZE        (M_AXI_AWSIZE),
    .M_AXI_AWBURST       (M_AXI_AWBURST),
    .M_AXI_AWVALID       (M_AXI_AWVALID),
    .M_AXI_AWREADY       (M_AXI_AWREADY),

    // AXI3 Write Data Channel
    .M_AXI_WDATA         (M_AXI_WDATA),
    .M_AXI_WSTRB         (M_AXI_WSTRB),
    .M_AXI_WLAST         (M_AXI_WLAST),
    .M_AXI_WVALID        (M_AXI_WVALID),
    .M_AXI_WREADY        (M_AXI_WREADY),

    // AXI3 Write Response Channel
    .M_AXI_BRESP         (M_AXI_BRESP),
    .M_AXI_BVALID        (M_AXI_BVALID),
    .M_AXI_BREADY        (M_AXI_BREADY),

        

    // AXI3 Read Address Channel
    .M_AXI_ARADDR        (M_AXI_ARADDR),
    .M_AXI_ARLEN         (M_AXI_ARLEN),
    .M_AXI_ARSIZE        (M_AXI_ARSIZE),
    .M_AXI_ARBURST       (M_AXI_ARBURST),
    .M_AXI_ARVALID       (M_AXI_ARVALID),
    .M_AXI_ARREADY       (M_AXI_ARREADY),

    // AXI3 Read Data Channel
    .M_AXI_RDATA         (M_AXI_RDATA),
    .M_AXI_RRESP         (M_AXI_RRESP),
    .M_AXI_RLAST         (M_AXI_RLAST),
    .M_AXI_RVALID        (M_AXI_RVALID),
    .M_AXI_RREADY        (M_AXI_RREADY)
    
    );
    
endmodule
