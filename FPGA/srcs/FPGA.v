`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/28/2025 05:37:23 PM
// Design Name: 
// Module Name: FPGA
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


module FPGA(
    input clk_in,
    input  btnC, 
    output ExcFlag,
    output [6:0] a_to_g,    
    output [7:0] an,       
    output dp 
    );
    //wire clk;
    wire [3:0] OutToBoard;
    wire reset_n;
    assign reset_n = ~btnC;
    
//    clk_wiz_0 ClkDivider
//  (
//  // Clock out ports  
//  .clk_out1(clk),
//  // Status and control signals               
//  .resetn(reset_n), 
//  //.locked(locked),
// // Clock in ports
//  .clk_in1(clk_in)
//  );
  
  Single_Cycle_TOP CPU(
    .clk(clk_in),
    .reset_n(reset_n),
    .OutToBoard(OutToBoard),
    .ExcFlag(ExcFlag)
    );
    
    
    reg [7:0] div;
reg [3:0] slow_Out;

always @(posedge clk_in or negedge reset_n) begin
    if (!reset_n)
        div <= 0;
    else
        div <= div + 1;
end

always @(posedge clk_in or negedge reset_n) begin
    if (!reset_n)
        slow_Out <= 0;
    else if (div == 40)   // pick a number to "sample" slower
        slow_Out <= OutToBoard;
end


    
    top seg7 (
    .reg4(slow_Out),
    .a_to_g(a_to_g),
    .an(an),
    .dp(dp)
    );
   
endmodule
