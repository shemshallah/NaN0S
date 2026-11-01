.org 0
JMP @main
.include "../lib/ata.nas"
main:
MOVI r13,1
MOVI r1,0
MOVI r2,4096
CALL @ata_read28
MOVI r1,@s0
CALL @puts
LD r1,r0,4096
CALL @puthex
MOVI r1,@s1
CALL @puts
LD r1,r0,4097
CALL @puthex
MOVI r1,@s2
CALL @puts
MOVI r1,4351
LD r1,r1,0
CALL @puthex
MOVI r1,@s_nl
CALL @puts
HALT
puts:
MOVI r4,255
p1:
LD r2,r1,0
MOVI r3,4
p2:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @p2
ADD r1,r1,r13
JMP @p1
puthex:
MOVI r7,7
MOVI r2,8
ph1:
SHR r3,r1,28
SHL r1,r1,4
MOVI r4,48
ADD r4,r4,r3
MOVI r5,10
CMP r3,r5
ADD[GE] r4,r4,r7
PUTC r4
SUB r2,r2,r13
JMP[NE] @ph1
RET
s0:
.str "W0="
s1:
.str " W1="
s2:
.str " W255="
s_nl:
.str "\n"
