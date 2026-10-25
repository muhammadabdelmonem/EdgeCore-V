_start:
auipc x1, 0  
addi  x1, x1, 0x40      # mtvec addr  (0x40 - 0x00) = 0x40
csrrw x0, mtvec, x1 

addi  x2, x0, 10 
addi  x3, x0, 20
add   x4, x2, x3

ecall                                  # should trap
after_ecall:
addi  x5, x0, 1  

auipc x6, 0  
addi  x6, x6, 0x90  
lw    x7, 0(x6)                         # misaligned load

after_misaligned:
addi  x5, x0, 2 

# illegal instruction
addi x0,x0,0
after_illegal:
addi  x5, x0, 3  

end_loop:
jal   x0, 0                # infinite loop x3c

# =========================================================
# Trap Handler
# =========================================================
trap_handler:
csrrs x10, mcause, x0 
csrrs x11, mepc, x0  
csrrs x12, mtval, x0  

addi x13, x0, 11                      # ecall cause
beq  x10, x13, 0x18   

addi x13, x0, 4                       # misaligned load
beq  x10, x13, 0x1C   

addi x13, x0, 2                       # illegal instruction
beq  x10, x13, 0x20   

jal x0, 0x28   

handle_ecall:
addi x11, x11, 4   
csrrw x0, mepc, x11  
jal x0, 0x1C  

handle_misaligned:
addi x11, x11, 4   
csrrw x0, mepc, x11  
jal x0, 0x10   

handle_illegal:
addi x11, x11, 4   
csrrw x0, mepc, x11  
jal x0, 0x04  

trap_exit:
mret






```
0x00000000:    _start:
0x00000000:    auipc x1, 0  done
0x00000004:    addi  x1, x1, 0x40   done   # mtvec addr  (0x40 - 0x00) = 0x40
0x00000008:    csrrw x0, mtvec, x1 done

0x0000000C:    addi  x2, x0, 10 done
0x00000010:    addi  x3, x0, 20
0x00000014:    add   x4, x2, x3

0x00000018:    ecall                       done           # should trap
0x0000001C: after_ecall:
0x0000001C:    addi  x5, x0, 1  done

0x00000020:    auipc x6, 0 done 
0x00000024:    addi  x6, x6, 0x90  done
0x00000028:    addi  x6, x6, 1      done                  # misalign intentionally
0x0000002C:    lw    x7, 0(x6)      done                   # misaligned load

0x00000030: after_misaligned:
0x00000030:    addi  x5, x0, 2 done

0x00000034:    .word 0xffffffff     done                   # illegal instruction
0x00000038: after_illegal:
0x00000038:    addi  x5, x0, 3 done 

0x0000003C: end_loop:
0x0000003C:    jal   x0, 0x0   done             # infinite loop x3c

# =========================================================
# Trap Handler
# =========================================================
0x00000040: trap_handler:
0x00000040:    csrrs x10, mcause, x0 done
0x00000044:    csrrs x11, mepc, x0 done 
0x00000048:    csrrs x12, mtval, x0  done

0x0000004C:    addi x13, x0, 11        done              # ecall cause
0x00000050:    beq  x10, x13, 0x18   done

0x00000054:    addi x13, x0, 4     done                  # misaligned load
0x00000058:    beq  x10, x13, 0x1C  done 

0x0000005C:    addi x13, x0, 2      done                 # illegal instruction
0x00000060:    beq  x10, x13, 0x20   done

0x00000064:    jal x0, 0x28   done

0x00000068: handle_ecall:
0x00000068:    addi x11, x11, 4  done 
0x0000006C:    csrrw x0, mepc, x11  done
0x00000070:    jal x0, 0x1C done 

0x00000074: handle_misaligned:
0x00000074:    addi x11, x11, 4  done 
0x00000078:    csrrw x0, mepc, x11 done 
0x0000007C:    jal x0, 0x10  done 

0x00000080: handle_illegal:
0x00000080:    addi x11, x11, 4  done 
0x00000084:    csrrw x0, mepc, x11 done 
0x00000088:    jal x0, 0x04 done 

0x0000008C: trap_exit:
0x0000008C:    mret
```