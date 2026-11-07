; MC0DB/BS0DB quota manager guest regression.
main:
; Reserve 10 pages from BS0DB.
MOVI r1,1
MOVI r2,10
CALL @mc_scratch_reserve
CMP r3,r0
JMP[NE] @fail
MOVI r7,1
CMP r1,r7
JMP[NE] @fail
; Reserve 20 pages from MC0DB.
MOVI r1,2
MOVI r2,20
CALL @mc_scratch_reserve
CMP r3,r0
JMP[NE] @fail
MOVI r7,2
CMP r1,r7
JMP[NE] @fail
; Verify counters.
CALL @mc_scratch_stats
MOVI r7,10
CMP r1,r7
JMP[NE] @fail
MOVI r7,20
CMP r2,r7
JMP[NE] @fail
MOVI r7,30
CMP r3,r7
JMP[NE] @fail
; Reject a reservation above the BS0DB quota.
MOVI r1,1
MOVI r2,262145
CALL @mc_scratch_reserve
MOVI r7,3
CMP r3,r7
JMP[NE] @fail
; Release BS0DB allocation and verify idempotence is rejected.
MOVI r1,1
CALL @mc_scratch_release
CMP r3,r0
JMP[NE] @fail
MOVI r1,1
CALL @mc_scratch_release
MOVI r7,5
CMP r3,r7
JMP[NE] @fail
CALL @mc_scratch_stats
CMP r1,r0
JMP[NE] @fail
MOVI r7,20
CMP r2,r7
JMP[NE] @fail
MOVI r7,20
CMP r3,r7
JMP[NE] @fail
; PASS
MOVI r1,77
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
fail:
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,10
PUTC r1
HALT
.include "mc0db_scratch.nas"
