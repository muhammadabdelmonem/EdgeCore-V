`timescale 1ns / 1ps
module Register_File(
    input  clk,
    input  rst,
    input  WE3,
    input  MAC_EN,
    input  [4:0] A1,
    input  [4:0] A2,
    input  [4:0] A3,
    //input  [4:0] A3_Mac,
    input  [63:0] WD3,
    output [63:0] RD1,
    output [63:0] RD2,
    output [63:0] RD3
);

    reg [63:0] reg_file [0:31];
    integer i;

    always @(negedge clk) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1)
                reg_file[i] <= 64'd0;
        end else begin
            reg_file[0] <= 64'd0;
            if (WE3 && (A3 != 0))
                reg_file[A3] <= WD3;
        end
    end

    assign RD1 = (A1 != 0) ? reg_file[A1] : 64'd0;
    assign RD2 = (A2 != 0) ? reg_file[A2] : 64'd0;
    assign RD3 = (A3 != 0 && MAC_EN) ? reg_file[A3] : 64'd0;

endmodule
