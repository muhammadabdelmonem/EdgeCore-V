`timescale 1ns / 1ps

module Division_unit2(
    input              CLK,
    input              reset_n,
    input       [3:0]  Div_Control,
    input       [63:0] Divisor,
    input       [63:0] Dividend,
    output reg         Valid,
    output      [63:0] Final_Result
);

    // ---------- FSM STATES ----------
    localparam Start        = 3'd0,
               Shifting     = 3'd1, 
               Subtraction  = 3'd2,
               Set_1        = 3'd3,
               Restore_Set0 = 3'd4,
               Check        = 3'd5,
               Stop         = 3'd6;

    reg [2:0]  state_reg, state_next;

    // ---------- DATAPATH REGISTERS ----------
    reg [64:0] A_reg, A_next;     // Accumulator (65 bits)
    reg [63:0] Q_reg, Q_next;     // Quotient shift register
    reg [63:0] M_reg, M_next;     // Divisor
    reg [6:0]  N_reg, N_next;     // Counter (0..64)
 
    wire [63:0] DivisorNew ,DividendNew;
    wire [63:0] Divisor2Complement ,Dividend2Complement;
    reg [63:0] ResultMux ,RemainderMux;
    reg [63:0] Result2Complement ,Remainder2Complement;
    reg [63:0] result_reg, remainder_reg;
    reg [63:0] result_next, remainder_next;
    wire  [63:0] Demo_Result;
    wire [63:0] ResultOut ,RemainderOut;

   assign Divisor2Complement = ~(Divisor)+1;
   assign  Dividend2Complement = ~(Dividend)+1;
   
   
   
       mux2x1 Dividend_mux    (.sel(Dividend[63]&Div_Control[0]),
                              .in1(Dividend),
                              .in2(Dividend2Complement),
                              .out(DividendNew));
                              
       mux2x1 Divisor_mux    (.sel(Divisor[63]&Div_Control[0]),
                              .in1(Divisor),
                              .in2(Divisor2Complement),
                              .out(DivisorNew));
                              
       mux2x1 Remainder_mux  (.sel(Dividend[63]),
                              .in1(RemainderMux),
                              .in2(Remainder2Complement),
                              .out(RemainderOut));
                              
       mux2x1 Result_mux     (.sel(Divisor[63]^Dividend[63]),
                              .in1(ResultMux),
                              .in2(Result2Complement),
                               .out(ResultOut));
                               
      mux2x1 Final_Mux     (.sel(Div_Control[1]),
                              .in1(ResultOut),
                              .in2(RemainderOut),
                              .out(Demo_Result));
     assign Final_Result = Div_Control[2] ? {{32{Demo_Result[31]}}, Demo_Result[31:0]} : Demo_Result; //word instruction
            
    // ============================================================
    //  (1) SEQUENTIAL ALWAYS BLOCK (UPDATE REGISTERS)
    // ============================================================
    
    always @(posedge CLK or negedge reset_n) begin
        if (!reset_n) begin 
            state_reg   <= Start;
            Valid       <=0;
            A_reg       <= 0;
            Q_reg       <= 0;
            M_reg       <= 0;
            N_reg       <= 0;
            ResultMux      <= 0;
            
        end else begin
            state_reg   <= state_next;
            A_reg       <= A_next;
            Q_reg       <= Q_next;
            M_reg       <= M_next;
            N_reg       <= N_next;
            ResultMux      <= result_next;
            RemainderMux   <= remainder_next;
        end
    end

    // ============================================================
    //  (2) COMBINATIONAL ALWAYS BLOCK (NEXT STATE & NEXT DATA)
    // ============================================================
    always @(*) begin

       
       if(Div_Control[3]==1) begin
        // Default holds
        state_next     = state_reg;
        A_next         = A_reg;
        Q_next         = Q_reg;
        M_next         = M_reg;
        N_next         = N_reg;
        //result_next    = ResultMux;
//        remainder_next = Remainder;

        case(state_reg)

        // -----------------------------
        // START: Load operands
        // -----------------------------
        Start: begin
            A_next     = 0;
            Valid      = 0;
            Q_next     = DividendNew;
            M_next     = DivisorNew;
            N_next     = 64;
            state_next = Shifting;
        end

        // -----------------------------
        // SHIFT LEFT:  {A,Q} <<= 1
        // -----------------------------
        Shifting: begin
            A_next = {A_reg[63:0], Q_reg[63]}; // bring MSB of Q into LSb of A
            Q_next = Q_reg << 1;               // shift left Q
            state_next = Subtraction;
        end

        // -----------------------------
        // SUBTRACT: A ← A - M
        // -----------------------------
        Subtraction: begin
            A_next = A_reg - M_reg;

            if (A_next[64] == 1) // negative?
                state_next = Restore_Set0;
            else
                state_next = Set_1;
        end

        // -----------------------------
        // SUCCESSFUL subtraction → Q[0] = 1
        // -----------------------------
        Set_1: begin
            Q_next[0] = 1'b1;
            N_next    = N_reg - 1;
            state_next = Check;
        end

        // -----------------------------
        // FAILED subtraction → restore A, Q[0] = 0
        // -----------------------------
        Restore_Set0: begin
            A_next = A_reg + M_reg;
            Q_next[0] = 1'b0;
            N_next = N_reg - 1;
            state_next = Check;
        end

        // -----------------------------
        // LOOP CONTROL
        // -----------------------------
        Check: begin
            if (N_next == 0)
                state_next = Stop;
            else
                state_next = Shifting;
        end

        // -----------------------------
        // STOP: Output results
        // -----------------------------
        Stop: begin
            result_next    = Q_reg;
            remainder_next = A_reg[63:0];
            Result2Complement = ~(Q_reg)+1;
            Remainder2Complement = ~(A_reg[63:0])+1;
            Valid =1'b1;
            state_next= Start;
            // optionally go to Start for next operation
            // state_next = Start;
        end

        endcase
        
        end
    end

endmodule
