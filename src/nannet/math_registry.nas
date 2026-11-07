; NaN16 mathematical object/operator registry.
; Direct-call ABI:
;   nmr_obj_put: r1=id,r2=kind,r3=owner_point,r4=payload_digest -> r1=slot,r3=status
;   nmr_obj_bind_data: r1=id,r2=guest_word_pointer -> r1=slot,r3=status
;   nmr_obj_get: r1=id -> r1=kind,r2=owner,r3=digest,r4=slot,r5=status,r6=data_pointer
;   nmr_op_put: r1=op_id,r2=left_kind,r3=right_kind,r4=out_kind,r5=program_id -> r1=slot,r3=status
;   nmr_resolve: r1=left_object_id,r2=right_object_id,r3=op_id
;       -> r1=out_kind,r2=program_id,r3=status,r4=left_data_pointer,r5=right_data_pointer
; Status: 0 success, 1 invalid/unknown, 3 full, 5 immutable-key conflict, 6 signature/type mismatch.
; Object records are id,kind,owner,digest,data_pointer (5 words).
; Operator records are op_id,left_kind,right_kind,out_kind,program_id (5 words).
; Fixed-size tables are bootstrap scratch. MC0DB persistence/checkpointing is a later layer.

nmr_obj_put:
ST r15,r0,@nmr_obj_put_ret
ST r1,r0,@nmr_tmp_id
ST r2,r0,@nmr_tmp_kind
ST r3,r0,@nmr_tmp_owner
ST r4,r0,@nmr_tmp_digest
MOVI r4,@nmr_obj_table
MOVI r5,32
MOVI r6,0
nmr_obj_put_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_obj_put_empty
LD r8,r0,@nmr_tmp_id
CMP r7,r8
JMP[EQ] @nmr_obj_put_found
ADDI r4,r4,5
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_obj_put_scan
MOVI r1,0
MOVI r3,3
LD r15,r0,@nmr_obj_put_ret
RET
nmr_obj_put_found:
LD r8,r0,@nmr_tmp_kind
LD r9,r4,1
CMP r8,r9
JMP[NE] @nmr_obj_put_conflict
LD r8,r0,@nmr_tmp_owner
LD r9,r4,2
CMP r8,r9
JMP[NE] @nmr_obj_put_conflict
LD r8,r0,@nmr_tmp_digest
LD r9,r4,3
CMP r8,r9
JMP[NE] @nmr_obj_put_conflict
BOOL.14 r1,r6,r0
MOVI r3,0
LD r15,r0,@nmr_obj_put_ret
RET
nmr_obj_put_empty:
LD r8,r0,@nmr_tmp_id
ST r8,r4,0
LD r8,r0,@nmr_tmp_kind
ST r8,r4,1
LD r8,r0,@nmr_tmp_owner
ST r8,r4,2
LD r8,r0,@nmr_tmp_digest
ST r8,r4,3
ST r0,r4,4
BOOL.14 r1,r6,r0
MOVI r3,0
LD r15,r0,@nmr_obj_put_ret
RET
nmr_obj_put_conflict:
MOVI r1,0
MOVI r3,5
LD r15,r0,@nmr_obj_put_ret
RET
nmr_obj_put_ret:
.word 0

; Bind a vector's guest-memory payload after immutable object registration.
; A pointer may be set once or re-bound idempotently to the same value.
nmr_obj_bind_data:
ST r15,r0,@nmr_obj_bind_ret
ST r1,r0,@nmr_bind_id
ST r2,r0,@nmr_bind_ptr
CMP r1,r0
JMP[EQ] @nmr_obj_bind_bad
CMP r2,r0
JMP[EQ] @nmr_obj_bind_bad
MOVI r4,@nmr_obj_table
MOVI r5,32
MOVI r6,0
nmr_obj_bind_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_obj_bind_next
LD r8,r0,@nmr_bind_id
CMP r7,r8
JMP[EQ] @nmr_obj_bind_found
nmr_obj_bind_next:
ADDI r4,r4,5
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_obj_bind_scan
MOVI r1,0
MOVI r3,1
LD r15,r0,@nmr_obj_bind_ret
RET
nmr_obj_bind_found:
LD r8,r4,1
MOVI r9,4
CMP r8,r9
JMP[NE] @nmr_obj_bind_type
LD r8,r4,4
CMP r8,r0
JMP[EQ] @nmr_obj_bind_write
LD r9,r0,@nmr_bind_ptr
CMP r8,r9
JMP[NE] @nmr_obj_bind_conflict
JMP @nmr_obj_bind_ok
nmr_obj_bind_write:
LD r9,r0,@nmr_bind_ptr
ST r9,r4,4
nmr_obj_bind_ok:
BOOL.14 r1,r6,r0
MOVI r3,0
LD r15,r0,@nmr_obj_bind_ret
RET
nmr_obj_bind_type:
MOVI r1,0
MOVI r3,6
LD r15,r0,@nmr_obj_bind_ret
RET
nmr_obj_bind_conflict:
MOVI r1,0
MOVI r3,5
LD r15,r0,@nmr_obj_bind_ret
RET
nmr_obj_bind_bad:
MOVI r1,0
MOVI r3,1
LD r15,r0,@nmr_obj_bind_ret
RET
nmr_obj_bind_ret:
.word 0

nmr_obj_get:
ST r15,r0,@nmr_obj_get_ret
ST r1,r0,@nmr_tmp_id
MOVI r4,@nmr_obj_table
MOVI r5,32
MOVI r6,0
nmr_obj_get_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_obj_get_next
LD r8,r0,@nmr_tmp_id
CMP r7,r8
JMP[EQ] @nmr_obj_get_found
nmr_obj_get_next:
ADDI r4,r4,5
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_obj_get_scan
MOVI r1,0
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,1
MOVI r6,0
LD r15,r0,@nmr_obj_get_ret
RET
nmr_obj_get_found:
LD r1,r4,1
LD r2,r4,2
LD r3,r4,3
LD r7,r4,4
BOOL.14 r4,r6,r0
MOV r6,r7
MOVI r5,0
LD r15,r0,@nmr_obj_get_ret
RET
nmr_obj_get_ret:
.word 0

nmr_op_put:
ST r15,r0,@nmr_op_put_ret
ST r1,r0,@nmr_tmp_op
ST r2,r0,@nmr_tmp_left
ST r3,r0,@nmr_tmp_right
ST r4,r0,@nmr_tmp_out
ST r5,r0,@nmr_tmp_program
MOVI r4,@nmr_op_table
MOVI r5,16
MOVI r6,0
nmr_op_put_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_op_put_empty
LD r8,r0,@nmr_tmp_op
CMP r7,r8
JMP[EQ] @nmr_op_put_found
ADDI r4,r4,5
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_op_put_scan
MOVI r1,0
MOVI r3,3
LD r15,r0,@nmr_op_put_ret
RET
nmr_op_put_found:
LD r8,r0,@nmr_tmp_left
LD r9,r4,1
CMP r8,r9
JMP[NE] @nmr_op_put_conflict
LD r8,r0,@nmr_tmp_right
LD r9,r4,2
CMP r8,r9
JMP[NE] @nmr_op_put_conflict
LD r8,r0,@nmr_tmp_out
LD r9,r4,3
CMP r8,r9
JMP[NE] @nmr_op_put_conflict
LD r8,r0,@nmr_tmp_program
LD r9,r4,4
CMP r8,r9
JMP[NE] @nmr_op_put_conflict
BOOL.14 r1,r6,r0
MOVI r3,0
LD r15,r0,@nmr_op_put_ret
RET
nmr_op_put_empty:
LD r8,r0,@nmr_tmp_op
ST r8,r4,0
LD r8,r0,@nmr_tmp_left
ST r8,r4,1
LD r8,r0,@nmr_tmp_right
ST r8,r4,2
LD r8,r0,@nmr_tmp_out
ST r8,r4,3
LD r8,r0,@nmr_tmp_program
ST r8,r4,4
BOOL.14 r1,r6,r0
MOVI r3,0
LD r15,r0,@nmr_op_put_ret
RET
nmr_op_put_conflict:
MOVI r1,0
MOVI r3,5
LD r15,r0,@nmr_op_put_ret
RET
nmr_op_put_ret:
.word 0

nmr_resolve:
ST r15,r0,@nmr_resolve_ret
ST r1,r0,@nmr_tmp_left_id
ST r2,r0,@nmr_tmp_right_id
ST r3,r0,@nmr_tmp_op
LD r1,r0,@nmr_tmp_left_id
CALL @nmr_obj_get
CMP r5,r0
JMP[NE] @nmr_resolve_missing
ST r1,r0,@nmr_tmp_left_kind
ST r6,r0,@nmr_tmp_left_data
LD r1,r0,@nmr_tmp_right_id
CALL @nmr_obj_get
CMP r5,r0
JMP[NE] @nmr_resolve_missing
ST r1,r0,@nmr_tmp_right_kind
ST r6,r0,@nmr_tmp_right_data
MOVI r4,@nmr_op_table
MOVI r5,16
MOVI r6,0
nmr_resolve_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @nmr_resolve_next
LD r8,r0,@nmr_tmp_op
CMP r7,r8
JMP[EQ] @nmr_resolve_found
nmr_resolve_next:
ADDI r4,r4,5
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @nmr_resolve_scan
JMP @nmr_resolve_missing
nmr_resolve_found:
LD r8,r0,@nmr_tmp_left_kind
LD r9,r4,1
CMP r8,r9
JMP[NE] @nmr_resolve_signature
LD r8,r0,@nmr_tmp_right_kind
LD r9,r4,2
CMP r8,r9
JMP[NE] @nmr_resolve_signature
LD r1,r4,3
LD r2,r4,4
LD r4,r0,@nmr_tmp_left_data
LD r5,r0,@nmr_tmp_right_data
MOVI r3,0
LD r15,r0,@nmr_resolve_ret
RET
nmr_resolve_signature:
MOVI r1,0
MOVI r2,0
MOVI r3,6
MOVI r4,0
MOVI r5,0
LD r15,r0,@nmr_resolve_ret
RET
nmr_resolve_missing:
MOVI r1,0
MOVI r2,0
MOVI r3,1
MOVI r4,0
MOVI r5,0
LD r15,r0,@nmr_resolve_ret
RET
nmr_resolve_ret:
.word 0

nmr_tmp_id:
.word 0
nmr_tmp_kind:
.word 0
nmr_tmp_owner:
.word 0
nmr_tmp_digest:
.word 0
nmr_tmp_op:
.word 0
nmr_tmp_left:
.word 0
nmr_tmp_right:
.word 0
nmr_tmp_out:
.word 0
nmr_tmp_program:
.word 0
nmr_tmp_left_id:
.word 0
nmr_tmp_right_id:
.word 0
nmr_tmp_left_kind:
.word 0
nmr_tmp_right_kind:
.word 0
nmr_tmp_left_data:
.word 0
nmr_tmp_right_data:
.word 0
nmr_bind_id:
.word 0
nmr_bind_ptr:
.word 0

.org 20000
nmr_obj_table:
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
nmr_op_table:
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
.word 0,0,0,0,0
