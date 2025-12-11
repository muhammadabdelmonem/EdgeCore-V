`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/19/2025 12:43:27 AM
// Design Name: 
// Module Name: Forwarding_Unit
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

module Forwarding_Unit(
    input             RegWriteM,
    input             RegWriteW,
    input             reset_n,
    input      [4:0]  Rs1E,
    input      [4:0]  Rs2E,
    input      [4:0]  RdM,
    input      [4:0]  RdW,
    output reg [1:0]  ForwardAE,
    output reg [1:0]  ForwardBE
);

    always @(*) begin
      if(~reset_n) begin
       ForwardAE =2'b00;
       ForwardBE =2'b00;
      end
      else begin
      // Forwarding for A
        if (((Rs1E == RdM) && RegWriteM) && (Rs1E != 0)) begin
            ForwardAE = 2'b10;
        end
        else if (((Rs1E == RdW) && RegWriteW) && (Rs1E != 0)) begin
            ForwardAE = 2'b01;
        end
        else begin
            ForwardAE = 2'b00;
        end

        // Forwarding for B
        if (((Rs2E == RdM) && RegWriteM) && (Rs2E != 0)) begin
            ForwardBE = 2'b10;
        end
        else if (((Rs2E == RdW) && RegWriteW) && (Rs2E != 0)) begin
            ForwardBE = 2'b01;
        end
        else begin
            ForwardBE = 2'b00;
        end
      
      end
        
    end

endmodule
