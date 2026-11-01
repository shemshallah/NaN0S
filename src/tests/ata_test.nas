; ata_test.nas - read sector 0 of the ATA primary master and check 'NAN0'.
.org 0
JMP @main
.include "../lib/ata.nas"
main:
MOVI r13,1
MOVI r1,0
MOVI r2,4096
CALL @ata_read28
LD r1,r0,4096
ST r1,r0,@w0
MOVI r1,@s_w
CALL @puts
LD r1,r0,@w0
CALL @puthex
MOVI r1,#ATA_STATUS
INB r1,r1
MOVI r2,@s_st
CALL @puts
CALL @puthex
MOVI r1,#ATA_STATUS
INW r1,r1
MOVI r2,@s_stw
CALL @puts
CALL @puthex
MOVI r1,#ATA_STATUS
MOVI r1,0x1F1
INB r1,r1
MOVI r2,@s_er
CALL @puts
CALL @puthex
LD r1,r0,@w0
MOVI r2,0x414E
CMP r1,r2
JMP[NE] @bad
MOVI r1,@s_pass
CALL @puts
HALT
bad:
MOVI r1,@s_fail
CALL @puts
LD r1,r0,4096
CALL @puthex
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
s_pass:
.str "ATA PASS\n"
s_fail:
.str "ATA FAIL "
s_w:
.str "W0="
s_st:
.str " ST="
s_er:
.str " ER="
s_stw:
.str " STW="
w0:
.word 0
