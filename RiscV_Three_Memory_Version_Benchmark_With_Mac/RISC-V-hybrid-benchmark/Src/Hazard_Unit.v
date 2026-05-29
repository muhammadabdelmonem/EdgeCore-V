`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 12:06:49 AM
// Design Name: 
// Module Name: Hazard_Unit
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


module Hazard_Unit(
    input RegWriteW, RegWriteM,
    input ResultSrc,
    input reset_n,
    input [4:0] RdW, RdM,
    input [4:0] Rs1E, Rs2E, RdE, Rs1D, Rs2D,
    input   Mispred,
    input exceptionF, exceptionD, exceptionE, exceptionM ,
    input mret_Flush,
    // ICU stall signals
    input ICU_Valid,
    input [1:0] Function_SelD,
    input icache_stall_F,
    input dcache_stall_M,
    
    input dma_lw_stall,
    
    output  FlushF, FlushD, FlushE, FlushM,
    output  [1:0] ForwardAE, ForwardBE, ForwardCE,
    output  StallD, StallF, StallE , StallM , StallW
);

    wire lwStall;

    Control_Hazard control_hazard(
    .Mispred(Mispred),
    .FlushF(FlushF),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .FlushM(FlushM),
    .lwStall(lwStall),
    .reset_n(reset_n),
    
    .dma_lw_stall(dma_lw_stall),
    .dcache_stall_M(dcache_stall_M),
    
    .mret_Flush(mret_Flush),
    .exceptionF(exceptionF),
    .exceptionD(exceptionD),
    .exceptionE(exceptionE),
    .exceptionM(exceptionM)
    );
    
    Stalling_Unit stalling_unit(
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .RdE(RdE),
    .ResultSrcE0(ResultSrc),
    .ICU_Valid(ICU_Valid),
    .Function_SelD(Function_SelD),
    .icache_stall_F(icache_stall_F),
    .dcache_stall_M(dcache_stall_M),
    .StallF(StallF),
    .StallD(StallD),
    .StallE(StallE),
    .StallM(StallM),
    .StallW(StallW),
    .lwStall(lwStall),
    .reset_n(reset_n),
    
    .dma_lw_stall(dma_lw_stall)
    );
    
     Forwarding_Unit forwarding_unit(
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .ForwardCE(ForwardCE),
    .reset_n(reset_n)
    );

endmodule
