`timescale 1ns / 1ps

module Main_Decoder(
    input [6:0]OP,
    input [2:0] funct3,
    input [6:0] funct7,
    output RegWrite,
    output [2:0]ImmSrc,
    output  ALUSrcA,
    output  ALUSrcB,
    output MemWrite,
    output MemRead,
    output [1:0]ResultSrc,
    output Branch,
    output [1:0] ALUOp,
    output Jump,
    output SignExtension,
    output Target,
    
    output reg [2:0] Mul_Control,
    output reg [3:0] Div_Control,
    output reg [1:0] Function_Sel,    // ? Changed from [2:0] to [1:0]
    output reg  Flag,
    
    output reg        MAC_Sel,
    output reg [1:0]  Mode,
    output reg        Signed_en,
    output illegal_instr,
    output system_instr,
    
    
    output csr_write_en
    );
    
    reg [15:0] outputs;
    
    reg illegal_instr_reg;
    reg system_instr_reg;    
    reg csr_write_en_reg;
    
    always@(*)           
    begin
        illegal_instr_reg = 1'b0;
        system_instr_reg  = 1'b0;
        csr_write_en_reg  = 1'b0;
        outputs = 16'b1_000_0_0_0_0_00_0_00_0_0_1 ;
        Function_Sel = 2'b00;   // ? Default to ALU
        Mul_Control  = 3'b000;
        Div_Control  = 4'b0000;
        Flag = 1'b0;
        MAC_Sel  =1'b0; 
        Mode              = 2'b00;   // â? added: prevents inferred latch
        Signed_en         = 1'b0; 
//        ACC_En=1'b0;
       
        case(OP)
        7'b0000011: outputs = 16'b1_000_0_1_0_1_01_0_00_0_0_1 ; //LW
        7'b0100011: outputs = 16'b0_001_0_1_1_0_00_0_00_0_0_1 ; //SW
        
        //======================================================================
        // R-Type (64-bit): OP = 0110011
        //======================================================================
        7'b0110011: begin
            if(funct7 == 7'b0000001) begin
                // M-Extension: MUL/DIV instructions
                outputs = 16'b1_000_0_0_0_0_00_0_10_0_0_1;
                Flag = 1'b1;
                if(!funct3[2])begin
                    Function_Sel = 2'b01;
                    Mode=2'b11;
                    Mul_Control         = {1'b1,funct3[1:0]};   // funct3[1:0] = 00
           	    end
           	    else begin
                    Function_Sel = 2'b10;   // ? Select DIV unit
                    Div_Control  = {OP[4:3],funct3[1:0]}; 
                end
                   
                    
            end
            else begin
                // Normal R-type ALU instructions (funct7 != 0000001)
                outputs = 16'b1_000_0_0_0_0_00_0_10_0_0_1;
                Function_Sel = 2'b00;  // ? Select ALU
                Mode  = 2'b00;
                Div_Control  = 4'b0000;
                Flag = 1'b0;
            end
        end
        
        //======================================================================
        // R-Type WORD (32-bit): OP = 0111011 (OP-32)
        //======================================================================
        7'b0111011: begin
            if(funct7 == 7'b0000001) begin
                // M-Extension WORD operations: MULW, DIVW, REMW              
                outputs = 16'b1_000_0_0_0_0_00_0_10_0_1_1;  // R-type word, OP3=1
                Flag = 1'b1;
                
                
                if(!funct3[2])begin
                   Function_Sel = 2'b01;
                   Mode  = 2'b11;
                   Mul_Control  = 3'b100;
                end
                else begin
                   Function_Sel = 2'b10;   // ? Select DIV unit
                   Div_Control  = {OP[4:3],funct3[1:0]}; 
                end
                     
                   
            end
            else begin
                // Normal R-type word ALU instructions
                outputs = 16'b1_000_0_0_0_0_00_0_10_0_1_1;
                Function_Sel = 2'b00;
                Mul_Control  = 3'b000;
                Div_Control  = 4'b0000;
                Flag = 1'b0;
            end
        end
        
        //======================================================================
        // Other Instructions (unchanged)
        //======================================================================
        7'b1100011: outputs = 16'b0_010_0_0_0_0_00_1_01_0_0_1 ; //Beq
        7'b0001011: begin //MAC
                    MAC_Sel  =1'b1;                  
                    outputs = 16'b1_000_0_0_0_0_00_0_00_0_0_0;
                    Function_Sel=2'b00;
               if(funct7 == 7'b0000000) begin
                 Signed_en=1'b0;                    
                 Mode =funct3[1:0];
                 outputs[1] = funct3[1]?1'b1:1'b0;
                  end       
               else if(funct7 == 7'b0000001) begin
                  Signed_en=1'b1;
                  Mode =funct3[1:0];
                  outputs[1] = funct3[1]?1'b1:1'b0;
                  end                    
                  end
        7'b0010011: begin  //I Type
            case (funct3)
                3'b001, 3'b101: outputs = 16'b1_100_0_1_0_0_00_0_10_0_0_1 ; // Shift immediate
                default: outputs = 16'b1_000_0_1_0_0_00_0_10_0_0_1; //I type ALU
            endcase 
        end
        
        7'b0011011: begin
            if(funct3 == 3'b000) 
                outputs = 16'b1_000_0_1_0_0_00_0_10_0_1_1 ; // ADDIW
            else
                outputs = 16'b1_100_0_1_0_0_00_0_10_0_1_1 ; // Shift immediate word 
        end
        7'b1101111: outputs = 16'b1_011_0_0_0_0_10_0_00_1_0_1 ; //JAL
        7'b1100111: outputs = 16'b1_000_0_0_0_0_10_0_00_1_0_0 ; //JALR
        7'b0010111: outputs = 16'b1_101_1_1_0_0_00_0_00_0_0_1 ; //AUIPC
        7'b0110111: outputs = 16'b1_101_1_1_0_0_00_0_11_0_0_1 ; //LUI
        
        7'b1110011: begin  // SYSTEM instructions
            if (funct3 == 3'b000) begin
                // System instruction: ECALL / EBREAK / MRET 
                system_instr_reg = 1'b1;
                outputs = 16'b0_000_0_0_0_0_00_0_00_0_0_0;
            end 
            else begin
                // CSR instruction
                csr_write_en_reg = 1'b1;
                outputs = 16'b1_000_0_0_0_0_00_0_00_0_0_0;
            end
        end 
        
        7'b0000000: outputs = 16'b0_000_0_0_0_0_00_0_00_0_0_0;          
        
        default: begin
            illegal_instr_reg = 1'b1;
            outputs = 16'b0_000_0_0_0_0_00_0_00_0_0_0;
        end
        endcase  
    end
    
    assign csr_write_en  = csr_write_en_reg;
    assign illegal_instr = illegal_instr_reg;
    assign system_instr  = system_instr_reg;
    
    assign {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite, MemRead, ResultSrc, Branch, ALUOp, Jump, SignExtension, Target} = outputs;
    
endmodule
