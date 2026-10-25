`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/22/2025 03:19:39 PM
// Design Name: 
// Module Name: top
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


module top(
    input  wire [3:0] reg4,       // 4-bit input (switches)
    output wire [6:0] a_to_g,     // 7-segment outputs
    output wire [7:0] an,         // anodes
    output wire dp                // decimal point
    );
    
     // Enable all digits (active low on Nexys)
    assign an = 8'b11111110;

    // Turn decimal point off
    assign dp = 1'b1;

    // Instantiate hex to 7-seg decoder
    hex2seg D1 (
        .x(reg4),
        .a_to_g(a_to_g)
    );

endmodule
