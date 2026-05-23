`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2026 06:00:41 PM
// Design Name: 
// Module Name: Wallance_tree_8
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


module Wallance_tree_8(
    input signed [7:0]  a,b,
    output [15:0] prod
    );

    localparam WIDTH_HA1 = 3;
    localparam WIDTH_HA2 = 2;
    localparam WIDTH_HA3 = 3;
    localparam WIDTH_HA4 = 3;
    localparam WIDTH_HA5 = 1;
    localparam WIDTH_FA1 = 11;
    localparam WIDTH_FA2 = 12;
    localparam WIDTH_FA3 = 5;
    localparam WIDTH_FA4 = 6;
    localparam WIDTH_FA5 = 8;
   
//module full_adder (
//    output S, Cout,
//    input A, B, Cin
//);
//    wire w1, w2, w3;
//    //XOR gates for Sum
//    xor (w1, A, B);
//    xor (S, w1, Cin);
//    //AND gates for Carry
//    and (w2, A, B);
//    and (w3, w1, Cin);
//    //OR gate for final Carry
//    or (Cout, w2, w3);
//endmodule

//module half_adder(
//    output S, Cout,
//    input A, B

//);
//    xor(S, A, B);
//    and (Cout, A, B);
//endmodule

//module wallace_8x8(
//    input [7:0] a,b,
//    output [15:0] prod
//);
    wire p[7:0][7:0];
    genvar i, j;
    generate
    for (i = 0; i < 8; i = i + 1) begin : gen_i
        for (j = 0; j < 8; j = j + 1) begin : gen_j
            and and_gates ((p[i][j]),(a[i]),(b[j]));
        end
    end
    endgenerate
    // Half adders
    wire h0s,h0c,h1s,h1c,h2s,h2c,h3s,h3c,h4s,h4c,
         h5s,h5c,h6s,h6c,h7s,h7c,h8s,h8c,h9s,h9c,
         h10s,h10c,h11s,h11c,h12s,h12c,h13s,h13c,
         h14s,h14c,h15s,h15c,h16s,h16c;

    // Full adders
    wire f0s,f0c,f1s,f1c,f2s,f2c,f3s,f3c,f4s,f4c,
         f5s,f5c,f6s,f6c,f7s,f7c,f8s,f8c,f9s,f9c,
         f10s,f10c,f11s,f11c,f12s,f12c,f13s,f13c,
         f14s,f14c,f15s,f15c,f16s,f16c,f17s,f17c,
         f18s,f18c,f19s,f19c,f20s,f20c,f21s,f21c,
         f22s,f22c,f23s,f23c,f24s,f24c,f25s,f25c,
         f26s,f26c,f27s,f27c,f28s,f28c,f29s,f29c,
         f30s,f30c,f31s,f31c,f32s,f32c,f33s,f33c,
         f34s,f34c,f35s,f35c,f36s,f36c,f37s,f37c,
         f38s,f38c,f39s,f39c,f40s,f40c,f41s,f41c,
         f42s,f42c,f43s,f43c,f44s,f44c,f45s,f45c,
         f46s,f46c; 
    
    //first level
     HA_array #(.WIDTH(WIDTH_HA1)) Stage1_HA(
    .in1({p[7][4],p[1][3],p[7][1],p[1][0]}),
    .in2({p[6][5],p[0][4],p[6][2],p[0][1]}),
    .S_out({h3s,h2s,h1s,h0s}),
    .C_out({h3c,h2c,h1c,h0c})
    );
 
 
     FA_array #(.WIDTH(WIDTH_FA1)) Stage1_FA1 (
    .in1({p[7][3],p[6][3],p[5][3],p[4][3],p[3][3],p[2][3],p[7][0],p[6][0],p[5][0],p[4][0],p[3][0],p[2][0]}),
    .in2({p[6][4],p[5][4],p[4][4],p[3][4],p[2][4],p[1][4],p[6][1],p[5][1],p[4][1],p[3][1],p[2][1],p[1][1]}),
    .C_in({p[5][5],p[4][5],p[3][5],p[2][5],p[1][5],p[0][5],p[5][2],p[4][2],p[3][2],p[2][2],p[1][2],p[0][2]}),
    .S_out({f11s,f10s,f9s,f8s,f7s,f6s,f5s,f4s,f3s,f2s,f1s,f0s}),
    .C_out({f11c,f10c,f9c,f8c,f7c,f6c,f5c,f4c,f3c,f2c,f1c,f0c}));
// half_adder ha0(h0s,h0c,p[1][0],p[0][1]);  
//    full_adder fa0(f0s,f0c,p[2][0],p[1][1],p[0][2]);
//    full_adder fa1(f1s,f1c,p[3][0],p[2][1],p[1][2]);
//    full_adder fa2(f2s,f2c,p[4][0],p[3][1],p[2][2]);
//    full_adder fa3(f3s,f3c,p[5][0],p[4][1],p[3][2]);
//    full_adder fa4(f4s,f4c,p[6][0],p[5][1],p[4][2]);
//    full_adder fa5(f5s,f5c,p[7][0],p[6][1],p[5][2]);
//    half_adder ha1(h1s,h1c,p[7][1],p[6][2]);    
//    half_adder ha2(h2s,h2c,p[1][3],p[0][4]);
//    full_adder fa6(f6s,f6c,p[2][3],p[1][4],p[0][5]);
//    full_adder fa7(f7s,f7c,p[3][3],p[2][4],p[1][5]);
//    full_adder fa8(f8s,f8c,p[4][3],p[3][4],p[2][5]);
//    full_adder fa9(f9s,f9c,p[5][3],p[4][4],p[3][5]);
//    full_adder fa10(f10s,f10c,p[6][3],p[5][4],p[4][5]);
//    full_adder fa11(f11s,f11c,p[7][3],p[6][4],p[5][5]);
//    //half_adder ha3(h3s,h3c,p[7][4],p[6][5]);
    
    //second level 
   HA_array #(.WIDTH(WIDTH_HA2)) Stage2_HA(
    .in1({p[7][6],f4s,h0c}),
    .in2({p[6][7],f7s,f0s}),
    .S_out({h6s,h5s,h4s}),
    .C_out({h6c,h5c,h4c}));
    
   FA_array #(.WIDTH(WIDTH_FA2)) Stage2_FA2 (
    .in1({p[5][7],p[4][7],p[3][7],f10s,f8c,f8s,p[3][6],p[2][6],p[1][6],p[0][6],h2c,f1c,p[0][3]}),
    .in2({p[7][5],f11c,f10c,h1c,h1s,f4c,p[2][7],p[1][7],p[0][7],f3c,f2c,f2s,f0c}),
    .C_in({h3c,h3s,f11s,f9c,f9s,f7c,p[7][2],f5c,f5s,f6c,f3s,h2s,f1s}),
    .S_out({f24s,f23s,f22s,f21s,f20s,f19s,f18s,f17s,f16s,f15s,f14s,f13s,f12s}),
    .C_out({f24c,f23c,f22c,f21c,f20c,f19c,f18c,f17c,f16c,f15c,f14c,f13c,f12c}));
//    half_adder ha4(h4s,h4c,h0c,f0s);
//    full_adder fa12(f12s,f12c,p[0][3],f0c,f1s);
//    full_adder fa13(f13s,f13c,f1c,f2s,h2s);
//    full_adder fa14(f14s,f14c,h2c,f2c,f3s);
//    full_adder fa15(f15s,f15c,p[0][6],f3c,f6c);
//    full_adder fa16(f16s,f16c,p[1][6],p[0][7],f5s);
//    full_adder fa17(f17s,f17c,p[2][6],p[1][7],f5c);
//    full_adder fa18(f18s,f18c,p[3][6],p[2][7],p[7][2]);  
//    half_adder ha5(h5s,h5c,f4s,f7s);
//    full_adder fa19(f19s,f19c,f8s,f4c,f7c);
//    full_adder fa20(f20s,f20c,f8c,h1s,f9s);
//    full_adder fa21(f21s,f21c,f10s,h1c,f9c);
//    full_adder fa22(f22s,f22c,p[3][7],f10c,f11s);
//    full_adder fa23(f23s,f23c,p[4][7],f11c,h3s);
//    full_adder fa24(f24s,f24c,p[5][7],p[7][5],h3c);
//    half_adder ha6(h6s,h6c,p[7][6],p[6][7]);
    
    //third level
     HA_array #(.WIDTH(WIDTH_HA3)) Stage3_HA(
    .in1({f23c,f22c,f12c,h4c}),
    .in2({f24s,f23s,f13s,f12s}),
    .S_out({h10s,h9s,h8s,h7s}),
    .C_out({h10c,h9c,h8c,h7c}));
    
   FA_array #(.WIDTH(WIDTH_FA3)) Stage3_FA2 (
    .in1({f13c,f14c,h5c,f19c,f17c,f18c}),
    .in2({f14s,f15s,f15c,f16c,f20c,f21c}),
    .C_in({f6s,h5s,f16s,f17s,f18s,f22s}),
    .S_out({f25s,f26s,f27s,f28s,f29s,f30s}),
    .C_out({f25c,f26c,f27c,f28c,f29c,f30c}));
//    half_adder ha7(h7s,h7c,h4c,f12s);
//    half_adder ha8(h8s,h8c,f12c,f13s);
//    full_adder fa25(f25s,f25c,f13c,f14s,f6s);
//    full_adder fa26(f26s,f26c,f14c,f15s,h5s);
//    full_adder fa27(f27s,f27c,h5c,f15c,f16s);
//    full_adder fa28(f28s,f28c,f19c,f16c,f17s);
//    full_adder fa29(f29s,f29c,f17c,f20c,f18s);
//    full_adder fa30(f30s,f30c,f18c,f21c,f22s);
//    half_adder ha9(h9s,h9c,f22c,f23s);
//    half_adder ha10(h10s,h10c,f23c,f24s);
    
    //fourth level
     HA_array #(.WIDTH(WIDTH_HA4)) Stage4_HA(
    .in1({h6c,f25c,h8c,h7c}),
    .in2({p[7][7],f26s,f25s,h8s}),
    .S_out({h14s,h13s,h12s,h11s}),
    .C_out({h14c,h13c,h12c,h11c}));
    
   FA_array #(.WIDTH(WIDTH_FA4)) Stage4_FA4 (
    .in1({h10c,h9c,f30c,f29c,f28c,f27c,f26c}),
    .in2({f24c,h10s,h9s,f30s,f29s,f28s,f27s}),
    .C_in({h6s,p[6][6],p[5][6],p[4][6],f21s,f20s,f19s}),
    .S_out({f37s,f36s,f35s,f34s,f33s,f32s,f31s}),
    .C_out({f37c,f36c,f35c,f34c,f33c,f32c,f31c}));
//    half_adder ha11(h11s,h11c,h7c,h8s);
//    half_adder ha12(h12s,h12c,h8c,f25s);
//    half_adder ha13(h13s,h13c,f25c,f26s);
//    full_adder fa31(f31s,f31c,f26c,f27s,f19s);
//    full_adder fa32(f32s,f32c,f27c,f28s,f20s);
//    full_adder fa33(f33s,f33c,f28c,f29s,f21s);
//    full_adder fa34(f34s,f34c,f29c,f30s,p[4][6]);
//    full_adder fa35(f35s,f35c,f30c,h9s,p[5][6]);
//    full_adder fa36(f36s,f36c,h9c,h10s,p[6][6]);
//    full_adder fa37(f37s,f37c,h10c,f24c,h6s);
//    half_adder ha14(h14s,h14c,h6c,p[7][7]);
    
    //fifth level
   HA_array #(.WIDTH(WIDTH_HA5)) Stage5_HA(
    .in1({f46c,h11c}),
    .in2({h14c,h12s}),
    .S_out({h16s,h15s}),
    .C_out({h16c,h15c}));
    
   FA_array #(.WIDTH(WIDTH_FA5)) Stage5_FA5 (
    .in1({f45c,f44c,f43c,f42c,f41c,f40c,f39c,f38c,h15c}),
    .in2({f37c,f36c,f35c,f34c,f33c,f32c,f31c,h13c,h12c}),
    .C_in({h14s,f37s,f36s,f35s,f34s,f33s,f32s,f31s,h13s}),
    .S_out({f46s,f45s,f44s,f43s,f42s,f41s,f40s,f39s,f38s}),
.    C_out({f46c,f45c,f44c,f43c,f42c,f41c,f40c,f39c,f38c}));
//    half_adder ha15(h15s,h15c,h11c,h12s);
//    full_adder fa38(f38s,f38c,h15c,h12c,h13s);
//    full_adder fa39(f39s,f39c,f38c,h13c,f31s);
//    full_adder fa40(f40s,f40c,f39c,f31c,f32s);
//    full_adder fa41(f41s,f41c,f40c,f32c,f33s);
//    full_adder fa42(f42s,f42c,f41c,f33c,f34s);
//    full_adder fa43(f43s,f43c,f42c,f34c,f35s);
//    full_adder fa44(f44s,f44c,f43c,f35c,f36s);
//    full_adder fa45(f45s,f45c,f44c,f36c,f37s);
//    full_adder fa46(f46s,f46c,f45c,f37c,h14s);
//    half_adder ha16(h16s,h16c,f46c,h14c);

    //Assign
    assign prod = {h16s, f46s, f45s, f44s, f43s, f42s, f41s, f40s,
                f39s, f38s, h15s, h11s, h7s, h4s, h0s, p[0][0]};
    
endmodule


