`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2025 08:24:34 PM
// Design Name: 
// Module Name: Register_File_tb
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


module Register_File_tb(
    );
    
    // Testbench signals
    reg  clk ;
    reg  WE3 ;
    reg  [4:0] A1 ;
    reg  [4:0] A2 ;
    reg  [4:0] A3 ;
    reg  [31:0] WD3 ;
    wire [31:0] RD1 ;
    wire [31:0] RD2 ;
    
    //Instantiate RF
    Register_File RF_UUT(
    .clk(clk) ,
    .WE3(WE3) ,
    .A1(A1) ,
    .A2(A2) ,
    .A3(A3) ,
    .WD3(WD3) ,
    .RD1(RD1) ,
    .RD2(RD2)
    );
    
    //clk generation
    localparam T = 10 ;
    initial begin
    clk = 0 ;
    end
    
    always 
    begin
    #(T/2) clk = ~clk ;
    end
    
    //simulation
    initial
    begin
    WE3 = 1'b0 ;
    WD3 = 32'd0 ;
    
    //check when the WE3 is disabled 
    #10 A3 = 5'b00011 ;
        WD3 = 32'd333 ;
    
    //Enable WE3 
    #10 WE3 = 1'b1 ;
        A1 = 5'b00011 ; 
        A2 = 5'b00011 ;
    // write to another register
    #10 A3 = 5'b00100 ;
        WD3 = 32'd444 ;
    // Read from this register
    #10 A1 = 5'b00100 ; 
        A2 = 5'b00100 ;
    // write to x0
    #10 A3 = 5'b00000 ;
        WD3 = 32'd80 ;
        A1 = 5'b00000 ; 
        A2 = 5'b00000 ;
   // disable WE3
    #20 WE3 = 1'b0 ;
        A3 = 5'b00110 ;
        WD3 = 32'd666 ;
        A1 = 5'b00110 ; 
        A2 = 5'b00110 ;
        
        
    #30 $stop ;     
    end
    
    //monitor
    initial begin
    $monitor("time = %0t , A1 = %0b , A2 = %0b , A3 = %0b , WE3 = %0b , RD1 = %0d , RD2 = %0d , WD3 = %0d ",$time,A1,A2,A3,WE3,RD1,RD2,WD3);
    end
    
endmodule
