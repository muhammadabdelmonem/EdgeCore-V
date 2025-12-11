`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 06:08:43 PM
// Design Name: 
// Module Name: Exception_decoder
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


module Exception_decoder(
    input  illegal_instr_flag,      
    input  ebreak_flag,             
    input  ecall_flag,              
    input  pc_misaligned_flag,      
    input  addr_misaligned_flag,

    input [63:0] PCD, // Current PC of the instruction causing exception in decode stage
    input [63:0] PCE,       // Current PC of the instruction causing exception in execute stage
    input [63:0] PCF,
    input  [63:0] misaligned_pc,    // Misaligned PC target (for jumps/branches)
    input  [63:0] faulting_addr,    // Faulting address (for misaligned load/store)
    //input  [31:0]  instrE,       // Full 32-bit instruction (for illegal instr mtval)
    input  [31:0]  instrD,
    
    output reg exception_en,
    output [3:0] exception_code, // mcause
    output [63:0] mtval_content, // mtval
    output [63:0] faulting_pc, // mepc
    //to hazard unit
    output exceptionF,
    output exceptionD,
    output exceptionE
    );
    
    reg [3:0] exception_code_reg; 
    reg [63:0] mtval_content_reg;
    reg [63:0] faulting_pc_reg;
    
    assign exception_code = exception_code_reg;
    assign mtval_content =  mtval_content_reg;
    assign faulting_pc = faulting_pc_reg;
    
    // Exception Cause Selection
    // Exceptions are checked in priority order
    always @(*)
        begin 
            if(illegal_instr_flag)
                begin
                    mtval_content_reg = {32'b0, instrD};
                    exception_code_reg = 2;
                  //  faulting_pc_reg = current_pc;
                end
                
            else if (pc_misaligned_flag)
                begin
                    exception_code_reg = 0;
                    mtval_content_reg = misaligned_pc;
               //     faulting_pc_reg = current_pc;
                end 
                   
            else if(ebreak_flag)
                begin
                    exception_code_reg = 3;
                    mtval_content_reg = 64'b0;
               //    faulting_pc_reg = current_pc;
                end
            
            else if(addr_misaligned_flag)
                begin
                    exception_code_reg = 4;
                    mtval_content_reg = faulting_addr;
               //     faulting_pc_reg = current_pc;
            end 
                    
            else if(ecall_flag)
                begin
                    exception_code_reg = 11;
                    mtval_content_reg = 64'b0; 
                //    faulting_pc_reg = current_pc;
                end
 
           else // Default: No exception
                begin
                    exception_code_reg = 0;
                    mtval_content_reg = 64'b0;
//                    faulting_pc_reg = 64'b0;                    
                end
        end
    
       always @(*) begin
               exception_en = 0;
               if(illegal_instr_flag | ebreak_flag | ecall_flag | pc_misaligned_flag | addr_misaligned_flag)
                exception_en = 1;
            end
      
      assign exceptionF = pc_misaligned_flag;      
      assign exceptionD = illegal_instr_flag | ebreak_flag | ecall_flag;
      assign exceptionE = pc_misaligned_flag | addr_misaligned_flag;
      
      always @(*)
      begin
          if (exceptionF)
             faulting_pc_reg = PCF;
          else if(exceptionD)
             faulting_pc_reg = PCD;
          else if (exceptionE)
             faulting_pc_reg = PCE;
          else 
             faulting_pc_reg = 64'b0; 
      end   

endmodule