`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 06:26:25 PM
// Design Name: 
// Module Name: EXECUTE_UNIT
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


module Execute_Register(
   // Clock
input CLK,

// Data Inputs/Outputs
input  [63:0] RD1, RD2,
input  [63:0] PCD, PCPlus4D, ImmExtD,
input  [4:0] Rs1D,
input  [4:0] Rs2D,
input  [4:0]  RdD,
output reg [63:0] RD1E, RD2E,
output reg [63:0] PCE,
output reg [4:0] Rs1E,
output reg [4:0] Rs2E,
output reg [4:0]  RdE,
output reg [63:0] ImmExtE,
output reg [63:0] PCPlus4E,

// Control Unit Inputs/Outputs
input        RegWriteD,
input  [1:0] ResultSrcD,
input        MemWriteD,
input        SignExtendD,
input  [3:0] ALUControlD,
input        ALUSrcAD,
input        ALUSrcBD,
input        TargetD,
input        OP3D,
input  [2:0] funct3ControlD,
input        BranchD,
input        JumpD,
//input        BranchFlagD,
output reg        RegWriteE,
output reg [1:0]  ResultSrcE,
output reg        MemWriteE,
output reg        SignExtendE,
output reg [3:0]  ALUControlE,
output reg        ALUSrcAE,
output reg        ALUSrcBE,
output reg        TargetE,
output reg        OP3E,
output reg [2:0]  funct3ControlE,
output reg        BranchE,
output reg        JumpE,
//output reg        BranchFlagE,

// Hazard Unit Inputs/Outputs
input CLR

    );
    
    always @(posedge CLK)
        begin
            if(CLR)
                begin
                RegWriteE <= 0;
                ResultSrcE <=0;
                MemWriteE <= 0;
                SignExtendE <= 0;
                ALUControlE <= 0;
                ALUSrcAE <= 0;
                ALUSrcBE <= 0; 
                TargetE <= 0;
                OP3E <= 0;
                funct3ControlE <= 0;
                BranchE <= 0;
                JumpE <= 0;
                //BranchFlagE <= 0;
                RD1E <= 0;
                RD2E <= 0;
                PCE <= 0;
                Rs1E <= 0;
                Rs2E <= 0;
                RdE <= 0;
                PCPlus4E <= 0;
                ImmExtE <= 0;
                end
           else
                begin
                RegWriteE <= RegWriteD;
                ResultSrcE <= ResultSrcD;
                MemWriteE <= MemWriteD;
                SignExtendE <= SignExtendD;
                ALUControlE <= ALUControlD;
                ALUSrcAE <= ALUSrcAD;
                ALUSrcBE <= ALUSrcBD; 
                TargetE <= TargetD;
                OP3E <= OP3D;
                funct3ControlE <= funct3ControlD;
                BranchE <= BranchD;
                JumpE <= JumpD;
                //BranchFlagE <= BranchFlagD;
                RD1E <= RD1;
                RD2E <= RD2;
                PCE <= PCD;
                Rs1E <= Rs1D;
                Rs2E <= Rs2D;
                RdE <= RdD;
                PCPlus4E <= PCPlus4D;
                ImmExtE <= ImmExtD;
                end   
        end
    
endmodule
