/*
 * inference.c
 * MNIST fixed-point inference for EdgeCore-V (RV64IM)
 *
 * Dependencies : weights.h   (int8 weights + shifts)
 *                test_data.h (struct-based test samples)
 *
 * Compile (x86 test):
 *   gcc -O2 -o inference inference.c && ./inference
 *
 * Compile (RISC-V):
 *   riscv64-unknown-elf-gcc -O2 -march=rv64im -mabi=lp64 \
 *       -nostdlib -o inference.elf inference.c
 *       (add your BSP / startup files as needed)
 *
 * No floats. No malloc. No stdlib (only printf for results).
 * All arithmetic: int8 MACs, int32 accumulator, right-shifts.
 */

#include <stdint.h>
#include <stdio.h>

#include "weights.h"
#include "test_data.h"

/* ── Single forward pass ────────────────────────────────────────────────────
 * Input  : pixels[]  uint8, range [0, 127]  (already >> 1 in test_data.h)
 * Output : returns predicted digit (0-9)
 */
static int forward(const uint8_t *pixels)
{
    int8_t  a1[HIDDEN1_SIZE];
    int8_t  a2[HIDDEN2_SIZE];
    int32_t scores[OUTPUT_SIZE];

    int32_t acc;
    int     n, i;

    /* ── Layer 1: INPUT -> HIDDEN1 ─────────────────────────────────────────
     * acc = sum( W1[n][i] * pixels[i] )    for i in [0, INPUT_SIZE)
     * acc >>= SHIFT_W1                     rescale to Q7
     * acc += b1[n]                         add int8 bias
     * ReLU + clip to [0, 127]
     * store as int8
     */
    for (n = 0; n < HIDDEN1_SIZE; n++) {
        acc = 0;
        for (i = 0; i < INPUT_SIZE; i++) {
            acc += (int32_t)W1_data[n * INPUT_SIZE + i]
                 * (int32_t)pixels[i];
        }
        acc >>= SHIFT_W1;
        acc  += (int32_t)b1_data[n];
        if (acc < 0)   acc = 0;    /* ReLU  */
        if (acc > 127) acc = 127;  /* clip  */
        a1[n] = (int8_t)acc;
    }

    /* ── Layer 2: HIDDEN1 -> HIDDEN2 ───────────────────────────────────────*/
    for (n = 0; n < HIDDEN2_SIZE; n++) {
        acc = 0;
        for (i = 0; i < HIDDEN1_SIZE; i++) {
            acc += (int32_t)W2_data[n * HIDDEN1_SIZE + i]
                 * (int32_t)a1[i];
        }
        acc >>= SHIFT_W2;
        acc  += (int32_t)b2_data[n];
        if (acc < 0)   acc = 0;
        if (acc > 127) acc = 127;
        a2[n] = (int8_t)acc;
    }

    /* ── Layer 3: HIDDEN2 -> OUTPUT ────────────────────────────────────────
     * No ReLU, no softmax — argmax of raw int32 scores is enough.
     */
    for (n = 0; n < OUTPUT_SIZE; n++) {
        acc = 0;
        for (i = 0; i < HIDDEN2_SIZE; i++) {
            acc += (int32_t)W3_data[n * HIDDEN2_SIZE + i]
                 * (int32_t)a2[i];
        }
        acc     >>= SHIFT_W3;
        acc      += (int32_t)b3_data[n];
        scores[n] = acc;
    }

    /* ── Argmax ─────────────────────────────────────────────────────────────*/
    int     best_class = 0;
    int32_t best_score = scores[0];
    for (n = 1; n < OUTPUT_SIZE; n++) {
        if (scores[n] > best_score) {
            best_score = scores[n];
            best_class = n;
        }
    }

    return best_class;
}


/* ── Main ───────────────────────────────────────────────────────────────────*/
int main(void)
{
    int correct = 0;
    int i;

    printf("Running MNIST inference on %d samples...\n", NUM_TESTS);

    for (i = 0; i < NUM_TESTS; i++) {
        int pred = forward(test_data[i].pixels);
        if (pred == (int)test_data[i].label)
            correct++;
    }

    /* Integer-only percentage: avoids float printf on bare-metal */
    int accuracy_whole = (correct * 100)       / NUM_TESTS;
    int accuracy_frac  = (correct * 10000 / NUM_TESTS) % 100;

    printf("Correct : %d / %d\n", correct, NUM_TESTS);
    printf("Accuracy: %d.%02d%%\n", accuracy_whole, accuracy_frac);

    return 0;
}