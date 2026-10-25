`timescale 1ns / 1ps

module Wallace_64x64_shifter(
    input             signed_en,   // used only for MUL (MAC path, Mul_Control=3'b100)
    input      [1:0]  mode,
    input       [2:0] Mul_Control,
    input      [63:0] a,
    input      [63:0] b,
    output reg [63:0] result
);

// ============================================================
// Sign decode - each variant has its own per-operand policy
//
//  Mul_Control | Instruction | sign_a       | sign_b
//  ------------|-------------|--------------|---------------
//  3'b100      | MUL         | signed_en&a63| signed_en&b63  (MAC/GPR shared)
//  3'b101      | MULH        | a[63]        | b[63]          (signed × signed)
//  3'b110      | MULHSU      | a[63]        | 0              (signed × unsigned)
//  3'b111      | MULHU       | 0            | 0              (unsigned × unsigned)
// ============================================================
wire sign_a = (Mul_Control == 3'b101) ?  a[63]            :  // MULH
              (Mul_Control == 3'b110) ?  a[63]            :  // MULHSU
              (Mul_Control == 3'b100) ? (signed_en & a[63]) : // MUL / MAC
              1'b0;                                           // MULHU / default

wire sign_b = (Mul_Control == 3'b101) ?  b[63]            :  // MULH
              (Mul_Control == 3'b110) ?  1'b0             :  // MULHSU: b is unsigned
              (Mul_Control == 3'b100) ? (signed_en & b[63]) : // MUL / MAC
              1'b0;                                           // MULHU / default

// Absolute values
wire [63:0] abs_a = sign_a ? (~a + 1) : a;
wire [63:0] abs_b = sign_b ? (~b + 1) : b;

// Sign of result (only meaningful for signed operations)
wire result_neg = sign_a ^ sign_b;

// ============================================================
// STAGE 1 - 8×8 grid of Wallace-tree-8 instances
// ============================================================
wire [15:0] pp [0:7][0:7];
genvar gi, gj;
generate
    for (gi = 0; gi < 8; gi = gi + 1) begin : ROW
        for (gj = 0; gj < 8; gj = gj + 1) begin : COL
            Wallance_tree_8 u_wt (
                .a    ( abs_a[8*gi +: 8] ),
                .b    ( abs_b[8*gj +: 8] ),
                .prod ( pp[gi][gj]        )
            );
        end
    end
endgenerate

// ============================================================
// STAGE 2 - Shift & accumulate
// ============================================================
wire [127:0] sh [0:7][0:7];
genvar si, sj;
generate
    for (si = 0; si < 8; si = si + 1) begin : SH_ROW
        for (sj = 0; sj < 8; sj = sj + 1) begin : SH_COL
            assign sh[si][sj] = ({112'd0, pp[si][sj]} << (8 * (si + sj)));
        end
    end
endgenerate

// 8-bit mode: only [0][0]
wire [127:0] sum_8b = sh[0][0];

// 16-bit mode: 2×2 block
wire [127:0] sum_16b_tmp [0:3];
assign sum_16b_tmp[0] = sh[0][0] + sh[0][1];
assign sum_16b_tmp[1] = sh[1][0] + sh[1][1];
wire [127:0] sum_16b   = sum_16b_tmp[0] + sum_16b_tmp[1];

// 32-bit mode: 4×4 block
wire [127:0] sum_32b_tmp [0:3];
assign sum_32b_tmp[0] = sh[0][0] + sh[0][1] + sh[0][2] + sh[0][3];
assign sum_32b_tmp[1] = sh[1][0] + sh[1][1] + sh[1][2] + sh[1][3];
assign sum_32b_tmp[2] = sh[2][0] + sh[2][1] + sh[2][2] + sh[2][3];
assign sum_32b_tmp[3] = sh[3][0] + sh[3][1] + sh[3][2] + sh[3][3];
wire [127:0] sum_32b   = (sum_32b_tmp[0] + sum_32b_tmp[1]) +
                         (sum_32b_tmp[2] + sum_32b_tmp[3]);

// 64-bit mode: full 8×8 block
wire [127:0] sum_64b_row [0:7];
assign sum_64b_row[0] = sh[0][0]+sh[0][1]+sh[0][2]+sh[0][3]+sh[0][4]+sh[0][5]+sh[0][6]+sh[0][7];
assign sum_64b_row[1] = sh[1][0]+sh[1][1]+sh[1][2]+sh[1][3]+sh[1][4]+sh[1][5]+sh[1][6]+sh[1][7];
assign sum_64b_row[2] = sh[2][0]+sh[2][1]+sh[2][2]+sh[2][3]+sh[2][4]+sh[2][5]+sh[2][6]+sh[2][7];
assign sum_64b_row[3] = sh[3][0]+sh[3][1]+sh[3][2]+sh[3][3]+sh[3][4]+sh[3][5]+sh[3][6]+sh[3][7];
assign sum_64b_row[4] = sh[4][0]+sh[4][1]+sh[4][2]+sh[4][3]+sh[4][4]+sh[4][5]+sh[4][6]+sh[4][7];
assign sum_64b_row[5] = sh[5][0]+sh[5][1]+sh[5][2]+sh[5][3]+sh[5][4]+sh[5][5]+sh[5][6]+sh[5][7];
assign sum_64b_row[6] = sh[6][0]+sh[6][1]+sh[6][2]+sh[6][3]+sh[6][4]+sh[6][5]+sh[6][6]+sh[6][7];
assign sum_64b_row[7] = sh[7][0]+sh[7][1]+sh[7][2]+sh[7][3]+sh[7][4]+sh[7][5]+sh[7][6]+sh[7][7];
wire [127:0] sum_64b   = (sum_64b_row[0] + sum_64b_row[1]) +
                         (sum_64b_row[2] + sum_64b_row[3]) +
                         (sum_64b_row[4] + sum_64b_row[5]) +
                         (sum_64b_row[6] + sum_64b_row[7]);

// Mode mux (used by MUL/MULH* when mode selects 8/16/32-bit SIMD paths)
wire [127:0] raw_sum = (mode == 2'b00) ? sum_8b  :
                       (mode == 2'b01) ? sum_16b :
                       (mode == 2'b10) ? sum_32b :
                                         sum_64b;

// Sign-corrected full product
wire [127:0] signed_result = result_neg ? (~raw_sum + 1) : raw_sum;

// ============================================================
// Result mux
//
//  MUL   (3'b100) → lower 64 bits (sign-corrected)
//  MULH  (3'b101) → upper 64 bits, signed × signed
//  MULHSU(3'b110) → upper 64 bits, signed × unsigned
//  MULHU (3'b111) → upper 64 bits, unsigned × unsigned
//                   (result_neg is always 0 here; raw_sum used
//                    directly to make the intent explicit)
// ============================================================
always @(*) begin
    case (Mul_Control)
        3'b100:  result = signed_result[63:0];    // MUL  - low  half
        3'b101:  result = signed_result[127:64];  // MULH - high half, signed×signed
        3'b110:  result = signed_result[127:64];  // MULHSU - high half, signed×unsigned
        3'b111:  result = raw_sum[127:64];        // MULHU - high half, fully unsigned
        default: result = signed_result[63:0];
    endcase
end

endmodule