`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2025 01:09:56 PM
// Design Name: 
// Module Name: Cache_Controller
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


module Cache_Controller(
    input  clk,
    input  reset_n,
    
    // CPU Interface
    input  [63:0] cpu_address,
    input         cpu_r_en,
    input         cpu_w_en,
    input  [2:0]  cpu_size,  // funct3: 000=byte, 001=halfword, 010=word, 011=dword
    output reg    stall,
    
    // Cache Memory Interface
    output reg        cache_r_en,
    output reg        cache_w_en,
    output reg [5:0]  cache_set_sel,
    output reg [1:0]  cache_way_sel,
    output reg [5:0]  cache_offset,
    output reg        victim_enable,
    input             r_valid,
    
    // Simple Memory Write Interface (write-back)
    output reg        w_en,
    output reg [63:0] w_add,
    output reg [31:0] w_size,   // number of bytes or line size; here we drive BLOCK_SIZE
    input             w_ready,
    
    // Simple Memory Read Interface (refill)
    output reg        r_en,
    output reg [63:0] r_add

);

    // Cache Parameters
    parameter CACHE_SIZE = 16384;  // 16KB
    parameter BLOCK_SIZE = 64;     // 64 bytes per cache line
    parameter NUM_WAYS   = 4;      // 4 ways
    parameter NUM_SETS   = 64;     // CACHE_SIZE / (BLOCK_SIZE * NUM_WAYS)
    parameter SET_BITS   = 6;      // log2(NUM_SETS)
    
    // State Definitions 
    parameter [2:0] IDLE         = 3'b000;
    parameter [2:0] READ_HIT     = 3'b001;
    parameter [2:0] READ_MISS    = 3'b010;
    parameter [2:0] WRITE_HIT    = 3'b011;
    parameter [2:0] WRITE_MISS   = 3'b100;
    parameter [2:0] VICTIM_WRITE = 3'b101;
    parameter [2:0] FETCH        = 3'b110;
    
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    // Address decomposition
    wire [51:0] tag   = cpu_address[63:12];
    wire [5:0]  index = cpu_address[11:6];  // 64 sets (6 bits)
    wire [5:0]  offset= cpu_address[5:0];   // 64 bytes (6 bits)
    
    // Internal registers
    reg [51:0] tag_reg;
    reg [5:0]  index_reg;
    reg [5:0]  offset_reg;
    reg [2:0]  size_reg;
    reg        hit;
    reg [1:0]  hit_way;
    reg [1:0]  victim_way;
    reg        was_write_miss;
    
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
    
    // Internal wires for hit detection
    wire hit_way0;
    wire hit_way1;
    wire hit_way2;
    wire hit_way3;
    
    // Hit detection logic
    assign hit_way0 = valid_way0[index] && (tags_way0[index] == tag);
    assign hit_way1 = valid_way1[index] && (tags_way1[index] == tag);
    assign hit_way2 = valid_way2[index] && (tags_way2[index] == tag);
    assign hit_way3 = valid_way3[index] && (tags_way3[index] == tag);
    
    // Combined hit signal and way selection
    always @(*) begin
        hit = hit_way0 | hit_way1 | hit_way2 | hit_way3;
        case (1'b1)
            hit_way0: hit_way = 2'b00;
            hit_way1: hit_way = 2'b01;
            hit_way2: hit_way = 2'b10;
            hit_way3: hit_way = 2'b11;
            default:  hit_way = 2'b00;
        endcase
    end
    
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
    
    // Dirty bit of chosen victim
    wire current_dirty;
    assign current_dirty = (victim_way == 2'b00) ? dirty_way0[index_reg] :
                           (victim_way == 2'b01) ? dirty_way1[index_reg] :
                           (victim_way == 2'b10) ? dirty_way2[index_reg] :
                                                   dirty_way3[index_reg];
    
    // State register
    integer i;
    always @(posedge clk) begin
        if (~reset_n) begin
            current_state <= IDLE;
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
                
                tags_way0[i] <= 52'b0;
                tags_way1[i] <= 52'b0;
                tags_way2[i] <= 52'b0;
                tags_way3[i] <= 52'b0;
                
                lru_counter_way0[i] <= 2'b00;
                lru_counter_way1[i] <= 2'b01;
                lru_counter_way2[i] <= 2'b10;
                lru_counter_way3[i] <= 2'b11;
            end
            was_write_miss <= 1'b0;
        end
        else begin
            current_state <= next_state;
            // Track if we're handling a write miss
            if (current_state == IDLE && cpu_w_en && !hit) begin
                was_write_miss <= 1'b1;
            end else if (current_state == FETCH && r_valid) begin
                was_write_miss <= 1'b0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (cpu_r_en) begin
                    if (hit)
                        next_state = READ_HIT;
                    else
                        next_state = READ_MISS;
                end
                else if (cpu_w_en) begin
                    if (hit)
                        next_state = WRITE_HIT;
                    else
                        next_state = WRITE_MISS;
                end
                else
                    next_state = IDLE;
            end
            
            READ_HIT,
            WRITE_HIT: begin
                next_state = IDLE;
            end
            
            READ_MISS,
            WRITE_MISS: begin
                if (current_dirty)
                    next_state = VICTIM_WRITE;
                else
                    next_state = FETCH;  // wait for read data
            end
            
            VICTIM_WRITE: begin
                if (w_ready)  // write-back finished
                    next_state = FETCH;
            end
            
            FETCH: begin
                if (r_valid)  // refill data available
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic and register updates
    always @(posedge clk) begin
        if (~reset_n) begin
            stall         <= 1'b0;
            cache_r_en    <= 1'b0;
            cache_w_en    <= 1'b0;
            victim_enable <= 1'b0;
            w_en          <= 1'b0;
            w_add         <= 64'b0;
            w_size        <= 32'b0;
            r_en          <= 1'b0;
            r_add         <= 64'b0;
        end
        else begin
            case (current_state)
                IDLE: begin
                    stall         <= 1'b0;
                    cache_r_en    <= 1'b0;
                    cache_w_en    <= 1'b0;
                    victim_enable <= 1'b0;
                    w_en          <= 1'b0;
                    r_en          <= 1'b0;
                    w_size        <= BLOCK_SIZE; // constant line size
                    
                    if (cpu_r_en || cpu_w_en) begin
                        tag_reg    <= tag;
                        index_reg  <= index;
                        offset_reg <= offset;
                        size_reg   <= cpu_size;
                        stall      <= 1'b1;
                        victim_way <= get_victim_way(index);
                    end
                end
                
                READ_HIT: begin
                    cache_r_en    <= 1'b1;
                    cache_set_sel <= index_reg;
                    cache_way_sel <= hit_way;
                    cache_offset  <= offset_reg;
                    update_lru_counters(index_reg, hit_way);
                    stall         <= 1'b0;
                end
                
                WRITE_HIT: begin
                    cache_w_en    <= 1'b1;
                    cache_set_sel <= index_reg;
                    cache_way_sel <= hit_way;
                    cache_offset  <= offset_reg;
                    case (hit_way)
                        2'b00: dirty_way0[index_reg] <= 1'b1;
                        2'b01: dirty_way1[index_reg] <= 1'b1;
                        2'b10: dirty_way2[index_reg] <= 1'b1;
                        2'b11: dirty_way3[index_reg] <= 1'b1;
                    endcase
                    update_lru_counters(index_reg, hit_way);
                    stall         <= 1'b0;
                end
                
                READ_MISS,
                WRITE_MISS: begin
                    // Miss detected: either write-back first or directly fetch
                    if (current_dirty) begin
                      // Victim write-back
                        //signals to write axi interface
                        w_en          <= 1'b1;
                        w_size        <= BLOCK_SIZE;
                        case (victim_way)
                            2'b00: w_add <= {tags_way0[index_reg], index_reg, 6'b0};
                            2'b01: w_add <= {tags_way1[index_reg], index_reg, 6'b0};
                            2'b10: w_add <= {tags_way2[index_reg], index_reg, 6'b0};
                            2'b11: w_add <= {tags_way3[index_reg], index_reg, 6'b0};
                        endcase
                        //signals to get the data from cache mem to be send to the mem
                        victim_enable <= 1'b1; 
                        cache_set_sel <= index_reg;
                        cache_way_sel <= victim_way;
                    end
                    else begin
                        // No write-back needed → issue read for new line
                        r_en  <= 1'b1;
                        r_add <= {tag_reg, index_reg, 6'b0};
                    end
                end
                
                VICTIM_WRITE: begin
                    // Wait for write-back completion
                    if (w_ready) begin
                        w_en          <= 1'b0;
                        victim_enable <= 1'b0;
                        // Now request the new line
                        r_en  <= 1'b1;
                        r_add <= {tag_reg, index_reg, 6'b0};
                    end
                end
                
                FETCH: begin
                    // Wait for refill data
                    if (r_valid) begin
                        r_en <= 1'b0;
                        
                        // Update cache metadata for fetched line
                        case (victim_way)
                            2'b00: begin
                                valid_way0[index_reg] <= 1'b1;
                                dirty_way0[index_reg] <= 1'b0;
                                tags_way0[index_reg]  <= tag_reg;
                            end
                            2'b01: begin
                                valid_way1[index_reg] <= 1'b1;
                                dirty_way1[index_reg] <= 1'b0;
                                tags_way1[index_reg]  <= tag_reg;
                            end
                            2'b10: begin
                                valid_way2[index_reg] <= 1'b1;
                                dirty_way2[index_reg] <= 1'b0;
                                tags_way2[index_reg]  <= tag_reg;
                            end
                            2'b11: begin
                                valid_way3[index_reg] <= 1'b1;
                                dirty_way3[index_reg] <= 1'b0;
                                tags_way3[index_reg]  <= tag_reg;
                            end
                        endcase
                        
                        // Mark fetched way as MRU
                        update_lru_counters(index_reg, victim_way);
                        
                        // If it was a write miss, perform the write into the new line
                        if (was_write_miss) begin
                            cache_w_en    <= 1'b1;
                            cache_set_sel <= index_reg;
                            cache_way_sel <= victim_way;
                            cache_offset  <= offset_reg;
                            case (victim_way)
                                2'b00: dirty_way0[index_reg] <= 1'b1;
                                2'b01: dirty_way1[index_reg] <= 1'b1;
                                2'b10: dirty_way2[index_reg] <= 1'b1;
                                2'b11: dirty_way3[index_reg] <= 1'b1;
                            endcase
                        end
                        else begin   //was read miss, perform the read from the new line
                            cache_r_en    <= 1'b1;
                            cache_set_sel <= index_reg;
                            cache_way_sel <= victim_way;
                            cache_offset  <= offset_reg;
                        end
                        stall <= 1'b0;
                    end
                end
                
                default: begin
                    stall         <= 1'b0;
                    cache_r_en    <= 1'b0;
                    cache_w_en    <= 1'b0;
                    victim_enable <= 1'b0;
                    w_en          <= 1'b0;
                    r_en          <= 1'b0;
                end
            endcase
        end
    end

endmodule