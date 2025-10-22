`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 03:32:05 AM
// Design Name: 
// Module Name: Hazard_unit_tb
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


module Hazard_unit_tb();

    reg RegWriteW, RegWriteM;
    reg [1:0] ResultSrc;
    reg [4:0] RdW, RdM;
    reg [4:0] Rs1E, Rs2E, RdE, Rs1D, Rs2D;
    reg PCSrcE,CLK;

    wire FlushD, FlushE;
    wire [1:0] ForwardAE, ForwardBE;
    wire StallD, StallF;

    Hazard_Unit uut (
        .RegWriteW(RegWriteW),
        .RegWriteM(RegWriteM),
        .ResultSrc(ResultSrc),
        .RdW(RdW),
        .RdM(RdM),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .PCSrcE(PCSrcE),
        .FlushD(FlushD),
        .FlushE(FlushE),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .StallD(StallD),
        .StallF(StallF)
    );
initial begin
       CLK=1;
       forever #2 CLK=~CLK;
    end
//    initial begin
//       RegWriteM=1;Rs1E=5'bb01010;Rs2E=5'bb00010;RdM=5'bb01010;
//       #5 RegWriteM=1;Rs1E=5'bb01010;Rs2E=5'bb00010;RdM=5'bb01010;
//    end
initial begin
        // Initialize all signals
        RegWriteM = 0; RegWriteW = 0;
        Rs1E = 0; Rs2E = 0; RdM = 0; RdW = 0; RdE = 0;
        Rs1D = 0; Rs2D = 0;
        ResultSrc = 2'b00;
        PCSrcE = 0;

        #5; // wait 5 ns

        // ---- Test 1: Forwarding from MEM stage ----
        RegWriteM = 1; RegWriteW = 0;
        Rs1E = 5'b01010; Rs2E = 5'b00010; RdM = 5'b01010;
        #5;

        // ---- Test 2: Forwarding from WB stage ----
        RegWriteM = 0; RegWriteW = 1;
        Rs1E = 5'b01100; Rs2E = 5'b01100; RdW = 5'b01100;
        #5;

        // ---- Test 3: No forwarding needed ----
        RegWriteM = 0; RegWriteW = 0;
        Rs1E = 5'b00100; Rs2E = 5'b01000;
        #5;

        // ---- Test 4: Load-use hazard (stall expected) ----
        ResultSrc = 2'b01;  // Indicates load in EX stage
        RdE = 5'b00101;
        Rs1D = 5'b00101; Rs2D = 5'b01010;
        #5;

        // ---- Test 5: Branch taken (flush expected) ----
        PCSrcE = 1;  // Branch taken
        #5;
        PCSrcE = 0;

        // ---- Test 6: Combined check ----
        RegWriteM = 1; RegWriteW = 1;
        RdM = 5'b00010; RdW = 5'b00110;
        Rs1E = 5'b00010; Rs2E = 5'b00110;
        ResultSrc = 2'b00;
        #5;
        
        // Test 7
        PCSrcE = 1;
        ResultSrc = 0;
        #5
        
        // Test 8
        PCSrcE = 0;
        ResultSrc = 1;
        #5
        
        // Finish simulation
        $display("Simulation completed");
        $stop;
    end

endmodule

