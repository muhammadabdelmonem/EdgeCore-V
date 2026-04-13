`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 07:34:22 PM
// Design Name: 
// Module Name: WRITEBACK_UNIT
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


module WRITEBACK_UNIT(
    // Clock
input CLK,

// Data Unit Inputs / Outputs
input  [63:0] Result_IcuM, RD, PCPlus4M, ResultCSR_M,
input  [11:7]  RdM,
input csr_flagM, 
output reg [63:0] Result_IcuW, ReadDataW, PCPlus4W, ResultCSR_W,
output reg [11:7]  RdW,
output reg csr_flagW, 
// Control Unit Inputs / Outputs
input        RegWriteM,
input  [1:0] ResultSrcM,
output reg        RegWriteW,
output reg [1:0]  ResultSrcW,

input EN,
input CLR

    );
    
    always @(posedge CLK)
        if (CLR) begin
            RegWriteW <= 0;
            csr_flagW <= 0;
        begin
        if(EN) begin
            PCPlus4W <= PCPlus4M;
            Result_IcuW <= Result_IcuM;
            ReadDataW <= RD;
            RegWriteW <= RegWriteM;
            RdW <= RdM;
            ResultSrcW <= ResultSrcM;
            ResultCSR_W <= ResultCSR_M;
            csr_flagW <= csr_flagM;
        end
        end
        end
    
endmodule
