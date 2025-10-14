`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2025 03:16:03 PM
// Design Name: 
// Module Name: CLA_4bit
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


module CLA_4bit(
    input  [3:0] a,
    input  [3:0] b,
    input  cin,
    output [3:0]sum,
    output cout,
    output Gg,  // group generate
    output Pg   // group propagate
    );
    
    wire [3:0] G, P, C;

    assign G = a & b;    // bit generate
    assign P = a ^ b;    // bit propagate

    // carry lookahead inside 4 bits
    assign C[0] = cin;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) 
                | (P[2] & P[1] & P[0] & C[0]);
    assign cout = G[3] | (P[3] & G[2]) 
                | (P[3] & P[2] & G[1]) 
                | (P[3] & P[2] & P[1] & G[0]) 
                | (P[3] & P[2] & P[1] & P[0] & C[0]);

    // group generate & propagate
    assign Gg = cout;
    assign Pg = &P;   // propagate if all bits propagate

    // final sum
    assign sum = P ^ C;
endmodule
