`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 09:02:16 PM
// Design Name: 
// Module Name: Branch_Prediction_Top_tb
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


module Branch_Prediction_Top_tb();
reg Clk , reset_n;
    reg BranchE, JumpE, TargetE, BranchTaken;
    reg [63:0] PCF, PCE, PCPlus4E, PC_targetE;
    wire Mispred_Sel, Predict_Sel;
    wire [63:0] Predict_Target, Mispred_CorrectTarget;

    // Instantiate the Unit Under Test (UUT)
    Branch_Prediction_Top uut (
        .Clk(Clk),
        .reset_n(reset_n),   
        .BranchE(BranchE), 
        .JumpE(JumpE),
        .TargetE(TargetE), 
        .BranchTaken(BranchTaken),
        .PCF(PCF),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .PC_targetE(PC_targetE),
        .Mispred_Sel(Mispred_Sel),
        .Predict_Sel(Predict_Sel),
        .Predict_Target(Predict_Target),
        .Mispred_CorrectTarget(Mispred_CorrectTarget)
    );
    localparam [1:0] Strongly_Not_Taken =2'b00;
    localparam [1:0] Weakly_Not_Taken =2'b01;
    localparam [1:0] Weakly_Taken =2'b10;
    localparam [1:0] Strongly_Taken =2'b11;

    // Clock Generation: period = 4ns
    initial begin
        Clk = 0;
        forever #2 Clk = ~Clk;
    end

    // Reset and test sequence
    initial begin
        // ====== INITIAL STATE ======
        reset_n = 0;
        BranchE = 0; JumpE = 0; TargetE = 0; BranchTaken = 0;
        PCF = 0; PCE = 0; PCPlus4E = 0; PC_targetE = 0;

        // ====== RELEASE RESET ======
        #20; // 20ns passed (≈5 clock cycles)
        reset_n = 1;
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1; BranchTaken = 1'b0;//Strongly_Not_Taken
        PCF = 64'b000000110_100000_00;
        PCE = 64'b000000001_000000_00;
        PC_targetE = 64'b0001000000100000001100000100000001010000011000000111000010000001;
        PCPlus4E   = 64'b0001000000100000001100000100111101010000011000000111000010000000;

        // ====== TEST CASE 1 ======
        #20; // t = 40ns, 10 clock cycles
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1; BranchTaken = 1'b1;//Weakly_Not_Taken
        PCF = 64'b000000001_000000_00;
        PCE = 64'b000000010_000001_00;
        PC_targetE = 64'b1111000011110000111100001111000011110000111100001111000011110000;
        PCPlus4E   = 64'b1111000000100000001100000100111101010000011000000111000010000000;

        // ====== TEST CASE 2 ======
        #20; // t = 60ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1; BranchTaken = 1'b1;//Weakly_Taken
        PCF = 64'b000000010_000001_00;
        PCE = 64'b000000011_000010_00;
        PC_targetE = 64'b0001000000100000001100000100000001010000011000000111000010000000;
        PCPlus4E   = 64'b0001000000100000001100000100111101010000011000000111000010001111;

        // ====== TEST CASE 3 ======
        #20; // t = 80ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1;  BranchTaken = 1'b1;//Strongly_Taken
        PCF = 64'b000000011_000010_00;
        PCE = 64'b000000100_000011_00;
        PC_targetE = 64'b0000000000000000000000000000000000000000000000000001000000001000;
        PCPlus4E   = 64'b0001000000100000001100000100111101010101111000000111000010001111;

        // ====== TEST CASE 4 ======
        #20; // t = 100ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1; BranchTaken = 1'b1;//Strongly_Taken
        PCF = 64'b000000100_000011_00;
        PCE = 64'b000000001_000000_00;
        PC_targetE = 64'b0001000000100000001100000100000001010000011000000111000010000001;
        PCPlus4E   = 64'b0001000000100000001100000100111101010000011000000111000010000000;

        // ====== TEST CASE 5 ======
        #20; // t = 120ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1; BranchTaken = 1'b0; //Weakly_Taken 
        PCF = 64'b000000001_000000_00;
        PCE = 64'b000000010_000001_00;
        PC_targetE = 64'b1111000011110000111100001111000011110000111100001111000011110000;
        PCPlus4E   = 64'b1111000000100000001100000100111101010000011000000111000010000000;

        // ====== TEST CASE 6 ======
        #20; // t = 140ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1;  BranchTaken = 1'b0;//Weakly_Not_Taken 
        PCF = 64'b000000010_000001_00;
        PCE = 64'b000000011_000010_00;
        PC_targetE = 64'b0001000000100000001100000100000001010000011000000111000010000000;
        PCPlus4E   = 64'b0001000000100000001100000100111101010000011000000111000010001111;

        // ====== TEST CASE 7 ======
        #20; // t = 160ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1;  BranchTaken = 1'b1;//Weakly_Taken 
        PCF = 64'b000000011_000010_00;
        PCE = 64'b000000100_000011_00;
        PC_targetE = 64'b0000000000000000000000000000000000000000000000000001000000001000;
        PCPlus4E   = 64'b0001000000100000001100000100111101010101111000000111000010001111;

        // ====== TEST CASE 8 (Jump) ======
        #20; // t = 180ns
        BranchE = 1'b0; JumpE = 1'b1; TargetE = 1'b1;  BranchTaken = 1'b0;//Strongly_Taken 
        PCF = 64'b000000001_111000_00;
        PCE = 64'b000000101_000100_00;
        PC_targetE = 64'b0001001000110100010101100111100010011010101111001101111011110001;
        PCPlus4E   = 64'b0001000000100000001100101010111101010101111000000111000010001111;

        // ====== TEST CASE 9 (Jump continues) ======
        #20; // t = 200ns
        BranchE = 1'b0; JumpE = 1'b1; TargetE = 1'b1; BranchTaken = 1'b0;
        PCF = 64'b000000001_000000_00;
        PCE = 64'b100000001_001000_00;
        PC_targetE = 64'b1001100110011001100110011001100110011001100110011001100110011001;
        PCPlus4E   = 64'b0001001100100000001100000100111101010101111000000111000010001111;

        // ====== TEST CASE 10 ======
        #20; // t = 220ns
        BranchE = 1'b0; JumpE = 1'b1; TargetE = 1'b0;  BranchTaken = 1'b0;
        PCF = 64'b100000001_111111_00;
        PCE = 64'b100000001_001001_00;
        PC_targetE = 64'b0000000000000000000000000000000000000000000100000000000000001000;
        #20; // t = 240ns
         reset_n = 1;
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b1; BranchTaken = 1'b1;
        PCF = 64'b000000110_101010_00;
        PCE = 64'b000000001_000000_00;
        PC_targetE = 64'b0001000000100000001100000100000001010000011000000111000010000001;
        PCPlus4E   = 64'b0001000000100000001100000100111101010000011000000111000010000000;

        // ====== TEST CASE 11 ======
        #20; // t = 260ns
        BranchE = 1'b1; JumpE = 1'b0; TargetE = 1'b0;//default
        PCF = 64'b100000001_100001_00;
        PCE = 64'b100000001_001001_00;
        PC_targetE = 64'b0000000000000000000000000000000000000000000100000000000000001000;

        #20; // t = 260ns
        $finish;
    end
endmodule

