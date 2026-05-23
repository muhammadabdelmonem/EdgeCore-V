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
input reset_n,
// Data Inputs/Outputs
input  [63:0] RD1, RD2, RD3,
input  [63:0] PCD, PCPlus4D, ImmExtD,
input  [4:0] Rs1D,
input  [4:0] Rs2D,
input  [4:0]  RdD,
input  [63:0] ResultCSR_D,

input csr_flagD, csr_weD,
input [11:0] csr_addrD,
output reg [63:0] RD1E, RD2E, RD3E,
output reg [63:0] PCE,
output reg [4:0] Rs1E,
output reg [4:0] Rs2E,
output reg [4:0]  RdE,
output reg [63:0] ImmExtE,
output reg [63:0] PCPlus4E,
output reg [63:0] ResultCSR_E,
output reg csr_flagE, csr_weE,
output reg [11:0] csr_addrE,
// Control Unit Inputs/Outputs
input        RegWriteD,
input  [1:0] ResultSrcD,
input        MemWriteD,
input        MemReadD,
input        SignExtendD,
input  [3:0] ALUControlD,
input        ALUSrcAD,
input        ALUSrcBD,
input        TargetD,
input        OP3D,
input  [2:0] funct3ControlD,
input        BranchD,
input        JumpD,
input  [2:0] Mul_ControlD,
input  [3:0] Div_ControlD,
input  [1:0] Function_SelD,
input        FlagD,
input        MAC_SelD,
input  [1:0] ModeD,
input        Signed_enD,
//input        BranchFlagD,
output reg        RegWriteE,
output reg [1:0]  ResultSrcE,
output reg        MemWriteE,
output reg        MemReadE,
output reg        SignExtendE,
output reg [3:0]  ALUControlE,
output reg        ALUSrcAE,
output reg        ALUSrcBE,
output reg        TargetE,
output reg        OP3E,
output reg [2:0]  funct3ControlE,
output reg        BranchE,
output reg        JumpE,
output reg   [2:0] Mul_ControlE,
output reg   [3:0] Div_ControlE,
output reg   [1:0] Function_SelE,
output reg         FlagE,
output reg         MAC_SelE,
output reg   [1:0] ModeE,
output reg         Signed_enE,
//output reg        BranchFlagE,

// Hazard Unit Inputs/Outputs
input CLR , EN

    );
    
    always @(posedge CLK, negedge reset_n)
        begin
            if(~reset_n)
                begin 
                RegWriteE <= 0;
                ResultSrcE <=0;
                MemWriteE <= 0;
                MemReadE <=0;
                SignExtendE <= 0;
                ALUControlE <= 0;
                ALUSrcAE <= 0;
                ALUSrcBE <= 0; 
                TargetE <= 0;
                OP3E <= 0;
                funct3ControlE <= 0;
                BranchE <= 0;
                JumpE <= 0;
                Mul_ControlE <= 0;
                Div_ControlE <= 0;
                Function_SelE <= 0;
                FlagE <= 0;
                MAC_SelE <= 0;
                ModeE <= 0;
               Signed_enE <= 0;
                //BranchFlagE <= 0;
                RD1E <= 0;
                RD2E <= 0;
                PCE <= 0;
                Rs1E <= 0;
                Rs2E <= 0;
                RD3E <= 0;
                RdE <= 0;
                PCPlus4E <= 0;
                ImmExtE <= 0;
                ResultCSR_E <= 0;
                csr_flagE <= 0;
                csr_addrE <= 0;
                csr_weE <= 0;
                end
            else if(CLR)
                begin
                RegWriteE <= 0;
                ResultSrcE <=0;
                MemWriteE <= 0;
                MemReadE <=0;
                SignExtendE <= 0;
                ALUControlE <= 0;
                ALUSrcAE <= 0;
                ALUSrcBE <= 0; 
                TargetE <= 0;
                OP3E <= 0;
                funct3ControlE <= 0;
                BranchE <= 0;
                JumpE <= 0;
                Mul_ControlE <= 0;
                Div_ControlE <= 0;
                Function_SelE <= 0;
                FlagE <= 0;
                MAC_SelE <= 0;
                ModeE <= 0;
                Signed_enE <= 0;
                //BranchFlagE <= 0;
                RD1E <= 0;
                RD2E <= 0;
                RD3E <= 0;
                PCE <= 0;
                Rs1E <= 0;
                Rs2E <= 0;
                RdE <= 0;
                PCPlus4E <= 0;
                ImmExtE <= 0;
                ResultCSR_E <= 0;
                csr_flagE <= 0;
                csr_addrE <= 0;
                csr_weE <= 0;
                end
           else if(EN)
                begin
                RegWriteE <= RegWriteD;
                ResultSrcE <= ResultSrcD;
                MemWriteE <= MemWriteD;
                MemReadE <= MemReadD;
                SignExtendE <= SignExtendD;
                ALUControlE <= ALUControlD;
                ALUSrcAE <= ALUSrcAD;
                ALUSrcBE <= ALUSrcBD; 
                TargetE <= TargetD;
                OP3E <= OP3D;
                funct3ControlE <= funct3ControlD;
                BranchE <= BranchD;
                JumpE <= JumpD;
                Mul_ControlE <= Mul_ControlD;
                Div_ControlE <= Div_ControlD;
                Function_SelE <= Function_SelD;
                FlagE <= FlagD;
                MAC_SelE <= MAC_SelD;
                ModeE <= ModeD;
                Signed_enE <= Signed_enD;
                //BranchFlagE <= BranchFlagD;
                RD1E <= RD1;
                RD2E <= RD2;
                RD3E <= RD3;
                PCE <= PCD;
                Rs1E <= Rs1D;
                Rs2E <= Rs2D;
                RdE <= RdD;
                PCPlus4E <= PCPlus4D;
                ImmExtE <= ImmExtD;
                ResultCSR_E <= ResultCSR_D;
                csr_flagE <= csr_flagD;
                csr_addrE <= csr_addrD;
                csr_weE <= csr_weD;
                end   
        end
    
endmodule
