`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2025 02:25:54 PM
// Design Name: 
// Module Name: CLA_nbit
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


module CLA_nbit
    #(parameter N = 32)(
    input [N-1 : 0] a ,
    input [N-1 : 0] b ,
    input addn_sub , //if 0 then add & if 1 then sub
    output [N-1 : 0] s ,
    output c_out
    );
    
    //the effective b to handle the sub operation
    wire [N-1 : 0] b_eff = b ^ {N{addn_sub}} ;
    
    //wires for calculations 
    wire [N : 0] c ;
    wire [N-1 : 0] G , P ;
    assign c[0] = addn_sub ;
        
    genvar k ;
    
    //Generate and Propagate calculations
    generate
        for(k=0 ; k<N ; k=k+1)
        begin : GP
            assign G[k] = a[k] & b_eff[k] ;
            assign P[k] = a[k] ^ b_eff[k] ;
        end
    endgenerate
    
    //CLA generation
    generate
        for(k=0 ; k<N ; k=k+1)
        begin : CARRY
           assign c[k+1] = G[k] | (P[k]&c[k]) ;
        end
    endgenerate
    
    //final carry out
    assign c_out = c[N] ;
    
    //final output
    assign s = P ^ c[N-1 : 0] ;
endmodule
