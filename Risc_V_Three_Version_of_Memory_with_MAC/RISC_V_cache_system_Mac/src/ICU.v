`timescale 1ns / 1ps
//==============================================================================
// Integrated Computational Unit (ICU)
// Combines ALU, Multiplier (M-extension), and Divider in one unified unit
//==============================================================================

module ICU(
    // Clock and reset
    input wire        CLK,
    input wire        reset_n,
    
    // Data inputs
    input wire [63:0] SrcA,
    input wire [63:0] SrcB,
    
    
    // Control inputs
    input wire [3:0]  ALUControl,      // [3:0]=ALU operation
    //input wire [2:0]  Mul_Control,     // [2]=enable, [1:0]=funct3[1:0]
    input wire [3:0]  Div_Control,     // [3]=enable, [2:0]=operation
    input wire [1:0]  Function_Sel,    // 00=ALU, 01=MUL, 10=DIV, 11=illegal
    input wire [63:0] OutToMuxC ,  
    input wire        MAC_SelE,
   // input wire        ACC_EnE,
    input wire [1:0]  ModeE,
    input wire        Signed_enE,
    // ALU-specific controls
    input wire [2:0]  funct3Control,
    input wire        SignExtension,
    input wire        OP3,             // 0=64-bit ops, 1=32-bit word ops (MULW)
    
    // Outputs
    output wire        BranchFlag,
    output wire        Zero,
    output wire        Valid,
    output wire [63:0] Result_ICU
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    wire [63:0] AluResult;
    wire [63:0] MulResult;
    wire [63:0] DivResult;
    
    wire [63:0] MAMU1;
    wire [63:0] MAMU2;
    
   // wire MulValid;
    wire DivValid;
    // wire mul_busy;
    
    // MUL funct3 generation with priority encoding
    reg [2:0] mul_funct3;
    
    
   // always @(*) begin
        /*if (OP3 && (Function_Sel == 2'b01)) begin
            // MULW: 32-bit word operation
            mul_funct3 = 3'b100;
        end else begin
            // Normal MUL/MULH/MULHSU/MULHU: extract from Mul_Control
            mul_funct3 = {1'b0, Mul_Control[1:0]};
        end
    end*/
    
    //==========================================================================
    // ALU Unit (Combinational - always 1 cycle)
    //==========================================================================
    mux2x1 MAC_MUX_1(
        .sel(MAC_SelE),
        .in1(SrcA),
        .in2(MulResult),
        .out(MAMU1)
    );
    mux2x1 MAC_MUX_2(
        .sel(MAC_SelE),
        .in1(SrcB),
        .in2(OutToMuxC),
        .out(MAMU2)
    );
//    Accumluator ACC_unit(.ACC_in(AluResult),
//                         .EN(ACC_EnE),
//                         .CLR(ACC_CLR),
//                         .ACC_out(ACC_out)
//    );
    

    ALU_UNIT ALU (
        .SrcA(MAMU1),
        .SrcB(MAMU2),
        .ALUControl(ALUControl),
        .SignExtension(SignExtension),
        .OP3(OP3),
        .funct3Control(funct3Control),
        .BranchFlag(BranchFlag),
        .ALUResult(AluResult),
        .Zero(Zero)
    );
    // reg A   
    //
    //==========================================================================
    // MUL Unit (M-Extension - 64-65 cycles)
    //==========================================================================
  //  reg mul_start;
    
    // Generate start pulse when MUL is enabled and not already running
 //    always @(posedge CLK or negedge reset_n) begin
 //       if (!reset_n)
//            mul_start <= 1'b0;
//        else if (Mul_Control[2] && !mul_busy && !MulValid)
//            mul_start <= 1'b1;
//        else
//            mul_start <= 1'b0;
//    end
    
//    rv64_m_mul_unit Mul (
//        .clk(CLK),
//        .   rst_n(reset_n),
//        .start(mul_start),
//        . rs1(SrcA),
//        .rs2(SrcB),
//        .funct3(mul_funct3),
//        .rd(MulResult),
//        .done(MulValid),
//        .busy(mul_busy)
//    );
//    Combinational_Multiplier_Test MT(.A(SrcA),
//                                     .B(SrcB),
//                                     .P(MulResult)
//                                     );
    Wallace_64x64_shifter WTS(.signed_en(Signed_enE), 
                             .mode(ModeE),          // size selector
                             .a(SrcA),
                             .b(SrcB),                     
                             .result(MulResult)
                             );
    //==========================================================================
    // DIV Unit (M-Extension - variable cycles)
    //==========================================================================

Division_unit3 Div(.CLK(CLK),
                   .reset_n(reset_n),
                   .Div_Control(Div_Control),
                   .Divisor(SrcB),
                   .Dividend(SrcA),
                   .Valid(DivValid),
                   .Final_Result(DivResult)
                    );
    
    //==========================================================================
    // Result Selection MUX (3-to-1)
    //==========================================================================
    assign Result_ICU = (Function_Sel == 2'b00) ? AluResult :
                        (Function_Sel == 2'b01) ? MulResult :
                        (Function_Sel == 2'b10) ? DivResult :
                        64'h0;
    
    //==========================================================================
    // Valid Signal Logic (3-way selection)
    //==========================================================================
    assign Valid = //Function_Sel == 2'b01) ? MulValid :  // MUL: wait for completion
                   (Function_Sel == 2'b10) ? DivValid :  // DIV: wait for completion
                   1'b0; 
           

endmodule