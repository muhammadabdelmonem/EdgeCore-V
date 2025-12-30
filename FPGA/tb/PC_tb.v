`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2025 12:29:56 PM
// Design Name: 
// Module Name: PC_tb
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


module PC_tb(
    );
    
    // Testbench signals
    reg clk ;
    reg reset_n ;
    reg [31:0]PCNext ;
    wire [31:0]PC ;
    
    // Instantiate PC
    PC PC_UUT(
    .clk(clk) ,
    .reset_n(reset_n) ,
    .PCNext(PCNext) ,
    .PC(PC)
    );
    
    //Clock generation
    localparam T = 10 ;
    initial clk = 0 ;
    always 
    begin
    #(T/2) clk = ~clk ;
    end
    
    //simulation
    initial
    begin
    reset_n = 1'b0;
    PCNext  = 32'b0;
    
    #20  reset_n = 1'b1;
    #10  PCNext  = 32'd10;
    #10  PCNext  = 32'd5;
    #10  PCNext  = 32'd40;
    #10  reset_n = 1'b0;
    
    #20 $stop ;
    
    end
    
    //monitor
    initial
    begin
    $monitor("time = %0t , reset_n = %0b , PCNext = %0d , PC = %0d ",$time,reset_n,PCNext,PC);
    end
    
endmodule
