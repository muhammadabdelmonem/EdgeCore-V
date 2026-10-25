`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2026 01:57:13 AM
// Design Name: 
// Module Name: Direct_CPU_AXI_Bridge
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


module Direct_CPU_AXI_Bridge#(
    parameter AXI_ADDR_WIDTH  = 64,
    parameter AXI_DATA_WIDTH  = 128,   
    parameter CACHE_LINE_SIZE = 512    // I-Cache line size in bits
)(  
    // AXI Global
    input  wire ACLK,
    input  wire ARESETn,


    // Direct CPU Data-Memory Interface 
    input  wire         cpu_d_read_en,    
    input  wire         cpu_d_write_en,   
    input  wire [63:0]  cpu_d_address,    
    input  wire [63:0]  cpu_d_wdata,     
    input  wire [2:0]   cpu_d_size,      
    output reg  [63:0]  cpu_d_rdata,      
    output reg          cpu_d_read_valid,
    output reg          cpu_d_write_ready,
    output reg d_stall,
    output reg d_bus_error_exception,
    output store_exception, 
    output [63:0] mem_exception_addr ,  

    // I-Cache Interface  (UNCHANGED from original Caches_Axi_Bridge)
    input  wire                         icache_r_en,
    input  wire [63:0]                  icache_r_address,
    input  wire [31:0]                  icache_r_size,    
    output reg                          icache_r_valid,
    output reg  [CACHE_LINE_SIZE-1:0]   icache_r_data,
    input icache_stall_F,

    // AXI3 Master Interface  (identical to original)
    // Write Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0]    M_AXI_AWADDR,
    output reg  [3:0]                   M_AXI_AWLEN,
    output reg  [2:0]                   M_AXI_AWSIZE,
    output reg  [1:0]                   M_AXI_AWBURST,
    output reg                          M_AXI_AWVALID,
    input  wire                         M_AXI_AWREADY,

    // Write Data Channel
    output reg  [AXI_DATA_WIDTH-1:0]    M_AXI_WDATA,
    output reg  [AXI_DATA_WIDTH/8-1:0]  M_AXI_WSTRB,
    output reg                          M_AXI_WLAST,
    output reg                          M_AXI_WVALID,
    input  wire                         M_AXI_WREADY,

    // Write Response Channel
    input  wire [1:0]                   M_AXI_BRESP,
    input  wire                         M_AXI_BVALID,
    output reg                          M_AXI_BREADY,

    // Read Address Channel
    output reg  [AXI_ADDR_WIDTH-1:0]    M_AXI_ARADDR,
    output reg  [3:0]                   M_AXI_ARLEN,
    output reg  [2:0]                   M_AXI_ARSIZE,
    output reg  [1:0]                   M_AXI_ARBURST,
    output reg                          M_AXI_ARVALID,
    input  wire                         M_AXI_ARREADY,

    // Read Data Channel
    input  wire [AXI_DATA_WIDTH-1:0]    M_AXI_RDATA,
    input  wire [1:0]                   M_AXI_RRESP,
    input  wire                         M_AXI_RLAST,
    input  wire                         M_AXI_RVALID,
    output reg                          M_AXI_RREADY
    );
    
    //some constants
    localparam BYTES_PER_BEAT       = AXI_DATA_WIDTH / 8;           // 16
    localparam BEAT_OFFSET_BITS     = $clog2(BYTES_PER_BEAT);        // 4
    localparam BEATS_PER_CACHE_LINE = CACHE_LINE_SIZE / AXI_DATA_WIDTH; // 4

    // State encoding
    localparam [2:0] IDLE        = 3'd0;
    localparam [2:0] READ_ADDR   = 3'd1;
    localparam [2:0] READ_DATA   = 3'd2;
    localparam [2:0] READ_DONE   = 3'd3;
    localparam [2:0] WRITE_ADDR  = 3'd4;
    localparam [2:0] WRITE_DATA  = 3'd5;
    localparam [2:0] WRITE_RESP  = 3'd6;
    //Time out parametere and reg
    localparam TIMEOUT_CYCLES = 1000; // Wait 1000 cycles before giving up   //exactly how long should we wait ??????
    reg [11:0] timeout_counter; // A counter large enough for TIMEOUT_CYCLES

    //state regs
    reg [2:0]  state, next_state;
    reg [7:0]  beat_counter;
    reg [CACHE_LINE_SIZE-1:0] read_buffer;   // 512-bit; only [127:0] used for D-direct    
    reg current_is_d;  //   1 = D-direct, 0 = I-Cache
    // latch cpu info
    reg [63:0] saved_addr;
    reg [63:0] saved_wdata;
    reg [2:0]  saved_size; 
    reg is_writing ; 
    
    // Rising-edge detection for enable signals
    reg cpu_d_read_en_prev;
    reg cpu_d_write_en_prev;
    reg icache_r_en_prev;
    wire cpu_d_read_rising  = cpu_d_read_en  & ~cpu_d_read_en_prev;
    wire cpu_d_write_rising = cpu_d_write_en & ~cpu_d_write_en_prev;
    wire icache_r_rising    = icache_r_en    & ~icache_r_en_prev;
    
    //data setup (only for the data memory)
    wire [63:0] d_aligned_addr = {saved_addr[63:BEAT_OFFSET_BITS], {BEAT_OFFSET_BITS{1'b0}}}; //getting the base address
    wire [3:0] d_byte_offset = saved_addr[BEAT_OFFSET_BITS-1:0]; //the location of the first offset bzte
    wire [6:0] d_shift_bits = {d_byte_offset, 3'b000};  // multiply the offset by 8 to get the offset bits
    
    //Writing setup
    reg [BYTES_PER_BEAT-1:0] d_wstrb_base;  // base mask before shifting
    // set the mask based on the size
    always @(*) begin
        case (saved_size[1:0])  // only bottom 2 bits matter for byte count the thirs is for the sign and we don't care now
            2'b00:   d_wstrb_base = 16'h0001; //00000001  one byte   SB
            2'b01:   d_wstrb_base = 16'h0003; //00000011  two bytes  SH
            2'b10:   d_wstrb_base = 16'h000F; //00001111  4 bytes    SW
            2'b11:   d_wstrb_base = 16'h00FF; //11111111  8 bytes    SD
            default: d_wstrb_base = 16'h00FF;
        endcase
    end
    //the data to be written and its mask 
    wire [BYTES_PER_BEAT-1:0] d_wstrb = d_wstrb_base << d_byte_offset; //shifting the mask to match the offset
    wire [AXI_DATA_WIDTH-1:0] d_wdata_shifted ={{(AXI_DATA_WIDTH-64){1'b0}}, saved_wdata} << d_shift_bits; ////shifting the data to match the offset
    
    //Reading setup 
    wire [63:0] d_rdata_raw = read_buffer[127:0] >> d_shift_bits; //shidt the data so the first byte be at location zero 
    reg [63:0] d_rdata_final;
    always@(*)begin
        case(saved_size)
            3'b000:  d_rdata_final = {{56{d_rdata_raw[7]}},  d_rdata_raw[7:0]}; //LB
            3'b001:  d_rdata_final = {{48{d_rdata_raw[15]}}, d_rdata_raw[15:0]}; //LH
            3'b010:  d_rdata_final = {{32{d_rdata_raw[31]}}, d_rdata_raw[31:0]}; //LW
            3'b011:  d_rdata_final = d_rdata_raw;  //LD
            3'b100:  d_rdata_final = {56'b0, d_rdata_raw[7:0]}; //LBU
            3'b101:  d_rdata_final = {48'b0, d_rdata_raw[15:0]}; //LHU
            3'b110:  d_rdata_final = {32'b0, d_rdata_raw[31:0]}; //LWU
            default: d_rdata_final = 64'b0;
        endcase
    end
    
    //assign d_stall = ((state != IDLE) ||(cpu_d_read_en && ~cpu_d_read_valid) || (cpu_d_write_en && ~cpu_d_write_ready))&& ~d_bus_error_exception ;
    always@(*) begin
        d_stall = 0 ;
        if(((state != IDLE && current_is_d) ||((cpu_d_read_en == 1'b1 )&& ~cpu_d_read_valid) || ((cpu_d_write_en == 1'b1)&& ~cpu_d_write_ready))&& ~d_bus_error_exception)
            d_stall = 1;
        else 
            d_stall = 0 ;
    end
    //nnext state logic
    wire w_en = (state != IDLE) ;
    reg write_req_in_flight;
    wire r_en = (state != IDLE) ;
    reg read_req_in_flight;
    reg icache_req_pending;
    reg [63:0] saved_icache_addr;
    always @(posedge ACLK) begin
    if (!ARESETn) begin
        icache_req_pending <= 1'b0;
    end else begin
        // latch request
        if (icache_r_en && !icache_req_pending) begin
            icache_req_pending <= 1'b1;
            saved_icache_addr  <= icache_r_address;
        end

        // clear when served
        if (state == READ_DONE && !current_is_d) begin
            icache_req_pending <= 1'b0;
        end
    end
end
    
    
    always @(posedge ACLK) begin
        if (!ARESETn) 
            state <= IDLE;
        else         
            state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        if (d_bus_error_exception) begin
        next_state = IDLE;   // abort everything, go home
        end else begin
        case (state)
            IDLE: begin
                // D-write has highest priority (matches original arbitration)
                if(cpu_d_write_en && ~write_req_in_flight) 
                    next_state = WRITE_ADDR;
                else if(cpu_d_read_en && ~read_req_in_flight)
                    next_state = READ_ADDR;
                else if (icache_req_pending)    
                    next_state = READ_ADDR;
                else
                    next_state = IDLE;
            end
            READ_ADDR:
                if (M_AXI_ARVALID && M_AXI_ARREADY)
                    next_state = READ_DATA;
            READ_DATA:
                if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST) 
                    next_state = READ_DONE;
            READ_DONE:
                next_state = IDLE;
            WRITE_ADDR:
                if (M_AXI_AWVALID && M_AXI_AWREADY) 
                    next_state = WRITE_DATA;
            WRITE_DATA:
                if (M_AXI_WVALID && M_AXI_WREADY && M_AXI_WLAST) 
                    next_state = WRITE_RESP;
            WRITE_RESP:
                if (M_AXI_BVALID && (M_AXI_BRESP == 2'b00)) 
                    next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
        end
    end
    
    //output logic
    always@(posedge ACLK)begin
        if(~ARESETn)begin
        
            cpu_d_rdata <= 64'b0;
            cpu_d_read_valid <= 1'b0;
            cpu_d_write_ready <= 1'b0;
            d_bus_error_exception <= 1'b0;
            icache_r_valid <= 1'b0;
            icache_r_data <= {CACHE_LINE_SIZE{1'b0}};
            
            beat_counter        <= 8'b0;
            read_buffer         <= {CACHE_LINE_SIZE{1'b0}};
            current_is_d        <= 1'b0;
            saved_addr          <= 64'b0;
            saved_wdata         <= 64'b0;
            saved_size          <= 3'b0;
            cpu_d_read_en_prev  <= 1'b0;
            cpu_d_write_en_prev <= 1'b0;
            icache_r_en_prev    <= 1'b0;
            is_writing <= 1'b0;
            timeout_counter <= 1'b0;
            write_req_in_flight <= 1'b0;
            read_req_in_flight <= 1'b0;
            
            M_AXI_AWADDR  <= {AXI_ADDR_WIDTH{1'b0}};
            M_AXI_AWLEN   <= 4'b0;
            M_AXI_AWSIZE  <= 3'b0;
            M_AXI_AWBURST <= 2'b01;
            M_AXI_AWVALID <= 1'b0;

            M_AXI_WDATA   <= {AXI_DATA_WIDTH{1'b0}};
            M_AXI_WSTRB   <= {(AXI_DATA_WIDTH/8){1'b0}};
            M_AXI_WLAST   <= 1'b0;
            M_AXI_WVALID  <= 1'b0;
            M_AXI_BREADY  <= 1'b0;

            M_AXI_ARADDR  <= {AXI_ADDR_WIDTH{1'b0}};
            M_AXI_ARLEN   <= 4'b0;
            M_AXI_ARSIZE  <= 3'b0;
            M_AXI_ARBURST <= 2'b01;
            M_AXI_ARVALID <= 1'b0;
            M_AXI_RREADY  <= 1'b0;
        
        end else begin
            // Update edge-detection 
            cpu_d_read_en_prev  <= cpu_d_read_en;
            cpu_d_write_en_prev <= cpu_d_write_en;
            icache_r_en_prev    <= icache_r_en;
            write_req_in_flight <= w_en;
            read_req_in_flight  <= r_en;
            // Default is zero
            cpu_d_read_valid  <= 1'b0;
            cpu_d_write_ready <= 1'b0;
            icache_r_valid    <= 1'b0;
            
            case(state)
            IDLE:begin
                    M_AXI_ARVALID <= 1'b0;
                    M_AXI_AWVALID <= 1'b0;
                    M_AXI_WVALID  <= 1'b0;
                    M_AXI_RREADY  <= 1'b0;
                    M_AXI_BREADY  <= 1'b0;
                    beat_counter  <= 8'b0;
                    is_writing <= 1'b0;
                    // Capture the request that trna get access 
                    if (cpu_d_write_en) begin
                        current_is_d <= 1'b1;
                        saved_addr   <= cpu_d_address;
                        saved_wdata  <= cpu_d_wdata;
                        saved_size   <= cpu_d_size;
                        is_writing <= 1'b1;
                    end else if (cpu_d_read_en) begin
                        current_is_d <= 1'b1;
                        saved_addr   <= cpu_d_address;
                        saved_size   <= cpu_d_size;
                    end else if (icache_req_pending) begin
                        current_is_d <= 1'b0;
                        // icache_r_address sampled directly in READ_ADDR below
                    end
            end     
            READ_ADDR:begin
                    if (!M_AXI_ARVALID) begin
                        if (current_is_d) begin
                            M_AXI_ARADDR <= d_aligned_addr;
                            M_AXI_ARLEN  <= 4'd0;  // only 1 beat
                        end else begin
                            M_AXI_ARADDR <= saved_icache_addr;
                            M_AXI_ARLEN  <= BEATS_PER_CACHE_LINE - 1;  
                        end
                        M_AXI_ARSIZE  <= $clog2(BYTES_PER_BEAT);
                        M_AXI_ARBURST <= 2'b01;   // INCR
                        M_AXI_ARVALID <= 1'b1;
                    end
                    if (M_AXI_ARREADY)
                        M_AXI_ARVALID <= 1'b0;

                    M_AXI_RREADY <= 1'b1;
                
            end 
            READ_DATA:begin
                    M_AXI_RREADY <= 1'b1;
                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        // cbuffer the incoming beat into the read buffer
                        read_buffer[beat_counter * AXI_DATA_WIDTH +: AXI_DATA_WIDTH]<= M_AXI_RDATA;
                        beat_counter <= beat_counter + 1;

                        if (M_AXI_RLAST) begin
                            M_AXI_RREADY <= 1'b0;
                            beat_counter  <= 8'b0;
                        end
                    end        
            end 
            READ_DONE:begin
                    if (current_is_d) begin
                        // Extract & zero-mask the bytes the CPU actually asked for
                        cpu_d_rdata <= d_rdata_final;
                        cpu_d_read_valid <= 1'b1;
                    end else begin
                        icache_r_data <= read_buffer;
                        icache_r_valid <= 1'b1;
                    end
            end 
            WRITE_ADDR:begin
                    if (!M_AXI_AWVALID) begin
                        M_AXI_AWADDR  <= d_aligned_addr;
                        M_AXI_AWLEN   <= 4'd0; // 1 beat
                        M_AXI_AWSIZE  <= $clog2(BYTES_PER_BEAT);   
                        M_AXI_AWBURST <= 2'b01;
                        M_AXI_AWVALID <= 1'b1;
                    end
                    if (M_AXI_AWREADY)
                        M_AXI_AWVALID <= 1'b0;
            end
            WRITE_DATA:begin
                    if (!M_AXI_WVALID || (M_AXI_WVALID && M_AXI_WREADY)) begin
                        M_AXI_WDATA  <= d_wdata_shifted;  // CPU data at correct position
                        M_AXI_WSTRB  <= d_wstrb;          // Only target bytes enabled
                        M_AXI_WLAST  <= 1'b1;             // Always the only beat
                        M_AXI_WVALID <= 1'b1;
                        if (M_AXI_WREADY) begin
                            if (M_AXI_WLAST) begin
                                M_AXI_WVALID <= 1'b0;
                                M_AXI_WLAST  <= 1'b0;
                            end
                        end
                    end       
            end
            WRITE_RESP:begin
                    //M_AXI_BREADY <= 1'b1;
                    if (M_AXI_BVALID && (M_AXI_BRESP == 2'b00)) begin
                        cpu_d_write_ready <= 1'b1; // Tell CPU the write is done
                        M_AXI_BREADY      <= 1'b1;
                    end
            end
            endcase
            
            //Timeout Counter Management
            if (state != IDLE && current_is_d) begin
            // If we are waiting for memory, increment the counter
            if (timeout_counter < TIMEOUT_CYCLES) begin
                timeout_counter <= timeout_counter + 1;
            end else begin
                // We have timed out!
                d_bus_error_exception <= 1'b1;
                timeout_counter       <= 12'b0;
            end
            end else begin
            // If we are not waiting for memory, keep the counter reset
            timeout_counter       <= 12'b0;
            d_bus_error_exception <= 1'b0;  // clear when idle or I-Cache running
            end  
        end
    end
    assign store_exception = is_writing;
    assign mem_exception_addr = saved_addr;
endmodule
