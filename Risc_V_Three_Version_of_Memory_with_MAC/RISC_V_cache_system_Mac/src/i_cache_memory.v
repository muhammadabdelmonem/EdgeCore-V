`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 03:38:37 PM
// Design Name: 
// Module Name: I_Cache_Memory
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


module I_Cache_Memory(
    input  clk,
    input  reset_n,
    
    // CPU Interface 
    output reg [31:0] data_read,     // To CPU: The requested read data
    // Controller Interface
    input         cache_r_en,
    input   [1:0] way_sel,
    input   [5:0] cache_set_sel,
    input   [5:0] cache_offset,
    output        r_valid, // To Controller: Signals refill is complete and data is stored
    
    // AXI Interface (from Main Memory)
    input  [511:0] axi_data_line,
    input          axi_line_valid
    
);

    // Cache memory arrays - 4 ways x 64 sets x 64 bytes (512 bits)
    reg [511:0] cache_data_way0 [0:63];
    reg [511:0] cache_data_way1 [0:63];
    reg [511:0] cache_data_way2 [0:63];
    reg [511:0] cache_data_way3 [0:63];
    
    //internal regs
    reg [511:0] selected_line;
    reg r_valid_pulse;  // Internal register for the delayed r_valid pulse
    assign r_valid = r_valid_pulse;

    
    // This block handles reads from the cache requested by the CPU.
    // It has a one-cycle latency, which the controller is designed for.
    always @(posedge clk) begin
        
        if (cache_r_en) begin
            // Select the correct 512-bit line based on the controller's signals
            case (way_sel)
                2'b00: selected_line = cache_data_way0[cache_set_sel];
                2'b01: selected_line = cache_data_way1[cache_set_sel];
                2'b10: selected_line = cache_data_way2[cache_set_sel];
                2'b11: selected_line = cache_data_way3[cache_set_sel];
                default: selected_line = 512'b0;
            endcase

            // Extract the specific bytes from the line based on offset and size
            data_read <= selected_line[cache_offset * 8 +: 32];
        end 
    end
    
    // Unified Synchronous Refill Logic 
    // This single block handles all writes to the cache RAMs, preventing conflicts.
    always @(posedge clk) begin
        if (~reset_n) begin
            r_valid_pulse <= 1'b0;
        end else begin
            // Default to de-asserting the pulse
            r_valid_pulse <= 1'b0;

            // Priority given to AXI refill, as it's part of a miss-handling cycle
            if (axi_line_valid) begin
                // AXI line refill (full line write)
                case (way_sel)
                    2'b00: cache_data_way0[cache_set_sel] <= axi_data_line;
                    2'b01: cache_data_way1[cache_set_sel] <= axi_data_line;
                    2'b10: cache_data_way2[cache_set_sel] <= axi_data_line;
                    2'b11: cache_data_way3[cache_set_sel] <= axi_data_line;
                endcase
                // Schedule the "refill done" pulse for the next cycle
                r_valid_pulse <= 1'b1;
            end
        end
    end
    
endmodule
