`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 01:28:59 AM
// Design Name: 
// Module Name: Extend_tb
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


module Extend_tb(
    );
    
    reg  [31:7] Instr;
    reg  [1:0]  ImmSrc;
    wire [31:0] ImmExt;

    // Instantiate the Unit Under Test (UUT)
    Extend uut (
        .Instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    initial begin

        //  I-type (Immediate in bits [31:20])
        ImmSrc = 2'b00;
        Instr  = 25'b1000000000000000000000000; // example with sign bit = 1
        
        #20 ;
        //S-type (Immediate in bits [31:25] & [11:7])
        ImmSrc = 2'b01;
        Instr  = 25'b0100000000000000000000000;
    
        #20 ;
        //B-type (Immediate in bits [31], [7], [30:25], [11:8], 1'b0)
        ImmSrc = 2'b10;
        Instr  = 25'b1100000000000000000000000;

        #20 ;
        //J-type (Immediate in bits [31], [19:12], [20], [30:21], 1'b0)
        ImmSrc = 2'b11;
        Instr  = 25'b1000000000000000000000000;

        #20 ;
        //Default / Undefined
        ImmSrc = 2'bxx;
        Instr  = 25'b0;

        #20 $finish;
    end
    
    initial begin
    $monitor("time = %0t , ImmSrc = %0b , Instr = %0b , ImmExt = %0h ",$time, ImmSrc, Instr, ImmExt);
    end
endmodule
