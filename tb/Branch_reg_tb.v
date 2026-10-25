`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 09:00:01 PM
// Design Name: 
// Module Name: Branch_reg_tb
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


module Branch_reg_tb();
reg CLK;
reg [1:0] BranchState;
wire [1:0] Branch_State_E;
Branch_reg uut(.CLK(CLK),
               .BranchState(BranchState),
               .Branch_State_E(Branch_State_E));
initial begin
CLK=0;
forever #2 CLK=~CLK;
end
initial begin
#2
BranchState=2'b00;
#4 BranchState=2'b01;
#4 BranchState=2'b10;
#4 BranchState=2'b11;
#4 BranchState=2'b00;
#4 $finish;

end
endmodule

