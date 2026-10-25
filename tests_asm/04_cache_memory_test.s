   0  addi x10, x0, 0x40             # Base address = 0x40

   4  addi x1, x0, 0x7F          # 127   -> positive byte
   8  addi x2, x0, -2            # -2    -> negative halfword
   12 addi x3, x0, 0x7AA         # 1962  -> fits in 12-bit
   16 addi x4, x0, 0x55          # 85    -> for SD

   20 sb  x1, 0(x10)            # MEM[0x40]   = 0x7F
   24  sh  x2, 8(x10)            # MEM[0x48]   = 0xFFFE
   28  sw  x3, 16(x10)           # MEM[0x50]   = 0x000007AA
   32 sd  x4, 24(x10)           # MEM[0x58]   = 0x0000000000000055

   36  lb   x5, 0(x10)           # signed byte   (0x7F)                  
   40  lbu  x6, 0(x10)           # unsigned byte (0x7F)                 
   44  lh   x7, 8(x10)           # signed half   (0xFFFE = -2)           

   48  lhu  x8, 8(x10)           # unsigned half (0xFFFE = 65534)        
   52  lw   x9, 16(x10)          # signed word   (0x7AA)   
   56  lhu  x9, 8(x10)           # unsigned half (0xFFFE = 65534)              
   60  lwu  x11, 16(x10)         # unsigned word (0x7AA)                  
   64  add x14,x1,x1             x14 = 0xFE
   68  ld   x12, 24(x10)         # doubleword    (0x55)
   72  addi  x12, x12,1          x12 = 0x56     
                       
   76  add x13,x1,x1             x13 = 0XFE
   80 add x14,x1,x1             x14 = 0xFE

   84  jal x0, 0                 # NOP 
