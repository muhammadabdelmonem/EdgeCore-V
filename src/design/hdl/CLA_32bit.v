`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date: 10/04/2025 03:32:22 PM
// Design Name: 
// Module Name: CLA_32bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:      Two-Level Carry Lookahead Adder.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CLA_32bit(
    input  [31:0] a,
    input  [31:0] b,
    input  addn_sub,  // 0=add, 1=sub
    output [31:0] sum,
    output cout
);
    localparam BLOCKS = 8;

    wire [31:0] b_eff = b ^ {32{addn_sub}};
    wire [BLOCKS-1:0] Gg, Pg;   // block generate/propagate
    wire [BLOCKS:0] Cblock;   // block carries
    wire [31:0] sum_internal;

    assign Cblock[0] = addn_sub; // initial carry in

    // Block-Level Carry Lookahead 
    assign Cblock[1] = Gg[0] 
                     | (Pg[0] & Cblock[0]);

    assign Cblock[2] = Gg[1] 
                     | (Pg[1] & Gg[0]) 
                     | (Pg[1] & Pg[0] & Cblock[0]);

    assign Cblock[3] = Gg[2] 
                     | (Pg[2] & Gg[1]) 
                     | (Pg[2] & Pg[1] & Gg[0]) 
                     | (Pg[2] & Pg[1] & Pg[0] & Cblock[0]);

    assign Cblock[4] = Gg[3] 
                     | (Pg[3] & Gg[2]) 
                     | (Pg[3] & Pg[2] & Gg[1]) 
                     | (Pg[3] & Pg[2] & Pg[1] & Gg[0]) 
                     | (Pg[3] & Pg[2] & Pg[1] & Pg[0] & Cblock[0]);

    assign Cblock[5] = Gg[4] 
                     | (Pg[4] & Gg[3]) 
                     | (Pg[4] & Pg[3] & Gg[2]) 
                     | (Pg[4] & Pg[3] & Pg[2] & Gg[1]) 
                     | (Pg[4] & Pg[3] & Pg[2] & Pg[1] & Gg[0]) 
                     | (Pg[4] & Pg[3] & Pg[2] & Pg[1] & Pg[0] & Cblock[0]);

    assign Cblock[6] = Gg[5] 
                     | (Pg[5] & Gg[4]) 
                     | (Pg[5] & Pg[4] & Gg[3]) 
                     | (Pg[5] & Pg[4] & Pg[3] & Gg[2]) 
                     | (Pg[5] & Pg[4] & Pg[3] & Pg[2] & Gg[1]) 
                     | (Pg[5] & Pg[4] & Pg[3] & Pg[2] & Pg[1] & Gg[0]) 
                     | (Pg[5] & Pg[4] & Pg[3] & Pg[2] & Pg[1] & Pg[0] & Cblock[0]);

    assign Cblock[7] = Gg[6] 
                     | (Pg[6] & Gg[5]) 
                     | (Pg[6] & Pg[5] & Gg[4]) 
                     | (Pg[6] & Pg[5] & Pg[4] & Gg[3]) 
                     | (Pg[6] & Pg[5] & Pg[4] & Pg[3] & Gg[2]) 
                     | (Pg[6] & Pg[5] & Pg[4] & Pg[3] & Pg[2] & Gg[1]) 
                     | (Pg[6] & Pg[5] & Pg[4] & Pg[3] & Pg[2] & Pg[1] & Gg[0]) 
                     | (Pg[6] & Pg[5] & Pg[4] & Pg[3] & Pg[2] & Pg[1] & Pg[0] & Cblock[0]);

    assign Cblock[8] = Gg[7] 
                     | (Pg[7] & Gg[6]) 
                     | (Pg[7] & Pg[6] & Gg[5]) 
                     | (Pg[7] & Pg[6] & Pg[5] & Gg[4]) 
                     | (Pg[7] & Pg[6] & Pg[5] & Pg[4] & Gg[3]) 
                     | (Pg[7] & Pg[6] & Pg[5] & Pg[4] & Pg[3] & Gg[2]) 
                     | (Pg[7] & Pg[6] & Pg[5] & Pg[4] & Pg[3] & Pg[2] & Gg[1]) 
                     | (Pg[7] & Pg[6] & Pg[5] & Pg[4] & Pg[3] & Pg[2] & Pg[1] & Gg[0]) 
                     | (Pg[7] & Pg[6] & Pg[5] & Pg[4] & Pg[3] & Pg[2] & Pg[1] & Pg[0] & Cblock[0]);

    // Instantiate the 4-bit CLAs 
    genvar i;
    generate
        for (i=0; i<BLOCKS; i=i+1) begin : CLA_BLOCKS
            CLA_4bit cla4 (
            .a(a[4*i+3 : 4*i]),
            .b(b_eff[4*i+3 : 4*i]),
            .cin(Cblock[i]),
            .sum(sum_internal[4*i+3 : 4*i]),
            .cout(),     // we don't need local cout, we use Gg
            .Gg(Gg[i]),
            .Pg(Pg[i])
            );
        end
    endgenerate

    assign sum  = sum_internal;
    assign cout = Cblock[8]; // final carry out
endmodule
