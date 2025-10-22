`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 12:26:15 AM
// Design Name: 
// Module Name: Data_Memory_tb
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


module Data_Memory_tb(
    );
    
    // Parameters
    localparam DEPTH = 256;
    //signals
    reg clk;
    reg WE;
    reg [31:0] A;
    reg [31:0] WD;
    wire [31:0] RD;

    // Instantiate UUT
    Data_Memory #(.depth(DEPTH)) DM_UUT (
    .clk(clk),
    .WE(WE),
    .A(A),
    .WD(WD),
    .RD(RD)
    );

    // Clock generation
    localparam T = 10; // clock period
    initial clk = 0;
    always begin
    #(T/2) clk = ~clk;
    end
    
    // Simulation 
    initial begin
        // Initial values
        WE = 0;
        A  = 0;
        WD = 0;

        // 1. Write 0xAABBCCDD at address 0
        #10 WE = 1; 
            A = 0; 
            WD = 32'hAABBCCDD;
        #10 WE = 0;

        // 2. Read same address
        #10 A = 0;

        // 3. Write 0x11223344 at address 4
        #10 WE = 1; 
            A = 4; 
            WD = 32'h11223344;
        #10 WE = 0;

        // 4. Read from address 4
        #10 A = 4;

        // 5. Try to write when WE=0 (shouldn’t change)
        #10 WE = 0; 
            A = 8; 
            WD = 32'hDEADBEEF;

        // 6. Overwrite address 0 with 0x55667788
        #10 WE = 1; 
            A = 0; 
            WD = 32'h55667788;
        #10 WE = 0; 
            A = 0;

        // 7. Edge test (last valid word)
        #10 WE = 1; 
            A = DEPTH - 4; 
            WD = 32'hCAFEBABE;
        #10 WE = 0; 
            A = DEPTH - 4;

        // Finish
        #20 $stop;
        $stop;
    end

    // Monitor changes
    initial begin
        $monitor("time=%0t | WE=%b | A=%0d | WD=%h | RD=%h",
                  $time, WE, A, WD, RD);
    end
    
endmodule
