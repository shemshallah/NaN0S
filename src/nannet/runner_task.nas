; NaNLMROUTER bounded task ledger prototype.
; Task record (15 words): id, epoch, checkpoint, runner, logical_point,
; operation, input_digest, scratch_words, step_budget, time_budget,
; expiry_epoch, state, output_digest, trace_digest, claim_epoch.
; States: 0 empty, 1 queued, 2 claimed, 3 completed.
; ABI:
; nmr_task_submit r1..r11 = fields 0..10; returns r1=slot,r3=status.
; nmr_task_claim  r1=task_id,r2=runner_id,r3=epoch; returns r3=status.
; nmr_task_finish r1=task_id,r2=runner_id,r3=epoch,r4=output_digest,r5=trace_digest.
; Status: 0 success, 1 invalid/not found, 3 full, 5 duplicate id, 6 runner/epoch mismatch, 7 invalid state/replay, 8 expired.
nmr_task_submit:
ST r15,r0,@nmr_task_submit_ret
ST r1,r0,@nmr_task_tmp_id
ST r2,r0,@nmr_task_tmp_epoch
ST r3,r0,@nmr_task_tmp_checkpoint
ST r4,r0,@nmr_task_tmp_runner
ST r5,r0,@nmr_task_tmp_point
ST r6,r0,@nmr_task_tmp_op
ST r7,r0,@nmr_task_tmp_input
ST r8,r0,@nmr_task_tmp_scratch
ST r9,r0,@nmr_task_tmp_steps
ST r10,r0,@nmr_task_tmp_time
ST r11,r0,@nmr_task_tmp_expiry
; Reject missing identity/budget fields and reserved/out-of-range point.
CMP r1,r0
JMP[EQ] @nmr_task_invalid
CMP r2,r0
JMP[EQ] @nmr_task_invalid
CMP r4,r0
JMP[EQ] @nmr_task_invalid
CMP r5,r0
JMP[EQ] @nmr_task_invalid
CMP r6,r0
JMP[EQ] @nmr_task_invalid
CMP r8,r0
JMP[EQ] @nmr_task_invalid
CMP r9,r0
JMP[EQ] @nmr_task_invalid
CMP r10,r0
JMP[EQ] @nmr_task_invalid
CMP r11,r0
JMP[EQ] @nmr_task_invalid
MOVI r12,255
CMP r5,r12
JMP[GT] @nmr_task_invalid
LD r8,r0,@nmr_task_tmp_epoch
LD r9,r0,@nmr_task_tmp_expiry
CMP r8,r9
JMP[GE] @nmr_task_invalid
MOVI r4,@nmr_task_table
MOVI r5,16
MOVI r6,0
nmr_task_submit_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_task_submit_empty
LD r8,r0,@nmr_task_tmp_id
CMP r7,r8
JMP[EQ] @nmr_task_duplicate
ADDI r4,r4,15
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_task_submit_scan
MOVI r1,0
MOVI r3,3
LD r15,r0,@nmr_task_submit_ret
RET
nmr_task_submit_empty:
LD r8,r0,@nmr_task_tmp_id
ST r8,r4,0
LD r8,r0,@nmr_task_tmp_epoch
ST r8,r4,1
LD r8,r0,@nmr_task_tmp_checkpoint
ST r8,r4,2
LD r8,r0,@nmr_task_tmp_runner
ST r8,r4,3
LD r8,r0,@nmr_task_tmp_point
ST r8,r4,4
LD r8,r0,@nmr_task_tmp_op
ST r8,r4,5
LD r8,r0,@nmr_task_tmp_input
ST r8,r4,6
LD r8,r0,@nmr_task_tmp_scratch
ST r8,r4,7
LD r8,r0,@nmr_task_tmp_steps
ST r8,r4,8
LD r8,r0,@nmr_task_tmp_time
ST r8,r4,9
LD r8,r0,@nmr_task_tmp_expiry
ST r8,r4,10
MOVI r8,1
ST r8,r4,11
ST r0,r4,12
ST r0,r4,13
ST r0,r4,14
BOOL.14 r1,r6,r0
MOVI r3,0
LD r15,r0,@nmr_task_submit_ret
RET
nmr_task_duplicate:
MOVI r1,0
MOVI r3,5
LD r15,r0,@nmr_task_submit_ret
RET
nmr_task_invalid:
MOVI r1,0
MOVI r3,1
LD r15,r0,@nmr_task_submit_ret
RET
nmr_task_submit_ret:
.word 0

nmr_task_claim:
ST r15,r0,@nmr_task_claim_ret
ST r1,r0,@nmr_task_tmp_id
ST r2,r0,@nmr_task_tmp_runner
ST r3,r0,@nmr_task_tmp_epoch
MOVI r4,@nmr_task_table
MOVI r5,16
MOVI r6,0
nmr_task_claim_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_task_claim_next
LD r8,r0,@nmr_task_tmp_id
CMP r7,r8
JMP[EQ] @nmr_task_claim_found
nmr_task_claim_next:
ADDI r4,r4,14
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_task_claim_scan
JMP @nmr_task_missing
nmr_task_claim_found:
LD r8,r0,@nmr_task_tmp_runner
LD r9,r4,3
CMP r8,r9
JMP[NE] @nmr_task_owner_error
LD r8,r0,@nmr_task_tmp_epoch
LD r9,r4,1
CMP r8,r9
JMP[LT] @nmr_task_owner_error
LD r9,r4,10
CMP r9,r8
JMP[LT] @nmr_task_expired
LD r8,r4,11
MOVI r9,1
CMP r8,r9
JMP[NE] @nmr_task_state_error
MOVI r8,2
ST r8,r4,11
LD r8,r0,@nmr_task_tmp_epoch
ST r8,r4,14
MOVI r3,0
LD r15,r0,@nmr_task_claim_ret
RET
nmr_task_owner_error:
MOVI r3,6
LD r15,r0,@nmr_task_claim_ret
RET
nmr_task_state_error:
MOVI r3,7
LD r15,r0,@nmr_task_claim_ret
RET
nmr_task_expired:
MOVI r3,8
LD r15,r0,@nmr_task_claim_ret
RET
nmr_task_missing:
MOVI r3,1
LD r15,r0,@nmr_task_claim_ret
RET
nmr_task_claim_ret:
.word 0

nmr_task_finish:
ST r15,r0,@nmr_task_finish_ret
ST r1,r0,@nmr_task_tmp_id
ST r2,r0,@nmr_task_tmp_runner
ST r3,r0,@nmr_task_tmp_epoch
ST r4,r0,@nmr_task_tmp_output
ST r5,r0,@nmr_task_tmp_trace
MOVI r4,@nmr_task_table
MOVI r5,16
MOVI r6,0
nmr_task_finish_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_task_finish_next
LD r8,r0,@nmr_task_tmp_id
CMP r7,r8
JMP[EQ] @nmr_task_finish_found
nmr_task_finish_next:
ADDI r4,r4,14
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_task_finish_scan
JMP @nmr_task_missing_finish
nmr_task_finish_found:
LD r8,r0,@nmr_task_tmp_runner
LD r9,r4,3
CMP r8,r9
JMP[NE] @nmr_task_owner_error_finish
LD r8,r0,@nmr_task_tmp_epoch
LD r9,r4,14
CMP r8,r9
JMP[NE] @nmr_task_owner_error_finish
LD r9,r4,10
CMP r9,r8
JMP[LT] @nmr_task_expired_finish
LD r8,r4,11
MOVI r9,2
CMP r8,r9
JMP[NE] @nmr_task_state_error_finish
LD r8,r0,@nmr_task_tmp_output
ST r8,r4,12
LD r8,r0,@nmr_task_tmp_trace
ST r8,r4,13
MOVI r8,3
ST r8,r4,11
MOVI r3,0
LD r15,r0,@nmr_task_finish_ret
RET
nmr_task_owner_error_finish:
MOVI r3,6
LD r15,r0,@nmr_task_finish_ret
RET
nmr_task_state_error_finish:
MOVI r3,7
LD r15,r0,@nmr_task_finish_ret
RET
nmr_task_expired_finish:
MOVI r3,8
LD r15,r0,@nmr_task_finish_ret
RET
nmr_task_missing_finish:
MOVI r3,1
LD r15,r0,@nmr_task_finish_ret
RET
nmr_task_finish_ret:
.word 0

nmr_task_tmp_id:
.word 0
nmr_task_tmp_epoch:
.word 0
nmr_task_tmp_checkpoint:
.word 0
nmr_task_tmp_runner:
.word 0
nmr_task_tmp_point:
.word 0
nmr_task_tmp_op:
.word 0
nmr_task_tmp_input:
.word 0
nmr_task_tmp_scratch:
.word 0
nmr_task_tmp_steps:
.word 0
nmr_task_tmp_time:
.word 0
nmr_task_tmp_expiry:
.word 0
nmr_task_tmp_output:
.word 0
nmr_task_tmp_trace:
.word 0
.org 22000
nmr_task_table:
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0
