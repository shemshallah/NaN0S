; NaN16 selftest: lane truth-table check, bswap orbit check, rule 90, rule 30. (mnemonic source; hex in selftest.nan)
main:
MOVI r13,1
MOVI r11,16
MOVI r12,0
MOVI r1,@s_banner
CALL @puts
MOVI r1,@s_t1
CALL @puts
MOVI r1,0xCCCC
MOVHI r1,0xCCCC
MOVI r2,0xAAAA
MOVHI r2,0xAAAA
MOVI r3,0
MOVI r6,@slot
MOVI r7,2
MOVHI r7,0x0051
tl:
STW r7,r6,r3
slot:
BOOL.0 r5,r1,r2
SHL r9,r3,4
BOOL.14 r8,r3,r9
SHL r9,r8,8
BOOL.14 r8,r8,r9
SHL r9,r8,16
BOOL.14 r8,r8,r9
CMP r5,r8
MOVI r9,46
MOVI r10,88
PUTC[EQ] r9
PUTC[NE] r10
ADD[NE] r12,r12,r13
ADD r3,r3,r13
CMP r3,r11
JMP[LT] @tl
MOVI r1,@s_t2
CALL @puts
MOVI r3,0
MOVI r4,0
MOVI r6,@tmp
MOVI r7,0
MOVI r10,3
tb:
STW r7,r6,r3
BSWAPM r6,0
LDN r5,r6,0
CMP r5,r3
ADD[EQ] r4,r4,r13
BOOL.8 r9,r3,r10
SHL r9,r9,2
SHR r2,r3,2
BOOL.14 r8,r9,r2
CMP r5,r8
MOVI r9,46
MOVI r2,88
PUTC[EQ] r9
PUTC[NE] r2
ADD[NE] r12,r12,r13
ADD r3,r3,r13
CMP r3,r11
JMP[LT] @tb
MOVI r2,4
CMP r4,r2
MOVI r9,46
MOVI r10,88
PUTC[EQ] r9
PUTC[NE] r10
ADD[NE] r12,r12,r13
MOVI r1,@s_r90
CALL @puts
MOVI r8,0
MOVHI r8,1
MOVI r9,6
g90:
BOOL.12 r1,r8,r8
CALL @prow
SHR r2,r8,1
SHL r4,r8,31
BOOL.14 r2,r2,r4
SHL r3,r8,1
SHR r4,r8,31
BOOL.14 r3,r3,r4
BOOL.6 r8,r2,r3
SUB r9,r9,r13
JMP[NE] @g90
MOVI r1,@s_r30
CALL @puts
MOVI r8,0
MOVHI r8,1
MOVI r9,6
g30:
BOOL.12 r1,r8,r8
CALL @prow
SHR r2,r8,1
SHL r4,r8,31
BOOL.14 r2,r2,r4
SHL r3,r8,1
SHR r4,r8,31
BOOL.14 r3,r3,r4
BOOL.14 r3,r8,r3
BOOL.6 r8,r2,r3
SUB r9,r9,r13
JMP[NE] @g30
MOVI r1,@s_t3
CALL @puts
MOVI r9,46
MOVI r10,88
MOVI r1,0x1234
MOVHI r1,0xBEEF
MOVI r6,@scratch
ST r1,r6,0
LD r2,r6,0
CMP r1,r2
PUTC[EQ] r9
PUTC[NE] r10
ADD[NE] r12,r12,r13
MOVI r6,@jt
JMPR r6
PUTC r10
ADD r12,r12,r13
jt:
PUTC r9
MOVI r1,0x0F41
MOVI r3,1999
VPOKE r1,r3
VPEEK r2,r3
CMP r1,r2
PUTC[EQ] r9
PUTC[NE] r10
ADD[NE] r12,r12,r13
TICK r1
TICK r2
CMP r2,r1
PUTC[GE] r9
PUTC[LT] r10
ADD[LT] r12,r12,r13
MOVI r1,5
MOVI r2,3
CMP r1,r2
PUTC[GT] r9
PUTC[LE] r10
ADD[LE] r12,r12,r13
MOVI r1,3
MOVI r2,5
CMP r1,r2
PUTC[LE] r9
PUTC[GT] r10
ADD[GT] r12,r12,r13
CMP r2,r2
PUTC[LE] r9
PUTC[GT] r10
ADD[GT] r12,r12,r13
PUTC[ALWAYS] r9
PUTC[NEVER] r10
ADD[NEVER] r12,r12,r13
MOVI r1,@s_col
CALL @puts
MOVI r1,27
MOVI r4,0
cl:
CMP r1,r13
JMP[EQ] @cdone
BOOL.8 r2,r1,r13
CMP r2,r0
JMP[EQ] @ceven
ADD r2,r1,r1
ADD r1,r2,r1
ADD r1,r1,r13
JMP @cnext
ceven:
SHR r1,r1,1
cnext:
ADD r4,r4,r13
JMP @cl
cdone:
BOOL.12 r8,r4,r4
BOOL.12 r1,r4,r4
CALL @puthex
MOVI r2,111
CMP r8,r2
PUTC[EQ] r9
PUTC[NE] r10
ADD[NE] r12,r12,r13
MOVI r1,@s_end
CALL @puts
BOOL.12 r1,r12,r12
CALL @puthex
HALT
puts:
MOVI r4,255
pw:
LD r2,r1,0
MOVI r3,4
pt1:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @pt1
ADD r1,r1,r13
JMP @pw
puthex:
MOVI r3,8
MOVI r4,10
MOVI r7,7
ph1:
SHR r2,r1,28
SHL r1,r1,4
MOVI r6,48
ADD r6,r6,r2
CMP r2,r4
ADD[GE] r6,r6,r7
PUTC r6
SUB r3,r3,r13
JMP[NE] @ph1
RET
prow:
MOVI r3,32
MOVI r6,35
MOVI r7,46
pr1:
SHR r2,r1,31
SHL r1,r1,1
CMP r2,r0
PUTC[EQ] r7
PUTC[NE] r6
SUB r3,r3,r13
JMP[NE] @pr1
MOVI r2,13
PUTC r2
MOVI r2,10
PUTC r2
RET
tmp:
.word 0
scratch:
.word 0
s_banner:
.str "NaN/0S v0.0.2 NaN16 selftest\r\n"
s_t1:
.str "lanes  "
s_t2:
.str "\r\nbswap  "
s_r90:
.str "\r\nrule 90\r\n"
s_r30:
.str "rule 30\r\n"
s_end:
.str "fails="
s_t3:
.str "\r\nops    "
s_col:
.str "\r\ncollatz27 steps="
