0x00000000:    _start:
0x00000000:    auipc x1, 0  
0x00000004:    addi  x1, x1, 0x40   done   # mtvec addr  (0x40 - 0x00) = 0x40
0x00000008:    csrrw x0, mtvec, x1 done

0x0000000C:    addi x2,x0,5  x2=5
0x00000010:    addi x3,x0,1  x3=1
0x00000014:    bne  x2,x3,8  taken
0x00000018     addi x4,x2,2  x4=5+2=7 not taken
0x0000001c:    ecall         should trap
0x00000020: after_ecall:
0x00000020:    addi  x4, x2, 4    x4=5+4=9

0x00000024:    addi x0 , 0   

0x00000028:    addi x0 , 0 
0x0000002C:    addi x0 , 0 
0x00000030:    addi x0 , 0 
0x00000034:    addi x0 , 0 
0x00000038:    addi x0 , 0 
 
0x0000003C:    jal   x0, 0   infinite loop 

# =========================================================
# Trap Handler
# =========================================================
0x00000040: trap_handler:
0x00000040:    csrrs x10, mcause, x0 done
0x00000044:    csrrs x11, mepc, x0 done 
0x00000048:    csrrs x12, mtval, x0  done

0x0000004C:    addi x13, x0, 11        done              # ecall cause
0x00000050:    beq  x10, x13, 0x68   done

0x00000054:    addi x13, x0, 4                       # misaligned load
0x00000058:    beq  x10, x13, 0x74

0x0000005C:    addi x13, x0, 2                       # illegal instruction
0x00000060:    beq  x10, x13, 0x80

0x00000064:    j 0x8c 

0x00000068: handle_ecall:
0x00000068:    addi x11, x11, 4
0x0000006C:    csrrw x0, mepc, 0x11
0x00000070:    j 0x8c

0x00000074: handle_misaligned:
0x00000074:    addi x11, x11, 4
0x00000078:    csrrw x0, mepc, 0x11
0x0000007C:    j x8c

0x00000080: handle_illegal:
0x00000080:    addi x11, x11, 4
0x00000084:    csrrw x0, mepc, 0x11
0x00000088:    j 0x8c

0x0000008C: trap_exit:
0x0000008C:    mret
0x00000090: data_section:
0x00000090:    .word 0xAABBCCDD