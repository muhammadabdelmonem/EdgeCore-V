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
    input Mispred, lwStall,reset_n,
    input mret_Flush,
    input dcache_stall_M,
    input exceptionF, exceptionD, exceptionE,exceptionM,
    output reg FlushF, FlushD, FlushE ,FlushM
    );  
    always@(*) 
    begin
        if(~reset_n)
            begin
            FlushF = 0;
            FlushD = 0;
            FlushE = 0;
            FlushM=  0;
            
            end
         else
            begin
            if(exceptionF)
                FlushF = 1'b1;
            else
                FlushF = 1'b0;
            //FlushF = exceptionF; 
            
            if(Mispred | exceptionD | exceptionE | mret_Flush | exceptionM)
                FlushD = 1'b1;
            else
                FlushD = 1'b0;
            //FlushD = Mispred | exceptionD | exceptionE | mret_Flush | exceptionM;
            
            if(((lwStall & ~dcache_stall_M) | Mispred) | exceptionE | exceptionM)
                FlushE = 1'b1;
            else
                FlushE = 1'b0;
            //FlushE = (lwStall | Mispred) | exceptionE | exceptionM;
            
            if(exceptionM)
                FlushM = 1'b1;
            else
                FlushM = 1'b0;
            //FlushM = exceptionM ;
            end
        end
        
endmodule
