# ---------------- Setup addresses ----------------
# ---------------- Local buffer addresses ----------------
addi    x2, x0, 0x280       # x2 = X   address (byte 640,  word 80)
addi    x3, x0, 0x5C0       # x3 = a1  address (byte 1472, word 184)
addi    x4, x0, 0x640       # x4 = a2  address (byte 1600, word 200)
addi    x5, x0, 0x680       # x5 = out address (byte 1664, word 208)

# ---------------- Weight/bias addresses ----------------
lui     x6, 0x1                              # x6 = w1 address (0x000800)
addi    x6, x6, -0x800

lui     x7, 0x1B                             # x7 = b1 address (0x01B280)
addi    x7, x7, 0x280

lui     x8, 0x19                             # x8 = w2 address (0x019000, exact)

lui     x9, 0x1B                             # x9 = b2 address (0x01B300)
addi    x9, x9, 0x300

lui     x10, 0x1B                            # x10 = w3 address (0x01B000, exact)

lui     x11, 0x1B                            # x11 = b3 address (0x01B340)
addi    x11, x11, 0x340

# ---------------- Setup constants ----------------
#   input size = 784
#   hidden1 size = 128
#   hidden2 size = 64
#   output size = 10
#   neurons per tile = 8
#	tile  size = 6272
#   number of tiles = 16
#	shift_w1 = 6
#	shift_w2 = 6
#	shift_w3 = 7

# -------------------  Start  ---------------------
# ------------------- layer 1 ---------------------  
# --------------- layer1 engine---------------------
#----------- compute 128 neuron ------------
    addi    x20, x0, 0          # x20 = neuron index 
    addi    x21, x0, 128        # x21 = number of neurons 
    add     x22, x0, x6         # x22 = weight ptr in memory (starts at w1 base), advances +784 per neuron)
    add     x23, x0, x3         # x23 = output ptr in a1[]
neuron_loop_l1:
    beq  x20, x21, layer1_done

#-------------- mac loop ----------------
    addi    x24, x0, 0          # x24 = acc = 0
    add     x25, x0, x2         # x25 = X input pointer
    add     x26, x0, x22        # x26 = weight ptr 
    addi    x27, x0, 784        # x27 = counter = 784  (input size)

mac_l1:
    beq x27, x0, mac_l1_done

    lb   x28, 0(x26)            # w  = W1_tile[n][i]  int8
    lbu  x29, 0(x25)            # x  = input[i]       uint8
	macb  x24, x28, x29          # acc = acc + w * x (signed byte operation)
    addi x25, x25, 1            # x = x + 1  input increment
    addi x26, x26, 1            # w = w + 1  weight increment
    addi x27, x27, -1           # count = count - 1 
    jal x0, mac_l1

mac_l1_done:
    srai x24, x24, 6           # acc >>= SHIFT_W1  scale back to int8
    
# ------------------- add b1 after the mul --------------------
    add     x25, x0, x7        # x25 = b1 base
    add     x25, x25, x20       # x25 = &b1[n]

    lb      x26, 0(x25)         # x26 = bias
    add     x24, x24, x26       # acc += bias

# --------------------- ReLU ---------------------- 
    bge   x24, x0, clip_l1
    addi  x24, x0, 0
clip_l1:
    addi x25, x0, 127
    blt  x24, x25, store_l1
    addi x24, x0, 127
# -------------------- store ----------------------	
store_l1:
    sb   x24, 0(x23)           # a1[global_n] = (int8)acc
# --------------- next neuron setup ---------------
    addi x22, x22, 784         # next neuron weights(+784)
    addi x23, x23, 1           # output ptr in a1[] = x23 + 1  (next output byte)
    addi x20, x20, 1           # neuron++
    jal x0, neuron_loop_l1
# -------------------- done -----------------------
layer1_done:

# ------------------- layer 2 --------------------- 
# ---------------- layer2 engine ------------------
#----------- compute 64 neuron ------------
    addi    x20, x0, 0          # x20 = neuron index
    addi    x21, x0, 64        # x21 = total neurons

    add     x22, x0, x8         # x22 = weight ptr in memory (starts at w2 base), advances +128 per neuron)
    add     x23, x0, x4         # x23 = output pointer a2[]

neuron_loop_l2:
    beq     x20, x21, layer2_done


# ------------------- MAC loop --------------------
    addi    x24, x0, 0          # x24 = accumulator = 0

    add     x25, x0, x3         # x25 = a1 input pointer
    add     x26, x0, x22        # x26 = weight pointer

    addi    x27, x0, 128        # x27 = counter = input size

mac_l2:
    beq     x27, x0, mac_l2_done

    lb      x28, 0(x26)         # w = W2[n][i]
    lbu     x29, 0(x25)         # a1 = input[i]

    macb     x24, x28, x29       # acc += w2 * a1

    addi    x25, x25, 1         # next input
    addi    x26, x26, 1         # next weight
    addi    x27, x27, -1        # counter--

    jal     x0, mac_l2


mac_l2_done:
    srai    x24, x24, 6         # scale back


# ------------------- add b2 after the mul --------------------
    add     x25, x0, x9        # x25 = b2 base
    add     x25, x25, x20       # x25 = &b2[n]

    lb      x26, 0(x25)         # x26 = bias
    add     x24, x24, x26       # acc += bias


# --------------------- ReLU ----------------------
    bge     x24, x0, clip_l2
    addi    x24, x0, 0

clip_l2:
    addi    x25, x0, 127
    blt     x24, x25, store_l2

    addi    x24, x0, 127


# -------------------- store ----------------------
store_l2:
    sb      x24, 0(x23)         # a2[n] = acc


# --------------- next neuron setup ---------------
    addi    x22, x22, 128       # next neuron weights
    addi    x23, x23, 1         # next output byte
    addi    x20, x20, 1         # neuron++

    jal     x0, neuron_loop_l2


# -------------------- done -----------------------
layer2_done:	


# ------------------- layer 3 --------------------- 
# ---------------- layer3 engine ------------------
#----------- compute 10 neuron ------------
    addi    x20, x0, 0          # x20 = neuron index
    addi    x21, x0, 10        # x21 = total neurons

    add     x22, x0, x10         # x22 = weight ptr in memory (starts at w3 base), advances +64 per neuron)
    add     x23, x0, x5         # x23 = output pointer out[]

neuron_loop_l3:
    beq     x20, x21, layer3_done


# ------------------- MAC loop --------------------
    addi    x24, x0, 0          # x24 = accumulator = 0

    add     x25, x0, x4         # x25 = a2 input pointer
    add     x26, x0, x22        # x26 = weight pointer

    addi    x27, x0, 64        # x27 = counter = input size

mac_l3:
    beq     x27, x0, mac_l3_done

    lb      x28, 0(x26)         # w = W3[n][i]
    lbu     x29, 0(x25)         # a2 = input[i]

    macb     x24, x28, x29       # acc += w3 * a2

    addi    x25, x25, 1         # next input
    addi    x26, x26, 1         # next weight
    addi    x27, x27, -1        # counter--

    jal     x0, mac_l3


mac_l3_done:
    srai    x24, x24, 7         # scale back


# ------------------- add bias --------------------
    add     x25, x0, x11        # x25 = b3 base
    add     x25, x25, x20       # x25 = &b3[n]

    lb      x26, 0(x25)         # x26 = bias
    add     x24, x24, x26       # acc += bias

# -------------------- store ----------------------
store_l3:
    sb      x24, 0(x23)         # out[n] = acc


# --------------- next neuron setup ---------------
    addi    x22, x22, 64       # next neuron weights
    addi    x23, x23, 1         # next output byte
    addi    x20, x20, 1         # neuron++

    jal     x0, neuron_loop_l3


# -------------------- done -----------------------
layer3_done:

# ---------------- ARGMAX (prediction) ---------------
	addi x17, x0, 0             # pred = 0
	lb   x18, 0(x5)             # best = out[0]
	
	addi x19, x0, 1             # n = 1
	add  x20, x0, x5            # x20 = pointer to out[]
	
	addi x21, x0, 10            # OUTPUT_SIZE = 10
	
argmax_loop:
    beq  x19, x21, argmax_done
	
	add  x22, x20, x19          # address = out + n
    lb   x23, 0(x22)            # x23 = out[n]
	
	bge  x18, x23, skip_update

    add  x18, x23, x0           # best = out[n]
    add  x17, x19, x0             # pred = n
	
skip_update:
    addi x19, x19, 1
    jal  x0, argmax_loop


argmax_done:
# ---------------- End of program ----------------
jal     x0, 0  		