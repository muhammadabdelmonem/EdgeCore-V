`timescale 1ns / 1ps

module tb_CPU_System_Top();

    // 1. Declare testbench signals
    reg clk;
    reg reset_n;

    // 2. Instantiate the Top Level Module (Device Under Test)
    CPU_System_Top dut (
        .clk(clk),
        .reset_n(reset_n)
    );

    // 3. Generate the Clock (100 MHz -> 10ns period)
    always #5 clk = ~clk;

    // 4. Initial Block: Drive signals and run the test
    initial begin
        // Initialize clock and assert reset (active low)
        clk = 0;
        reset_n = 0;

        // Load the machine code into the main memory array
        // Hierarchical path: dut -> u_main_memory -> memory
        $readmemh("test.mem", dut.u_main_memory.memory);

        // Wait a few clock cycles, then release reset to start the CPU
        #20;
        reset_n = 1;

        // Let the processor run for 5000 nanoseconds
        // You can increase this number if your program is longer
        #5000;
        
        // Stop the simulation
        $display("Simulation finished!");
        $finish;
    end

    initial begin
    $dumpfile("simulation_results.vcd"); // Name of the file
    $dumpvars(0, dut);                   // Capture everything inside 'dut'
    end

endmodule