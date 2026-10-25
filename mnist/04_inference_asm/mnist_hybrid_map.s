# ---------------- Setup addresses ----------------
    lui     x1, 0x00000         # x1  = DCache_Base
    lui     x2, 0x80000         # x2  = SPM_BASE upper
    lui     x3, 0xFFFF0         # x3  = DMA_CTRL_BASE upper

    addi    x4, x0, 0x0         # x4  = input (X) address
    addi    x5, x0, 0x400       # x5  = b2 address
    addi    x6, x0, 0x600       # x6  = a1 address
    addi    x7, x0, 0x800       # x7  = a2 address
    addi    x8, x0, 0xa00       # x8  = out address

    lui     x9, 0x80000         # x9  = W address in SPM
    lui     x10, 0x80001       
    addi    x10, x10, 0xb58     # x10  = b address in SPM

    lui     x11, 0x10000        # x11 = w1 external address
    lui     x12, 0x10018
    addi    x12, x12, 0x800     # x12 = b1 external address 
    lui     x13, 0x10018
    addi    x13, x13, 0x880     # x13 = w2 external address
    lui     x14, 0x1001a
    addi    x14, x14, 0x880     # x14 = b2 external address  
    lui     x15, 0x1001a
    addi    x15, x15, 0x8c0     # x15 = w3 external address
    lui     x16, 0x1001a
    addi    x16, x16, 0xb40     # x16 = b3 external address  

# ---------------- Setup constants ----------------
#    addi    x17, x0, 784       # x17 = input size = 784
#    addi    x18, x0, 128       # x18 = hidden1 size = 128
#    addi    x19, x0, 64        # x19 = hidden2 size = 64
#    addi    x20, x0, 10        # x20 = output size = 10
#    addi    x21, x0, 8         # x21 = neurons per tile = 8
#    addi    x22, x0, 6272      # x22 = tile  size = 6272
#    addi    x23, x0, 16        # x23 = number of tiles = 16
#    addi    x24, x0, 6         # x24 = shift_w1 = 6
#    addi    x25, x0, 6         # x25 = shift_w2 = 6
#    addi    x26, x0, 7         # x26 = shift_w3 = 6

# -------------------  Start  ---------------------
# ------------------- layer 1 ---------------------  
# ------------------- load b1 --------------------- 
    addi    x18, x0, 128        # x18 = hidden1 size
    addi    x19, x0, 0x3        # x19 = CTRL START = 1 & Direction = 1 
    sd      x12, 0(x3)          # DMA[SRC] = b1 external address
    sd      x10, 8(x3)          # DMA[DST] = b address in SPM
    sd      x18, 16(x3)         # DMA[SIZE] = hidden1 size = 128 byte
    sd      x19, 24(x3)         # DMA[CTRL] = START

# --------------- layer1 engine---------------------
    addi    x17, x0, 16         # x17 = number of tiles = 16
    addi    x18, x0, 0          # x18 = tile index from 0 to 15
    add     x19, x0, x11        # x19 = w1 tile address
layer1_tiel_loop:
    beq  18, x17, layer1_done

    #------------- W1 teil load --------------
    addi    x20, x0, 6272       # x20 = tile  size
    addi    x21, x0, 0x3        # x221 = CTRL START = 1 & Direction = 1 
    sd      x19, 0(x3)          # DMA[SRC] = w1 external address
    sd      x9, 8(x3)           # DMA[DST] = w address in SPM
    sd      x20, 16(x3)         # DMA[SIZE] = tile size = 6272 bytes 
    sd      x21, 24(x3)         # DMA[CTRL] = START

    #----------- compute 8 neuron ------------
    addi    x20, x0, 0          # x20 = neuron index within the teil
    addi    x21, x0, 8          # x21 = number of neurons per tile
    add     x22, x0, x9         # x22 = weight ptr in SPM (starts at SPM_W_TILE (base), advances +784 per neuron)
    add     x23, x0, x6         # x23 = output ptr in a1[]
neuron_loop_l1:
    beq  x20, x21, tile_l1_done

    #-------------- mac loop ----------------
    addi    x24, x0, 0          # x24 = acc = 0
    add     x25, x0, x4         # x25 = input pointer
    add     x26, x0, x22        # x26 = weight ptr 
    addi    x27, x0, 784        # x27 = counter = 784  (input size)

mac_l1:
    beq x27, x0, mac_l1_done

    lb   x28, 0(x26)            # w  = W1_tile[n][i]  int8
    lbu  x29, 0(x25)            # x  = input[i]       uint8
    mul  x28, x28, x29          # x28 = w * x
    add  x24, x24, x28          # acc = acc + w * x
    addi x25, x25, 1            # x = x + 1  input increment
    addi x26, x26, 1            # w = w + 1  weight increment
    addi x27, x27, -1           # count = count - 1 
    jal x0, mac_l1

mac_l1_done:
    srai x24, x24, 6           # acc >>= SHIFT_W1  scale back to int8
    
    #-------- add b after the mul-----------
    add  x25, x0, x10          # x25 = b1 base address in SPM
    slli x26, x18, 3           # x26 = tile * 8
    add  x25, x25, x26         # x25 = SPM_B1 + tile*8
    add  x25, x25, x20         # 25 = SPM_B1 + tile*8 + n  = b1[global_n]
    lb   x26, 0(x25)           # x26 = b1[n]  int8
    add  x24, x24, x26         # a24 = acc = acc + bias

    # ReLU
    bge   x24, zero, clip_l1
    addi  x24, x0, 0
clip_l1:
    addi x25, x0, 127
    blt  x24, x25, store_l1
    addi x24, x0, 127
store_l1:
    sb   x24, 0(x23)           # a1[global_n] = (int8)acc

    addi x22, x22, 784         # x22 = weight ptr in SPM next neuron weights in SPM (+784)
    addi x23, x23, 1           # x23 = output ptr in a1[] = x23 + 1  (next output byte)
    addi x20, x20, 1           # x20 = neuron index within the teil = x20 + 1 
    jal, x0, neuron_loop_l1

tile_l1_done:
    addi x18, x18, 1            # x18 = teil index = tile++
    addi x19, x19, 6272         # x19 = w1 tile address = previous teil address + 6272
    addi x6, x6, 8              # x6 = a1 address = a1 output ptr + 8
    jal  x0, layer1_tile_loop

layer1_done:
