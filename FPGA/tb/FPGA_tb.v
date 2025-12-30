`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/28/2025 06:40:33 PM
// Design Name: 
// Module Name: FPGA_tb
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


module FPGA_tb(

    );
    
    //signals

    reg clk_in;
    reg  btnC;
    wire ExcFlag;
    wire [6:0] a_to_g;   
    wire [7:0] an;     
    wire dp;
    // Instantiate UUT
    FPGA S_C_UUT (
    .clk_in(clk_in),
    .btnC(btnC), 
    .ExcFlag(ExcFlag),
    .a_to_g(a_to_g),    
    .an(an),       
    .dp(dp) 
    );

    //Clock generation
    localparam T = 10 ;
    initial clk_in = 0 ;
    always 
    begin
    #(T/2) clk_in = ~clk_in ;
    end

    // Simulation
    initial begin

        // Initialize
        btnC = 1;
        #20;
        btnC = 0; // Release reset

        // Let the CPU run for some time
        #2000;

        $finish;
    end
    
endmodule
