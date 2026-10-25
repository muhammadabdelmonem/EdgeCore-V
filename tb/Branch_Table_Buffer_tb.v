`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 08:57:56 PM
// Design Name: 
// Module Name: Branch_Table_Buffer_tb
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


module Branch_Table_Buffer_tb(
);
 reg          CLK;
 reg          reset_n;
 reg  [63:0]  PCF;  
 reg  [63:0]  PCE;
 reg          WE;
 reg  [63:0]  PC_Target_E;
 reg  [1:0]   Branch_N_State;
 wire         Hit;
 wire [1:0]   Branch_state;
 wire [63:0]  Predict_Target;
 localparam [1:0] Strongly_Not_Taken =2'b00;
 localparam [1:0] Weakly_Not_Taken =2'b01;
 localparam [1:0] Weakly_Taken =2'b10;
 localparam [1:0] Strongly_Taken =2'b11;
 Branch_Table_Buffer uut(.CLK(CLK),
                         .reset_n(reset_n),
                         .PCF(PCF),
                         .PCE(PCE),
                         .WE(WE),
                         .PC_Target_E(PC_Target_E),
                         .Branch_N_State(Branch_N_State),
                         .Hit(Hit),
                         .Branch_state(Branch_state),
                         .Predict_Target(Predict_Target));
 initial begin
 CLK=0;
 forever #2 CLK=~CLK;
 end
 initial begin
 reset_n=0;
 #10 reset_n=1;WE=1;Branch_N_State=Weakly_Not_Taken;
 PCF = 64'b101010000_000001_00;
 PCE = 64'b101010101_000000_00;
 PC_Target_E = 64'b0001000000100000001100000100000001010000011000000111000010000000;
 
 #10 reset_n=1;WE=1;Branch_N_State=Weakly_Not_Taken;
PCF = 64'b101010101_000000_00;
PCE = 64'b101011111_000010_00;
PC_Target_E = 64'b1111000011110000111100001111000011110000111100001111000011110000;
 
 #10 reset_n=1;WE=1;Branch_N_State=Weakly_Taken;
 PCF = 64'b101011101_000010_00;
 PCE = 64'b101010101_000011_00;
 PC_Target_E = 64'b0001000000100000001100000100000001010000011000000111000010000000;
 
 #10 reset_n=1;WE=1;Branch_N_State=Weakly_Taken;
 PCF = 64'b101010101_000011_00;
 PCE = 64'b111010101_000100_00;
 PC_Target_E = 64'b0000000000000000000000000000000000000000000000000001000000001000;
 
 #10 reset_n=1;WE=1;Branch_N_State=Strongly_Taken;
 PCF = 64'b111010101_000100_00;
 PCE = 64'b101010101_000101_00;
 PC_Target_E = 64'b0001001000110100010101100111100010011010101111001101111011110001;


#10 WE = 1; Branch_N_State = Strongly_Not_Taken;
PCF = 64'b101010101_111111_00;
PCE = 64'b100000001_000000_00;
PC_Target_E = 64'b1001100110011001100110011001100110011001100110011001100110011001;

#10 WE = 1; Branch_N_State = Weakly_Taken;
PCF = 64'b100000001_000000_00;
PCE = 64'b101010101_100010_00;
PC_Target_E = 64'b0000000000000000000000000000000000000000000100000000000000001000;

#10 $finish;
 end
 
endmodule


