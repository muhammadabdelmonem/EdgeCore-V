`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 01:05:37 PM
// Design Name: 
// Module Name: Cache_Memory
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


module Cache_Memory(
    input  clk,
    input  reset_n,
    
    // CPU Interface 
    input  [63:0] data_write,
    input  [2:0]  size,
    
    // Controller Interface
    input         cache_r_en,
    input         cache_w_en,
    input   [1:0] way_sel,
    input   [5:0] cache_set_sel,
    input   [5:0] cache_offset,
    input         victim_enable,
    output        r_valid, // To Controller: Signals refill is complete and data is stored
    
    // AXI Interface (from Main Memory)
    input  [511:0] axi_data_line,
    input          axi_line_valid,
    
    // Outputs
    output reg [63:0] data_read,     // To CPU: The requested read data
    output reg [511:0] victim_data    // To AXI: The line being evicted
);

    // Cache memory arrays - 4 ways x 64 sets x 64 bytes (512 bits)
    reg [511:0] cache_data_way0 [0:63];
    reg [511:0] cache_data_way1 [0:63];
    reg [511:0] cache_data_way2 [0:63];
    reg [511:0] cache_data_way3 [0:63];
    
    //internal regs
    reg [511:0] selected_line;
    reg [63:0] raw_data;
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
            case (size)
                3'b000, 3'b100: raw_data = selected_line[cache_offset * 8 +: 8];   // Byte
                3'b001, 3'b101: raw_data = selected_line[cache_offset * 8 +: 16];  // Half-word
                3'b010, 3'b110: raw_data = selected_line[cache_offset * 8 +: 32];  // Word
                3'b011:         raw_data = selected_line[cache_offset * 8 +: 64];  // Double-word
                default:        raw_data = 64'b0;
            endcase

            // Sign-extend or zero-extend the result and register it to the output
            case (size)
                3'b000:  data_read  <= {{56{raw_data[7]}}, raw_data[7:0]};   // Signed Byte
                3'b001:  data_read  <= {{48{raw_data[15]}}, raw_data[15:0]}; // Signed Half-word
                3'b010:  data_read  <= {{32{raw_data[31]}}, raw_data[31:0]}; // Signed Word
                3'b011:  data_read  <= raw_data;                             // Double-word
                3'b100:  data_read  <= {{56{1'b0}}, raw_data[7:0]};          // Unsigned Byte
                3'b101:  data_read  <= {{48{1'b0}}, raw_data[15:0]};         // Unsigned Half-word
                3'b110:  data_read  <= {{32{1'b0}}, raw_data[31:0]};         // Unsigned Word
                default: data_read  <= 64'b0;
            endcase
        end 
    end
    
    // Unified Synchronous Write Path & Refill Logic 
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
            else if (cache_w_en) begin
                // CPU write (sub-word write)
                case (way_sel)
                    2'b00: case (size)
                        3'b000: cache_data_way0[cache_set_sel][cache_offset*8 +: 8]   <= data_write[7:0];
                        3'b001: cache_data_way0[cache_set_sel][cache_offset*8 +: 16]  <= data_write[15:0];
                        3'b010: cache_data_way0[cache_set_sel][cache_offset*8 +: 32]  <= data_write[31:0];
                        3'b011: cache_data_way0[cache_set_sel][cache_offset*8 +: 64]  <= data_write;
                    endcase
                    2'b01: case (size)
                        3'b000: cache_data_way1[cache_set_sel][cache_offset*8 +: 8]   <= data_write[7:0];
                        3'b001: cache_data_way1[cache_set_sel][cache_offset*8 +: 16]  <= data_write[15:0];
                        3'b010: cache_data_way1[cache_set_sel][cache_offset*8 +: 32]  <= data_write[31:0];
                        3'b011: cache_data_way1[cache_set_sel][cache_offset*8 +: 64]  <= data_write;
                    endcase
                    2'b10: case (size)
                        3'b000: cache_data_way2[cache_set_sel][cache_offset*8 +: 8]   <= data_write[7:0];
                        3'b001: cache_data_way2[cache_set_sel][cache_offset*8 +: 16]  <= data_write[15:0];
                        3'b010: cache_data_way2[cache_set_sel][cache_offset*8 +: 32]  <= data_write[31:0];
                        3'b011: cache_data_way2[cache_set_sel][cache_offset*8 +: 64]  <= data_write;
                    endcase
                    2'b11: case (size)
                        3'b000: cache_data_way3[cache_set_sel][cache_offset*8 +: 8]   <= data_write[7:0];
                        3'b001: cache_data_way3[cache_set_sel][cache_offset*8 +: 16]  <= data_write[15:0];
                        3'b010: cache_data_way3[cache_set_sel][cache_offset*8 +: 32]  <= data_write[31:0];
                        3'b011: cache_data_way3[cache_set_sel][cache_offset*8 +: 64]  <= data_write;
                    endcase
                endcase
            end
        end
    end
    
    //  Combinational Victim Data Output 
    // This can remain combinational as it's only used during a write-back,
    // which is a multi-cycle operation, so timing is not as tight.
    always @(*) begin
        if (victim_enable) begin
            case (way_sel)
                2'b00: victim_data = cache_data_way0[cache_set_sel];
                2'b01: victim_data = cache_data_way1[cache_set_sel];
                2'b10: victim_data = cache_data_way2[cache_set_sel];
                2'b11: victim_data = cache_data_way3[cache_set_sel];
                default: victim_data = 512'b0;
            endcase
        end else begin
            victim_data = 512'b0;
        end
    end
    
    
endmodule
