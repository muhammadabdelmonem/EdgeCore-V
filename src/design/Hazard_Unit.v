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
    output  FlushD, FlushE,
    output  [1:0] ForwardAE, ForwardBE,
    output  StallD, StallF
);

    wire lwStall;

    Control_Hazard control_hazard(
    .Mispred(Mispred),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .lwStall(lwStall),
    .reset_n(reset_n)
    );
    
    Stalling_Unit stalling_unit(
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .RdE(RdE),
    .ResultSrcE0(ResultSrc),
    .StallF(StallF),
    .StallD(StallD),
    .lwStall(lwStall),
    .reset_n(reset_n)
    );
    
    Forwarding_Unit forwarding_unit(
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdM(RdM),
    .RdW(RdW),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .reset_n(reset_n)
    );

endmodule
