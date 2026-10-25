import numpy as np

# ── Load weights ──────────────────────────────────────────────────────────────
data = np.load("mnist_weights.npz")

W1 = data['W1']            # (128, 784)
b1 = data['b1'].flatten()  # (128,)
W2 = data['W2']            # (64,  128)
b2 = data['b2'].flatten()  # (64,)
W3 = data['W3']            # (10,  64)
b3 = data['b3'].flatten()  # (10,)

print("Loaded weights:")
print(f"  W1: {W1.shape}  max_abs={np.max(np.abs(W1)):.4f}")
print(f"  W2: {W2.shape}  max_abs={np.max(np.abs(W2)):.4f}")
print(f"  W3: {W3.shape}  max_abs={np.max(np.abs(W3)):.4f}")
print(f"  b1: max_abs={np.max(np.abs(b1)):.4f}")
print(f"  b2: max_abs={np.max(np.abs(b2)):.4f}")
print(f"  b3: max_abs={np.max(np.abs(b3)):.4f}")


# =============================================================================
#  MEMORY LAYOUT — everything stored as int8
#
#  Weights (int8):   quantized with shift per layer
#  Biases  (int8):   quantized in Q7 (scale = 128) — added AFTER the shift
#  Activations:      int8 (temporary, just a stack array in C)
#  Accumulator:      int32 REGISTER only — never stored, costs zero memory
#
#  Flow inside one neuron in C:
#
#    int32_t acc = 0;
#    for (i = 0; i < N; i++)
#        acc += (int32_t)W[n*N+i] * (int32_t)x[i];  // int32 register
#    acc >>= SHIFT_W;              // back to Q7 range
#    acc += (int32_t)b[n];         // add int8 bias (cast to int32 for add)
#    if (acc < 0)   acc = 0;       // ReLU
#    if (acc > 127) acc = 127;     // clip
#    output[n] = (int8_t)acc;      // store as int8
#
#  Total memory stored = weights + biases, ALL int8. Nothing else.
# =============================================================================

INPUT_SHIFT = 7   # pixels: x = pixel >> 1, range [0,127], scale = 2^7

def get_shift(arr):
    """Largest shift N such that max_abs * 2^N <= 127 (fits in int8)."""
    max_abs = np.max(np.abs(arr))
    return int(np.floor(np.log2(127.0 / max_abs)))

def quantize_int8(arr, shift):
    """Quantize to int8 using power-of-2 scale = 2^shift."""
    scale = 2 ** shift
    return np.clip(np.round(arr * scale), -127, 127).astype(np.int8)

# Weight shifts — per layer
shift_W1 = get_shift(W1)
shift_W2 = get_shift(W2)
shift_W3 = get_shift(W3)

# Bias shift — same as Q7 (= INPUT_SHIFT = 7) because bias is added
# AFTER acc >>= SHIFT_W, so the accumulator is already back in Q7 scale.
# Therefore bias_int8 = round(b_float * 128), clipped to [-127, 127].
BIAS_SHIFT = INPUT_SHIFT  # = 7

print(f"\nShifts:")
print(f"  SHIFT_W1 = {shift_W1}  (weight scale = 2^{shift_W1} = {2**shift_W1})")
print(f"  SHIFT_W2 = {shift_W2}  (weight scale = 2^{shift_W2} = {2**shift_W2})")
print(f"  SHIFT_W3 = {shift_W3}  (weight scale = 2^{shift_W3} = {2**shift_W3})")
print(f"  BIAS_SHIFT = {BIAS_SHIFT}  (bias scale = 2^{BIAS_SHIFT} = {2**BIAS_SHIFT})")

# Quantize everything to int8
W1q = quantize_int8(W1, shift_W1)
W2q = quantize_int8(W2, shift_W2)
W3q = quantize_int8(W3, shift_W3)

b1q = quantize_int8(b1, BIAS_SHIFT)
b2q = quantize_int8(b2, BIAS_SHIFT)
b3q = quantize_int8(b3, BIAS_SHIFT)

print(f"\nAll int8 ranges:")
print(f"  W1q : [{W1q.min():4d}, {W1q.max():4d}]")
print(f"  W2q : [{W2q.min():4d}, {W2q.max():4d}]")
print(f"  W3q : [{W3q.min():4d}, {W3q.max():4d}]")
print(f"  b1q : [{b1q.min():4d}, {b1q.max():4d}]")
print(f"  b2q : [{b2q.min():4d}, {b2q.max():4d}]")
print(f"  b3q : [{b3q.min():4d}, {b3q.max():4d}]")

# Warn if any bias was clipped (means float bias exceeded ~0.99)
for name, bq, bf in [("b1", b1q, b1), ("b2", b2q, b2), ("b3", b3q, b3)]:
    clipped = np.sum(np.abs(bf) * (2**BIAS_SHIFT) > 127)
    if clipped > 0:
        print(f"  WARNING: {clipped} values in {name} were clipped — "
              f"max_abs={np.max(np.abs(bf)):.4f} exceeds int8 range at scale 128")


# ── Verify: simulate exact C behaviour in Python ──────────────────────────────
print("\nVerifying fixed-point accuracy on first 1000 test samples...")

with open("mnist_test_int8.csv", 'r') as f:
    test_list = f.readlines()

correct = 0
for row in test_list[:1000]:
    vals   = row.split(',')
    label  = int(vals[0])
    pixels = np.array(vals[1:], dtype=np.int32)

    x = pixels >> 1                    # int8 range [0, 127]

    # Layer 1
    a1 = np.zeros(128, dtype=np.int8)
    for n in range(128):
        acc  = int(np.dot(W1q[n].astype(np.int32), x))   # int32 accumulator
        acc >>= shift_W1                                   # back to Q7
        acc += int(b1q[n])                                 # add int8 bias
        if acc < 0:   acc = 0                              # ReLU
        if acc > 127: acc = 127                            # clip
        a1[n] = np.int8(acc)

    # Layer 2
    a2 = np.zeros(64, dtype=np.int8)
    for n in range(64):
        acc  = int(np.dot(W2q[n].astype(np.int32), a1.astype(np.int32)))
        acc >>= shift_W2
        acc += int(b2q[n])
        if acc < 0:   acc = 0
        if acc > 127: acc = 127
        a2[n] = np.int8(acc)

    # Layer 3 — argmax only, no softmax needed
    scores = np.zeros(10, dtype=np.int32)
    for n in range(10):
        acc  = int(np.dot(W3q[n].astype(np.int32), a2.astype(np.int32)))
        acc >>= shift_W3
        acc += int(b3q[n])
        scores[n] = acc

    if int(np.argmax(scores)) == label:
        correct += 1

print(f"  Fixed-point accuracy : {correct / 10:.1f}%  (1000 samples)")


# ── Memory summary ────────────────────────────────────────────────────────────
total = W1q.size + b1q.size + W2q.size + b2q.size + W3q.size + b3q.size
print(f"\nMemory footprint (everything int8, 1 byte each):")
print(f"  W1 : {W1q.size:7,} bytes")
print(f"  b1 : {b1q.size:7,} bytes")
print(f"  W2 : {W2q.size:7,} bytes")
print(f"  b2 : {b2q.size:7,} bytes")
print(f"  W3 : {W3q.size:7,} bytes")
print(f"  b3 : {b3q.size:7,} bytes")
print(f"  TOTAL : {total:,} bytes = {total/1024:.1f} KB")


# ── Write weights.h ───────────────────────────────────────────────────────────
def write_int8_array(f, name, arr, cols=16):
    flat = arr.flatten()
    f.write(f"static const int8_t {name}[] = {{\n")
    for i in range(0, len(flat), cols):
        line = ", ".join(f"{int(v):4d}" for v in flat[i:i+cols])
        f.write(f"    {line},\n")
    f.write("};\n\n")

with open("weights.h", "w", encoding='utf-8') as f:
    f.write("// weights.h - all int8, auto-generated by export_weights.py\n")
    f.write("// Zero floats. Accumulator is int32 register only (not stored).\n")
    f.write("// Bias is added AFTER acc >>= SHIFT_WN.\n\n")
    f.write("#ifndef WEIGHTS_H\n")
    f.write("#define WEIGHTS_H\n\n")
    f.write("#include <stdint.h>\n\n")

    f.write("// Network dimensions\n")
    f.write("#define INPUT_SIZE    784\n")
    f.write("#define HIDDEN1_SIZE  128\n")
    f.write("#define HIDDEN2_SIZE   64\n")
    f.write("#define OUTPUT_SIZE    10\n\n")

    f.write("// Fixed-point shifts (used as >> in C after MAC loop)\n")
    f.write(f"#define SHIFT_W1  {shift_W1}\n")
    f.write(f"#define SHIFT_W2  {shift_W2}\n")
    f.write(f"#define SHIFT_W3  {shift_W3}\n\n")

    f.write("// Weights - int8, row-major\n")
    f.write("// Access: W1_data[neuron * INPUT_SIZE + input_index]\n")
    write_int8_array(f, "W1_data", W1q)
    write_int8_array(f, "W2_data", W2q)
    write_int8_array(f, "W3_data", W3q)

    f.write("// Biases - int8, scale = 2^7 = 128\n")
    f.write("// Added to acc AFTER acc >>= SHIFT_WN\n")
    write_int8_array(f, "b1_data", b1q)
    write_int8_array(f, "b2_data", b2q)
    write_int8_array(f, "b3_data", b3q)

    f.write("#endif // WEIGHTS_H\n")

print(f"\nweights.h written (UTF-8, all int8).")