`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 01:33:17 PM
// Design Name: 
// Module Name: Register_File
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


module Register_File(
    input  clk,
    input  WE3,
    input   MAC_EN,
    input  [4:0] A1,
    input  [4:0] A2,
    input  [4:0] A3,
    input  [4:0] A3_Mac,
    input  [63:0] WD3,
    output [63:0] RD1,
    output [63:0] RD2,
    output [63:0] RD3
    );
    
    reg [63:0] reg_file [0:31];
    
    integer i;
    initial begin
    for (i = 0; i<64; i = i+1)
     reg_file[i]=0;
     end  
//    integer i;
//    initial begin
//    for (i = 0; i<64; i = i+1)
//     reg_file[i]=0;
//     end  
    always@(negedge(clk))
    begin
        reg_file[0] <= 0;
        if(WE3 &(A3 != 0))  //we can't write in address x0, it is always zero
            reg_file[A3] <= WD3 ;
    end
    assign RD1 = (A1 != 0)? reg_file[A1] : 0 ; //x0 is always zero
    assign RD2 = (A2 != 0)? reg_file[A2] : 0 ; //x0 is always zero
    assign RD3 = (A3 != 0 & MAC_EN)? reg_file[A3] :0;//64'bZ ; //x0 is always zero
//    assign RD1 = reg_file[A1];
//    assign RD2 = reg_file[A2];
endmodule
