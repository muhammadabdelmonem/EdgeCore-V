//==============================================================================
// Radix-2 Booth Algorithm Multiplier (65-bit operands)
// Extended to support unsigned multiplication via sign extension wrapper
//==============================================================================

module booth_radix2_multiplier_65bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [64:0] multiplicand,    // 65-bit operand (64 data + 1 sign/zero)
    input  wire [64:0] multiplier,      // 65-bit operand (64 data + 1 sign/zero)
    output reg  [129:0] product,        // 130-bit result (65 � 65)
    output reg         done,
    output reg         busy
);

    localparam IDLE    = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH  = 2'b10;

    reg [1:0] state, next_state;
    reg [6:0] count;                // Iteration counter (0 to 64, need 65 iterations)

    reg [64:0]  A;                  // Accumulator (65-bit)
    reg [64:0]  Q;                  // Multiplier register (65-bit)
    reg         Q_1;                // Q-1 bit
    reg [64:0]  M;                  // Multiplicand register (65-bit)

    // Combinational logic for add/subtract
    reg [64:0] A_add_sub;
    always @(*) begin
        case ({Q[0], Q_1})
            2'b01: A_add_sub = A + M;
            2'b10: A_add_sub = A - M;
            default: A_add_sub = A;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = COMPUTE;
            COMPUTE: if (count == 7'd64) next_state = FINISH;  // 65 iterations (0-64)
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            busy <= (state == COMPUTE);
            done <= (state == FINISH);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 7'd0;
            A <= 65'd0;
            Q <= 65'd0;
            Q_1 <= 1'b0;
            M <= 65'd0;
            product <= 130'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        count <= 7'd0;
                        A <= 65'd0;
                        Q <= multiplier;
                        Q_1 <= 1'b0;
                        M <= multiplicand;
                        product <= 130'd0;
                    end
                end
                
                COMPUTE: begin
                    // Arithmetic right shift of {A, Q, Q_1}
                    A <= {A_add_sub[64], A_add_sub[64:1]};      // Sign extend
                    Q <= {A_add_sub[0], Q[64:1]};
                    Q_1 <= Q[0];
                    count <= count + 1;
                end
                
                FINISH: begin
                    product <= {A, Q};  // 65 + 65 = 130 bits
                end
            endcase
        end
    end

endmodule

