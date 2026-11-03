; NSPV1 header probe: read ATA primary-master sector 0 and check the magic.
.org 0
JMP @main
.include "../../src/lib/ata.nas"
main:
MOVI r13,1
MOVI r1,0
MOVI r2,4096
CALL @ata_read28
LD r1,r0,4096
MOVI r2,0x5631
CMP r1,r2
JMP[NE] @bad
LD r1,r0,4097
MOVI r2,0x5350
CMP r1,r2
JMP[NE] @bad
MOVI r1,@s_ok
CALL @puts
HALT
bad:
MOVI r1,@s_no
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
s_ok:
.str "NSPV OK\n"
s_no:
.str "NSPV NO\n"
