`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26/2/2026 05:01:18 AM
// Design Name: 
// Module Name: Arbiter
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
module Arbiter #(
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 128
    )(
    input wire clk,
    input wire reset_n,

    // Master 0 (CPU_TOP) AXI Interface
    input  wire [AXI_ADDR_WIDTH-1:0]   cpu_axi_awaddr,
    input  wire [3:0]                  cpu_axi_awlen,
    input  wire [2:0]                  cpu_axi_awsize,
    input  wire [1:0]                  cpu_axi_awburst,
    input  wire                        cpu_axi_awvalid,
    output wire                        cpu_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0]   cpu_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0] cpu_axi_wstrb,
    input  wire                        cpu_axi_wlast,
    input  wire                        cpu_axi_wvalid,
    output wire                        cpu_axi_wready,

    output wire [1:0]                  cpu_axi_bresp,
    output wire                        cpu_axi_bvalid,
    input  wire                        cpu_axi_bready,

    input  wire [AXI_ADDR_WIDTH-1:0]   cpu_axi_araddr,
    input  wire [3:0]                  cpu_axi_arlen,
    input  wire [2:0]                  cpu_axi_arsize,
    input  wire [1:0]                  cpu_axi_arburst,
    input  wire                        cpu_axi_arvalid,
    output wire                        cpu_axi_arready,

    output wire [AXI_DATA_WIDTH-1:0]   cpu_axi_rdata,
    output wire [1:0]                  cpu_axi_rresp,
    output wire                        cpu_axi_rlast,
    output wire                        cpu_axi_rvalid,
    input  wire                        cpu_axi_rready,

    // Master 1 (SPM_TOP) AXI Interface
    input  wire [AXI_ADDR_WIDTH-1:0]   dma_axi_awaddr,
    input  wire [3:0]                  dma_axi_awlen,
    input  wire [2:0]                  dma_axi_awsize,
    input  wire [1:0]                  dma_axi_awburst,
    input  wire                        dma_axi_awvalid,
    output wire                        dma_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0]   dma_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0] dma_axi_wstrb,
    input  wire                        dma_axi_wlast,
    input  wire                        dma_axi_wvalid,
    output wire                        dma_axi_wready,

    output wire [1:0]                  dma_axi_bresp,
    output wire                        dma_axi_bvalid,
    input wire                         dma_axi_bready, 

    input  wire [AXI_ADDR_WIDTH-1:0]   dma_axi_araddr,
    input  wire [3:0]                  dma_axi_arlen,
    input  wire [2:0]                  dma_axi_arsize,
    input  wire [1:0]                  dma_axi_arburst,
    input  wire                        dma_axi_arvalid,
    output wire                        dma_axi_arready,

    output wire [AXI_DATA_WIDTH-1:0]   dma_axi_rdata,
    output wire [1:0]                  dma_axi_rresp,
    output wire                        dma_axi_rlast,
    output wire                        dma_axi_rvalid,
    input  wire                        dma_axi_rready,

    // Slave (Main Memory) AXI Interface
    output wire [AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    output wire [3:0]                  s_axi_awlen,
    output wire [2:0]                  s_axi_awsize,
    output wire [1:0]                  s_axi_awburst,
    output wire                        s_axi_awvalid,
    input  wire                        s_axi_awready,

    output wire [AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    output wire                        s_axi_wlast,
    output wire                        s_axi_wvalid,
    input  wire                        s_axi_wready,

    input  wire [1:0]                  s_axi_bresp,
    input  wire                        s_axi_bvalid,
    output wire                        s_axi_bready,

    output wire [AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    output wire [3:0]                  s_axi_arlen,
    output wire [2:0]                  s_axi_arsize,
    output wire [1:0]                  s_axi_arburst,
    output wire                        s_axi_arvalid,
    input  wire                        s_axi_arready,

    input  wire [AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    input  wire [1:0]                  s_axi_rresp,
    input  wire                        s_axi_rlast,
    input  wire                        s_axi_rvalid,
    output wire                        s_axi_rready
);

    // Internal signals for arbitration state
    reg current_master_w; // 0 for CPU, 1 for DMA
    reg current_master_r; // 0 for CPU, 1 for DMA

    // State for write channel arbitration
    localparam IDLE_W = 2'b00;
    localparam GRANT_CPU_W = 2'b01;
    localparam GRANT_DMA_W = 2'b10;
    reg [1:0] write_state;

    // State for read channel arbitration
    localparam IDLE_R = 2'b00;
    localparam GRANT_CPU_R = 2'b01;
    localparam GRANT_DMA_R = 2'b10;
    reg [1:0] read_state;

    // =========================================================================
    // Write Address (AW) Channel Arbitration
    // =========================================================================

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            write_state <= IDLE_W;
            current_master_w <= 1'b0; // Default to CPU
        end else begin
            case (write_state)
                IDLE_W: begin
                    if (cpu_axi_awvalid) begin // CPU has priority
                        write_state <= GRANT_CPU_W;
                        current_master_w <= 1'b0;
                    end else if (dma_axi_awvalid) begin // DMA only if CPU not requesting
                        write_state <= GRANT_DMA_W;
                        current_master_w <= 1'b1;
                    end
                end
                GRANT_CPU_W: begin
                    // Stay in this state until the entire burst is complete
                    // A write burst is complete when WLAST is transferred AND BVALID is received and BREADY is high.
                    if (s_axi_bvalid && cpu_axi_bready) begin
                        write_state <= IDLE_W;
                    end
                end
                GRANT_DMA_W: begin
                    // Stay in this state until the entire burst is complete
                    if (s_axi_bvalid && dma_axi_bready) begin
                        // DMA burst complete. Check for pending CPU request.
                        if (cpu_axi_awvalid) begin
                            write_state <= GRANT_CPU_W;
                            current_master_w <= 1'b0; // Switch to CPU
                        end else begin
                            write_state <= IDLE_W;
                        end
                    end
                end
                default: write_state <= IDLE_W;
            endcase
        end
    end

    // AWREADY generation
    assign cpu_axi_awready =(write_state == GRANT_CPU_W && s_axi_awready);
                                     
    assign dma_axi_awready =(write_state == GRANT_DMA_W && s_axi_awready);

    // AW Channel Muxing to Slave
    assign s_axi_awaddr  = (current_master_w == 1'b0) ? cpu_axi_awaddr  : dma_axi_awaddr;
    assign s_axi_awlen   = (current_master_w == 1'b0) ? cpu_axi_awlen   : dma_axi_awlen;
    assign s_axi_awsize  = (current_master_w == 1'b0) ? cpu_axi_awsize  : dma_axi_awsize;
    assign s_axi_awburst = (current_master_w == 1'b0) ? cpu_axi_awburst : dma_axi_awburst;
    assign s_axi_awvalid = ((write_state == GRANT_CPU_W) && cpu_axi_awvalid) ||
                           ((write_state == GRANT_DMA_W) && dma_axi_awvalid);

    // =========================================================================
    // Write Data (W) Channel Muxing
    // =========================================================================
    assign s_axi_wdata  = (current_master_w == 1'b0) ? cpu_axi_wdata  : dma_axi_wdata;
    assign s_axi_wstrb  = (current_master_w == 1'b0) ? cpu_axi_wstrb  : dma_axi_wstrb;
    assign s_axi_wlast  = (current_master_w == 1'b0) ? cpu_axi_wlast  : dma_axi_wlast;
    assign s_axi_wvalid = (current_master_w == 1'b0) ? cpu_axi_wvalid : dma_axi_wvalid;

    // WREADY generation
    assign cpu_axi_wready = (current_master_w == 1'b0) ? s_axi_wready : 1'b0;
    assign dma_axi_wready = (current_master_w == 1'b1) ? s_axi_wready : 1'b0;

    // =========================================================================
    // Write Response (B) Channel Demuxing
    // =========================================================================
    assign cpu_axi_bresp  = (current_master_w == 1'b0) ? s_axi_bresp  : 2'b00;
    assign cpu_axi_bvalid = (current_master_w == 1'b0) ? s_axi_bvalid : 1'b0;
    assign dma_axi_bresp  = (current_master_w == 1'b1) ? s_axi_bresp  : 2'b00;
    assign dma_axi_bvalid = (current_master_w == 1'b1) ? s_axi_bvalid : 1'b0;

    // BREADY generation
    assign s_axi_bready = (current_master_w == 1'b0) ? cpu_axi_bready : dma_axi_bready;

    // =========================================================================
    // Read Address (AR) Channel Arbitration
    // =========================================================================

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            read_state <= IDLE_R;
            current_master_r <= 1'b0; // Default to CPU
        end else begin
            case (read_state)
                IDLE_R: begin
                    if (cpu_axi_arvalid) begin // CPU has priority
                        read_state <= GRANT_CPU_R;
                        current_master_r <= 1'b0;
                    end else if (dma_axi_arvalid) begin // DMA only if CPU not requesting
                        read_state <= GRANT_DMA_R;
                        current_master_r <= 1'b1;
                    end
                end
                GRANT_CPU_R: begin
                    // Stay in this state until the entire burst is complete
                    if (s_axi_rvalid && s_axi_rlast && s_axi_rready) begin
                        read_state <= IDLE_R;
                    end
                end
                GRANT_DMA_R: begin
                    // Stay in this state until the entire burst is complete
                    if (s_axi_rvalid && s_axi_rlast && s_axi_rready) begin
                        // DMA burst complete. Check for pending CPU request.
                        if (cpu_axi_arvalid) begin
                            read_state <= GRANT_CPU_R;
                            current_master_r <= 1'b0; // Switch to CPU
                        end else begin
                            read_state <= IDLE_R;
                        end
                    end
                end
                default: read_state <= IDLE_R;
            endcase
        end
    end

    // ARREADY generation
    assign cpu_axi_arready = (read_state == GRANT_CPU_R && s_axi_arready);
    assign dma_axi_arready = (read_state == GRANT_DMA_R && s_axi_arready);

    // AR Channel Muxing to Slave
    assign s_axi_araddr  = (current_master_r == 1'b0) ? cpu_axi_araddr  : dma_axi_araddr;
    assign s_axi_arlen   = (current_master_r == 1'b0) ? cpu_axi_arlen   : dma_axi_arlen;
    assign s_axi_arsize  = (current_master_r == 1'b0) ? cpu_axi_arsize  : dma_axi_arsize;
    assign s_axi_arburst = (current_master_r == 1'b0) ? cpu_axi_arburst : dma_axi_arburst;
    assign s_axi_arvalid = ((read_state == GRANT_CPU_R) && cpu_axi_arvalid) ||
                           ((read_state == GRANT_DMA_R) && dma_axi_arvalid);

    // =========================================================================
    // Read Data (R) Channel Demuxing
    // =========================================================================
    assign cpu_axi_rdata  = (current_master_r == 1'b0) ? s_axi_rdata  : {AXI_DATA_WIDTH{1'b0}};
    assign cpu_axi_rresp  = (current_master_r == 1'b0) ? s_axi_rresp  : 2'b00;
    assign cpu_axi_rlast  = (current_master_r == 1'b0) ? s_axi_rlast  : 1'b0;
    assign cpu_axi_rvalid = (current_master_r == 1'b0) ? s_axi_rvalid : 1'b0;
    assign dma_axi_rdata  = (current_master_r == 1'b1) ? s_axi_rdata  : {AXI_DATA_WIDTH{1'b0}};
    assign dma_axi_rresp  = (current_master_r == 1'b1) ? s_axi_rresp  : 2'b00;
    assign dma_axi_rlast  = (current_master_r == 1'b1) ? s_axi_rlast  : 1'b0;
    assign dma_axi_rvalid = (current_master_r == 1'b1) ? s_axi_rvalid : 1'b0;

    // RREADY generation
    assign s_axi_rready = (current_master_r == 1'b0) ? cpu_axi_rready : dma_axi_rready;

endmodule

