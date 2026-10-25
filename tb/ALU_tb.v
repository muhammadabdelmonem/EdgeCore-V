`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2025 09:02:31 PM
// Design Name: 
// Module Name: ALU_tb
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


module ALU_tb(
    );
    


    // Testbench signals
    reg [31:0] SrcA;
    reg [31:0] SrcB;
    reg [2:0]  ALUControl;
    wire [31:0] ALUResult;
    wire Zero;

    // Instantiate  ALU
    ALU ALU_UUT (
    .SrcA(SrcA),
    .SrcB(SrcB),
    .ALUControl(ALUControl),
    .ALUResult(ALUResult),
    .Zero(Zero)
    );

    // Simulation
    initial begin
        // Initialize inputs
        SrcA = 0;
        SrcB = 0;
        ALUControl = 3'b000;

        // Basic operations
        #10 SrcA = 10;   SrcB = 5;    ALUControl = 3'b000; // ADD normal
        #10 SrcA = 10;   SrcB = 5;    ALUControl = 3'b001; // SUB positive result
        #10 SrcA = 5;    SrcB = 10;   ALUControl = 3'b001; // SUB negative result
        #10 SrcA = 10;   SrcB = 10;   ALUControl = 3'b001; // SUB zero result
        #10 SrcA = 32'hFFFF_FFFF; SrcB = 1; ALUControl = 3'b000; // wrap-around edge test
        #10 SrcA = 32'h7FFF_FFFF; SrcB = 1; ALUControl = 3'b000; // ADD positive overflow
        #10 SrcA = 32'h8000_0000; SrcB = 32'hFFFF_FFFF; ALUControl = 3'b001; // SUB negative overflow

        // Bitwise operations
        #10 SrcA = 32'hFFFF_0000; SrcB = 32'h0FFF_FFFF; ALUControl = 3'b010; // AND
        #10 SrcA = 32'h0000_FFFF; SrcB = 32'hFFFF_0000; ALUControl = 3'b011; // OR
        #10 SrcA = 32'hAAAA_AAAA; SrcB = 32'h5555_5555; ALUControl = 3'b010; // AND alternating bits
        #10 SrcA = 32'hAAAA_AAAA; SrcB = 32'h5555_5555; ALUControl = 3'b011; // OR alternating bits

        // SLT (set less than)
        #10 SrcA = 32'd5;  SrcB = 32'd10; ALUControl = 3'b101; // A < B
        #10 SrcA = 32'd10; SrcB = 32'd5;  ALUControl = 3'b101; // A > B
        #10 SrcA = 32'd10; SrcB = 32'd10; ALUControl = 3'b101; // A == B

        // Edge cases
        #10 SrcA = 32'd0; SrcB = 32'd0; ALUControl = 3'b000; // ADD zero + zero
        #10 SrcA = 32'hFFFF_FFFF; SrcB = 32'hFFFF_FFFF; ALUControl = 3'b011; // OR all 1s
        #10 SrcA = 32'h0000_0000; SrcB = 32'h0000_0000; ALUControl = 3'b010; // AND all 0s
        
       
        #20 $stop;
    end

    // Monitor 
    initial begin
        $monitor("time=%0t | ALUControl=%b | SrcA=%0h | SrcB=%0h | ALUResult=%0h | Zero=%b",$time, ALUControl, SrcA, SrcB, ALUResult, Zero);
    end
    
endmodule
