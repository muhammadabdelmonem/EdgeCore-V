import numpy as np

INPUT_FILE  = "mnist_test.csv"
OUTPUT_FILE = "mnist_test_int8.csv"

print("Converting test dataset to int8...")

with open(INPUT_FILE, 'r') as f:
    lines = f.readlines()

converted = []

for row in lines:
    vals = row.strip().split(',')

    label = vals[0]
    pixels = np.array(vals[1:], dtype=np.int32)

    # Quantize: 0–255 → 0–127
    pixels_int8 = pixels >> 1

    # Convert back to string
    new_row = [label] + [str(int(x)) for x in pixels_int8]
    converted.append(",".join(new_row))

# Write output
with open(OUTPUT_FILE, 'w') as f:
    for row in converted:
        f.write(row + "\n")

print(f"Done.")
print(f"Saved to: {OUTPUT_FILE}")
print(f"Samples  : {len(converted)}")