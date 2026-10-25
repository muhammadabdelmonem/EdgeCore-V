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
input reset_n,
// Data Inputs / Outputs
input  [63:0] Result_IcuE, WriteDataE, PCPlus4E, ResultCSR_E,
input  [11:7]  RdE,
input csr_flagE,
output reg [63:0] Result_IcuM, WriteDataM, PCPlus4M, ResultCSR_M,
output reg [11:7]  RdM,
output reg csr_flagM, 
// Control Inputs / Outputs
input        RegWriteE,
input  [1:0] ResultSrcE,
input        MemWriteE,
input        MemReadE,
input  [63:0] PCE,
input  [2:0]      funct3ControlE,

input dma_read_stall,
//input [1:0] TargetMemE,
//output reg [1:0] TargetMemM,

output reg        RegWriteM,
output reg [1:0]  ResultSrcM,
output reg        MemWriteM,
output reg        MemReadM,
output reg [2:0] funct3ControlM,
output reg [63:0] PCM,

input CLR , EN

    );
   
    always @(posedge CLK, negedge reset_n)
        begin
            
        if(~reset_n) begin 
            Result_IcuM <= 0;
            WriteDataM <= 0;
            RdM <= 0;
            PCPlus4M <= 0;
            RegWriteM <= 0;
            ResultSrcM <= 0;
            MemWriteM <= 0;
            MemReadM <= 0;
            funct3ControlM <= 0;
            ResultCSR_M <= 0;
            csr_flagM <= 0;
            PCM <= 0;
            
//            TargetMemM <= 0;
        end
        else if(CLR)begin
            Result_IcuM <= 0;
            WriteDataM <= 0;
            RdM <= 0;
            PCPlus4M <= 0;
            RegWriteM <= 0;
            ResultSrcM <= 0;
            MemWriteM <= 0;
            MemReadM <= 0;
            funct3ControlM <= 0;
            ResultCSR_M <= 0;
            csr_flagM <= 0;
            PCM <= 0;
            
//            TargetMemM <= 0;
        end
        else if(EN) begin
            Result_IcuM <= Result_IcuE;
            WriteDataM <= WriteDataE;
            RdM <= RdE;
            PCPlus4M <= PCPlus4E;
            RegWriteM <= RegWriteE;
            ResultSrcM <= ResultSrcE;
            MemWriteM <= MemWriteE;
            MemReadM <= MemReadE;
            funct3ControlM <= funct3ControlE;
            ResultCSR_M <= ResultCSR_E;
            csr_flagM <= csr_flagE;
            PCM <= PCE;
            
//            TargetMemM <= TargetMemE;
        end
        
         else if (dma_read_stall) begin
         MemReadM <= 0;
        end
        end
  
endmodule
