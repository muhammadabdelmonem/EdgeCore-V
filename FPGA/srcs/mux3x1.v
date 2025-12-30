`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 08:03:45 PM
// Design Name: 
// Module Name: mux3x1
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


module mux3x1(
    input  [1:0] sel,
    input  [63:0] in1,
    input  [63:0] in2,
    input  [63:0] in3,
    output [63:0] out
    );
    reg [63:0]out_reg ;
    always @(*) begin
        case(sel)
            2'b00: out_reg = in1;
            2'b01: out_reg = in2;
            2'b10: out_reg = in3;
            default: out_reg = 64'b0; 
        endcase
    end
    assign out = out_reg ;
endmodule
