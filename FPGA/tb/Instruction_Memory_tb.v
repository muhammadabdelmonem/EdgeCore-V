`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2025 01:37:50 PM
// Design Name: 
// Module Name: Instruction_Memory_tb
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


module Instruction_Memory_tb(
    );
    
    // Testbench signals
    reg  [31:0] A  ; //address of inistructoin
    wire [31:0] RD ;
    
    // Instantiate PC
    Instruction_Memory IM_UUT(
    .A(A) ,
    .RD(RD)
    );
    
    
    //simulation
    initial
    begin
        
    //access the IM
    #10 A = 32'h00000000;
    #10 A = 32'h00000004;
    #10 A = 32'h00000008;
    #10 A = 32'h0000000C;
    #10 A = 32'h00000010;
    
    #20 $stop ;
    end
    
    //monitor
    initial
    begin
    $monitor("time = %0t , A = %0h , RD = %0h  ",$time,A,RD);
    end
    
endmodule
