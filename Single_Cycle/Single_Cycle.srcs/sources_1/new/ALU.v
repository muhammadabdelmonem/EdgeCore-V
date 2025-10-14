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
    output [63:0] ALUResult ,
    output Zero
    );
    reg [63:0]result ;
    always @(*) begin
        case(ALUControl)
        
            4'b0000 : result = SrcA + SrcB ; //add
            4'b0001 : result = SrcA - SrcB ; //sub
            4'b0010 : result = SrcA & SrcB ; //and
            4'b0011 : result = SrcA | SrcB ; //or
            4'b0100 : result = SrcA ^ SrcB ; //xor          
            4'b0101 : result = (SrcA < SrcB) ; //sltu
            4'b0110 : result = ($signed(SrcA) < $signed(SrcB)) ; //slt
            default: result = SrcA;
        endcase
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
//1010    addw






