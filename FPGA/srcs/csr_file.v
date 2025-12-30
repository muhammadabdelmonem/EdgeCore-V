`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/30/2025 05:37:21 PM
// Design Name: 
// Module Name: csr_file
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


module csr_file(
    input clk, 
    input reset_n,
    
    // Exception handling
    input exception_en,
    input [3:0] exception_code,
    input [63:0] faulting_pc,
    input [63:0] mtval_content, 
    
    // CSR access
    input csr_we,
    input [11:0] csr_addrD, // csr address for read
    input [11:0] csr_addrE, // csr address for write
    input [63:0] csr_wdata, // data to write
    input [2:0] csr_op, // operation
    output [63:0] csr_rdata, // read data
     
    // CSR outputs for other stages
    output [63:0] mtvec, // trap_handler_pc
    output [63:0] mtval, // debug
    output [63:0] mcause, // debug
    output [63:0] mepc // MRET instruction
    );
    
    // CSR Addresses
    localparam MTVEC  = 12'h305;
    localparam MEPC   = 12'h341;
    localparam MCAUSE = 12'h342;
    localparam MTVAL  = 12'h343;
    
    reg [63:0] mtvec_reg, mtval_reg, mcause_reg, mepc_reg;
    reg [63:0] csr_rdata_reg;
    
    // Immediate handling
    wire [63:0] zimm = {59'b0, csr_wdata[4:0]}; // zero-extend for immediate
    wire [63:0] source_data = (csr_op[2] ? zimm : csr_wdata); // if csr_op[2] = 1, then source_data will equal the zero extended version (CSSRWI, etc)

    reg [63:0] current_csr, new_value;
    
     
    assign mtvec  = mtvec_reg;
    assign mepc   = mepc_reg;
    assign mcause = mcause_reg;
    assign mtval  = mtval_reg;
    
    assign csr_rdata = csr_rdata_reg;
    
   
    
    always @(posedge clk) //should we make the reset synchronous?
        begin
            if (!reset_n)
                begin
                mtvec_reg  <= 64'b0;
                mepc_reg   <= 64'b0;
                mcause_reg <= 64'b0;
                mtval_reg  <= 64'b0;
                
                end
            else
                begin
                    if (exception_en)
                    begin
                        mtval_reg  <= mtval_content;
                        mcause_reg <= {60'b0, exception_code};
                        mepc_reg   <= faulting_pc;
                    end
                    else if (csr_we)
                    begin
                     // Select current CSR value
                        case(csr_addrE)
                             MTVEC:  current_csr = mtvec_reg;
                             MEPC:   current_csr = mepc_reg;
                             MCAUSE: current_csr = mcause_reg;
                             MTVAL:  current_csr = mtval_reg;
                             default: current_csr = 64'b0;
                        endcase
                        
                         // Compute new CSR value based on csr_operation
                        case(csr_op[1:0]) 
                             2'b01: new_value = source_data;
                             2'b10: new_value = current_csr | source_data;
                             2'b11: new_value = current_csr & ~source_data;
                             default: new_value = current_csr;
                        endcase
                        
                        // Write back
                        case(csr_addrE)
                             MTVEC:  mtvec_reg  <= new_value;
                             MEPC:   mepc_reg   <= new_value;
                             MCAUSE: mcause_reg <= new_value;
                             MTVAL:  mtval_reg  <= new_value;
                        endcase
                        
                    end
                end
        end

   // CSR read
    always @(*) begin
        if (csr_we || exception_en) begin
        case (csr_addrE)
            MTVEC:  csr_rdata_reg = mtvec_reg;
            MEPC:   csr_rdata_reg = mepc_reg;
            MCAUSE: csr_rdata_reg = mcause_reg;
            MTVAL:  csr_rdata_reg = mtval_reg;
            default: csr_rdata_reg = 64'b0;
        endcase
    end
    end
   
endmodule