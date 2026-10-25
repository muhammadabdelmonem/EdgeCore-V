`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 07:08:32 PM
// Design Name: 
// Module Name: Exception_Handler
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


module Exception_Handler(
    input clk,
    input reset_n,
    input system_instr, // from main decoder
    input illegal_instr, // from main decoder
    input [63:0] PCTarget, // datapath
    input [63:0] MemAddr, //datapath = aluresult
    input [2:0] funct3, // datapath
    input [63:0] current_pc, // datapath pc
    input [31:0] instr, //datapath
    
    input [63:0]csr_rdata,
    input [63:0]csr_wdata,
    input csr_we, // from main decoder
    output  exception_en,
    
    output mret, // to the datapath pcsrc logic
    output flush,
    
    output [63:0] mepc,
    output [63:0] mtvec
    
    );
    
    wire [11:0] imm12;
   
    assign imm12 = instr[31:20];
    
    wire ecall_flag;
    wire ebreak_flag;
    wire illegal_instr_flag;
    wire pc_misaligned_flag;
    wire addr_misaligned_flag;
    
    wire [63:0] faulting_addr;
    wire [63:0] misaligned_pc;
    
    wire [3:0] exception_code;
    wire [63:0] mtval_content;
    wire [63:0] faulting_pc;
    
    wire [63:0] mtval;
    wire [63:0] mcause;
    
    Exception_Controller EXC_CONTROL(
    .system_instr(system_instr),
    .illegal_instr(illegal_instr),
    .imm12(imm12),
    .pc_target(PCTarget),
    .MemAddr(MemAddr),
    .DataSizeCon(funct3),
    .ecall_flag(ecall_flag),
    .ebreak_flag(ebreak_flag),
    .illegal_instr_flag(illegal_instr_flag),
    .pc_misaligned_flag(pc_misaligned_flag),
    .addr_misaligned_flag(addr_misaligned_flag),
    .faulting_addr(faulting_addr),
    .misaligned_pc(misaligned_pc),
    .mret(mret)
    );
    
     Exception_decoder EXC_DECOD (
    .illegal_instr_flag(illegal_instr_flag),
    .ebreak_flag(ebreak_flag),
    .ecall_flag(ecall_flag),
    .pc_misaligned_flag(pc_misaligned_flag),
    .addr_misaligned_flag(addr_misaligned_flag),
    .current_pc(current_pc),
    .misaligned_pc(misaligned_pc),
    .faulting_addr(faulting_addr),
    .instr_bits(instr),
    .exception_en(exception_en),
    .exception_code(exception_code),
    .mtval_content(mtval_content),
    .faulting_pc(faulting_pc),
    .flush(flush)
    );
    
    
    csr_file CSR_UNIT (
    .clk(clk),
    .reset_n(reset_n),
    .exception_en(exception_en),
    .exception_code(exception_code),
    .faulting_pc(faulting_pc),
    .mtval_content(mtval_content),
    .csr_we(csr_we),
    .csr_addr(imm12),
    .csr_wdata(csr_wdata),
    .csr_op(funct3),
    .csr_rdata(csr_rdata),
    .mtvec(mtvec),
    .mtval(mtval),
    .mcause(mcause),
    .mepc(mepc)
    );
     
endmodule
