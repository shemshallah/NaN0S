; NaN/0S museum library (NaN16 mnemonics). Conventions: r0=0 r13=1 r15=link. Lib routines clobber r3..r9 and r15 only.
; Text cells are VGA words: attr<<8 | char. COLS is fixed at 80 (museum forces mode 3).
; vputs: r1=string addr, r2=cell, r3=attr<<8, r5=current col, r6=left margin. Strings: 4 chars/word, 0-terminated, \n = next line at margin.
vputs:
vw:
LD r4,r1,0
MOVI r9,4
vc:
MOVI r8,255
BOOL.8 r7,r4,r8
CMP r7,r0
RET[EQ]
MOVI r8,10
CMP r7,r8
JMP[EQ] @vnl
BOOL.14 r8,r7,r3
VPOKE r8,r2
ADD r2,r2,r13
ADD r5,r5,r13
JMP @vnx
vnl:
SUB r2,r2,r5
ADD r2,r2,r6
MOVI r8,80
ADD r2,r2,r8
BOOL.12 r5,r6,r6
vnx:
SHR r4,r4,8
SUB r9,r9,r13
JMP[NE] @vc
ADD r1,r1,r13
JMP @vw
; vhex: r1=value, r2=cell, r3=attr<<8 -> 8 hex digits
vhex:
MOVI r9,8
MOVI r4,10
MOVI r7,7
vh1:
SHR r5,r1,28
SHL r1,r1,4
MOVI r6,48
ADD r6,r6,r5
CMP r5,r4
ADD[GE] r6,r6,r7
BOOL.14 r6,r6,r3
VPOKE r6,r2
ADD r2,r2,r13
SUB r9,r9,r13
JMP[NE] @vh1
RET
; vdec: r1=value, r2=cell, r3=attr<<8 -> decimal, no leading zeros, space-padded to 10 wide on the right
vdec:
MOVI r8,0
MOVI r9,0
vd1:
LD r5,r8,@pw10
MOVI r6,0
vd2:
CMP r1,r5
JMP[LT] @vd3
SUB r1,r1,r5
ADD r6,r6,r13
JMP @vd2
vd3:
BOOL.14 r9,r9,r6
MOVI r7,9
CMP r8,r7
ADD[EQ] r9,r9,r13
CMP r9,r0
JMP[EQ] @vd4
MOVI r7,48
ADD r6,r6,r7
BOOL.14 r6,r6,r3
VPOKE r6,r2
ADD r2,r2,r13
vd4:
ADD r8,r8,r13
MOVI r7,10
CMP r8,r7
JMP[LT] @vd1
RET
pw10:
.word 1000000000
.word 100000000
.word 10000000
.word 1000000
.word 100000
.word 10000
.word 1000
.word 100
.word 10
.word 1
; vcls: clear screen to attr 0x07 blank (r3 clobbered)
vcls:
MOVI r3,3
DISPSET r3
RET
