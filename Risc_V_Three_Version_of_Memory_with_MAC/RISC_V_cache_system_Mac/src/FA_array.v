`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2026 09:11:09 PM
// Design Name: 
// Module Name: FA_array
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


module FA_array#(
    parameter WIDTH = 4
)(
input  [WIDTH:0] in1, in2, C_in,
output [WIDTH:0]  S_out, C_out
    );
    
        genvar i;

    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : FA_GEN
        Full_adder FA1 (
            .A(in1[i]),
            .B(in2[i]),
            .CIN(C_in[i]),
            .COUT(C_out[i]),
            .S(S_out[i])
         );
         end
         endgenerate 
endmodule
