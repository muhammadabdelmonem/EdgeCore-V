`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 03:38:37 PM
// Design Name: 
// Module Name: I_Cache_Controller
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


module I_Cache_Controller(
    input  clk,
    input  reset_n,

    // CPU Interface
    input  [63:0] cpu_address,
    input         cpu_r_en,
    output        stall,
    output        cpu_data_valid, //99% chance that we will not need this but let's keep it for the moment 

    // Cache Memory Interface
    input       r_valid,    // From Cache Memory: Refill is done and data is stored
    output      cache_r_en,
    output [5:0]cache_set_sel,
    output [1:0]cache_way_sel,
    output [5:0]cache_offset,

    // Main Memory (AXI) Interface
    output reg [31:0] mem_size,
    output reg        mem_r_en,
    output reg [63:0] mem_r_add,
    
    //Bus Timeout Exception Outpot 
    output reg bus_error_exception,
    
    //benchmarking output
    output reg icache_hit,
    output reg icache_miss,
    output reg icache_access 
);

    // Cache Parameters
    parameter BLOCK_SIZE = 64;
    parameter NUM_WAYS   = 4;
    parameter NUM_SETS   = 64;

    // State Definitions
    parameter [1:0] IDLE         = 2'b00;
    parameter [1:0] LOOKUP       = 2'b01;
    parameter [1:0] FETCH        = 2'b10;


    //Time out parametere and reg
    parameter TIMEOUT_CYCLES = 1000; // Wait 1000 cycles before giving up   //exactly how long should we wait ??????
    reg [11:0] timeout_counter; // A counter large enough for TIMEOUT_CYCLES

    reg [1:0] current_state, next_state;

    // Internal Registers for Pipelining
    reg [63:0] addr_reg;
    reg [1:0]  victim_way_reg;
    
    // Delay register to generate a correct, 1-cycle delayed cpu_data_valid signal
    reg read_request_in_flight;

    // Cache metadata arrays
    reg  valid_way0 [0:NUM_SETS-1];
    reg  valid_way1 [0:NUM_SETS-1];
    reg  valid_way2 [0:NUM_SETS-1];
    reg  valid_way3 [0:NUM_SETS-1];
    
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
    wire [51:0] tag_from_reg    = addr_reg[63:12];
    wire [5:0]  index_from_reg  = addr_reg[11:6];
    wire [5:0]  offset_from_reg = addr_reg[5:0];

    // --- Combinational Logic for Decisions and Control ---

    // Hit detection (based on registered address)
    wire hit_way0 = valid_way0[index_from_reg] && (tags_way0[index_from_reg] == tag_from_reg);
    wire hit_way1 = valid_way1[index_from_reg] && (tags_way1[index_from_reg] == tag_from_reg);
    wire hit_way2 = valid_way2[index_from_reg] && (tags_way2[index_from_reg] == tag_from_reg);
    wire hit_way3 = valid_way3[index_from_reg] && (tags_way3[index_from_reg] == tag_from_reg);
    wire is_hit   = hit_way0 | hit_way1 | hit_way2 | hit_way3;
    wire [1:0] hit_way = hit_way0 ? 2'b00 : (hit_way1 ? 2'b01 : (hit_way2 ? 2'b10 : 2'b11));

    // Predictive (combinational) victim selection for immediate decision making
    //wire [1:0] potential_victim_way = get_victim_way(index_from_reg);
    reg [1:0] potential_victim_way;
    always @(*) begin
        // Explicitly reading all arrays forces the simulator to
        // re-evaluate whenever any counter changes
        if      (lru_counter_way0[index_from_reg] == 2'b00) potential_victim_way = 2'b00;
        else if (lru_counter_way1[index_from_reg] == 2'b00) potential_victim_way = 2'b01;
        else if (lru_counter_way2[index_from_reg] == 2'b00) potential_victim_way = 2'b10;
        else if (lru_counter_way3[index_from_reg] == 2'b00) potential_victim_way = 2'b11;
        else if (lru_counter_way0[index_from_reg] <= lru_counter_way1[index_from_reg] &&
                 lru_counter_way0[index_from_reg] <= lru_counter_way2[index_from_reg] &&
                 lru_counter_way0[index_from_reg] <= lru_counter_way3[index_from_reg])
                                                             potential_victim_way = 2'b00;
        else if (lru_counter_way1[index_from_reg] <= lru_counter_way2[index_from_reg] &&
                 lru_counter_way1[index_from_reg] <= lru_counter_way3[index_from_reg])
                                                             potential_victim_way = 2'b01;
        else if (lru_counter_way2[index_from_reg] <= lru_counter_way3[index_from_reg])
                                                             potential_victim_way = 2'b10;
        else                                                 potential_victim_way = 2'b11;
    end
    
    
    // Combinational outputs for immediate control
    assign cache_r_en = (current_state == LOOKUP && is_hit ) ||
                        (current_state == FETCH && r_valid );

    assign cache_set_sel = (current_state == LOOKUP && is_hit) ? index_from_reg :
                           (current_state == FETCH)? index_from_reg : 6'bX;

    assign cache_way_sel = (current_state == LOOKUP && is_hit) ? hit_way :
                           (current_state == FETCH) ? victim_way_reg : 2'bX;
                       
    assign cache_offset = (current_state == LOOKUP && is_hit) ? offset_from_reg :
                          (current_state == FETCH) ? offset_from_reg : 6'bX; //do we need to remove this r_valid as we did with the other flags ??
    
    assign cpu_data_valid = read_request_in_flight;
    
    //  Stall Logic 
    //  wire to predict if a stall will be needed on the NEXT cycle.
    //wire will_stall_next_cycle = (current_state == IDLE) && cpu_r_en ;
    //Stall logic which will stall all the pipeline registers including the MEM/WB 
    //assign stall = ((current_state != IDLE || will_stall_next_cycle) && !bus_error_exception);
    //assign stall = ((current_state != IDLE || (cpu_r_en && ~read_request_in_flight)) && !bus_error_exception) ;
    assign stall = (current_state != IDLE || (read_request_in_flight && current_state == IDLE)) && !bus_error_exception;    
    



    // --- State Machine Logic ---
    always @(posedge clk) begin
        if (~reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        
        if (bus_error_exception) begin
        // If a timeout occurs, immediately go back to IDLE regardless of the current state
        next_state = IDLE;
        end else begin
        case (current_state)
            IDLE:
                if (cpu_r_en)
                    next_state = LOOKUP;
            LOOKUP:
                if (is_hit)
                    next_state = IDLE;
                else // It's a miss
                    next_state = FETCH;
            FETCH:
                if (r_valid)
                    next_state = IDLE;
        endcase
        end
    end

    // --- Main Sequential Logic ---
    integer i;
    always @(posedge clk ) begin
        if (~reset_n) begin
            // Reset registered outputs and internal state
            read_request_in_flight <= 1'b0;
            //victim_enable <= 1'b0;
            mem_r_en <= 1'b0;
            mem_size <= BLOCK_SIZE;
            addr_reg <= 64'b0;
            
            timeout_counter <= 0;
            bus_error_exception <= 1'b0;
        
            // Initialize cache metadata
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                valid_way0[i] <= 1'b0;
                valid_way1[i] <= 1'b0;
                valid_way2[i] <= 1'b0;
                valid_way3[i] <= 1'b0;
                
                lru_counter_way0[i] <= 2'b00;
                lru_counter_way1[i] <= 2'b01;
                lru_counter_way2[i] <= 2'b10;
                lru_counter_way3[i] <= 2'b11;
            end
        end else begin
            // Latch the value of the combinational read enable for the next cycle
            read_request_in_flight <= cache_r_en;

            //BUs error exception default to off
            bus_error_exception <= 1'b0; 
  
            // Default assignments for registered outputs
            //victim_enable <= 1'b0;
            mem_r_en <= 1'b0;
            case (current_state)
                IDLE:
                    if (cpu_r_en ) begin
                        addr_reg <= cpu_address;
                    end

                LOOKUP:
                    if (is_hit) begin
                        update_lru_counters(index_from_reg, hit_way);
                    end else begin // Miss
                        victim_way_reg <= potential_victim_way;
                        mem_r_en <= 1'b1;
                        mem_r_add <= {tag_from_reg, index_from_reg, 6'b0};
                        end

                FETCH: begin
                    if (r_valid) begin // Refill and Replay
                        mem_r_en <= 1'b0;
                        update_lru_counters(index_from_reg, victim_way_reg);
                        case (victim_way_reg)
                            2'b00: begin valid_way0[index_from_reg] <= 1'b1; tags_way0[index_from_reg] <= tag_from_reg;  end
                            2'b01: begin valid_way1[index_from_reg] <= 1'b1; tags_way1[index_from_reg] <= tag_from_reg;  end
                            2'b10: begin valid_way2[index_from_reg] <= 1'b1; tags_way2[index_from_reg] <= tag_from_reg;  end
                            2'b11: begin valid_way3[index_from_reg] <= 1'b1; tags_way3[index_from_reg] <= tag_from_reg;  end
                        endcase
                    end else begin // Issue fetch request
                          mem_r_en <= 1'b1;
                        
                    end
                end
            endcase
            
            
            //Timeout Counter Management
            if ((current_state == FETCH && !r_valid)) begin
            // If we are waiting for memory, increment the counter
            if (timeout_counter < TIMEOUT_CYCLES) begin
                timeout_counter <= timeout_counter + 1;
            end else begin
                // We have timed out!
                bus_error_exception <= 1'b1;
            end
            end else begin
            // If we are not waiting for memory, keep the counter reset
            timeout_counter <= 0;
            end
            
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

    //benchmarking logic
    always @(posedge clk) begin
    if (~reset_n) begin
        icache_hit    <= 1'b0;
        icache_miss   <= 1'b0;
        icache_access <= 1'b0;
    end
    else begin
        // default
        icache_hit    <= 1'b0;
        icache_miss   <= 1'b0;
        icache_access <= 1'b0;
        case (current_state)
            LOOKUP: begin
                // count every lookup as an access
                icache_access <= 1'b1;
                if (is_hit)
                    icache_hit <= 1'b1;
                else
                    icache_miss <= 1'b1;
            end

        endcase
    end
end

endmodule
