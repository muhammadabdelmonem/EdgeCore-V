
//==============================================================================
// RV64 M-Extension Multiplication Unit
// Implements sign extension wrapper as per reference document
// - Signed operands: append sign bit (bit 63) to MSB
// - Unsigned operands: append 0 to MSB
//==============================================================================

module rv64_m_mul_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [63:0] rs1,
    input  wire [63:0] rs2,
    input  wire [2:0]  funct3,
    output reg  [63:0] rd,
    output reg         done,
    output reg         busy
);

    localparam MUL    = 3'b000;
    localparam MULH   = 3'b001;
    localparam MULHSU = 3'b010;
    localparam MULHU  = 3'b011;
    localparam MULW   = 3'b100;

    localparam IDLE   = 2'b00;
    localparam EXEC   = 2'b01;
    localparam FINISH = 2'b10;

    reg [1:0] state, next_state;
    reg [2:0] current_funct3;

    wire [129:0] mul_product;       // 130-bit product from 65×65 multiplier
    wire         mul_done;
    wire         mul_busy;
    reg          mul_start;
    reg  [64:0]  multiplicand;      // 65-bit with sign extension
    reg  [64:0]  multiplier;        // 65-bit with sign extension

    // Instantiate 65-bit Booth multiplier
    booth_radix2_multiplier_65bit booth_mul (
        .clk(clk),
        .rst_n(rst_n),
        .start(mul_start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(mul_product),
        .done(mul_done),
        .busy(mul_busy)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (start) next_state = EXEC;
            EXEC:   if (mul_done) next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            busy <= (state == EXEC);
            done <= (state == FINISH);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_funct3 <= 3'b0;
            mul_start <= 1'b0;
            multiplicand <= 65'd0;
            multiplier <= 65'd0;
            rd <= 64'd0;
        end else begin
            case (state)
                IDLE: begin
                    mul_start <= 1'b0;
                    if (start) begin
                        current_funct3 <= funct3;
                        mul_start <= 1'b1;
                        
                        case (funct3)
                            MUL, MULH: begin
                                // Signed × Signed
                                // Append sign bit (bit 63) to MSB position (bit 64)
                                multiplicand <= {rs1[63], rs1};
                                multiplier <= {rs2[63], rs2};
                            end
                            
                            MULHSU: begin
                                // Signed × Unsigned
                                // rs1: append sign bit (signed)
                                // rs2: append 0 (unsigned)
                                multiplicand <= {rs1[63], rs1};
                                multiplier <= {1'b0, rs2};
                            end
                            
                            MULHU: begin
                                // Unsigned × Unsigned
                                // Both: append 0 (unsigned)
                                multiplicand <= {1'b0, rs1};
                                multiplier <= {1'b0, rs2};
                            end
                            
                            MULW: begin
                                // 32-bit Signed × Signed
                                // Sign-extend 32-bit to 64-bit, then append sign bit
                                multiplicand <= {rs1[31], {32{rs1[31]}}, rs1[31:0]};
                                multiplier <= {rs2[31], {32{rs2[31]}}, rs2[31:0]};
                            end
                            
                            default: begin
                                multiplicand <= {rs1[63], rs1};
                                multiplier <= {rs2[63], rs2};
                            end
                        endcase
                    end
                end
                
                EXEC: begin
                    mul_start <= 1'b0;
                end
                
                FINISH: begin
                    // Extract result from 130-bit product
                    // Product is {A[64:0], Q[64:0]} = 130 bits
                    // We want bits [127:64] for high, [63:0] for low
                    
                    case (current_funct3)
                        MUL: begin
                            // Return lower 64 bits
                            rd <= mul_product[63:0];
                        end
                        
                        MULH, MULHSU, MULHU: begin
                            // Return upper 64 bits
                            // mul_product[129:0], we want bits [127:64]
                            rd <= mul_product[127:64];
                        end
                        
                        MULW: begin
                            // Return sign-extended lower 32 bits
                            rd <= {{32{mul_product[31]}}, mul_product[31:0]};
                        end
                        
                        default: begin
                            rd <= mul_product[63:0];
                        end
                    endcase
                end
            endcase
        end
    end

endmodule
