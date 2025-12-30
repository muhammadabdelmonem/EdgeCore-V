`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 12:28:08 PM
// Design Name: 
// Module Name: PC
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


module PC(
    input clk,
    input reset_n,
    input [63:0] PCNext,
    output [63:0] PC,
    input EN,
    input CLR
    );
    
    reg [63:0] pc_reg;
    
//    assign EN = 0;
    
    always@(posedge clk, negedge reset_n)
    
    begin
        if(~reset_n)
            pc_reg <= 0;
        else if (CLR)
            begin
            pc_reg <= 64'b0;
            end 
        else if (EN)
            begin
            pc_reg <= PCNext;
            end
    end
    assign PC = pc_reg ;
endmodule
