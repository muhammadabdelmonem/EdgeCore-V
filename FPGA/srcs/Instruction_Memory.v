module Instruction_Memory(
    input  [63:0] A,  // Byte Address of instruction (PC)
    output reg [31:0] RD 
    );
    
    // The ROM is modeled as a purely combinational function:
    // RD is determined solely by the input address A.
    always @(*) begin
        // Default to NOP (addi x0, x0, 0) for safety
        RD = 32'h00000013; 

        // We use the byte address A to select the 32-bit instruction.
        // Since instructions are 4 bytes, the address must be a multiple of 4.
        // The case statement uses the lower bits of A to select the instruction.
        case (A[7:0]) 
            // Address 0x00: 00000097 (auipc x1, 0)
            8'h00: RD = 32'h00000097; 
            
            // Address 0x04: 04008093 (addi x1, x1, 4)
            8'h04: RD = 32'h04008093; 
            
            // Address 0x08: 30509073 (csrrw x0, mstatus, x1)
            8'h08: RD = 32'h30509073; 
            
            // Address 0x0C: 00500113 (addi x2, x1, 5)
            8'h0C: RD = 32'h00500113; 
            
            // Address 0x10: 00100193 (addi x3, x0, 1)
            8'h10: RD = 32'h00100193; 
            
            // Address 0x14: 00311463 (beq x2, x3, 0x00000000)
            8'h14: RD = 32'h00311463; 
            
            // Address 0x18: 00210213 (addi x4, x4, 2)
            8'h18: RD = 32'h00210213; 
            
            // Address 0x1C: 00000073 (ecall)
            8'h1C: RD = 32'h00000073; 
            
            // Address 0x20: 00410213 (addi x4, x4, 4)
            8'h20: RD = 32'h00410213; 
            
            // Addresses 0x24 to 0x38 (6 NOPs: 00000013)
            8'h24: RD = 32'h00000013; 
            8'h28: RD = 32'h00000013; 
            8'h2C: RD = 32'h00000013; 
            8'h30: RD = 32'h00000013; 
            8'h34: RD = 32'h00000013; 
            8'h38: RD = 32'h00000013; 
            
            // Address 0x3C: 0000006f (jal x0, 0x00000000)
            8'h3C: RD = 32'h0000006f; 
            
            // Address 0x40: 34202573 (csrrw x10, mscratch, x10)
            8'h40: RD = 32'h34202573; 
            
            // Address 0x44: 341025f3 (csrrw x11, mtvec, x10)
            8'h44: RD = 32'h341025f3; 
            
            // Address 0x48: 34302673 (csrrw x12, mepc, x10)
            8'h48: RD = 32'h34302673; 
            
            // Address 0x4C: 00b00693 (addi x13, x0, 11)
            8'h4C: RD = 32'h00b00693; 
            
            // Address 0x50: 06d50463 (beq x13, x14, 0x00000000)
            8'h50: RD = 32'h00d50c63; 
            
            // Address 0x54: 00400693 (addi x13, x0, 4)
            8'h54: RD = 32'h00400693; 
            
            // Address 0x58: 06d50a63 (beq x13, x14, 0x00000000)
            8'h58: RD = 32'h00d50e63; 
            
            // Address 0x5C: 00200693 (addi x13, x0, 2)
            8'h5C: RD = 32'h00200693; 
            
            // Address 0x60: 08d50063 (beq x13, x14, 0x00000000)
            8'h60: RD = 32'h02d50063; 
            
            // Address 0x64: 0280006f (jal x0, 0x00000000)
            8'h64: RD = 32'h0280006f; 
            
            // Address 0x68: 00458593 (addi x11, x11, 4)
            8'h68: RD = 32'h00458593; 
            
            // Address 0x6C: 34159073 (csrrw x10, mtvec, x11)
            8'h6C: RD = 32'h34159073; 
            
            // Address 0x70: 01c0006f (jal x0, 0x00000000)
            8'h70: RD = 32'h01c0006f; 
            
            // Address 0x74: 00458593 (addi x11, x11, 4)
            8'h74: RD = 32'h00458593; 
            
            // Address 0x78: 34159073 (csrrw x10, mtvec, x11)
            8'h78: RD = 32'h34159073; 
            
            // Address 0x7C: 0100006f (jal x0, 0x00000000)
            8'h7C: RD = 32'h0100006f; 
            
            // Address 0x80: 00458593 (addi x11, x11, 4)
            8'h80: RD = 32'h00458593; 
            
            // Address 0x84: 34159073 (csrrw x10, mtvec, x11)
            8'h84: RD = 32'h34159073; 
            
            // Address 0x88: 0040006f (jal x0, 0x00000000)
            8'h88: RD = 32'h0040006f; 
            
            // Address 0x8C: 30200073 (mret)
            8'h8C: RD = 32'h30200073; 
            
            // Address 0x90: AABBCCDD (End Marker)
            // Note: Your byte order was DD CC BB AA, which is little-endian.
            // When reading a 32-bit word, the result is 0xAABBCCDD.
            8'h90: RD = 32'hAABBCCDD; 
            
            default: RD = 32'h00000013; // NOP
        endcase
    end
endmodule
