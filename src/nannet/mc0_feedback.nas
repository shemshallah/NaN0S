; MC0 candidate staging / evidence / promotion kernel — NaN16 guest.
; Candidate record: id,parent_checkpoint,required_passes,passed,failed,state,last_evidence.
; States: 0 free, 1 staged, 2 promoted, 3 rejected. Promotion is monotonic.
; ABI:
;   mc_candidate_begin r1=id,r2=parent_checkpoint,r3=required_passes -> r1=slot,r3=status
;   mc_candidate_record r1=id,r2=pass(0|1),r3=evidence_digest -> r3=status
;   mc_candidate_promote r1=id -> r3=status
;   mc_candidate_get r1=id -> r1=state,r2=passed,r3=failed,r4=required,r5=status
; Status: 0 success, 1 invalid, 3 table full, 4 insufficient evidence, 5 duplicate ID, 7 invalid state.
; In-memory candidate table only. Durable journal/checkpoint commit is a later storage ABI.
mc_candidate_begin:
ST r15,r0,@mc_cand_begin_ret
ST r1,r0,@mc_cand_tmp_id
ST r2,r0,@mc_cand_tmp_parent
ST r3,r0,@mc_cand_tmp_required
CMP r1,r0
JMP[EQ] @mc_cand_invalid
CMP r2,r0
JMP[EQ] @mc_cand_invalid
CMP r3,r0
JMP[EQ] @mc_cand_invalid
MOVI r4,@mc_candidate_table
MOVI r5,32
MOVI r6,0
mc_cand_begin_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @mc_cand_begin_slot
LD r8,r0,@mc_cand_tmp_id
CMP r7,r8
JMP[EQ] @mc_cand_duplicate
ADDI r4,r4,7
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @mc_cand_begin_scan
JMP @mc_cand_full
mc_cand_begin_slot:
LD r8,r0,@mc_cand_tmp_id
ST r8,r4,0
LD r8,r0,@mc_cand_tmp_parent
ST r8,r4,1
LD r8,r0,@mc_cand_tmp_required
ST r8,r4,2
ST r0,r4,3
ST r0,r4,4
MOVI r8,1
ST r8,r4,5
ST r0,r4,6
ADD r1,r6,r0
MOVI r3,0
LD r15,r0,@mc_cand_begin_ret
RET
mc_cand_duplicate:
MOVI r1,0
MOVI r3,5
LD r15,r0,@mc_cand_begin_ret
RET
mc_cand_full:
MOVI r1,0
MOVI r3,3
LD r15,r0,@mc_cand_begin_ret
RET
mc_cand_invalid:
MOVI r1,0
MOVI r3,1
LD r15,r0,@mc_cand_begin_ret
RET
mc_cand_begin_ret:
.word 0

mc_candidate_record:
ST r15,r0,@mc_cand_record_ret
ST r1,r0,@mc_cand_tmp_id
ST r2,r0,@mc_cand_tmp_pass
ST r3,r0,@mc_cand_tmp_evidence
CMP r1,r0
JMP[EQ] @mc_cand_record_invalid
MOVI r4,@mc_candidate_table
MOVI r5,32
MOVI r6,0
mc_cand_record_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @mc_cand_record_next
LD r8,r0,@mc_cand_tmp_id
CMP r7,r8
JMP[EQ] @mc_cand_record_found
mc_cand_record_next:
ADDI r4,r4,7
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @mc_cand_record_scan
JMP @mc_cand_record_missing
mc_cand_record_found:
LD r8,r4,5
MOVI r9,1
CMP r8,r9
JMP[NE] @mc_cand_record_state
LD r8,r0,@mc_cand_tmp_pass
CMP r8,r0
JMP[EQ] @mc_cand_record_fail
MOVI r9,1
CMP r8,r9
JMP[NE] @mc_cand_record_invalid
LD r8,r4,3
ADDI r8,r8,1
ST r8,r4,3
JMP @mc_cand_record_evidence
mc_cand_record_fail:
LD r8,r4,4
ADDI r8,r8,1
ST r8,r4,4
MOVI r8,3
ST r8,r4,5
mc_cand_record_evidence:
LD r8,r0,@mc_cand_tmp_evidence
ST r8,r4,6
MOVI r3,0
LD r15,r0,@mc_cand_record_ret
RET
mc_cand_record_state:
MOVI r3,7
LD r15,r0,@mc_cand_record_ret
RET
mc_cand_record_invalid:
MOVI r3,1
LD r15,r0,@mc_cand_record_ret
RET
mc_cand_record_missing:
MOVI r3,1
LD r15,r0,@mc_cand_record_ret
RET
mc_cand_record_ret:
.word 0

mc_candidate_promote:
ST r15,r0,@mc_cand_promote_ret
ST r1,r0,@mc_cand_tmp_id
CMP r1,r0
JMP[EQ] @mc_cand_promote_invalid
MOVI r4,@mc_candidate_table
MOVI r5,32
MOVI r6,0
mc_cand_promote_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @mc_cand_promote_next
LD r8,r0,@mc_cand_tmp_id
CMP r7,r8
JMP[EQ] @mc_cand_promote_found
mc_cand_promote_next:
ADDI r4,r4,7
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @mc_cand_promote_scan
JMP @mc_cand_promote_missing
mc_cand_promote_found:
LD r8,r4,5
MOVI r9,1
CMP r8,r9
JMP[NE] @mc_cand_promote_state
LD r8,r4,4
CMP r8,r0
JMP[NE] @mc_cand_promote_state
LD r8,r4,3
LD r9,r4,2
CMP r8,r9
JMP[LT] @mc_cand_promote_incomplete
MOVI r8,2
ST r8,r4,5
MOVI r3,0
LD r15,r0,@mc_cand_promote_ret
RET
mc_cand_promote_incomplete:
MOVI r3,4
LD r15,r0,@mc_cand_promote_ret
RET
mc_cand_promote_state:
MOVI r3,7
LD r15,r0,@mc_cand_promote_ret
RET
mc_cand_promote_invalid:
MOVI r3,1
LD r15,r0,@mc_cand_promote_ret
RET
mc_cand_promote_missing:
MOVI r3,1
LD r15,r0,@mc_cand_promote_ret
RET
mc_cand_promote_ret:
.word 0

mc_candidate_get:
ST r15,r0,@mc_cand_get_ret
ST r1,r0,@mc_cand_tmp_id
MOVI r4,@mc_candidate_table
MOVI r5,32
MOVI r6,0
mc_cand_get_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @mc_cand_get_next
LD r8,r0,@mc_cand_tmp_id
CMP r7,r8
JMP[EQ] @mc_cand_get_found
mc_cand_get_next:
ADDI r4,r4,7
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @mc_cand_get_scan
MOVI r1,0
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,1
LD r15,r0,@mc_cand_get_ret
RET
mc_cand_get_found:
LD r1,r4,5
LD r2,r4,3
LD r3,r4,4
LD r4,r4,2
MOVI r5,0
LD r15,r0,@mc_cand_get_ret
RET
mc_cand_get_ret:
.word 0

mc_cand_tmp_id:
.word 0
mc_cand_tmp_parent:
.word 0
mc_cand_tmp_required:
.word 0
mc_cand_tmp_pass:
.word 0
mc_cand_tmp_evidence:
.word 0
.org 26000
mc_candidate_table:
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0
