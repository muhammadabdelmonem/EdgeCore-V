`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 06:17:47 PM
// Design Name: 
// Module Name: Exception_Controller
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

module Exception_Controller(
    input system_instr,
    input illegal_instr,
    input [11:0]imm12,
    
    input [63:0] PCF,
    
    input [63:0] MemAddr,
    input [2:0] DataSizeCon,
    
    output ecall_flag,
    output ebreak_flag,
    output illegal_instr_flag,
    output pc_misaligned_flag,
    output addr_misaligned_flag,
    
    output [63:0] faulting_addr,
    output [63:0] misaligned_pc,
    
     output mret
);
    
    reg ecall_flag_reg;
    reg ebreak_flag_reg;
    reg mret_reg;
    
    reg addr_misaligned_flag_reg;
    
    // EBREAK / ECALL / MRET
    always @(*)
    begin
        ecall_flag_reg = 1'b0;
        ebreak_flag_reg = 1'b0;
        mret_reg = 1'b0;

        if (system_instr)
        begin
        case(imm12)
        12'h000: ecall_flag_reg = 1'b1; // Ecall
        12'h001: ebreak_flag_reg = 1'b1; // Ebreak
        12'h302: mret_reg = 1'b1; // Mret
        endcase 
        end    
    end  
    
    // Illegal Instruction
    assign illegal_instr_flag = illegal_instr;
 
 
    // PC misalignment 
    assign pc_misaligned_flag = (PCF[1:0] != 2'b00);
    assign misaligned_pc = pc_misaligned_flag ? PCF : 64'b0;
    
    // Memory address misalignment
    always @(*) begin
        addr_misaligned_flag_reg = 1'b0;
        // Check misalignment
        case (DataSizeCon)
            3'b001: if (MemAddr[0] != 0) addr_misaligned_flag_reg = 1'b1; // Halfword (LH/LHU/SH)
            3'b010: if (MemAddr[1:0] != 2'b00) addr_misaligned_flag_reg = 1'b1; // Word (LW/LWU/SW)
            3'b011: if (MemAddr[2:0] != 3'b000) addr_misaligned_flag_reg = 1'b1; // Doubleword (LD/SD)
        endcase
        end 
        
    assign addr_misaligned_flag = addr_misaligned_flag_reg;
    assign faulting_addr = addr_misaligned_flag ? MemAddr : 64'b0;  
    
    assign ecall_flag = ecall_flag_reg;
    assign ebreak_flag = ebreak_flag_reg;
    assign mret = mret_reg;
    
    
endmodule
