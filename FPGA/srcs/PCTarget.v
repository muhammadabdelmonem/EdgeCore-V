`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 03:11:38 PM
// Design Name: 
// Module Name: PCTarget
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


module PCTarget(
    input  [63:0] ImmExt ,
    input  [63:0] BaseTarget ,
    output [63:0]PCTarget
    );
    assign PCTarget = BaseTarget + ImmExt ;
endmodule
