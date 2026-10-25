`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 12:45:16 AM
// Design Name: 
// Module Name: Branch_prediction
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


module Branch_Prediction_Top(
    input Clk , reset_n,
    input BranchE, JumpE,TargetE,BranchTaken,
    input [63:0] PCF, PCE, PCPlus4E,PC_targetE,
    output Mispred_Sel,Predict_Sel,
    output [63:0] Predict_Target, Mispred_CorrectTarget
    );
    
    
    wire WE;
    wire Hit;
    wire [1:0] Branch_N_State;
    wire [1:0] Branch_state;
    wire [1:0] Branch_State_E;
    
    Branch_Table_Buffer BTB_UNIT(
    .CLK(Clk),
    .reset_n(reset_n),
    .PCF(PCF),
    .PCE(PCE),
    .WE(WE),
    .PC_Target_E(PC_targetE),
    .Branch_N_State(Branch_N_State),
    .Hit(Hit),
    .Branch_state(Branch_state),
    .Predict_Target(Predict_Target)  
    );

    
    Branch_reg BR_UNIT(
    .CLK(Clk),
    .BranchState(Branch_state),
    .Branch_State_E(Branch_State_E)
    );
    
    Branch_State_Machine BSM_UNIT(
    .Branch_State_E(Branch_State_E),
    .PC_TargetE(PC_targetE),
    .PCPlus4E(PCPlus4E),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .Jalr(~TargetE),
    .BranchTaken(BranchTaken),
    .Mispred_CorrectTarget(Mispred_CorrectTarget),
    .Mispred_Sel(Mispred_Sel),
    .Branch_NextState(Branch_N_State)
    );
    
    assign WE = ((JumpE & TargetE) | BranchE);
    assign Predict_Sel = (Hit & Branch_state[1]);
endmodule