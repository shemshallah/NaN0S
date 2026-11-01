; NaN/0S exhibit: Sierpinski lattice (v3 of the NaN Lattice page). Every cell is a real NaN word:
; class nibble n=6 (XOR) is its function, payload bit0 = state, bit1 = guard. Cell reads neighbours L,R, applies f_n(L,R).
; Adapts to the display: asks DISPQ for cols/rows, so 80x25, 40x25 etc all work. Row 0 = title, rows 1.. = spacetime.
main:
MOVI r13,1
MOVI r1,@mode_req
LD r2,r1,0
CMP r2,r0
DISPSET[NE] r2
DISPQ r8
MOVI r1,@s_title
CALL @puts
BOOL.12 r1,r8,r8
CALL @puthex
MOVI r2,13
PUTC r2
MOVI r2,10
PUTC r2
MOVI r1,255
BOOL.8 r9,r8,r1
SHR r2,r8,8
BOOL.8 r2,r2,r1
MOVI r3,12
ADD r15,r2,r3
SUB r3,r2,r13
MOVI r10,0
ml:
ADD r10,r10,r9
SUB r3,r3,r13
JMP[NE] @ml
SUB r12,r9,r13
MOVI r11,1024
MOVI r14,1152
BOOL.12 r8,r9,r9
MOVI r4,6
SHR r5,r9,1
BOOL.12 r1,r0,r0
il:
MOVI r3,2
CMP r1,r5
ADD[EQ] r3,r3,r13
ADD r2,r1,r11
STW r3,r2,r4
ADD r1,r1,r13
CMP r1,r9
JMP[LT] @il
gen:
BOOL.12 r1,r0,r0
xl:
SUB r2,r1,r13
CMP r1,r0
ADD[EQ] r2,r12,r0
ADD r2,r2,r11
LD r3,r2,0
BOOL.8 r3,r3,r13
ADD r2,r1,r13
CMP r2,r9
SUB[EQ] r2,r2,r2
ADD r2,r2,r11
LD r4,r2,0
BOOL.8 r4,r4,r13
ADD r2,r1,r11
LDN r5,r2,0
BOOL.12 r6,r5,r5
CMP r3,r0
SHR[NE] r6,r6,2
CMP r4,r0
SHR[NE] r6,r6,1
BOOL.8 r6,r6,r13
ADD r2,r1,r14
MOVI r7,2
BOOL.14 r7,r7,r6
STW r7,r2,r5
MOVI r2,7
BOOL.8 r2,r5,r2
MOVI r3,9
ADD r2,r2,r3
SHL r2,r2,8
MOVI r3,219
BOOL.14 r2,r2,r3
MOVI r7,0x08B0
CMP r6,r0
ADD[NE] r7,r2,r0
ADD r2,r8,r1
VPOKE r7,r2
ADD r1,r1,r13
CMP r1,r9
JMP[LT] @xl
BOOL.12 r2,r11,r11
BOOL.12 r11,r14,r14
BOOL.12 r14,r2,r2
CMP r8,r10
JMP[LT] @adv
BOOL.12 r1,r9,r9
sl:
ADD r2,r1,r9
VPEEK r3,r2
VPOKE r3,r1
ADD r1,r1,r13
CMP r1,r10
JMP[LT] @sl
JMP @nextgen
adv:
ADD r8,r8,r9
nextgen:
SUB r15,r15,r13
JMP[NE] @gen
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
mode_req:
.word 0
s_title:
.str "NaN/0S sierpinski disp="
