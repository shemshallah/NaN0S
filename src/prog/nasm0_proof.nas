; nasm0 PROOF HARNESS (round 08). Image = this + nasm0.nas at word 0; tools/mkproof.py places the minified source at #SRC,
; the scaffold's expected words at #EXP/#EXPC, and the expected word count at #V_EXPN. Output: PASS or the first mismatch index.
main:
MOVI r13,1
MOVI r14,#STACK
MOVI r1,@s_banner
CALL @puts
ST r0,r0,#V_ERR
ST r0,r0,#V_MIRR
ST r0,r0,#V_NLAB
LD r2,r0,#V_LABB
ST r0,r2,0
MOVI r2,1
ST r2,r0,#V_PASS
CALL @run
MOVI r2,2
ST r2,r0,#V_PASS
CALL @run
MOVI r1,@s_w
CALL @puts
LD r1,r0,#V_IDX
CALL @puthex
MOVI r1,@s_l
CALL @puts
LD r1,r0,#V_NLAB
CALL @puthex
MOVI r1,@s_e
CALL @puts
LD r1,r0,#V_ERR
CALL @puthex
MOVI r1,@s_m
CALL @puts
LD r1,r0,#V_MIRR
CALL @puthex
CALL @compare
ST r6,r0,#V_DIFF
MOVI r1,@s_d
CALL @puts
LD r1,r0,#V_DIFF
CALL @puthex
LD r6,r0,#V_DIFF
CMP r6,r0
JMP[NE] @mfail
MOVI r1,@s_pass
CALL @puts
HALT
mfail:
MOVI r1,@s_fail
CALL @puts
LD r1,r0,#V_FIRST
CALL @puthex
HALT
; compare: OUT vs EXP/EXPC for V_EXPN words. returns r6 = mismatches (word count mismatch counts as 1), V_FIRST = first bad index
compare:
ST r15,r14,0
ADD r14,r14,r13
MOVI r5,0
MOVI r6,0
LD r7,r0,#V_EXPN
LD r2,r0,#V_IDX
CMP r2,r7
ADD[NE] r6,r6,r13
cmp1:
CMP r5,r7
JMP[GE] @cmpx
LD r2,r0,#V_EXPB
ADD r2,r2,r5
LD r3,r2,0
LD r2,r0,#V_OUTB
ADD r2,r2,r5
LD r4,r2,0
LDN r8,r2,0
SHR r9,r5,3
LD r2,r0,#V_EXPCB
ADD r2,r2,r9
LD r9,r2,0
MOVI r2,7
BOOL.8 r2,r5,r2
cmps:
CMP r2,r0
JMP[EQ] @cmpe
SHR r9,r9,4
SUB r2,r2,r13
JMP @cmps
cmpe:
MOVI r2,15
BOOL.8 r9,r9,r2
CMP r3,r4
JMP[NE] @cbad
CMP r9,r8
JMP[EQ] @cok
cbad:
ADD r6,r6,r13
CMP r6,r13
ST[EQ] r5,r0,#V_FIRST
cok:
ADD r5,r5,r13
JMP @cmp1
cmpx:
SUB r14,r14,r13
LD r15,r14,0
RET
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
s_banner:
.str "nasm0 proof\r\n"
s_w:
.str "words="
s_l:
.str " labels="
s_e:
.str " err="
s_m:
.str " mirror="
s_d:
.str " diff="
s_pass:
.str " PASS\r\n"
s_fail:
.str " FAIL first="
.include "nasm0.nas"
