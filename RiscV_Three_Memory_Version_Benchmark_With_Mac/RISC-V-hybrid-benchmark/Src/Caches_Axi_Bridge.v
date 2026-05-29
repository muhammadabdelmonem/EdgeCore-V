`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Cache_AXI_Bridge
// Description: Multiplexes D-Cache and I-Cache requests into a single AXI
//              master interface. Handles reads and writes with proper protocol
//              translation from custom cache signals to AXI standard.
//
// Features:
//  - Arbitrates between D-Cache and I-Cache (mutually exclusive operation)
//  - Translates custom cache protocol to AXI
//  - Supports 512-bit (64-byte) cache line transfers
//  - Handles AXI burst transactions (INCR mode)
//  - Proper handshaking and flow control
//////////////////////////////////////////////////////////////////////////////////

module Caches_Axi_Bridge #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128,  // AXI data width (typically 128 or 256 bits)
    parameter CACHE_LINE_SIZE = 512  // Cache line size in bits
)(
    // AXI Global Signals
    input wire ACLK,
    input wire ARESETn,

    // ========================================
    // D-Cache Interface (Custom Protocol)
    // ========================================
    // D-Cache Read Signals
    input wire                          dcache_r_en,
    input wire  [63:0]                  dcache_r_address,
    input wire  [31:0]                  dcache_r_size,
    output reg                          dcache_r_valid,
    output reg  [CACHE_LINE_SIZE-1:0]   dcache_r_data,
    
    // D-Cache Write Signals
    input wire                          dcache_w_en,
    input wire  [63:0]                  dcache_w_address,
    input wire  [31:0]                  dcache_w_size,
    input wire  [CACHE_LINE_SIZE-1:0]   dcache_w_data,
    output reg                          dcache_w_ready,

    // ========================================
    // I-Cache Interface (Custom Protocol)
    // ========================================
    // I-Cache Read Signals (Read-only cache)
    input wire                          icache_r_en,
    input wire  [63:0]                  icache_r_address,
    input wire  [31:0]                  icache_r_size,
    output reg                          icache_r_valid,
    output reg  [CACHE_LINE_SIZE-1:0]   icache_r_data,

    // ========================================
    // AXI3 Master Interface (In-order only, no IDs)
    // ========================================
    
    // AXI3 Write Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0]    M_AXI_AWADDR,
    output reg  [3:0]                   M_AXI_AWLEN,     // Burst length - 1 (AXI: 4 bits, max 16 beats)
    output reg  [2:0]                   M_AXI_AWSIZE,    // Burst size (bytes per beat)
    output reg  [1:0]                   M_AXI_AWBURST,   // Burst type (INCR = 2'b01)
    output reg                          M_AXI_AWVALID,
    input wire                          M_AXI_AWREADY,
    
    // AXI Write Data Channel (WID removed - in-order writes only)
    output reg  [AXI_DATA_WIDTH-1:0]    M_AXI_WDATA,
    output reg  [AXI_DATA_WIDTH/8-1:0]  M_AXI_WSTRB,
    output reg                          M_AXI_WLAST,
    output reg                          M_AXI_WVALID,
    input wire                          M_AXI_WREADY,
    
    // AXI Write Response Channel
    input wire  [1:0]                   M_AXI_BRESP,
    input wire                          M_AXI_BVALID,
    output reg                          M_AXI_BREADY,
    
    // AXI Read Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0]    M_AXI_ARADDR,
    output reg  [3:0]                   M_AXI_ARLEN,     // Burst length - 1 (AXI: 4 bits, max 16 beats)
    output reg  [2:0]                   M_AXI_ARSIZE,    // Burst size (bytes per beat)
    output reg  [1:0]                   M_AXI_ARBURST,   // Burst type (INCR = 2'b01)
    output reg                          M_AXI_ARVALID,
    input wire                          M_AXI_ARREADY,
    
    // AXI Read Data Channel
    input wire  [AXI_DATA_WIDTH-1:0]    M_AXI_RDATA,
    input wire  [1:0]                   M_AXI_RRESP,
    input wire                          M_AXI_RLAST,
    input wire                          M_AXI_RVALID,
    output reg                          M_AXI_RREADY
);

    // ========================================
    // Local Parameters
    // ========================================
    localparam BYTES_PER_BEAT = AXI_DATA_WIDTH / 8;
    localparam BEATS_PER_CACHE_LINE = CACHE_LINE_SIZE / AXI_DATA_WIDTH;
    
    // State Machine States
    localparam [2:0] IDLE           = 3'b000;
    localparam [2:0] READ_ADDR      = 3'b001;
    localparam [2:0] READ_DATA      = 3'b010;
    localparam [2:0] CACHE_UPDATE   = 3'b011;
    localparam [2:0] WRITE_ADDR     = 3'b100;
    localparam [2:0] WRITE_DATA     = 3'b101;
    localparam [2:0] WRITE_RESP     = 3'b110;

    // ========================================
    // Internal Registers
    // ========================================
    reg [2:0] state, next_state;
    reg [7:0] beat_counter;   // Counts beats in a burst
    reg [CACHE_LINE_SIZE-1:0] read_buffer;   // Accumulates read data
    reg [CACHE_LINE_SIZE-1:0] write_buffer;  // Holds write data to send
    reg current_cache;   // 0 = I-Cache, 1 = D-Cache
    reg is_dcache_write;  // Track if current operation is D-Cache write
    
    // Edge detection registers for enable signals
    // The cache keeps enables HIGH until valid/ready, so we need to detect the rising edge
    reg dcache_r_en_prev;
    reg dcache_w_en_prev;
    reg icache_r_en_prev;
    
    wire dcache_r_en_rising = dcache_r_en && !dcache_r_en_prev;
    wire dcache_w_en_rising = dcache_w_en && !dcache_w_en_prev;
    wire icache_r_en_rising = icache_r_en && !icache_r_en_prev;
    
    // ========================================
    // State Machine
    // ========================================
    always @(posedge ACLK) begin
        if (!ARESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                // Use rising edge detection since enables stay high until completion
                if (dcache_w_en_rising) begin
                    next_state = WRITE_ADDR;
                end else if (dcache_r_en_rising) begin
                    next_state = READ_ADDR;
                end else if (icache_r_en_rising) begin
                    next_state = READ_ADDR;
                end
            end
            
            READ_ADDR: begin
                if (M_AXI_ARVALID && M_AXI_ARREADY)
                    next_state = READ_DATA;
            end
            
            READ_DATA: begin
                if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST)
                    next_state = CACHE_UPDATE;
            end
            
            CACHE_UPDATE: begin
                    next_state = IDLE;
            end
            
            WRITE_ADDR: begin
                if (M_AXI_AWVALID && M_AXI_AWREADY)
                    next_state = WRITE_DATA;
            end
            
            WRITE_DATA: begin
                if (M_AXI_WVALID && M_AXI_WREADY && M_AXI_WLAST)
                    next_state = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (M_AXI_BVALID && (M_AXI_BRESP == 2'b00))
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // ========================================
    // Control Logic
    // ========================================
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            // Reset all outputs
            dcache_r_valid <= 1'b0;
            dcache_r_data <= {CACHE_LINE_SIZE{1'b0}};
            dcache_w_ready <= 1'b0;
            icache_r_valid <= 1'b0;
            icache_r_data <= {CACHE_LINE_SIZE{1'b0}};
            
            M_AXI_AWADDR <= {AXI_ADDR_WIDTH{1'b0}};
            M_AXI_AWLEN <= 4'b0;         // AXI3: 4 bits
            M_AXI_AWSIZE <= 3'b0;
            M_AXI_AWBURST <= 2'b01;      // INCR
            M_AXI_AWVALID <= 1'b0;
            
            M_AXI_WDATA <= {AXI_DATA_WIDTH{1'b0}};
            M_AXI_WSTRB <= {(AXI_DATA_WIDTH/8){1'b0}};
            M_AXI_WLAST <= 1'b0;
            M_AXI_WVALID <= 1'b0;
            
            M_AXI_BREADY <= 1'b0;
            
            M_AXI_ARADDR <= {AXI_ADDR_WIDTH{1'b0}};
            M_AXI_ARLEN <= 4'b0;         // AXI3: 4 bits
            M_AXI_ARSIZE <= 3'b0;
            M_AXI_ARBURST <= 2'b01;      // INCR
            M_AXI_ARVALID <= 1'b0;
            
            M_AXI_RREADY <= 1'b0;
            
            beat_counter <= 8'b0;
            read_buffer <= {CACHE_LINE_SIZE{1'b0}};
            write_buffer <= {CACHE_LINE_SIZE{1'b0}};
            current_cache <= 1'b0;
            is_dcache_write <= 1'b0;
            
            // Edge detection registers
            dcache_r_en_prev <= 1'b0;
            dcache_w_en_prev <= 1'b0;
            icache_r_en_prev <= 1'b0;
            
        end else begin
            // Update edge detection registers every cycle
            dcache_r_en_prev <= dcache_r_en;
            dcache_w_en_prev <= dcache_w_en;
            icache_r_en_prev <= icache_r_en;
            
            // Clear valid signals by default
            dcache_r_valid <= 1'b0;
            icache_r_valid <= 1'b0;
            dcache_w_ready <= 1'b0;
            
            case (state)
                IDLE: begin
                    M_AXI_ARVALID <= 1'b0;
                    M_AXI_AWVALID <= 1'b0;
                    M_AXI_WVALID <= 1'b0;
                    M_AXI_RREADY <= 1'b0;
                    M_AXI_BREADY <= 1'b0;
                    beat_counter <= 8'b0;
                    
                    // Arbitration: Sample on rising edge of enable signals
                    // D-Cache write has highest priority
                    if (dcache_w_en_rising) begin
                        current_cache <= 1'b1;  // D-Cache
                        is_dcache_write <= 1'b1;
                        write_buffer <= dcache_w_data;
                    end else if (dcache_r_en_rising) begin
                        current_cache <= 1'b1;  // D-Cache
                        is_dcache_write <= 1'b0;
                    end else if (icache_r_en_rising) begin
                        current_cache <= 1'b0;  // I-Cache
                        is_dcache_write <= 1'b0;
                    end
                end
                
                READ_ADDR: begin
                    // Issue read address
                    if (!M_AXI_ARVALID) begin
                        M_AXI_ARADDR <= current_cache ? dcache_r_address : icache_r_address;
                        M_AXI_ARLEN <= BEATS_PER_CACHE_LINE - 1;  // Burst length (AXI3: max 15)
                        M_AXI_ARSIZE <= $clog2(BYTES_PER_BEAT);    // Bytes per beat
                        M_AXI_ARBURST <= 2'b01;   // INCR
                        M_AXI_ARVALID <= 1'b1;
                    end
                    
                    if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 1'b0;
                    end
                    
                    M_AXI_RREADY <= 1'b1;  // Ready to receive data
                end
                
                READ_DATA: begin
                    M_AXI_RREADY <= 1'b1;
                    
                    if ((M_AXI_RVALID) && M_AXI_RREADY) begin
                        // Accumulate data in read buffer
                        read_buffer[beat_counter * AXI_DATA_WIDTH +: AXI_DATA_WIDTH] <= M_AXI_RDATA;
                        beat_counter <= beat_counter + 1;
                        
                        if (M_AXI_RLAST) begin
                            M_AXI_RREADY <= 1'b0;
                            beat_counter <= 8'b0;
                        end
                    end
                end
                
                CACHE_UPDATE: begin
                    // Transfer complete - send data to appropriate cache
                    if (current_cache) begin
                          // D-Cache
                          dcache_r_data <= read_buffer;
                          dcache_r_valid <= 1'b1;
                    end else begin
                          // I-Cache
                          icache_r_data <= read_buffer;
                          icache_r_valid <= 1'b1;
                    end
                end
                
                WRITE_ADDR: begin
                    // Issue write address
                    if (!M_AXI_AWVALID) begin
                        M_AXI_AWADDR <= dcache_w_address;
                        M_AXI_AWLEN <= BEATS_PER_CACHE_LINE - 1;  // AXI3: max 15
                        M_AXI_AWSIZE <= $clog2(BYTES_PER_BEAT);
                        M_AXI_AWBURST <= 2'b01;   // INCR
                        M_AXI_AWVALID <= 1'b1;
                    end
                    
                    if (M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 1'b0;
                    end
                end
                
                WRITE_DATA: begin
                    // Send write data
                    if (!M_AXI_WVALID || (M_AXI_WVALID && M_AXI_WREADY)) begin
                        M_AXI_WDATA <= write_buffer[beat_counter * AXI_DATA_WIDTH +: AXI_DATA_WIDTH];
                        M_AXI_WSTRB <= {(AXI_DATA_WIDTH/8){1'b1}};  // All bytes valid
                        M_AXI_WLAST <= (beat_counter == (BEATS_PER_CACHE_LINE - 1));
                        M_AXI_WVALID <= 1'b1;
                        
                        if (M_AXI_WREADY) begin
                            beat_counter <= beat_counter + 1;
                            if (M_AXI_WLAST) begin
                                M_AXI_WVALID <= 1'b0;
                                beat_counter <= 8'b0;
                            end
                        end
                    end
                end
                
                WRITE_RESP: begin
                   // M_AXI_BREADY <= 1'b1;
                    
                    if (M_AXI_BVALID && (M_AXI_BRESP == 2'b00)) begin
                        dcache_w_ready <= 1'b1;  // Indicate write complete
                        M_AXI_BREADY <= 1'b1;
                    end
                end
                
            endcase
        end
    end

endmodule
