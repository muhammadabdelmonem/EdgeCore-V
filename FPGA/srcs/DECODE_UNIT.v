`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 06:14:39 PM
// Design Name: 
// Module Name: DECODE_UNIT
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


module Decode_Register(
    // Clock
    input CLK,
    // Data Inputs/Outputs
    input [31:0] InstrF,
    input [63:0] PCF,
    input [63:0] PCPlus4F,
    output reg [31:0] InstrD,
    output reg [63:0] PCD,
    output reg [63:0] PCPlus4D,
    // Hazard Unit Inputs/Outputs
    input CLR, EN
    );
        
    always @(posedge CLK)
    
        begin
            if(CLR)
                begin
                InstrD <= 32'b0;
                PCD <= 63'b0;
                PCPlus4D <= 63'b0;
                end
           else if(EN)
                begin
                InstrD <= InstrF;
                PCD <= PCF;
                PCPlus4D <= PCPlus4F;  
                end   
                
        end
    
endmodule