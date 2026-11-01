; ata_rw_test.nas - read sector 0 signature, write pattern to sector 1,
; read it back, verify. NaN16 + ATA PIO only.
.org 0
JMP @main
.include "../lib/ata.nas"
main:
MOVI r13,1
; fill 256 words at 4096 with A5A5+i
MOVI r1,0
MOVI r3,4096
MOVI r4,0xA5A5
fill:
ADD r5,r4,r1
ST r5,r3,0
ADD r3,r3,r13
ADD r1,r1,r13
MOVI r5,256
CMP r1,r5
JMP[LT] @fill
; write sector 1
MOVI r1,1
MOVI r2,4096
CALL @ata_write28
; clear buffer
MOVI r1,0
MOVI r3,4096
MOVI r5,0
clear:
ST r5,r3,0
ADD r3,r3,r13
ADD r1,r1,r13
MOVI r5,256
CMP r1,r5
JMP[LT] @clear
; read sector 1
MOVI r1,1
MOVI r2,4096
CALL @ata_read28
; verify word 0 and word 255
LD r1,r0,4096
MOVI r2,0xA5A5
CMP r1,r2
JMP[NE] @fail0
MOVI r1,255
MOVI r2,4096
ADD r1,r1,r2
ST r1,r0,@tmp
LD r1,r1,0
MOVI r2,0xA6A4
CMP r1,r2
JMP[NE] @fail1
MOVI r1,@s_pass
CALL @puts
HALT
fail0:
MOVI r1,@s_f0
CALL @puts
JMP @fail
fail1:
MOVI r1,@s_f1
CALL @puts
fail:
MOVI r1,@s_fail
CALL @puts
LD r1,r0,4096
CALL @puthex
MOVI r1,@s_w255
CALL @puts
MOVI r1,4351
LD r1,r1,0
CALL @puthex
HALT
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
tmp:
.word 0
s_pass:
.str "ATA RW PASS\n"
s_f0:
.str "F0 "
s_f1:
.str "F1 "
s_fail:
.str "ATA RW FAIL W0="
s_w255:
.str " W255="
