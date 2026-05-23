`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Main_Memory_AXI_Slave
// Description: AXI3 slave interface for main memory. Responds to read and write
//              requests from the Cache_AXI_Bridge with proper protocol handling.
//              Memory is organized as 64-bit words, multiple accesses per AXI beat.
//
// Features:
//  - AXI3 compliant slave interface
//  - 64-bit wide memory array
//  - Configurable memory depth
//  - Supports burst transactions (INCR mode)
//  - Handles AXI_DATA_WIDTH > 64 by assembling multiple memory words
//  - Proper handshaking and flow control
//////////////////////////////////////////////////////////////////////////////////

module Main_Memory_AXI_Slave #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128,
    parameter MEM_DEPTH = 65536  // Number of 64-bit words
)(
    // AXI Global Signals
    input wire ACLK,
    input wire ARESETn,

    // ========================================
    // AXI3 Slave Interface
    // ========================================
    
    // AXI3 Write Address Channel
    input wire  [AXI_ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input wire  [3:0]                   S_AXI_AWLEN,
    input wire  [2:0]                   S_AXI_AWSIZE,
    input wire  [1:0]                   S_AXI_AWBURST,
    input wire                          S_AXI_AWVALID,
    output reg                          S_AXI_AWREADY,
    
    // AXI3 Write Data Channel
    input wire  [AXI_DATA_WIDTH-1:0]    S_AXI_WDATA,
    input wire  [AXI_DATA_WIDTH/8-1:0]  S_AXI_WSTRB,
    input wire                          S_AXI_WLAST,
    input wire                          S_AXI_WVALID,
    output reg                          S_AXI_WREADY,
    
    // AXI3 Write Response Channel
    output reg  [1:0]                   S_AXI_BRESP,
    output reg                          S_AXI_BVALID,
    input wire                          S_AXI_BREADY,
    
    // AXI3 Read Address Channel
    input wire  [AXI_ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input wire  [3:0]                   S_AXI_ARLEN,
    input wire  [2:0]                   S_AXI_ARSIZE,
    input wire  [1:0]                   S_AXI_ARBURST,
    input wire                          S_AXI_ARVALID,
    output reg                          S_AXI_ARREADY,
    
    // AXI3 Read Data Channel
    output reg  [AXI_DATA_WIDTH-1:0]    S_AXI_RDATA,
    output reg  [1:0]                   S_AXI_RRESP,
    output reg                          S_AXI_RLAST,
    output reg                          S_AXI_RVALID,
    input wire                          S_AXI_RREADY
);

    // ========================================
    // Local Parameters
    // ========================================
    localparam MEM_WORD_WIDTH = 64;  // Memory word width
    localparam MEM_BYTES_PER_WORD = MEM_WORD_WIDTH / 8;  // 8 bytes per memory word
    localparam WORDS_PER_AXI_BEAT = AXI_DATA_WIDTH / MEM_WORD_WIDTH;  // e.g., 128/64 = 2
    localparam BYTES_PER_AXI_BEAT = AXI_DATA_WIDTH / 8;
    localparam MEM_ADDR_LSB = $clog2(MEM_BYTES_PER_WORD);  // Bottom 3 bits for byte offset
    
    // AXI Response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // State Machine States
    localparam [2:0] IDLE        = 3'b000;
    localparam [2:0] READ_BURST  = 3'b001;
    localparam [2:0] WRITE_BURST = 3'b010;
    localparam [2:0] WRITE_RESP  = 3'b011;

    // ========================================
    // Memory Array - 64-bit words
    // ========================================
    reg [63:0] memory [0:MEM_DEPTH-1];
    
    initial begin
    memory[0]  = 64'h00A00113_00500093;
    memory[1]  = 64'h0020818B_01400193;
    memory[2]  = 64'h00150023_02114233;
    memory[3]  = 64'h00352823_00251423;
    memory[4]  = 64'h00050283_00453C23;
    memory[5]  = 64'h00851383_00054303;
    memory[6]  = 64'h01052483_00855403;
    memory[7]  = 64'h01056583_00855483;
    memory[8]  = 64'h01853603_00108733;
    memory[9]  = 64'h001086B3_00160613;
    memory[10] = 64'h0000006F_00108733;
    memory[11] = 64'h00000000_00000000;
end
    
    
    
    // ========================================
    // Internal Registers
    // ========================================
    reg [2:0] state, next_state;
    
    // Address phase registers
    reg [AXI_ADDR_WIDTH-1:0] wr_addr;
    reg [AXI_ADDR_WIDTH-1:0] rd_addr;
    reg [3:0] wr_len;
    reg [3:0] rd_len;
    reg [2:0] wr_size;
    reg [2:0] rd_size;
    reg [1:0] wr_burst;
    reg [1:0] rd_burst;
    
    // Beat counters
    reg [3:0] wr_beat_count;
    reg [3:0] rd_beat_count;
    
    // Current address for burst
    reg [AXI_ADDR_WIDTH-1:0] wr_current_addr;
    reg [AXI_ADDR_WIDTH-1:0] rd_current_addr;
    
    // Write response tracking
    reg write_error;
    
    // Temporary variables for read/write operations
    reg [AXI_ADDR_WIDTH-1:0] base_mem_idx;
    reg [AXI_ADDR_WIDTH-1:0] mem_idx;
    reg [AXI_DATA_WIDTH-1:0] read_data_temp;
    reg error_flag;
    
    // ========================================
    // Address Calculation Functions
    // ========================================
    function [AXI_ADDR_WIDTH-1:0] calculate_next_addr;
        input [AXI_ADDR_WIDTH-1:0] current_addr;
        input [1:0] burst_type;
        input [2:0] burst_size;
        begin
            case (burst_type)
                2'b00: calculate_next_addr = current_addr;  // FIXED
                2'b01: calculate_next_addr = current_addr + (1 << burst_size);  // INCR
//                2'b10: begin  // WRAP
//                    calculate_next_addr = current_addr + (1 << burst_size);
//                end
                default: calculate_next_addr = current_addr + (1 << burst_size);
            endcase
        end
    endfunction
    
    // Convert byte address to memory word index (64-bit word)
    function [AXI_ADDR_WIDTH-1:0] get_mem_index;
        input [AXI_ADDR_WIDTH-1:0] byte_addr;
        begin
            get_mem_index = byte_addr >> MEM_ADDR_LSB;  // Divide by 8
        end
    endfunction
    
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
                if (S_AXI_AWVALID) begin
                    next_state = WRITE_BURST;
                end else if (S_AXI_ARVALID) begin
                    next_state = READ_BURST;
                end
            end
            
            READ_BURST: begin
                if (S_AXI_RVALID && S_AXI_RREADY && S_AXI_RLAST)
                    next_state = IDLE;
            end
            
            WRITE_BURST: begin
                if (S_AXI_WVALID && S_AXI_WREADY && S_AXI_WLAST)
                    next_state = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (S_AXI_BVALID && S_AXI_BREADY)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // ========================================
    // Control Logic
    // ========================================
    integer i, j;
    
    always @(posedge ACLK) begin
        if (!ARESETn) begin
            // Reset all outputs
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY <= 1'b0;
            S_AXI_BRESP <= RESP_OKAY;
            S_AXI_BVALID <= 1'b0;
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RDATA <= {AXI_DATA_WIDTH{1'b0}};
            S_AXI_RRESP <= RESP_OKAY;
            S_AXI_RLAST <= 1'b0;
            S_AXI_RVALID <= 1'b0;
            
            // Reset internal registers
            wr_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_addr <= {AXI_ADDR_WIDTH{1'b0}};
            wr_len <= 4'b0;
            rd_len <= 4'b0;
            wr_size <= 3'b0;
            rd_size <= 3'b0;
            wr_burst <= 2'b0;
            rd_burst <= 2'b0;
            wr_beat_count <= 4'b0;
            rd_beat_count <= 4'b0;
            wr_current_addr <= {AXI_ADDR_WIDTH{1'b0}};
            rd_current_addr <= {AXI_ADDR_WIDTH{1'b0}};
            write_error <= 1'b0;
            
            base_mem_idx <= {AXI_ADDR_WIDTH{1'b0}};
            mem_idx <= {AXI_ADDR_WIDTH{1'b0}};
            read_data_temp <= {AXI_DATA_WIDTH{1'b0}};
            error_flag <= 1'b0;
            
//            // Initialize memory to zero (optional)
//            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
//                memory[i] <= 64'h0;
//            end
            
        end else begin
            case (state)
                IDLE: begin
                    S_AXI_AWREADY <= 1'b0;
                    S_AXI_WREADY <= 1'b0;
                    S_AXI_BVALID <= 1'b0;
                    S_AXI_ARREADY <= 1'b0;
                    S_AXI_RVALID <= 1'b0;
                    wr_beat_count <= 4'b0;
                    rd_beat_count <= 4'b0;
                    write_error <= 1'b0;
                    
                    // Sample write address channel (higher priority)
                    if (S_AXI_AWVALID && !S_AXI_ARVALID) begin
                        S_AXI_AWREADY <= 1'b1;
                        wr_addr <= S_AXI_AWADDR;
                        wr_len <= S_AXI_AWLEN;
                        wr_size <= S_AXI_AWSIZE;
                        wr_burst <= S_AXI_AWBURST;
                        wr_current_addr <= S_AXI_AWADDR;
                    end
                    // Sample read address channel
                    else if (S_AXI_ARVALID) begin
                        S_AXI_ARREADY <= 1'b1;
                        rd_addr <= S_AXI_ARADDR;
                        rd_len <= S_AXI_ARLEN;
                        rd_size <= S_AXI_ARSIZE;
                        rd_burst <= S_AXI_ARBURST;
                        rd_current_addr <= S_AXI_ARADDR;
                    end
                end
                
                READ_BURST: begin
                    S_AXI_ARREADY <= 1'b0;
                    
                    // Provide read data
                    if (!S_AXI_RVALID || (S_AXI_RVALID && S_AXI_RREADY)) begin
                        base_mem_idx = get_mem_index(rd_current_addr);
                        error_flag = 1'b0;
                        read_data_temp = {AXI_DATA_WIDTH{1'b0}};
                        
                        // Assemble AXI beat from multiple 64-bit memory words
                        for (j = 0; j < WORDS_PER_AXI_BEAT; j = j + 1) begin
                            mem_idx = base_mem_idx + j;
                            if (mem_idx < MEM_DEPTH) begin
                                read_data_temp[j*MEM_WORD_WIDTH +: MEM_WORD_WIDTH] = memory[mem_idx];
                            end else begin
                                read_data_temp[j*MEM_WORD_WIDTH +: MEM_WORD_WIDTH] = 64'h0;
                                error_flag = 1'b1;
                            end
                        end
                        
                        S_AXI_RDATA <= read_data_temp;
                        S_AXI_RRESP <= error_flag ? RESP_SLVERR : RESP_OKAY;
                        S_AXI_RLAST <= (rd_beat_count == rd_len);
                        S_AXI_RVALID <= 1'b1;
                        
                        if (S_AXI_RREADY) begin
                            if (S_AXI_RLAST) begin
                                S_AXI_RVALID <= 1'b0;
                                rd_beat_count <= 4'b0;
                            end else begin
                                rd_beat_count <= rd_beat_count + 1;
                                rd_current_addr <= calculate_next_addr(rd_current_addr, rd_burst, rd_size);
                            end
                        end
                    end
                end
                
                WRITE_BURST: begin
                    S_AXI_AWREADY <= 1'b0;
                    S_AXI_WREADY <= 1'b1;
                    
                    if (S_AXI_WVALID && S_AXI_WREADY) begin
                        base_mem_idx = get_mem_index(wr_current_addr);
                        
                        // Write AXI beat to multiple 64-bit memory words with byte strobes
                        for (j = 0; j < WORDS_PER_AXI_BEAT; j = j + 1) begin
                            mem_idx = base_mem_idx + j;
                            if (mem_idx < MEM_DEPTH) begin
                                // Handle byte strobes for each 64-bit word
                                for (i = 0; i < MEM_BYTES_PER_WORD; i = i + 1) begin
                                    if (S_AXI_WSTRB[j*MEM_BYTES_PER_WORD + i]) begin
                                        memory[mem_idx][i*8 +: 8] <= 
                                            S_AXI_WDATA[(j*MEM_WORD_WIDTH) + (i*8) +: 8];
                                    end
                                end
                            end else begin
                                write_error <= 1'b1;
                            end
                        end
                        
                        if (S_AXI_WLAST) begin
                            S_AXI_WREADY <= 1'b0;
                            wr_beat_count <= 4'b0;
                        end else begin
                            wr_beat_count <= wr_beat_count + 1;
                            wr_current_addr <= calculate_next_addr(wr_current_addr, wr_burst, wr_size);
                        end
                    end
                end
                
                WRITE_RESP: begin
                    S_AXI_BRESP <= write_error ? RESP_SLVERR : RESP_OKAY;
                    S_AXI_BVALID <= 1'b1;
                    
                    if (S_AXI_BREADY) begin
                        S_AXI_BVALID <= 1'b0;
                    end
                end
                
            endcase
        end
    end

endmodule