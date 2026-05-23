`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/06/2026 12:25:10 AM
// Design Name: 
// Module Name: SOC_TOP_tb
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


module CPU_System_Top_tb(
    );
    
    //signals
    reg clk;
    reg reset_n;

    // Instantiate UUT
    CPU_System_Top CPU_System_UUT (
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
        #20000000;

        $finish;
    end
    
endmodule
