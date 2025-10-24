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
    input PCSrcE, lwStall,reset_n,
    output reg FlushD, FlushE
    );  
    always@(*) 
    begin
        if(~reset_n)
            begin
            FlushD = 0;
            FlushE = 0;
            
            end
         else
            begin
            
            FlushD = PCSrcE;
            FlushE = (lwStall | PCSrcE);
            end
        end
endmodule
