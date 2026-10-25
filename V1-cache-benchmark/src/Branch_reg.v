`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 08:24:41 PM
// Design Name: 
// Module Name: Branch_reg
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


module Branch_reg(
    input CLK,
    input [1:0] BranchState,
    output reg [1:0] Branch_State_E
    );
    reg [1:0] BranchState_1;
    always@(posedge CLK) begin
    BranchState_1 <= BranchState ;
    Branch_State_E <= BranchState_1;
    end
endmodule

