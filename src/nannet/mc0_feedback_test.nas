; MC0 candidate evidence and promotion regression.
main:
; Candidate 101: require two independent passing checks.
MOVI r1,101
MOVI r2,5001
MOVI r3,2
CALL @mc_candidate_begin
CMP r3,r0
JMP[NE] @fail
; Duplicate candidate IDs are immutable.
MOVI r1,101
MOVI r2,5001
MOVI r3,2
CALL @mc_candidate_begin
MOVI r7,5
CMP r3,r7
JMP[NE] @fail
; One passing evaluation is not enough.
MOVI r1,101
MOVI r2,1
MOVI r3,7001
CALL @mc_candidate_record
CMP r3,r0
JMP[NE] @fail
MOVI r1,101
CALL @mc_candidate_promote
MOVI r7,4
CMP r3,r7
JMP[NE] @fail
; Two passes promote.
MOVI r1,101
MOVI r2,1
MOVI r3,7002
CALL @mc_candidate_record
CMP r3,r0
JMP[NE] @fail
MOVI r1,101
CALL @mc_candidate_promote
CMP r3,r0
JMP[NE] @fail
; Promotion is one-way; a replay attempt is rejected.
MOVI r1,101
CALL @mc_candidate_promote
MOVI r7,7
CMP r3,r7
JMP[NE] @fail
; Verify promoted record.
MOVI r1,101
CALL @mc_candidate_get
MOVI r7,2
CMP r1,r7
JMP[NE] @fail
MOVI r7,2
CMP r2,r7
JMP[NE] @fail
CMP r3,r0
JMP[NE] @fail
MOVI r7,2
CMP r4,r7
JMP[NE] @fail
; Candidate 102: a failed evaluation rejects it permanently.
MOVI r1,102
MOVI r2,5001
MOVI r3,1
CALL @mc_candidate_begin
CMP r3,r0
JMP[NE] @fail
MOVI r1,102
MOVI r2,0
MOVI r3,7999
CALL @mc_candidate_record
CMP r3,r0
JMP[NE] @fail
MOVI r1,102
CALL @mc_candidate_promote
MOVI r7,7
CMP r3,r7
JMP[NE] @fail
MOVI r1,102
CALL @mc_candidate_get
MOVI r7,3
CMP r1,r7
JMP[NE] @fail
MOVI r7,1
CMP r3,r7
JMP[NE] @fail
; PASS
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
.include "mc0_feedback.nas"
