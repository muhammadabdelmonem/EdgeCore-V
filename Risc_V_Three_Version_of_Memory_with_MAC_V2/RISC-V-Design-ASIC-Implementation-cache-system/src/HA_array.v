`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/29/2026 02:49:19 PM
// Design Name: 
// Module Name: HA_array
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


module HA_array
#(
    parameter WIDTH = 4
)(
input  [WIDTH:0] in1,in2,
output [WIDTH:0]  S_out,C_out
    );
    
        genvar i;

    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : HA_GEN
            Half_adder HA (
                .A(in1[i]),
                .B(in2[i]),
                .S(S_out[i]),
                .COUT(C_out[i])
            );
        end
    endgenerate
                  
endmodule
