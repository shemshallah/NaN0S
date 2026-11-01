; a64_test: portable NaN16 self-test for a new native core (x86 / A64 / RV64). Pure NaN16, guest word 0 = entry.
; Prints "NaN/0S core PASS" + CRLF and halts, or "FAIL nn" (nn = number of the first failing check).
MOVI r13,1
MOVI r10,10
; 1 MUL
MOVI r3,6
MOVI r4,7
MUL r5,r3,r4
MOVI r6,42
CMP r5,r6
MOVI r11,1
JMP[NE] @fail
; 2 BOOL xor
MOVI r3,0xF0F0
MOVI r4,0xFF00
BOOL.6 r5,r3,r4
MOVI r6,0x0FF0
CMP r5,r6
MOVI r11,2
JMP[NE] @fail
; 3,4 SUB borrow -> (Z=0,L=1): GE must NOT run, result all ones
MOVI r3,1
MOVI r4,2
SUB r5,r3,r4
MOVI r11,3
JMP[GE] @fail
MOVI r6,0xFFFF
MOVHI r6,0xFFFF
CMP r5,r6
MOVI r11,4
JMP[NE] @fail
; 5,6 DIVU MODU
MOVI r3,100
MOVI r4,7
DIVU r5,r3,r4
MODU r6,r3,r4
MOVI r7,14
CMP r5,r7
MOVI r11,5
JMP[NE] @fail
MOVI r7,2
CMP r6,r7
MOVI r11,6
JMP[NE] @fail
; 7,8 ST / LD / LDN (ST writes +q/+q = class 10)
MOVI r3,0x1234
MOVI r1,@scr
ST r3,r1,0
LD r5,r1,0
CMP r5,r3
MOVI r11,7
JMP[NE] @fail
LDN r5,r1,0
MOVI r7,10
CMP r5,r7
MOVI r11,8
JMP[NE] @fail
; 9,10 STW class 6, then BSWAPM -> class rot2(6)=9
MOVI r4,6
STW r3,r1,r4
LDN r5,r1,0
MOVI r7,6
CMP r5,r7
MOVI r11,9
JMP[NE] @fail
BSWAPM r1,0
LDN r5,r1,0
MOVI r7,9
CMP r5,r7
MOVI r11,10
JMP[NE] @fail
; 11,12 SHL SHR SAR
MOVI r3,1
SHL r5,r3,31
SHR r6,r5,31
CMP r6,r3
MOVI r11,11
JMP[NE] @fail
MOVI r7,0xFFFF
MOVHI r7,0xFFFF
SAR r6,r5,31
CMP r6,r7
MOVI r11,12
JMP[NE] @fail
; 13 CALL / RET
CALL @sub99
MOVI r7,99
CMP r8,r7
MOVI r11,13
JMP[NE] @fail
; 14 STB / LDB
MOVI r4,@scr
SHL r4,r4,2
MOVI r3,0x41
STB r3,r4,1
LDB r5,r4,1
CMP r5,r3
MOVI r11,14
JMP[NE] @fail
; 15 ADDI with negative immediate
MOVI r3,10
ADDI r5,r3,65531
MOVI r7,5
CMP r5,r7
MOVI r11,15
JMP[NE] @fail
; 16,17 BFILL / BCOPY
MOVI r1,@scr2
MOVI r2,0x55
MOVI r3,4
BFILL r1,r2,r3
LD r5,r1,3
CMP r5,r2
MOVI r11,16
JMP[NE] @fail
MOVI r4,@scr3
BCOPY r4,r1,r3
LD r5,r4,3
CMP r5,r2
MOVI r11,17
JMP[NE] @fail
; 18 CMPS signed (-1 < 1): LT must run
MOVI r3,0xFFFF
MOVHI r3,0xFFFF
MOVI r4,1
CMPS r3,r4
MOVI r11,18
JMP[GE] @fail
; all passed
MOVI r1,@okmsg
SHL r1,r1,2
CALL @prs
HALT
fail:
MOVI r1,@fmsg
SHL r1,r1,2
CALL @prs
DIVU r3,r11,r10
ADDI r3,r3,48
PUTC r3
MODU r4,r11,r10
ADDI r4,r4,48
PUTC r4
MOVI r3,13
PUTC r3
MOVI r3,10
PUTC r3
HALT
prs:
LDB r2,r1,0
CMP r2,r0
RET[EQ]
PUTC r2
ADDI r1,r1,1
JMP @prs
sub99:
MOVI r8,99
RET
okmsg:
.str "NaN/0S core PASS"
.word 13
.word 10
fmsg:
.str "FAIL "
scr:
.word 0
scr2:
.word 0,0,0,0
scr3:
.word 0,0,0,0
