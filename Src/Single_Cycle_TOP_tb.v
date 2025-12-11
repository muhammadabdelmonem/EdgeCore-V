`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 03:58:57 PM
// Design Name: 
// Module Name: Single_Cycle_TOP_tb
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


module Single_Cycle_TOP_tb(
    );
    
    //signals
    reg clk;
    reg reset_n;

    // Instantiate UUT
    Single_Cycle_TOP S_C_UUT (
        .clk(clk),
        .reset_n(reset_n)
    );

    //Clock generation
    localparam T = 10 ;
    initial clk = 0 ;
    always 
    begin
    #(T/2) clk = ~clk ;
    end

    // Simulation
    initial begin

        // Initialize
        reset_n = 0;
        #20;
        reset_n = 1; // Release reset

        // Let the CPU run for some time
        #2000000;

        $finish;
    end
    
endmodule
