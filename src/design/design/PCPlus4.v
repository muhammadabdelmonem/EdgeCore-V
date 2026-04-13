`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 03:10:07 PM
// Design Name: 
// Module Name: PCPlus4
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


module PCPlus4(
    input  [63:0] PC ,
    output [63:0]PCPlus4
    );
    assign PCPlus4 = PC + 63'd4 ;
endmodule
