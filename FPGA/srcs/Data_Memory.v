`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2025 01:16:49 PM
// Design Name: 
// Module Name: Data_Memory
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


module Data_Memory
    #(parameter depth = 100)(
    input  clk, 
    input  WE ,
    input  [63:0] A  , // Address 
    input  [63:0] WD ,
    input  [2:0]DataSizeCon,
    output [63:0] RD 
    );
    reg  [7:0] DATA_MEM [0:depth-1] ; //[7:0] to be word addressable 
    
//    integer i;
//    initial
//    begin
//        for(i =0 ; i<depth ; i=i+1)
//            DATA_MEM[i] = 0 ;
//    end
    reg [63:0] RD_reg ;
    
    //Store(WRITE)logic

    always @(posedge clk) 
    begin
        if (WE) begin
            case (DataSizeCon)
            3'b000: // SB
                begin 
                DATA_MEM[A] <= WD[7:0];
                end
            3'b001: // SH
                begin 
                DATA_MEM[A]   <= WD[7:0];
                DATA_MEM[A+1] <= WD[15:8];
                end
            3'b010: // SW
                begin 
                DATA_MEM[A]   <= WD[7:0];
                DATA_MEM[A+1] <= WD[15:8];
                DATA_MEM[A+2] <= WD[23:16];
                DATA_MEM[A+3] <= WD[31:24];
                end
            3'b011: // SD
                begin 
                DATA_MEM[A]   <= WD[7:0];
                DATA_MEM[A+1] <= WD[15:8];
                DATA_MEM[A+2] <= WD[23:16];
                DATA_MEM[A+3] <= WD[31:24];
                DATA_MEM[A+4] <= WD[39:32];
                DATA_MEM[A+5] <= WD[47:40];
                DATA_MEM[A+6] <= WD[55:48];
                DATA_MEM[A+7] <= WD[63:56];
                end
            default: ;
            endcase
        end
    end

    //Load(READ)logic
    always @(*) 
    begin
        case (DataSizeCon)
            3'b000: RD_reg = {{56{DATA_MEM[A][7]}}, DATA_MEM[A]};  // LB
            3'b001: RD_reg = {{48{DATA_MEM[A+1][7]}}, DATA_MEM[A+1], DATA_MEM[A]};  // LH
            3'b010: RD_reg = {{32{DATA_MEM[A+3][7]}}, DATA_MEM[A+3], DATA_MEM[A+2], DATA_MEM[A+1], DATA_MEM[A]}; // LW
            3'b011: RD_reg = {DATA_MEM [A+7],DATA_MEM [A+6],DATA_MEM [A+5],DATA_MEM [A+4],DATA_MEM [A+3],DATA_MEM [A+2],DATA_MEM [A+1],DATA_MEM [A]}; // LD
            3'b100: RD_reg = {56'b0, DATA_MEM[A]};  // LBU
            3'b101: RD_reg = {48'b0, DATA_MEM[A+1], DATA_MEM[A]};  // LHU
            3'b110: RD_reg = {32'b0, DATA_MEM[A+3], DATA_MEM[A+2], DATA_MEM[A+1], DATA_MEM[A]}; // LWU
            default: RD_reg = 64'b0;
        endcase
    end
    assign  RD = RD_reg ;
endmodule

