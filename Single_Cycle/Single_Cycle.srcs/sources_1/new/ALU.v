`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 02:20:54 PM
// Design Name: 
// Module Name: ALU
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


module ALU(
    input [63:0] SrcA ,
    input [63:0] SrcB ,
    input [3:0]  ALUControl ,
    input  SignExtension ,
    input OP3,
    output [63:0] ALUResult ,
    output Zero
    );
    reg [63:0]result ;
    reg [63:0] temp;
    always @(*) begin
        case(ALUControl)
        
            4'b0000 : temp = SrcA + SrcB ; // ADD
            4'b0001 : temp = SrcA - SrcB ; // SUB
            4'b0010 : temp = SrcA & SrcB ; // AND
            4'b0011 : temp = SrcA | SrcB ; // OR
            4'b0100 : temp = SrcA ^ SrcB ; // XOR           
            4'b0101 : temp = (SrcA < SrcB) ; // SLTU  
            4'b0110 : temp = ($signed(SrcA) < $signed(SrcB)) ; // SLT
            4'b0111 : temp = OP3? (SrcA[31:0] << SrcB) : (SrcA << SrcB); // SLL or SLLIW
            4'b1000 : temp = OP3? (SrcA[31:0] >> SrcB) : (SrcA >> SrcB); // SRL or SRLIW 
            4'b1001 : temp = OP3? ($signed(SrcA[31:0]) >>> SrcB) : ($signed(SrcA) >>> SrcB); // SRA or SRAIW
            4'b1010 : temp = SrcB; // LUI
            default: temp = SrcA;
        endcase   
        // Apply optional sign-extension for "word" shifts
        result = SignExtension ? {{32{temp[31]}}, temp[31:0]} : temp;
    end
    assign ALUResult = result ;
    assign Zero = ~(|ALUResult) ;    //beq bne
endmodule


//
//ALUControl   operation
//0000     add
//0001    sub
//0010    and
//0011    or
//0100    xor
//0101    sltu
//0110    slt
//0111    sll /slla  
//1000    sra
//1001    srl
//1010    lui






