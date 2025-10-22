`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 12:39:07 AM
// Design Name: 
// Module Name: Control_Hazard
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


module Control_Hazard(
    input PCSrcE, lwStall,
    output FlushD, FlushE
    );  
    
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;
        
endmodule
