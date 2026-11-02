; carry/borrow idiom probe: ADD+materialize, SUB borrow, flag preservation.
; Expected: A1 00000000 1 / A2 fffffff5 0 / S1 ffffffff 1 / S2 00000002 0
;           Q1 1 / Q3 1 / PASS
main:
MOVI r13,1
; --- A1: 0xFFFFFFFF + 1 -> lo 0, carry 1 (compare-after-add)
MOVI r2,65535
MOVHI r2,65535
MOVI r4,1
ADD r2,r2,r4
CMP r2,r4                 ; L = (sum < b) = carry
MOVI r5,0
ADDI[LT] r5,r5,1
MOVI r1,65
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,32
PUTC r1
CALL @ph
MOVI r1,32
PUTC r1
MOVI r1,48
ADD r1,r1,r5
PUTC r1
CALL @nl
; --- A2: 0xFFFFFFF0 + 5 -> lo FFFFFFF5, carry 0
MOVI r2,65520
MOVHI r2,65535
MOVI r4,5
ADD r2,r2,r4
CMP r2,r4
MOVI r5,0
ADDI[LT] r5,r5,1
MOVI r1,65
PUTC r1
MOVI r1,50
PUTC r1
MOVI r1,32
PUTC r1
CALL @ph
MOVI r1,32
PUTC r1
MOVI r1,48
ADD r1,r1,r5
PUTC r1
CALL @nl
; --- S1: 1 - 2 -> lo FFFFFFFF, borrow 1 (flags from SUB)
MOVI r2,1
MOVI r4,2
SUB r2,r2,r4
MOVI r5,0
ADDI[LT] r5,r5,1          ; L = borrow from SUB
MOVI r1,83
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,32
PUTC r1
CALL @ph
MOVI r1,32
PUTC r1
MOVI r1,48
ADD r1,r1,r5
PUTC r1
CALL @nl
; --- S2: 5 - 3 -> lo 2, borrow 0
MOVI r2,5
MOVI r4,3
SUB r2,r2,r4
MOVI r5,0
ADDI[LT] r5,r5,1
MOVI r1,83
PUTC r1
MOVI r1,50
PUTC r1
MOVI r1,32
PUTC r1
CALL @ph
MOVI r1,32
PUTC r1
MOVI r1,48
ADD r1,r1,r5
PUTC r1
CALL @nl
; --- Q1: does MOVI clobber the flags? CMP 1,2 then MOVI then materialize.
MOVI r2,1
MOVI r4,2
CMP r2,r4                 ; L = 1
MOVI r6,12345             ; if flags survive, the next line still takes
MOVI r5,0
ADDI[LT] r5,r5,1
MOVI r1,81
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,48
ADD r1,r1,r5
PUTC r1
CALL @nl
; --- Q3: branch fallback for the same condition.
MOVI r2,1
MOVI r4,2
CMP r2,r4
MOVI r5,0
JMP[GE] @q3d
MOVI r5,1
q3d:
MOVI r1,81
PUTC r1
MOVI r1,51
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,48
ADD r1,r1,r5
PUTC r1
CALL @nl
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
CALL @nl
HALT
; --- print r2 as 8 hex digits (clobbers r2,r4,r5,r6,r8)
ph:
ST r15,r0,@ph_ret
MOVI r8,8
phl:
SHR r7,r2,28
SHL r2,r2,4
MOVI r6,10
CMP r7,r6
MOVI r4,48
MOVI[GE] r4,87
ADD r4,r4,r7
PUTC r4
SUB r8,r8,r13
JMP[NE] @phl
LD r15,r0,@ph_ret
RET
nl:
ST r15,r0,@nl_ret
MOVI r1,10
PUTC r1
LD r15,r0,@nl_ret
RET
; return slots
ph_ret:
.word 0
nl_ret:
.word 0
