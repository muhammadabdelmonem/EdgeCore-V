`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2025 11:14:11 PM
// Design Name: 
// Module Name: SPM
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


module SPM(
    input  clk,
    input  we,
    input re,
    input  [63:0] spm_addr,
    input  [63:0] wdata,
    output reg [63:0] rdata
    );
    reg [63:0] ScratchPadMem [0:1023];   // example: 8KB SPM

    always @(posedge clk) 
    begin
        if (we)
         ScratchPadMem[spm_addr] <= wdata;
        else if(re)
         rdata <= ScratchPadMem[spm_addr];
    end

endmodule

