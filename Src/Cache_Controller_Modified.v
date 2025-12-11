`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/29/2025 04:06:55 PM
// Design Name: 
// Module Name: Cache_Controller_Modified
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


module Cache_Controller_Modified(
    input  clk,
    input  reset_n, // Active-low reset

    // CPU Interface
    input  [63:0] cpu_address,
    input         cpu_r_en,
    input         cpu_w_en,
    //input  [2:0]  cpu_size,
    output reg    stall,
    output reg    cpu_data_valid, // Signals to the CPU that read data is valid

    // Cache Memory Interface
    input             r_valid, //from the cache me to the controller indecating that the data is already refilled 
    output reg        cache_r_en,
    output reg        cache_w_en,
    output reg [5:0]  cache_set_sel,
    output reg [1:0]  cache_way_sel,
    output reg [5:0]  cache_offset,
    output reg        victim_enable,

    // Main Memory Interface (Axi interface)
    output reg        mem_w_en,
    output reg [63:0] mem_w_add,
    output reg [31:0] mem_w_size,
    input             mem_w_valid, //from the axi interface to the controller indecating that the data is wroteback successfylly
    
    output reg        mem_r_en,
    output reg [63:0] mem_r_add
    
);

    // Cache Parameters
    parameter BLOCK_SIZE = 64;
    parameter NUM_WAYS   = 4;
    parameter NUM_SETS   = 64;

    // OPTIMIZED State Definitions (4 States)
    parameter [1:0] IDLE         = 2'b00;
    parameter [1:0] LOOKUP       = 2'b01; // Stage 1: Register address, check tags, handle hits
    parameter [1:0] VICTIM_WRITE = 2'b10; // Stage 2 (Miss): Write back dirty victim
    parameter [1:0] FETCH        = 2'b11; // Stage 3 (Miss): Fetch new line and replay

    reg [1:0] current_state, next_state;

    // Internal Registers for pipelining the request
    reg [63:0] addr_reg;
    //reg [2:0]  size_reg;
    reg        is_write_op_reg;
    reg [1:0]  victim_way_reg; // Registered victim for use in WRITE/FETCH states

    // Cache metadata arrays
    reg [NUM_SETS-1:0] valid_way0;
    reg [NUM_SETS-1:0] valid_way1;
    reg [NUM_SETS-1:0] valid_way2;
    reg [NUM_SETS-1:0] valid_way3;
    
    reg [NUM_SETS-1:0] dirty_way0;
    reg [NUM_SETS-1:0] dirty_way1;
    reg [NUM_SETS-1:0] dirty_way2;
    reg [NUM_SETS-1:0] dirty_way3;
    
    reg [51:0] tags_way0 [0:NUM_SETS-1];
    reg [51:0] tags_way1 [0:NUM_SETS-1];
    reg [51:0] tags_way2 [0:NUM_SETS-1];
    reg [51:0] tags_way3 [0:NUM_SETS-1];
    
    // Counter-based LRU: 2 bits per way, 00 = LRU (oldest), 11 = MRU (newest)
    reg [1:0] lru_counter_way0 [0:NUM_SETS-1];
    reg [1:0] lru_counter_way1 [0:NUM_SETS-1];
    reg [1:0] lru_counter_way2 [0:NUM_SETS-1];
    reg [1:0] lru_counter_way3 [0:NUM_SETS-1];

    // Address decomposition from REGISTERED address
    wire [51:0] tag_from_reg   = addr_reg[63:12];
    wire [5:0]  index_from_reg = addr_reg[11:6];
    wire [5:0]  offset_from_reg= addr_reg[5:0];

    // Combinational Logic for Decision Making

    // Hit detection (based on registered address)
    wire hit_way0 = valid_way0[index_from_reg] && (tags_way0[index_from_reg] == tag_from_reg);
    wire hit_way1 = valid_way1[index_from_reg] && (tags_way1[index_from_reg] == tag_from_reg);
    wire hit_way2 = valid_way2[index_from_reg] && (tags_way2[index_from_reg] == tag_from_reg);
    wire hit_way3 = valid_way3[index_from_reg] && (tags_way3[index_from_reg] == tag_from_reg);
    wire is_hit = hit_way0 | hit_way1 | hit_way2 | hit_way3;
    wire [1:0] hit_way = hit_way0 ? 2'b00 : (hit_way1 ? 2'b01 : (hit_way2 ? 2'b10 : 2'b11));

    // Predictive (combinational) victim selection for immediate decision making
    wire [1:0] potential_victim_way = get_victim_way(index_from_reg);

    // Check if the *potential* victim is dirty to make a correct next-state decision
    wire victim_is_dirty = (potential_victim_way == 2'b00 && valid_way0[index_from_reg] && dirty_way0[index_from_reg]) ||
                           (potential_victim_way == 2'b01 && valid_way1[index_from_reg] && dirty_way1[index_from_reg]) ||
                           (potential_victim_way == 2'b10 && valid_way2[index_from_reg] && dirty_way2[index_from_reg]) ||
                           (potential_victim_way == 2'b11 && valid_way3[index_from_reg] && dirty_way3[index_from_reg]);

    // State logic 
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if (cpu_r_en || cpu_w_en)
                    next_state = LOOKUP;
            LOOKUP:
                if (is_hit)
                    next_state = IDLE;
                else // It's a miss, use the correctly calculated victim_is_dirty
                    next_state = victim_is_dirty ? VICTIM_WRITE : FETCH;
            VICTIM_WRITE:
                if (mem_w_valid)
                    next_state = FETCH;
            FETCH:
                if (r_valid)
                    next_state = IDLE;
        endcase
    end

    //Main Control Logic (Outputs and Registers) 
    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all outputs
            stall <= 1'b0;
            cpu_data_valid <= 1'b0;
            cache_r_en <= 1'b0;
            cache_w_en <= 1'b0;
            victim_enable <= 1'b0;
            mem_w_en <= 1'b0;
            mem_r_en <= 1'b0;
            mem_w_size <= BLOCK_SIZE;
            
            // Reset internal registers
            addr_reg <= 64'b0;
            is_write_op_reg <= 1'b0;

            // Initialize cache metadata
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                valid_way0[i] <= 1'b0;
                valid_way1[i] <= 1'b0;
                valid_way2[i] <= 1'b0;
                valid_way3[i] <= 1'b0;
                
                dirty_way0[i] <= 1'b0;
                dirty_way1[i] <= 1'b0;
                dirty_way2[i] <= 1'b0;
                dirty_way3[i] <= 1'b0;
                
                lru_counter_way0[i] <= 2'b00;
                lru_counter_way1[i] <= 2'b01;
                lru_counter_way2[i] <= 2'b10;
                lru_counter_way3[i] <= 2'b11;
            end
        end else begin
            // Default assignments for control signals each cycle
            stall <= (current_state != IDLE);
            cpu_data_valid <= 1'b0;
            cache_r_en <= 1'b0;
            cache_w_en <= 1'b0;
            victim_enable <= 1'b0;
            mem_w_en <= 1'b0;
            mem_r_en <= 1'b0;

            case (current_state)
                IDLE:
                    // If a new request comes in, latch it and prepare for LOOKUP
                    if (cpu_r_en || cpu_w_en) begin
                        addr_reg <= cpu_address;
                        //size_reg <= cpu_size;
                        is_write_op_reg <= cpu_w_en;
                    end

                LOOKUP: begin
                    // On a hit, perform the access and update metadata
                    if (is_hit) begin
                        cache_r_en <= !is_write_op_reg;
                        cache_w_en <= is_write_op_reg;
                        cache_set_sel <= index_from_reg;
                        cache_way_sel <= hit_way;
                        cache_offset <= offset_from_reg;
                        
                        if (!is_write_op_reg) begin
                            cpu_data_valid <= 1'b1;
                        end

                        update_lru_counters(index_from_reg, hit_way);
                        if (is_write_op_reg) begin
                            case (hit_way)
                                2'b00: dirty_way0[index_from_reg] <= 1'b1;
                                2'b01: dirty_way1[index_from_reg] <= 1'b1;
                                2'b10: dirty_way2[index_from_reg] <= 1'b1;
                                2'b11: dirty_way3[index_from_reg] <= 1'b1;
                            endcase
                        end
                    end else begin // On a miss, register the chosen victim for later states
                        victim_way_reg <= potential_victim_way;
                    end
                end

                VICTIM_WRITE: begin
                    mem_w_en <= 1'b1;
                    victim_enable <= 1'b1;
                    cache_set_sel <= index_from_reg;
                    cache_way_sel <= victim_way_reg; // Use the stable registered value
                    case (victim_way_reg)
                        2'b00: mem_w_add <= {tags_way0[index_from_reg], index_from_reg, 6'b0};
                        2'b01: mem_w_add <= {tags_way1[index_from_reg], index_from_reg, 6'b0};
                        2'b10: mem_w_add <= {tags_way2[index_from_reg], index_from_reg, 6'b0};
                        2'b11: mem_w_add <= {tags_way3[index_from_reg], index_from_reg, 6'b0};
                    endcase
                    if (mem_w_valid) begin
                        mem_w_en <= 1'b0;
                        victim_enable <= 1'b0;
                    end
                end
                
                FETCH: begin
                    // If data arrives this cycle, handle refill and replay the original operation
                    if (r_valid) begin
                        //disable the fetching request
                        mem_r_en <= 1'b0;
                        
                        // Provide select signals to the Cache_Memory module for writing
                        cache_set_sel <= index_from_reg;
                        cache_way_sel <= victim_way_reg;

                        // Update metadata for the newly filled line
                        update_lru_counters(index_from_reg, victim_way_reg);
                        case (victim_way_reg)
                            2'b00: begin 
                                    valid_way0[index_from_reg] <= 1'b1; 
                                    tags_way0[index_from_reg] <= tag_from_reg; 
                                    dirty_way0[index_from_reg] <= is_write_op_reg; 
                                    end
                            2'b01: begin 
                                    valid_way1[index_from_reg] <= 1'b1; 
                                    tags_way1[index_from_reg] <= tag_from_reg; 
                                    dirty_way1[index_from_reg] <= is_write_op_reg; 
                                    end
                            2'b10: begin 
                                    valid_way2[index_from_reg] <= 1'b1; 
                                    tags_way2[index_from_reg] <= tag_from_reg; 
                                    dirty_way2[index_from_reg] <= is_write_op_reg; 
                                    end
                            2'b11: begin 
                                    valid_way3[index_from_reg] <= 1'b1; 
                                    tags_way3[index_from_reg] <= tag_from_reg; 
                                    dirty_way3[index_from_reg] <= is_write_op_reg; 
                                    end
                        endcase

                        // Replay the original CPU operation
                        cache_r_en <= !is_write_op_reg;
                        cache_w_en <= is_write_op_reg;
                        cache_offset <= offset_from_reg;
                        
                        if (!is_write_op_reg) begin
                            cpu_data_valid <= 1'b1;
                        end
                    end else begin // Otherwise, keep the memory read request active
                        mem_r_en <= 1'b1;
                        mem_r_add <= {tag_from_reg, index_from_reg, 6'b0};
                    end
                end
            endcase
        end
    end

    // --- LRU and Victim Selection Logic ---
    // Counter-based LRU update: Set accessed way to 11 (MRU), decrement others with saturation
    task update_lru_counters;
        input [5:0] set_index;
        input [1:0] accessed_way;
        begin
            case (accessed_way)
                2'b00: begin
                if(lru_counter_way0[set_index] == 2'b11) //if it is the MRU then keep everything the same
                begin
                    lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                    lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                else //if not, then set it to 3, and decrement all the others by one
                begin
                    lru_counter_way0[set_index] <= 2'b11;
                    if (lru_counter_way1[set_index] > 2'b00) // the minimum value must be 0
                        lru_counter_way1[set_index] <= lru_counter_way1[set_index] - 1'b1;
                    else
                        lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    if (lru_counter_way2[set_index] > 2'b00)
                        lru_counter_way2[set_index] <= lru_counter_way2[set_index] - 1'b1;
                    else
                        lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                    if (lru_counter_way3[set_index] > 2'b00)
                        lru_counter_way3[set_index] <= lru_counter_way3[set_index] - 1'b1;
                    else
                        lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                end
                2'b01: begin
                if(lru_counter_way1[set_index] == 2'b11)
                begin
                    lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                    lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                else
                begin
                    lru_counter_way1[set_index] <= 2'b11;
                    if (lru_counter_way0[set_index] > 2'b00)
                        lru_counter_way0[set_index] <= lru_counter_way0[set_index] - 1'b1;
                    else
                        lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    if (lru_counter_way2[set_index] > 2'b00)
                        lru_counter_way2[set_index] <= lru_counter_way2[set_index] - 1'b1;
                    else
                        lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                    if (lru_counter_way3[set_index] > 2'b00)
                        lru_counter_way3[set_index] <= lru_counter_way3[set_index] - 1'b1;
                    else
                        lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                end
                2'b10: begin
                if(lru_counter_way2[set_index] == 2'b11)
                begin
                    lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                    lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                else
                begin
                    lru_counter_way2[set_index] <= 2'b11;
                    if (lru_counter_way0[set_index] > 2'b00)
                        lru_counter_way0[set_index] <= lru_counter_way0[set_index] - 1'b1;
                    else
                        lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    if (lru_counter_way1[set_index] > 2'b00)
                        lru_counter_way1[set_index] <= lru_counter_way1[set_index] - 1'b1;
                    else
                        lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    if (lru_counter_way3[set_index] > 2'b00)
                        lru_counter_way3[set_index] <= lru_counter_way3[set_index] - 1'b1;
                    else
                        lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                end
                2'b11: begin
                if(lru_counter_way3[set_index] == 2'b11)
                begin
                    lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                    lru_counter_way3[set_index] <= lru_counter_way3[set_index];
                end
                else
                begin
                    lru_counter_way3[set_index] <= 2'b11;
                    if (lru_counter_way0[set_index] > 2'b00)
                        lru_counter_way0[set_index] <= lru_counter_way0[set_index] - 1'b1;
                    else
                        lru_counter_way0[set_index] <= lru_counter_way0[set_index];
                    if (lru_counter_way1[set_index] > 2'b00)
                        lru_counter_way1[set_index] <= lru_counter_way1[set_index] - 1'b1;
                    else
                        lru_counter_way1[set_index] <= lru_counter_way1[set_index];
                    if (lru_counter_way2[set_index] > 2'b00)
                        lru_counter_way2[set_index] <= lru_counter_way2[set_index] - 1'b1;
                    else
                        lru_counter_way2[set_index] <= lru_counter_way2[set_index];
                end
                end
            endcase
        end
    endtask
    
    // Find victim way
    function [1:0] get_victim_way;
        input [5:0] set_index;
        reg [1:0] victim;
        begin
            if (lru_counter_way0[set_index] == 2'b00)
                victim = 2'b00;
            else if (lru_counter_way1[set_index] == 2'b00)
                victim = 2'b01;
            else if (lru_counter_way2[set_index] == 2'b00)
                victim = 2'b10;
            else if (lru_counter_way3[set_index] == 2'b00)
                victim = 2'b11;
            else if (lru_counter_way0[set_index] <= lru_counter_way1[set_index] &&
                     lru_counter_way0[set_index] <= lru_counter_way2[set_index] &&
                     lru_counter_way0[set_index] <= lru_counter_way3[set_index])
                victim = 2'b00;
            else if (lru_counter_way1[set_index] <= lru_counter_way2[set_index] &&
                     lru_counter_way1[set_index] <= lru_counter_way3[set_index])
                victim = 2'b01;
            else if (lru_counter_way2[set_index] <= lru_counter_way3[set_index])
                victim = 2'b10;
            else
                victim = 2'b11;
            
            get_victim_way = victim;
        end
    endfunction

endmodule
