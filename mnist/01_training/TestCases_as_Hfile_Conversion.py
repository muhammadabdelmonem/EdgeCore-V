import numpy as np

INPUT_FILE = "mnist_test.csv"

# Load file
with open(INPUT_FILE, 'r') as f:
    lines = f.readlines()

dataset = []

for row in lines:
    vals = row.strip().split(',')

    label = int(vals[0])
    pixels = np.array(vals[1:], dtype=np.int32)

    # Quantize: 0–255 → 0–127
    pixels = (pixels >> 1).astype(np.uint8)

    dataset.append((label, pixels))

# Write C file
with open("test_data.h", "w") as f:
    f.write("#ifndef TEST_DATA_H\n#define TEST_DATA_H\n\n")
    f.write("#include <stdint.h>\n\n")

    f.write("#define INPUT_SIZE 784\n")
    f.write(f"#define NUM_TESTS {len(dataset)}\n\n")

    f.write("typedef struct {\n")
    f.write("    uint8_t label;\n")
    f.write("    uint8_t pixels[INPUT_SIZE];\n")
    f.write("} test_sample_t;\n\n")

    f.write("static const test_sample_t test_data[] = {\n")

    for label, pixels in dataset:
        pixel_str = ", ".join(str(int(x)) for x in pixels)
        f.write(f"    {{{label}, {{{pixel_str}}}}},\n")

    f.write("};\n\n#endif\n")

print("Done. Struct-based test_data.h generated.")