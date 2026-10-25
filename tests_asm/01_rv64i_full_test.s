    # -------------------------------------
    # Setup base values
    # -------------------------------------
   0    addi x1, x0, 5           # x1 = 5
   4    addi x2, x0, 10          # x2 = 10
   8    addi x3, x0, -3          # x3 = -3 (sign test)
   12   lui  x4, 0x12345         # x4 = 0x12345000
   16   auipc x5, 0x10           # x5 = PC + 0x10000
   20   addi x20, x5, 4          # verify auipc effect

    # -------------------------------------
    # Arithmetic operations
    # -------------------------------------
   24   add  x6, x1, x2          # x6 = 15
   28   sub  x7, x2, x1          # x7 = 5
   32   slt  x8, x3, x1          # x8 = 1 (since -3 < 5)
   36   sltu x9, x3, x1          # x9 = 0 (unsigned compare)
   40   addi x10, x1, -2         # x10 = 3
   44   slti x11, x3, 0          # x11 = 1
   48   sltiu x12, x3, 0         # x12 = 0

    # -------------------------------------
    # Logical operations
    # -------------------------------------
    52  and  x13, x1, x2         # x13 = 0b0101 & 0b1010 = 0
    56  or   x14, x1, x2         # x14 = 15
    60  xor  x15, x1, x2         # x15 = 15
    64  andi x16, x2, 8          # x16 = 8
    68  ori  x17, x1, 2          # x17 = 7
    72  xori x18, x2, 1          # x18 = 11

    # -------------------------------------
    # Shift operations (32-bit & 64-bit)
    # -------------------------------------
    76  sll  x19, x1, x2         # shift left logical
    80  srl  x20, x2, x1         # shift right logical
    84  sra  x21, x3, x1         # shift right arithmetic (preserve sign)

    88  slli x22, x1, 2          # x22 = 5 << 2 = 20
    92  srli x23, x2, 1          # x23 = 5
    96  srai x24, x3, 1          # x24 = -2

    # 64-bit specific
    100  addiw x25, x1, 1         # x25 = (x1 + 1) 32-bit sign extended
    104  slliw x26, x1, 1         # x26 = (5 << 1) = 10
    108  srliw x27, x2, 1         # x27 = (10 >> 1) = 5
    112  sraiw x28, x3, 1         # x28 = -2 (sign-preserved)

    116  addw  x29, x1, x2        # x29 = 15 (32-bit add)
    120  subw  x30, x2, x1        # x30 = 5

    #sign-extension test for addiw
    124  lui   x31, 0xFFFFF
    128  addiw x31, x31, 1        # should sign-extend properly

    # -------------------------------------
    # Memory test (Base address = 0)
    # -------------------------------------
    132  sw   x1, 0(x0)           # store 32-bit 5
    136  sd   x2, 8(x0)           # store 64-bit 10
    140  lw   x3, 0(x0)           # load 32-bit -> x3 = 5
    144  ld   x4, 8(x0)           # load 64-bit -> x4 = 10
    148  lwu  x5, 0(x0)           # load word unsigned

    152  sb   x1, 16(x0)          # store byte
    156  sh   x2, 18(x0)          # store halfword
    160  lb   x6, 16(x0)          # load byte
    164  lbu  x7, 16(x0)          # load byte unsigned
    168  lh   x8, 18(x0)          # load halfword
    172  lhu  x9, 18(x0)          # load halfword unsigned

    # -------------------------------------
    # Branch and Jump tests
    # -------------------------------------
    176  addi x10, x0, 1
    180  addi x11, x0, 1
    184  beq  x10, x11, label_beq 
    188  addi x12, x0, 99         # should skip this
label_beq:
    192  bne  x10, x11, label_bne 
    196  addi x13, x0, 13
label_bne:
    200  blt  x3, x2, label_blt 
    204  addi x14, x0, 14
label_blt:
    208  bge  x2, x3, label_bge 
    212  addi x15, x0, 15
label_bge:
    216  bltu x0, x1, label_bltu 
    220  addi x16, x0, 16
label_bltu:
    224  bgeu x1, x0, label_bgeu 
    228  addi x17, x0, 17
label_bgeu:
    232  addi x17, x0 ,18
    # Jumps
    236  jal  x18, jump_target 
    240  addi x19, x0, 123        # should be skipped
jump_target:
    244  addi x19, x0, 321

    # ----- Test JALR -----
    248  addi x27, x0, 260      # (manual address for label_jalr)
    252  jalr x28, 0(x27)         # x28 = return addr, jump to label_jalr
    256  addi x29, x0, 333        # should be skipped

label_jalr:
    260  addi x29, x0, 444        # executed after JALR

    # Program end
    264  jal x0, 0                # infinite loop / stop
