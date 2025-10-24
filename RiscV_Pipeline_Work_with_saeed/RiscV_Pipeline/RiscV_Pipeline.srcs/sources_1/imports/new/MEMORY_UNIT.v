`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 07:21:41 PM
// Design Name: 
// Module Name: MEMORY_UNIT
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


module Memory_Register(
    // Clock
input CLK,

// Data Inputs / Outputs
input  [63:0] ALUResultE, WriteDataE, PCPlus4E,
input  [11:7]  RdE,
output reg [63:0] ALUResultM, WriteDataM, PCPlus4M,
output reg [11:7]  RdM,

// Control Inputs / Outputs
input        RegWriteE,
input  [1:0] ResultSrcE,
input        MemWriteE,
input  [2:0]      funct3ControlE,
output reg        RegWriteM,
output reg [1:0]  ResultSrcM,
output reg        MemWriteM,
output reg [2:0] funct3ControlM

    );
   
    always @(posedge CLK)
        begin
            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            RdM <= RdE;
            PCPlus4M <= PCPlus4E;
            RegWriteM <= RegWriteE;
            ResultSrcM <= ResultSrcE;
            MemWriteM <= MemWriteE;
            funct3ControlM <= funct3ControlE;
        end
endmodule
