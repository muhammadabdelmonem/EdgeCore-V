`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2025 10:04:55 PM
// Design Name: 
// Module Name: Branch_Table_Buffer
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


module Branch_Table_Buffer(
    input  wire        CLK,
    input  wire        reset_n,
    input  wire [63:0] PCF,
    
    input  wire [63:0] PCE,
    input  wire        WE,
    input  wire [63:0] PC_Target_E,
    input  wire [1:0]  Branch_N_State,
     
    output reg         Hit,
    output reg [1:0]   Branch_state,
    output reg [63:0]  Predict_Target  
);
    // ============================
    // Local params
    // ============================
    localparam [1:0] Strongly_Not_Taken =2'b00;
    localparam [1:0] Weakly_Not_Taken =2'b01;
    localparam [1:0] Weakly_Taken =2'b10;
    localparam [1:0] Strongly_Taken =2'b11;
    
    // ============================
    // BTB Memory arrays
    // ============================
    reg [55:0] Tags   [0:63];
    reg [63:0] Target [0:63];
    reg [63:0] Valid;
    reg [1:0]  State  [0:63];
    
    wire [5:0]  Lookup_index  = PCF[7:2];
    wire [55:0] Lookup_tag    = PCF[63:8];
    wire [5:0]  Updated_index = PCE[7:2];
    wire [55:0] Updated_tag   = PCE[63:8];
    
    integer i;

    // ============================
    // Reset + Write logic
    // ============================
    always @(posedge CLK or negedge reset_n) begin
        if (!reset_n) begin
            Valid <= 64'b0;
            for (i = 0; i < 64; i = i + 1) begin
                Tags[i]   <= 56'b0;
                Target[i] <= 64'b0;
                State[i]  <= Weakly_Not_Taken;
            end
        end else if (WE) begin
            Valid[Updated_index]  <= 1'b1;
            Tags[Updated_index]   <= Updated_tag;
            State[Updated_index]  <= Branch_N_State;
            Target[Updated_index] <= PC_Target_E;
        end
    end

    // ============================
    // Read / Predict logic
    // ============================
    always @(*) begin
        // Defaults (no hit)
        Hit            = 1'b0;
        Branch_state   = Weakly_Not_Taken;
        Predict_Target = PCF + 4;
        
        if (Valid[Lookup_index] && (Tags[Lookup_index] == Lookup_tag)) begin
            Hit            = 1'b1;
            Branch_state   = State[Lookup_index];
            Predict_Target = Target[Lookup_index];
        end
    end

endmodule