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
    output [63:0] mepc, // MRET instruction
    
    //interrupt related inputs and outputs 
    input dma_done_irq,  // the dma sending request to interrupt the cpu
    input interrupt_en, //hwen interrupt happens we need this to adjust the registers values (mstatus)
    input mret,   //we use it to readjust the registers values after the interrupt is done or exception
    
    //outputs to the decoder telling it if it is allowed to interrupt or not
    output mstatus_mie_out,
    output mie_dma_out,
    output mip_dma_out
    );
    
    // CSR Addresses
    localparam MSTATUS = 12'h300;   
    localparam MISA    = 12'h301;
    localparam MIE     = 12'h304;
    localparam MTVEC   = 12'h305;
    localparam MEPC    = 12'h341;
    localparam MCAUSE  = 12'h342;
    localparam MTVAL   = 12'h343;
    localparam MIP     = 12'h344;
    
    reg [63:0] mtvec_reg, mtval_reg, mcause_reg, mepc_reg;
    reg [63:0] csr_rdata_reg;
    reg [63:0] misa_reg;
    reg mstatus_mie;  //bit number 3 in mstatus 
    reg mstatus_mpie; //bit number 7 in mstatus
    reg mie_dma;      //bit number 16 in mie //checks if the dma is allowed to issue interrupt or not
    reg mip_dma;      //bit number 16 in mip //checks if an interrupt pinding req is here or not (only hardware can set this bit)
    
    wire [63:0] mstatus_full_reg = {51'b0,2'b11,3'b0,mstatus_mpie,3'b0,mstatus_mie,3'b0};
    wire [63:0] mip_full_reg = {47'b0,mip_dma,16'b0};
    wire [63:0] mie_full_reg = {47'b0,mie_dma,16'b0};
    
    // Immediate handling
    wire [63:0] zimm = {59'b0, csr_wdata[4:0]}; // zero-extend for immediate
    wire [63:0] source_data = (csr_op[2] ? zimm : csr_wdata); // if csr_op[2] = 1, then source_data will equal the zero extended version (CSSRWI, etc)

    reg [63:0] current_csr, new_value;
    
     
    assign mtvec  = mtvec_reg;
    assign mepc   = mepc_reg;
    assign mcause = mcause_reg;
    assign mtval  = mtval_reg;
    
    assign csr_rdata = csr_rdata_reg;
    
    assign mstatus_mie_out = mstatus_mie;
    assign mie_dma_out = mie_dma;
    assign mip_dma_out = mip_dma;
   
    
    always @(posedge clk) //should we make the reset synchronous?
        begin
            if (!reset_n)
                begin
                mtvec_reg    <= 64'b0;
                mepc_reg     <= 64'b0;
                mcause_reg   <= 64'b0;
                mtval_reg    <= 64'b0;
                mstatus_mie  <= 1'b0; 
                mstatus_mpie <= 1'b1;
                mie_dma      <= 1'b0;     
                mip_dma      <= 1'b0;       
                misa_reg     <={2'b10,49'b0,1'b1,3'b0,1'b1,8'b0};
                end
            else
                begin
                    if (exception_en)
                    begin
                        mtval_reg  <= mtval_content;
                        mcause_reg <= {60'b0, exception_code};
                        mepc_reg   <= faulting_pc;
                    end else if(interrupt_en)
                    begin
                        mtval_reg  <= 64'b0;
                        mcause_reg <= {1'b1, 47'b0, 16'd16}; // bit63=1 means interrupt, cause=16(DMA)
                        mepc_reg   <= faulting_pc;
                    end
                    
                    //the dma interrupt request sets mip to 1 and when it happens it go back to zero
                    if(dma_done_irq)
                        mip_dma <= 1'b1;
                    else if(interrupt_en & ~dma_done_irq)
                        mip_dma <= 1'b0;
                        
                    if(exception_en ||interrupt_en)
                    begin
                        mstatus_mpie <= mstatus_mie; //save previous mie value
                        mstatus_mie <= 1'b0; //disable interrupts
                    end else if (mret) begin
                        mstatus_mpie <= 1'b1; 
                        mstatus_mie <= mstatus_mpie; //restore the previous value 
                    end
                    
                    
                    else if (csr_we)
                    begin
                     // Select current CSR value
                        case(csr_addrE)
                             MSTATUS: current_csr = mstatus_full_reg;
                             MISA:    current_csr = misa_reg;
                             MIE:     current_csr = mie_full_reg;
                             MTVEC:   current_csr = mtvec_reg;
                             MEPC:    current_csr = mepc_reg;
                             MCAUSE:  current_csr = mcause_reg;
                             MTVAL:   current_csr = mtval_reg;
                             MIP:     current_csr = mip_full_reg;
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
                             MSTATUS:begin
                                    mstatus_mie  <= new_value[3];
                                    mstatus_mpie <= new_value[7];
                             end
                             MISA:;
                             MIE: mie_dma <= new_value[16];
                             MTVEC:  mtvec_reg  <= new_value;
                             MEPC:   mepc_reg   <= new_value;
                             MCAUSE: mcause_reg <= new_value;
                             MTVAL:  mtval_reg  <= new_value;
                             MIP:begin
                                if(~dma_done_irq && new_value[16] == 1'b0)
                                    mip_dma <= 1'b0;  //software can only clear it 
                             end
                        endcase
                        
                    end
                end
        end

   // CSR read
    always @(*) begin
        if (csr_we || exception_en || interrupt_en) begin
        case (csr_addrE)
            MSTATUS: csr_rdata_reg = mstatus_full_reg;
            MISA:    csr_rdata_reg = misa_reg;
            MIE:     csr_rdata_reg = mie_full_reg;
            MTVEC:   csr_rdata_reg = mtvec_reg;
            MEPC:    csr_rdata_reg = mepc_reg;
            MCAUSE:  csr_rdata_reg = mcause_reg;
            MTVAL:   csr_rdata_reg = mtval_reg;
            MIP:     csr_rdata_reg = mip_full_reg;
            default: csr_rdata_reg = 64'b0;
        endcase
    end
    end
   
endmodule
