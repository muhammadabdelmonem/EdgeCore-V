`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 09:05:43 PM
// Design Name: 
// Module Name: ALU_Decoder
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


module ALU_Decoder(
    input  [1:0]ALUOp ,
    input  [2:0]funct3 ,
    input  op_5 ,
    input  funct7_5 ,
    input  zero,
    input  op_3,
    
    output OP3,
    output [3:0]ALUControl,
    output [2:0]DataSizeCon,
    output BranchFlag
    );
    reg [3:0]ALUControl_Reg ;
    reg BranchFlag_reg;
    always@(*)
    begin
     case(ALUOp)
     2'b00: ALUControl_Reg =4'b0000; //add for (load and store)
     2'b11: ALUControl_Reg =4'b1010; //LUI U type
     2'b01: begin // B-Type
                 case(funct3)
                 3'b000: begin //BEQ
                         ALUControl_Reg = 4'b0001; // sub 
                         BranchFlag_reg = zero;
                         end
                 3'b001: begin //BNE
                         ALUControl_Reg = 4'b0001; // sub 
                         BranchFlag_reg = ~zero;
                         end
                 3'b100: begin //BLT
                         ALUControl_Reg = 4'b0101; // SLT
                         BranchFlag_reg = ~zero;
                         end
                 3'b101: begin //BGE
                         ALUControl_Reg = 4'b0101; // SLT 
                         BranchFlag_reg = zero;
                         end
                 3'b110: begin //BLTU
                         ALUControl_Reg = 4'b0100; // SLTU
                         BranchFlag_reg = ~zero;
                         end
                 3'b111: begin //BGEU
                         ALUControl_Reg = 4'b0101; // SLTU
                         BranchFlag_reg = zero;
                         end
                 default:ALUControl_Reg= 4'b0000;
                 endcase
            end
     2'b10: begin //R-Type & I type 
                case(funct3)
                3'b000: begin
                         case({op_5,funct7_5})
                         2'b11: ALUControl_Reg =4'b0001; //sub
                         2'b00, 2'b01, 2'b10: ALUControl_Reg =4'b0000; //add /addi
                         default: ALUControl_Reg =4'b0000;
                         endcase
                        end
                3'b010: ALUControl_Reg = 4'b0110;  //slt
                3'b011: ALUControl_Reg = 4'b0101;  //sltu
                3'b110: ALUControl_Reg = 4'b0011;  //or / ori
                3'b111: ALUControl_Reg = 4'b0010;  //and / andi
                3'b100: ALUControl_Reg = 4'b0100;  //xor / xori         
                3'b001: ALUControl_Reg = 4'b0111;  //sll 
                3'b101: begin 
                        case(funct7_5)
                        1'b0: ALUControl_Reg = 4'b1000;  //srl
                        1'b1: ALUControl_Reg = 4'b1001;  //sra
                        endcase 
                        end       
                default: ALUControl_Reg= 4'b0000;
                endcase
            end
     default: ALUControl_Reg =4'b0000;
     endcase
    end
    assign ALUControl = ALUControl_Reg ;
    assign BranchFlag = BranchFlag_reg;
    assign DataSizeCon = funct3;
    assign OP3 = op_3;
endmodule
