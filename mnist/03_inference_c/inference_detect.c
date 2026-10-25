/*
 * inference.c
 * Single-image MNIST inference.
 * Paste your image pixels into the input[] array below.
 * Compile test: gcc -O2 -o inference inference.c && ./inference
 */

#include <stdint.h>
#include <stdio.h>
#include "weights.h"

/* ── INPUT IMAGE ─────────────────────────────────────────────────────────────
 * 784 values, range 0-127  (original pixel >> 1)
 * Use extract_image.py to generate this array from any mnist_test.csv row.
 * Paste the output here and recompile (or re-assemble for your ISA).
 */
static const int8_t input[784] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 127, 54, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 126, 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67, 120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 122, 75, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 42, 127, 31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 101, 111, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 127, 108, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 127, 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70, 127, 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 118, 102, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 127, 82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 85, 127, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 116, 107, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 127, 79, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 75, 127, 71, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 127, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30, 125, 127, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70, 127, 102, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 107, 127, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 99, 88, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

/* ── Working buffers ─────────────────────────────────────────────────────────
 * a1  : 128 bytes  output of layer 1
 * a2  :  64 bytes  output of layer 2
 * out :  10 int32  raw scores from layer 3 (not stored after argmax)
 */
static int8_t  a1[HIDDEN1_SIZE];
static int8_t  a2[HIDDEN2_SIZE];
static int32_t out[OUTPUT_SIZE];

int main(void)
{
    int32_t acc;
    int n, i;

    /* ── Layer 1: 784 inputs -> 128 neurons ─────────────────────────────── */
    for (n = 0; n < HIDDEN1_SIZE; n++) {
        acc = 0;
        for (i = 0; i < INPUT_SIZE; i++) {
            acc += (int32_t)W1_data[n * INPUT_SIZE + i]
                 * (int32_t)input[i];
        }
        acc >>= SHIFT_W1;           /* rescale: right-shift, no float   */
        acc  += (int32_t)b1_data[n];/* add bias after shift             */
        if (acc < 0)   acc = 0;     /* ReLU                             */
        if (acc > 127) acc = 127;   /* clip to int8 range               */
        a1[n] = (int8_t)acc;
    }

    /* ── Layer 2: 128 inputs -> 64 neurons ──────────────────────────────── */
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

    /* ── Layer 3: 64 inputs -> 10 scores ────────────────────────────────── */
    for (n = 0; n < OUTPUT_SIZE; n++) {
        acc = 0;
        for (i = 0; i < HIDDEN2_SIZE; i++) {
            acc += (int32_t)W3_data[n * HIDDEN2_SIZE + i]
                 * (int32_t)a2[i];
        }
        acc   >>= SHIFT_W3;
        acc    += (int32_t)b3_data[n];
        out[n]  = acc;
    }

    /* ── Argmax: highest score = predicted digit ─────────────────────────── */
    int     pred  = 0;
    int32_t best  = out[0];
    for (n = 1; n < OUTPUT_SIZE; n++) {
        if (out[n] > best) {
            best = out[n];
            pred = n;
        }
    }

    printf("Predicted digit : %d\n", pred);
    printf("Scores: ");
    for (n = 0; n < OUTPUT_SIZE; n++)
        printf("[%d]=%d ", n, (int)out[n]);
    printf("\n");

    return 0;
}