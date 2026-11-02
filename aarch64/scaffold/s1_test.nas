; S1 differential test: only ops the AArch64 S1 layer-1 implements.
; Expected serial: Y4O\n  (computed 'Y' via SUB+CMP+EQ, '4' via MOVI/MOVHI,
; 'O' via CALL/RET; a JMP skips a decoy 'X'; the print before HALT is '\n').
main:
MOVI r13,1
MOVI r1,5
MOVI r2,3
SUB r3,r1,r2
MOVI r4,2
CMP r3,r4
MOVI r5,89
MOVI r6,78
PUTC[EQ] r5
PUTC[NE] r6
MOVI r1,4660
MOVHI r1,22136
PUTC r1
CALL @sub
JMP @skip
MOVI r1,88
PUTC r1
skip:
MOVI r1,10
PUTC r1
HALT
sub:
MOVI r1,79
PUTC r1
RET
