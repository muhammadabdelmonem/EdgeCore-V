module Division_unit3(
    input              CLK,
    input              reset_n,
    input       [3:0]  Div_Control,
    input       [63:0] Divisor,
    input       [63:0] Dividend,
    output reg         Valid,
    output      [63:0] Final_Result
);

    // ---------- FSM STATES ----------
    localparam Start     = 3'd0,
               Computing = 3'd1,
               Stop      = 3'd2;

    reg [2:0]  state_reg, state_next;

    // ---------- DATAPATH REGISTERS ----------
    reg [64:0] A_reg, A_next;     // Accumulator (65 bits)
    reg [63:0] Q_reg, Q_next;     // Quotient shift register
    reg [63:0] M_reg, M_next;     // Divisor
    reg [6:0]  N_reg, N_next;     // Counter (0..64)
 
    wire [63:0] DivisorNew, DividendNew;
    wire [63:0] Divisor2Complement, Dividend2Complement;
    reg  [63:0] ResultMux, RemainderMux;
    wire [63:0] Result2Complement, Remainder2Complement;
    reg  [63:0] result_reg, result_next;
    reg  [63:0] remainder_reg, remainder_next;
    wire [63:0] Demo_Result;
    wire [63:0] ResultOut, RemainderOut;  // Changed to wire
    reg  [63:0] ResultError, RemainderError;
    reg  flag_error;

    // 2's complement calculations
    assign Divisor2Complement  = ~Divisor + 1;
    assign Dividend2Complement = ~Dividend + 1;
    assign Result2Complement   = ~ResultMux + 1;
    assign Remainder2Complement = ~RemainderMux + 1;

    // Input multiplexers for signed operations
    mux2x1 Dividend_mux (
        .sel(Dividend[63] & ~Div_Control[0]),
        .in1(Dividend),
        .in2(Dividend2Complement),
        .out(DividendNew)
    );
                              
    mux2x1 Divisor_mux (
        .sel(Divisor[63] & ~Div_Control[0]),
        .in1(Divisor),
        .in2(Divisor2Complement),
        .out(DivisorNew)
    );
                              
    mux2x1 Remainder_mux_inst (
        .sel(Dividend[63] & ~Div_Control[0]),
        .in1(RemainderMux),
        .in2(Remainder2Complement),
        .out(RemainderOut)
    );
                              
    mux2x1 Result_mux_inst (
        .sel((Divisor[63] ^ Dividend[63]) & ~Div_Control[0]),
        .in1(ResultMux),
        .in2(Result2Complement),
        .out(ResultOut)
    );
    
    // Error handling muxes
    wire [63:0] Result_with_Error, Remainder_with_Error;
    
    mux2x1 Error_Result (
        .sel(flag_error),
        .in1(ResultOut),
        .in2(ResultError),
        .out(Result_with_Error)
    );   
    
    mux2x1 Error_Remainder (
        .sel(flag_error),
        .in1(RemainderOut),
        .in2(RemainderError),
        .out(Remainder_with_Error)
    );                        
    
    mux2x1 Final_Mux (
        .sel(Div_Control[1]),
        .in1(Result_with_Error),
        .in2(Remainder_with_Error),
        .out(Demo_Result)
    );
    
    // Word instruction sign extension
    assign Final_Result = Div_Control[2] ? {{32{Demo_Result[31]}}, Demo_Result[31:0]} : Demo_Result;
            
    // ============================================================
    //  SEQUENTIAL LOGIC - State and Register Updates
    // ============================================================
    always @(posedge CLK or negedge reset_n) begin
        if (!reset_n || !Div_Control[3]) begin
            state_reg     <= Start;
            A_reg         <= 65'd0;
            Q_reg         <= 64'd0;
            M_reg         <= 64'd0;
            N_reg         <= 7'd0;
            result_reg    <= 64'd0;
            remainder_reg <= 64'd0;
        end
        else begin
            state_reg     <= state_next;
            A_reg         <= A_next;
            Q_reg         <= Q_next;
            M_reg         <= M_next;
            N_reg         <= N_next;
            result_reg    <= result_next;
            remainder_reg <= remainder_next;
        end
    end

    // ============================================================
    //  COMBINATIONAL LOGIC - FSM and Datapath
    // ============================================================
    always @(*) begin
        // Default assignments (hold current values)
        state_next     = state_reg;
        A_next         = A_reg;
        Q_next         = Q_reg;
        M_next         = M_reg;
        N_next         = N_reg;
        result_next    = result_reg;
        remainder_next = remainder_reg;
        Valid          = 1'b0;
        ResultMux      = result_reg;
        RemainderMux   = remainder_reg;
        flag_error     = 1'b0;
        ResultError    = 64'd0;
        RemainderError = 64'd0;
        
        if (Div_Control[3]) begin  // Start signal                            
            case (state_reg)
                Start: begin
                    // Check for division by zero
                    if (Divisor == 64'd0) begin
                        Valid          = 1'b1;
                        flag_error     = 1'b1;
                        state_next     = Start;
                        RemainderError = Dividend;
                        
                        if (!Div_Control[2]) begin
                            // 64-bit division by zero
                            ResultError = Div_Control[0] ? 64'hFFFFFFFFFFFFFFFF : -64'd1;
                        end else begin
                            // 32-bit division by zero
                            ResultError = Div_Control[0] ? 64'hFFFFFFFF : -64'd1;
                        end
                    end
                    // Check for signed overflow (most negative / -1)
                    else if (Divisor == -64'd1 && Dividend == 64'h8000000000000000 && !Div_Control[0]) begin
                        Valid          = 1'b1;
                        flag_error     = 1'b1;
                        state_next     = Start;
                        RemainderError = 64'h0;                       
                        if (!Div_Control[2] ) begin
                            // 64-bit overflow 
                              
                            ResultError =  64'h8000000000000000;
                        end else begin
                            // 32-bit overflow
                            ResultError =  64'h80000000;
                        end
                    end
                    else begin
                        // Initialize for normal division
                        flag_error = 1'b0;
                        A_next     = 65'd0;
                        Q_next     = DividendNew;
                        M_next     = DivisorNew;
                        N_next     = 7'd64;
                        state_next = Computing;
                    end
                end
                
                Computing: begin
                    // Restoring division algorithm
                    // Step 1: Shift A and Q left by 1
                    A_next = {A_reg[63:0], Q_reg[63]};
                    Q_next = {Q_reg[62:0], 1'b0};
                    
                    // Step 2: Subtract divisor from A
                    A_next = A_next - {1'b0, M_reg};
                    
                    // Step 3: Check if result is negative
                    if (A_next[64] == 1'b0) begin
                        // Subtraction successful (A >= 0)
                        Q_next[0] = 1'b1;  // Set quotient bit
                    end
                    else begin
                        // Subtraction unsuccessful (A < 0) - Restore
                        A_next = {A_reg[63:0], Q_reg[63]};  // Just do the shift
                        Q_next = {Q_reg[62:0], 1'b0};       // Q bit stays 0
                    end
                    
                    // Decrement counter
                    N_next = N_reg - 7'd1;
                    
                    // Check if done
                    if (N_reg == 7'd1) begin
                        state_next = Stop;
                    end
                end
                
                Stop: begin
                    // Store final results
                    result_next    = Q_reg;
                    remainder_next = A_reg[63:0];
                    ResultMux      = Q_reg;
                    RemainderMux   = A_reg[63:0];
                    Valid          = 1'b1;
                    state_next     = Start;  // Return to Start state
                end
                
                default: begin
                    state_next = Start;
                end
            endcase
        end
    end

endmodule