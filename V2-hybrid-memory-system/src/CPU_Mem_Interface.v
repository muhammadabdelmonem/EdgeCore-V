`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2026 01:56:24 AM
// Design Name: 
// Module Name: CPU_Mem_Interface
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


module CPU_Mem_Interface(
    input clk,
    input reset_n,

    // Memory Decoder (addr decoder)
    input outside_re, 
    input outside_we, 
    input [1:0] TargetMem,
    input [2:0] DataSizeCon,
    
    input  [63:0] cpu_wdata,
    input [63:0] cpu_addr,
    
    output reg [63:0] cpu_rdata,
    
    // Request Handshake 
    input ready, 
    input rready,
    output reg valid,
     
    // output confirmed
    output reg [63:0] req_wdata,
    output reg [63:0] req_addr,
    
    input [63:0] req_rdata,
    
    // Accept signals
    output reg         req_re,
    output reg         req_we,
    output reg  [1:0]  req_targetmem,
    output reg [2:0] req_DataSizeCon,
    output dma_wait,
    output dma_read_stall
    
);
    reg [1:0] current_state, next_state;
    
    reg rready_latched;
    reg valid_latched;
    reg rvalid;
    // =============================
    // State Definitions 
    // =============================
    localparam [1:0] IDLE = 2'd0;
    //localparam [1:0] REQUEST = 2'd1;
    localparam [1:0] READ = 2'd1;
    localparam [1:0] WRITE = 2'd2; 
    
    wire access_dma = (TargetMem == 2'b10) || (TargetMem == 2'b11);
    
    assign dma_wait =0; // current_state != IDLE access_dma && (~rready);
    //assign dma_read_stall = access_dma && (outside_re); // (current_state != IDLE)
    assign dma_read_stall = ((current_state == READ) && ~ rvalid) || (outside_re && access_dma); //  (outside_re && access_dma)
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
        next_state = current_state;
        case (current_state)
        IDLE: begin
            if (!valid) begin
                if (outside_re && !outside_we) begin
                next_state = READ;
            end
            
                else if (!outside_re && outside_we) begin
                next_state = WRITE;
            end
        end
        end
        
        READ: begin 
            if (rvalid && rready) begin
                next_state = IDLE;
            end 
//            else if (valid && outside_we) begin
//                next_state = WRITE;
//            end 
        end
        
        WRITE: begin 
            if (req_we && ready && ~(outside_we || outside_re)) begin
                next_state = IDLE;
            end
            else if (valid && outside_re) begin
                next_state = READ;
            end 
            end
//        default: next_state = current_state;
        endcase
        end    
      //reg [63:0] req_rdata_reg;    
    // =============================
    // CONTROL LOGIC
    // =============================  
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            valid <= 0;  
            cpu_rdata <= 64'b0; 
                 
            req_addr <= 0;
            req_wdata <= 0;

            req_re <= 0;
            req_we <= 0;
            req_targetmem <= 2'b01;
            req_DataSizeCon <= 3'b000;
            rready_latched <= 0;
            rvalid <= 0;
        end else begin
            rready_latched <= rready;
            
            case (current_state)
        //---------------------------------
        // IDLE (start request)
        //---------------------------------
        IDLE: begin
                //valid <= 0;
                rvalid <= 0;
                cpu_rdata <= 64'b0;
                if (!valid && (outside_re || outside_we)) begin
                        req_re    <= outside_re;
                        req_we    <= outside_we;
                        req_addr  <= cpu_addr;
                        req_wdata <= cpu_wdata;
                        req_targetmem <= TargetMem;
                        req_DataSizeCon <= DataSizeCon;
                        valid <= 1;
                    end
                end
        //---------------------------------
        // READ 
        //---------------------------------
        READ: begin
                // READ Completion
                if (req_re && rready) begin
                    cpu_rdata <= req_rdata;
                    req_re    <= 0;
                    valid     <= 0;
                    req_targetmem <= 2'b01;
                    req_DataSizeCon <= 3'b000;
                    rvalid <= 1;
 
                end
            end

        //---------------------------------
        // WRITE (keep request active)
        //---------------------------------
        WRITE: begin
                // WRITE Completion
                if (ready && req_we) begin
                    req_we  <= 0;
                    valid   <= 0;
                    req_targetmem <= 2'b01;
                    req_DataSizeCon <= 3'b000;
                // ongoing request if any
                if (valid && (outside_we || outside_re)) begin
                    req_re    <= outside_re;
                    req_we    <= outside_we;
                    req_addr  <= cpu_addr;
                    req_wdata <= cpu_wdata;
                    //req_rdata_reg <= req_rdata;
                    req_targetmem <= TargetMem;
                    req_DataSizeCon <= DataSizeCon; 
                    valid     <= 1;
                end
                end
            end

        endcase
    end
end

endmodule
