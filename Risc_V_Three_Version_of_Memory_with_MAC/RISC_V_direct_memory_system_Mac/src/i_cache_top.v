`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2025 03:38:37 PM
// Design Name: 
// Module Name: I_Cache_Top
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


module I_Cache_Top(
    // Global Signals
    input clk,
    input reset_n,

    // CPU Interface
    // Inputs from CPU Pipeline
    input   [63:0]  cpu_address,
    input           cpu_r_en,
    // Outputs to CPU Pipeline
    output          cpu_stall,
    output          cpu_data_valid,
    output  [31:0]  cpu_read_data,

    //  (AXI) Interface
    output  [31:0] axi_size,
    // To AXI Read Channel
    output          axi_r_en,
    output  [63:0]  axi_r_address,
    input           axi_r_valid,
    input   [511:0] axi_r_data,
    
    //exception
    output bus_error_exception
);

    // --- Internal Wires for Connecting Controller and Memory ---

    // Controller -> Memory
    wire        cache_r_en_wire;
    wire [5:0]  cache_set_sel_wire;
    wire [1:0]  cache_way_sel_wire;
    wire [5:0]  cache_offset_wire;

    // Memory -> Controller
    wire        r_valid_wire;


    // Module Instantiation 

    // 1. Instantiate the Cache Controller
    I_Cache_Controller I_controller (
        .clk(clk),
        .reset_n(reset_n),

        // CPU Interface
        .cpu_address(cpu_address),
        .cpu_r_en(cpu_r_en),
        .stall(cpu_stall),
        .cpu_data_valid(cpu_data_valid),

        // Cache Memory Interface
        .r_valid(r_valid_wire),
        .cache_r_en(cache_r_en_wire),
        .cache_set_sel(cache_set_sel_wire),
        .cache_way_sel(cache_way_sel_wire),
        .cache_offset(cache_offset_wire),


        // Main Memory (AXI) Interface

        .mem_size(axi_size), 
        .mem_r_en(axi_r_en),
        .mem_r_add(axi_r_address),
        
        //Exception
        .bus_error_exception(bus_error_exception)
    );

    // 2. Instantiate the Cache Memory
    I_Cache_Memory I_memory (
        .clk(clk),
        .reset_n(reset_n),

        // Controller Interface
        .cache_r_en(cache_r_en_wire),
        .way_sel(cache_way_sel_wire),
        .cache_set_sel(cache_set_sel_wire),
        .cache_offset(cache_offset_wire),
        .r_valid(r_valid_wire),
        
        // AXI Interface
        .axi_data_line(axi_r_data),
        .axi_line_valid(axi_r_valid),
        
        // Outputs
        .data_read(cpu_read_data)
    );

endmodule
