; NaN16 corpus trainer v1.
; Input: N16TXT/1 LF header followed by newline-delimited UTF-8 records.
; Host boundary writes bytes at byte address 49152 and appends NUL.
; All parsing, bounds, record accounting, frequency updates and digest work run here.
; Output statistics: words 8448..8450 = content bytes, records, rolling digest.
main:
MOVI r13,1
MOVI r4,49152
; exact 9-byte header: N16TXT/1 + LF
LDB r1,r4,0
MOVI r2,78
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,1
MOVI r2,49
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,2
MOVI r2,54
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,3
MOVI r2,84
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,4
MOVI r2,88
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,5
MOVI r2,84
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,6
MOVI r2,47
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,7
MOVI r2,49
CMP r1,r2
JMP[NE] @reject
LDB r1,r4,8
MOVI r2,10
CMP r1,r2
JMP[NE] @reject
ADDI r4,r4,9
MOVI r5,0
MOVI r6,0
MOVI r7,0
MOVI r8,5381
MOVI r11,8192
scan:
LDB r9,r4,0
CMP r9,r0
JMP[EQ] @finish
MOVI r10,13
CMP r9,r10
JMP[EQ] @advance
MOVI r10,10
CMP r9,r10
JMP[EQ] @newline
MOVI r10,32
CMP r9,r10
JMP[LT] @control
JMP @accept
control:
MOVI r10,9
CMP r9,r10
JMP[EQ] @accept
JMP @reject
accept:
ADDI r7,r7,1
MOVI r10,4096
CMP r7,r10
JMP[GT] @reject
ADDI r5,r5,1
MOVI r10,0
MOVHI r10,16
CMP r5,r10
JMP[GT] @reject
; rolling digest h = h*33 + byte
MOVI r10,5
SHL r10,r8,5
ADD r8,r10,r8
ADD r8,r8,r9
; NaN16-owned byte-frequency table
ADD r12,r11,r9
LD r10,r12,0
ADDI r10,r10,1
ST r10,r12,0
advance:
ADDI r4,r4,1
JMP @scan
newline:
CMP r7,r0
JMP[EQ] @newline_advance
ADDI r6,r6,1
MOVI r7,0
newline_advance:
ADDI r4,r4,1
JMP @scan
finish:
CMP r7,r0
JMP[EQ] @finish_counted
ADDI r6,r6,1
finish_counted:
CMP r6,r0
JMP[EQ] @reject
MOVI r12,8448
ST r5,r12,0
ST r6,r12,1
ST r8,r12,2
; report success on COM1
MOVI r1,78
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,54
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,10
PUTC r1
HALT
reject:
MOVI r1,78
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,54
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,74
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,67
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,10
PUTC r1
HALT
.org 8192
freq:
.word 0
.org 8448
stats:
.word 0,0,0
.org 12288
corpus:
.str "N16TXT/1\nNaN16 owns the corpus codec.\nRunner and Android share one trainer.\nThe intake stages updates before merge.\n"
