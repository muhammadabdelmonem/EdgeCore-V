# ---------------- Setup addresses ----------------
0      lui     x10, 0x80000       # x10 = SPM_BASE = 0x80000000
4      lui     x11, 0xFFFF0       # x11 = DMA_CTRL_BASE
8      addi    x12, x0, 64        # x12 = transfer size = 64 bytes
12     lui     x13, 0x1           # x13 = 0x1000 (main memory base)

# --------------- D Cache loads ------------------
16     lw      x1, 0(x13)         # MEM[0x1000] = lower 32 of 0x1122334455667788
20     lw      x2, 8(x13)         # MEM[0x1008] = lower 32 of 0x99AABBCCDDEEFF00

# --------------- DMA: MEM -> SPM ----------------
24     sd      x13, 0(x11)        # DMA[SRC] = 0x1000
28     sd      x10, 8(x11)        # DMA[DST] = SPM_BASE
32     sd      x12, 16(x11)       # DMA[SIZE] = 64 bytes
36     addi    x14, x0, 0x3       # CTRL = START | DIR=MEM->SPM
40     sd      x14, 24(x11)       # kick off DMA  ← stall starts here

# --------------- D Cache loads (after stall releases) -----------
44     lw      x3, 72(x13)        # MEM[0x1020] = lower 32 of 0xA1B2C3D4E5F60718
48     lw      x4, 40(x13)        # MEM[0x1028] = lower 32 of 0xDEADC0DEBEEFCAFE

# --------------- Load DMA Status ----------------
52     ld      x5, 32(x11)        # x5 = DMA STATUS

# --------------- CPU reads SPM after DMA done ---
56     ld      x28, 0(x10)        # SPM[0]  = 0x1122334455667788
60     lw      x29, 16(x10)       # SPM[16] = lower 32 of 0x0123456789ABCDEF
64     addi    x29, x29, 1

# --------------- Modify SPM before sending back -----------------
68     addi    x20, x0, 0x42      # x20 = 0x42
72     sd      x20, 0(x10)        # SPM[0]  = 0x42
76     addi    x21, x0, -1        # x21 = 0xFFFF...
80     sh      x21, 8(x10)        # SPM[8]  = 0xFFFF
84     addi    x22, x0, 0x7AA     # x22 = 0x7AA  -- NOTE: addi is 12-bit signed
88     sw      x22, 16(x10)       # SPM[16] = 0x7AA  -- 0x7AA = 1962, fits OK
92     addi    x23, x0, 0x55      # x23 = 0x55
96     sd      x23, 24(x10)       # SPM[24] = 0x55
100    addi    x24, x0, 0x7F      # x24 = 0x7F
104    sb      x24, 32(x10)       # SPM[32] = 0x7F

# --------------- Read back to verify -------------------------
108    ld      x25, 0(x10)        # should be 0x42
112    lw      x26, 16(x10)       # should be 0x7AA
116    lh      x27, 8(x10)        # should be -1 (0xFFFF signed)

# --------------- DMA: SPM -> Main Memory (back) --------------
120    sd      x10, 0(x11)        # DMA[SRC] = SPM_BASE
124    sd      x13, 8(x11)        # DMA[DST] = 0x1000
128    sd      x12, 16(x11)       # DMA[SIZE] = 64 bytes
132    addi    x15, x0, 1         # CTRL = START | DIR=SPM->MEM
136    sd      x15, 24(x11)       # kick off DMA  ← stall starts here

140    ld      x16, 32(x11)       # DMA STATUS (done after stall releases)

# ---------------- End of program --------------------------------
144    jal     x0, 0




