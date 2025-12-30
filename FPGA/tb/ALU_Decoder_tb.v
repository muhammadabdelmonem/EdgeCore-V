`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 03:28:31 PM
// Design Name: 
// Module Name: ALU_Decoder_tb
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


module ALU_Decoder_tb(
    );
    
    //Signals
    reg [1:0] ALUOp;
    reg [2:0] funct3;
    reg op_5;
    reg funct7_5;
    wire [2:0] ALUControl;

    // Instantiate UUT
    ALU_Decoder ALU_D_UUT (
    .ALUOp(ALUOp),
    .funct3(funct3),
    .op_5(op_5),
    .funct7_5(funct7_5),
    .ALUControl(ALUControl)
    );

    //Simulation
    initial begin

        //  LW / SW (ALUOp=00 -> ADD)
        ALUOp = 2'b00; funct3 = 3'b000; op_5 = 0; funct7_5 = 0;
        

        //  BEQ (ALUOp=01 -> SUB)
        #10 ALUOp = 2'b01; funct3 = 3'b000; op_5 = 0; funct7_5 = 0;
        

        //  R-type ADD (funct3=000, op_5=0, funct7_5=0)
        #10 ALUOp = 2'b10; funct3 = 3'b000; op_5 = 0; funct7_5 = 0;
        

        //  R-type SUB (funct3=000, op_5=1, funct7_5=1)
        #10 ALUOp = 2'b10; funct3 = 3'b000; op_5 = 1; funct7_5 = 1;
        

        //  SLT (funct3=010)
        #10 ALUOp = 2'b10; funct3 = 3'b010; op_5 = 0; funct7_5 = 0;
        

        //  OR (funct3=110)
        #10 ALUOp = 2'b10; funct3 = 3'b110; op_5 = 0; funct7_5 = 0;
        

        //  AND (funct3=111)
        #10 ALUOp = 2'b10; funct3 = 3'b111; op_5 = 0; funct7_5 = 0;

        #20 $stop;
        
    end
    
    //Monitor
    initial begin
    $monitor("Time = %0t , ALUOp = %0b funct3 = %0b op_5 = %0b funct7_5 = %0b => ALUControl = %0b",$time, ALUOp, funct3, op_5, funct7_5, ALUControl);
    end
    
endmodule
