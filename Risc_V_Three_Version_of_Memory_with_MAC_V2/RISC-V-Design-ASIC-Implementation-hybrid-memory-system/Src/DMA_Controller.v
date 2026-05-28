`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 12:36:15 AM
// Design Name: 
// Module Name: DMA_Controller
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


module DMA_Controller #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128  // AXI data width (typically 128 or 256 bits)
    )(
    input clk,
    input reset_n,

    // =============================
    //  DMA Register interface
    // =============================
    // Inputs
    input [63:0] src,
    input [63:0] dst,
    input [63:0] size,
    input start,
    input dir,
    // Outputs 
    output reg dma_busy,
    output reg dma_start_ack,
    output reg dma_done,
    output reg dma_bus_error,
    output reg dma_confg_error,

    // =============================
    // AXI4 Memory interface (In-order only, no IDs)
    // =============================
    // AXI3 Write Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0]    M_AXI_AWADDR,
    output reg  [3:0]                   M_AXI_AWLEN,     // Burst length - 1 (AXI3: 4 bits, max 16 beats)
    output reg  [2:0]                   M_AXI_AWSIZE,    // Burst size (bytes per beat)
    output reg  [1:0]                   M_AXI_AWBURST,   // Burst type (INCR = 2'b01)
    output reg                          M_AXI_AWVALID,
    input wire                          M_AXI_AWREADY,
    
    // AXI3 Write Data Channel 
    output reg  [AXI_DATA_WIDTH-1:0]    M_AXI_WDATA,
    output reg  [AXI_DATA_WIDTH/8-1:0]  M_AXI_WSTRB,
    output reg                          M_AXI_WLAST,
    output reg                          M_AXI_WVALID,
    input wire                          M_AXI_WREADY,
    
    // AXI3 Write Response Channel
    input wire  [1:0]                   M_AXI_BRESP,
    input wire                          M_AXI_BVALID,
    output reg                          M_AXI_BREADY,
    
    // AXI3 Read Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0]    M_AXI_ARADDR,
    output reg  [3:0]                   M_AXI_ARLEN,     // Burst length - 1 (AXI3: 4 bits, max 16 beats)
    output reg  [2:0]                   M_AXI_ARSIZE,    // Burst size (bytes per beat)
    output reg  [1:0]                   M_AXI_ARBURST,   // Burst type (INCR = 2'b01)
    output reg                          M_AXI_ARVALID,
    input wire                          M_AXI_ARREADY,
    
    // AXI3 Read Data Channel
    input wire  [AXI_DATA_WIDTH-1:0]    M_AXI_RDATA,
    input wire  [1:0]                   M_AXI_RRESP,
    input wire                          M_AXI_RLAST,
    input wire                          M_AXI_RVALID,
    output reg                          M_AXI_RREADY,
    
    // =============================
    // SPM interface
    // =============================
    output reg [AXI_ADDR_WIDTH-1:0] spm_addr,
    output reg [AXI_DATA_WIDTH-1:0] spm_wdata,
    input [AXI_DATA_WIDTH-1:0] spm_rdata,
    // to enable read/ write of spm 
    output reg dma_ctrl_re,
    output reg dma_ctrl_we
    );
    
    // ========================================
    // Local Parameters
    // ========================================
    localparam BYTES_PER_BEAT = AXI_DATA_WIDTH / 8;
    
    // ========================================
    // Internal Registers
    // ========================================
    reg [2:0] current_state, next_state;
    reg signed [63:0] bytes_left;
    reg [63:0] current_src, current_dst;
    reg [3:0] beat_counter;
    
    // ========================================
    // Burst calculation 
    // ========================================
    reg [3:0] BEATS_PER_BURST;  // AXI3: max 16 beats per burst
    always @(*) begin
        if (bytes_left == 0)
            BEATS_PER_BURST = 0;  // no burst
        else if (bytes_left >= BYTES_PER_BEAT * 16)
            BEATS_PER_BURST = 16; // max AXI3 burst
        else
            // ceil division to cover remaining bytes
            BEATS_PER_BURST = (bytes_left + BYTES_PER_BEAT - 1) / BYTES_PER_BEAT;
    end

    // =============================
    // Configuration error check 
    // =============================
    localparam SPM_BASE = 64'h80000000;
    localparam SPM_SIZE = 64'd8192; // 8 KB
    
    wire src_is_spm;
    wire dst_is_spm;
    assign src_is_spm = (src >= SPM_BASE) && (src < SPM_BASE + SPM_SIZE);
    assign dst_is_spm = (dst >= SPM_BASE) && (dst < SPM_BASE + SPM_SIZE);
    
    wire dir_error;
    assign dir_error = (dir == 1 && !(~src_is_spm && dst_is_spm)) || 
                      (dir == 0 && !(src_is_spm && ~dst_is_spm));
    
    wire size_error;
    assign size_error = (size == 0);
    
    wire confg_error;
    assign confg_error = dir_error || size_error;

    // =============================
    // State Definitions 
    // =============================
    localparam [2:0] IDLE           = 3'd0;
    localparam [2:0] READ_ADDR      = 3'd1;
    localparam [2:0] READ_DATA      = 3'd2;
    localparam [2:0] WRITE_ADDR     = 3'd3;
    localparam [2:0] WRITE_DATA     = 3'd4;
    localparam [2:0] WRITE_RESP     = 3'd5;
    localparam [2:0] ERROR          = 3'd6;


    // ============================= 
    // STATE REGISTER
    // =============================
    always @(posedge clk or negedge reset_n) 
    begin
        if (!reset_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // =============================
    // NEXT STATE LOGIC
    // =============================
    always @(*) 
    begin
        case (current_state)
        IDLE: begin
            if (start && confg_error) begin
                next_state = ERROR;
                end
            else if (start) begin
                if (dir) // MEM to SPM
                    next_state = READ_ADDR;
                else // SPM to MEM
                    next_state = WRITE_ADDR;
            end
            else begin
                next_state = IDLE;
            end
            end
            
        READ_ADDR: begin
                if (M_AXI_ARVALID && M_AXI_ARREADY)
                    next_state = READ_DATA;
            end
            
        READ_DATA: begin
                if (M_AXI_RVALID && M_AXI_RREADY && (bytes_left > 0)) begin
                        next_state = READ_DATA;   // Issue next burst
                end
               else if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST) begin
                        next_state = IDLE;        // Transfer complete
                    end
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
                if (M_AXI_BVALID && M_AXI_BREADY)
                    next_state = IDLE;
            end

        ERROR:
            next_state = IDLE;

        default:
            next_state = IDLE;
        endcase
    end

 
    // =============================
    // CONTROL LOGIC
    // =============================
    always @(posedge clk or negedge reset_n) 
    begin
        if (!reset_n) 
        begin
            // Reset DMA outputs
            dma_done <= 0;
            dma_busy <= 0;
            dma_start_ack <= 0;
            dma_confg_error <= 0;
            dma_bus_error <= 0;
            
            // Reset AXI Write Address Channel
            M_AXI_AWADDR <= {AXI_ADDR_WIDTH{1'b0}};
            M_AXI_AWLEN <= 4'b0; 
            M_AXI_AWSIZE <= 3'b0;
            M_AXI_AWBURST <= 2'b01; // INCR
            M_AXI_AWVALID <= 1'b0;
            
            // Reset AXI Write Data Channel
            M_AXI_WDATA <= {AXI_DATA_WIDTH{1'b0}};
            M_AXI_WSTRB <= {(AXI_DATA_WIDTH/8){1'b0}};
            M_AXI_WLAST <= 1'b0;
            M_AXI_WVALID <= 1'b0;
            
            // Reset AXI Write Response Channel
            M_AXI_BREADY <= 1'b0;
            
            // Reset AXI Read Address Channel
            M_AXI_ARADDR <= {AXI_ADDR_WIDTH{1'b0}};
            M_AXI_ARLEN <= 4'b0;
            M_AXI_ARSIZE <= 3'b0;
            M_AXI_ARBURST <= 2'b00; // INCR
            M_AXI_ARVALID <= 1'b0;
            
            // Reset AXI Read Data Channel
            M_AXI_RREADY <= 1'b0;
            
            // Reset SPM Interface
            spm_addr <= 64'b0;
            spm_wdata <= 64'b0;
            dma_ctrl_re <= 1'b0;
            dma_ctrl_we <= 1'b0;
            
            // Reset internal registers
            bytes_left <= 64'b0;
            current_src <= 64'b0;
            current_dst <= 64'b0;
            beat_counter <= 4'b0;
        end 
        else begin
            // Default outputs
            dma_start_ack <= 1'b0;
            dma_done <= 1'b0;
//            dma_ctrl_re <= 1'b0;
//            dma_ctrl_we <= 1'b0;
            
            case (current_state)

                IDLE: begin
                    dma_busy <= 0;
                    M_AXI_ARVALID <= 1'b0;
                    M_AXI_AWVALID <= 1'b0;
                    M_AXI_WVALID <= 1'b0;
                    M_AXI_RREADY <= 1'b0;
                    M_AXI_BREADY <= 1'b0;
                    beat_counter <= 4'b0;
                    
                    if (start && !confg_error) begin //i guess we need to latch this config error?
                        dma_busy <= 1;
                        dma_start_ack <= 1;
                        
                        bytes_left <= size;
                        current_src <= src;
                        current_dst <= dst;
                    end
                end

             READ_ADDR: begin
                    // Setup AXI read request for MEM to SPM
                    if (!M_AXI_ARVALID) begin
                        M_AXI_ARADDR <= current_src;
                        M_AXI_ARLEN <= BEATS_PER_BURST - 1; 
                        M_AXI_ARSIZE <= $clog2(BYTES_PER_BEAT); // 4
                        M_AXI_ARBURST <= 2'b01; // INCR
                        M_AXI_ARVALID <= 1'b1;
                    end
                    
                      if (M_AXI_ARREADY) begin
                        M_AXI_ARVALID <= 1'b0;
                    end
                    
                    M_AXI_RREADY <= 1'b1;  // Ready to receive data
                end
                
                READ_DATA: begin
                    // Ready to receive read data
                    M_AXI_RREADY <= 1'b1;
                    
                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        // Check for bus errors
                        if (M_AXI_RRESP != 2'b00) begin
                            dma_bus_error <= 1'b1;
                        end
                       
                       if (dir == 1) begin
                            spm_addr  <= current_dst + (beat_counter * BYTES_PER_BEAT); // 128-bit = 16 bytes
                            spm_wdata <= M_AXI_RDATA;
                            dma_ctrl_we <= 1'b1;
                       end
                        
                        beat_counter <= beat_counter + 1;
                        
                        if (M_AXI_RLAST) begin
                            M_AXI_RREADY <= 1'b0;
                            end
                            // Update addresses and bytes left
                            current_src <= current_src + (BEATS_PER_BURST * BYTES_PER_BEAT);
                            current_dst <= current_dst + (BEATS_PER_BURST * (BYTES_PER_BEAT/2) ); // 64-bit increments
                            bytes_left <= bytes_left - (BEATS_PER_BURST * BYTES_PER_BEAT);
                            
                            beat_counter <= 4'b0;
                         
                        end
                    end
                
                WRITE_ADDR: begin
                    // Setup AXI write request for SPM to MEM
                    if (!M_AXI_AWVALID) begin
                        M_AXI_AWADDR <= current_dst;
                        M_AXI_AWLEN <= BEATS_PER_BURST - 1;
                        M_AXI_AWSIZE <= $clog2(BYTES_PER_BEAT);
                        M_AXI_AWBURST <= 2'b01;
                        M_AXI_AWVALID <= 1'b1;
                    end
                    
                    if (M_AXI_AWREADY) begin
                        M_AXI_AWVALID <= 1'b0;
                    end
                    
                    // Read first data from SPM
                    if (beat_counter == 0) begin
                        spm_addr <= current_src;
                        dma_ctrl_re <= 1'b1;
                        //M_AXI_WVALID <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    // Send write data
                   // M_AXI_WVALID <= 1'b0;
                    if (!M_AXI_WVALID || (M_AXI_WVALID && M_AXI_WREADY)) begin // !M_AXI_WVALID 
                        // 128-bit AXI
                        M_AXI_WDATA <= spm_rdata; // 128-bit AXI two concatenated data
                        //spm_addr <= current_src + (beat_counter * BYTES_PER_BEAT); 
                        M_AXI_WSTRB <= 16'b1111_1111_1111_1111;  // All bytes valid
                        M_AXI_WLAST <= (beat_counter == (BEATS_PER_BURST-1));
                        M_AXI_WVALID <= 1'b1;
                        
                        if (M_AXI_WREADY) begin
                            beat_counter = beat_counter + 1;
                            spm_addr <= current_src + (beat_counter * BYTES_PER_BEAT); 
                            dma_ctrl_re <= 1'b1;
                            // Read next SPM data if not last beat
                           if (M_AXI_WLAST) begin
                                beat_counter <= 0;
                                M_AXI_WVALID <= 0;
                          end 
                        end
                    end
                end
                
                WRITE_RESP: begin
                    dma_ctrl_re <= 1'b0;
                    M_AXI_WVALID <= 1'b0;
                    beat_counter <= 0;
                    if (M_AXI_BVALID) begin
                        M_AXI_BREADY <= 1'b1;
                        // Check for bus errors
                        if (M_AXI_BRESP != 2'b00) begin
                            dma_bus_error <= 1'b1;
                        end
                        
                        // Update addresses and bytes left
                        current_dst <= current_dst + (BEATS_PER_BURST * BYTES_PER_BEAT);
                        current_src <= current_src + (BEATS_PER_BURST * BYTES_PER_BEAT); // 64-bit increments
                        bytes_left <= bytes_left - (BEATS_PER_BURST * BYTES_PER_BEAT);
                        
                        beat_counter <= 4'b0;
                    end
                end
                
                ERROR: begin
                    dma_confg_error <= 1'b1;
                    dma_busy <= 1'b0;
                end
            endcase
            
            // Set dma_done when transfer completes
            if (bytes_left == 0 && (current_state == WRITE_RESP || current_state == READ_DATA)) begin
                dma_done <= 1'b1;
                dma_busy <= 1'b0;
            end
            if (dma_done) begin 
            dma_busy <= 1'b0;
            dma_ctrl_re <= 1'b0;
            dma_ctrl_we <= 1'b0;
            end
        end
    end
endmodule
