`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 08:43:48 PM
// Design Name: 
// Module Name: Branch_State_Machine_tb
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


module Branch_State_Machine_tb();
    reg  [1:0]   Branch_State_E;
    reg  [63:0]  PC_TargetE,PCPlus4E;
    reg          JumpE, BranchE, Jalr, BranchTaken;
    wire [63:0]  Mispred_CorrectTarget;
    wire         Mispred_Sel;
    wire [1:0]   Branch_NextState;
    wire [1:0]   temp = Branch_NextState ;
    
    localparam [1:0] Strongly_Not_Taken =2'b00;
    localparam [1:0] Weakly_Not_Taken =2'b01;
    localparam [1:0] Weakly_Taken =2'b10;
    localparam [1:0] Strongly_Taken =2'b11;
    
    Branch_State_Machine uut(
    .Branch_State_E(Branch_State_E),
    .PC_TargetE(PC_TargetE),
    .PCPlus4E(PCPlus4E),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .Jalr(Jalr),
    .BranchTaken(BranchTaken),
    .Mispred_CorrectTarget(Mispred_CorrectTarget),
    .Mispred_Sel(Mispred_Sel),
    .Branch_NextState(Branch_NextState));
                         
initial begin

BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=Strongly_Taken;
BranchTaken=1'b0;PC_TargetE=64'hacd;PCPlus4E=64'hac;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=temp;
BranchTaken=1'b0;PC_TargetE = 64'h00000000ABCDEF12;PCPlus4E   = 64'h00000000FEDCBA98;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=temp;
BranchTaken=1'b0;PC_TargetE = 64'h1F2A3B4C5D6E7F80;PCPlus4E   = 64'h9A8B7C6D5E4F3A2B;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=temp;
BranchTaken=1'b1;PC_TargetE = 64'h0000000000001000;PCPlus4E   = 64'h0000000000001004;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=temp;
BranchTaken=1'b1;PC_TargetE = 64'h0000000000003FFC;PCPlus4E   = 64'h0000000000004000;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=temp;
BranchTaken=1'b1;PC_TargetE = 64'h7ABCDEF012345678;PCPlus4E   = 64'hFEDCBA9876543210;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=temp;
BranchTaken=1'b1;PC_TargetE = 64'h0A1B2C3D4E5F6071;PCPlus4E   = 64'hFFEEDDCCBBAA9988;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=Weakly_Taken;
BranchTaken=1'b1;PC_TargetE = 64'h1111222233334444;PCPlus4E   = 64'h5555666677778888;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b0;Branch_State_E=Weakly_Taken;
BranchTaken=1'b0;PC_TargetE = 64'hFFEEDDCCBBAA9988;PCPlus4E   = 64'hFFEEDD000AA9988;

#10
BranchE=1'b0; JumpE=1'b1; Jalr=1'b0;Branch_State_E=Weakly_Not_Taken;
BranchTaken=1'b0;PC_TargetE = 64'hFFEEDDCCBBAA9988;PCPlus4E   = 64'hFFEEDD000AA9988;

#10
BranchE=1'b0; JumpE=1'b1; Jalr=1'b0;Branch_State_E=Weakly_Taken;
BranchTaken=1'b0;PC_TargetE = 64'hFFEEDDCCBBAA9988;PCPlus4E   = 64'hFFEEDD000AA9988;

#10
BranchE=1'b0; JumpE=1'b1; Jalr=1'b1;Branch_State_E=Weakly_Taken;
BranchTaken=1'b0;PC_TargetE = 64'hFFEEDDCCBBAA9988;PCPlus4E   = 64'hFFEEDD000AA9988;

#10
BranchE=1'b1; JumpE=1'b0; Jalr=1'b1;Branch_State_E=Weakly_Taken;
BranchTaken=1'b0;PC_TargetE = 64'hFFEEDDCCBBAA9988;PCPlus4E   = 64'hFFEEDD000AA9988;
#10
$finish;

end

endmodule

