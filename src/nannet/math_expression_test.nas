; End-to-end canonical route expression -> typed dispatch -> NaN16 execution.
main:
MOVI r1,48
ST r1,r0,@expr_stage
; Register endpoint objects at distinct HW0 logical points.
MOVI r1,1401
MOVI r2,4
MOVI r3,1
MOVI r4,4101
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @expr_fail
MOVI r1,1401
MOVI r2,@expr_vec_left
CALL @nmr_obj_bind_data
CMP r3,r0
JMP[NE] @expr_fail
MOVI r1,1402
MOVI r2,4
MOVI r3,2
MOVI r4,4102
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @expr_fail
MOVI r1,1402
MOVI r2,@expr_vec_right
CALL @nmr_obj_bind_data
CMP r3,r0
JMP[NE] @expr_fail
; Register vector(4) x vector(4) -> scalar(3), program 79.
MOVI r1,701
MOVI r2,4
MOVI r3,4
MOVI r4,3
MOVI r5,79
CALL @nmr_op_put
CMP r3,r0
JMP[NE] @expr_fail
MOVI r1,49
ST r1,r0,@expr_stage
; Canonical expression resolves both route endpoints and executes the operator.
MOVI r1,@expr_valid
SHL r1,r1,2
MOVI r2,4
MOVI r3,@expr_output
CALL @nmr_expr_execute
ST r3,r0,@expr_dbg_status
ST r1,r0,@expr_dbg_kind
ST r2,r0,@expr_dbg_program
ST r4,r0,@expr_dbg_ptr
MOVI r1,97
ST r1,r0,@expr_stage
CMP r3,r0
JMP[NE] @expr_fail
MOVI r1,98
ST r1,r0,@expr_stage
LD r1,r0,@expr_dbg_kind
MOVI r6,3
CMP r1,r6
JMP[NE] @expr_fail
MOVI r1,99
ST r1,r0,@expr_stage
MOVI r6,79
CMP r2,r6
JMP[NE] @expr_fail
MOVI r1,100
ST r1,r0,@expr_stage
MOVI r6,@expr_output
CMP r4,r6
JMP[NE] @expr_fail
MOVI r1,101
ST r1,r0,@expr_stage
LD r7,r6,0
MOVI r8,300
CMP r7,r8
JMP[NE] @expr_fail
MOVI r1,102
ST r1,r0,@expr_stage
MOVI r1,50
ST r1,r0,@expr_stage
; A route without ::op: is not an executable expression.
MOVI r1,@expr_no_operator
SHL r1,r1,2
MOVI r2,4
MOVI r3,@expr_output
CALL @nmr_expr_execute
MOVI r6,1
CMP r3,r6
JMP[NE] @expr_fail
MOVI r1,51
ST r1,r0,@expr_stage
; An unknown operator is rejected by the typed registry.
MOVI r1,@expr_unknown_operator
SHL r1,r1,2
MOVI r2,4
MOVI r3,@expr_output
CALL @nmr_expr_execute
MOVI r6,4
CMP r3,r6
JMP[NE] @expr_fail
MOVI r1,52
ST r1,r0,@expr_stage
; A syntactically valid endpoint at the wrong owner point is rejected.
MOVI r1,@expr_wrong_owner
SHL r1,r1,2
MOVI r2,4
MOVI r3,@expr_output
CALL @nmr_expr_execute
MOVI r6,2
CMP r3,r6
JMP[NE] @expr_fail
MOVI r1,53
ST r1,r0,@expr_stage
; Non-decimal operator IDs are malformed.
MOVI r1,@expr_bad_operator
SHL r1,r1,2
MOVI r2,4
MOVI r3,@expr_output
CALL @nmr_expr_execute
MOVI r6,1
CMP r3,r6
JMP[NE] @expr_fail
MOVI r1,54
ST r1,r0,@expr_stage
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
expr_fail:
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
LD r1,r0,@expr_stage
PUTC r1
LD r1,r0,@nmr_expr_debug_stage
PUTC r1
LD r1,r0,@expr_dbg_status
ADDI r1,r1,48
PUTC r1
LD r1,r0,@expr_dbg_kind
ADDI r1,r1,48
PUTC r1
LD r1,r0,@expr_dbg_program
PUTC r1
MOVI r1,10
PUTC r1
HALT
.include "route_address.nas"
.include "object_key_decode.nas"
.include "math_registry.nas"
.include "route_object_resolve.nas"
.include "vector_ops.nas"
.include "math_expression.nas"
.org 22990
expr_stage:
.word 48
expr_dbg_status:
.word 0
expr_dbg_kind:
.word 0
expr_dbg_program:
.word 0
expr_dbg_ptr:
.word 0
.org 23000
expr_vec_left:
.word 1,2,3,4
expr_vec_right:
.word 10,20,30,40
expr_output:
.word 0
.org 23100
expr_valid:
.str "nan://GM0:SC0:MC0:BS0:HW0::HW0:1::vector1401::op:701::nan://GM0:SC0:MC0:BS0:HW0::HW0:2::vector1402"
expr_no_operator:
.str "nan://GM0:SC0:MC0:BS0:HW0::HW0:1::vector1401"
expr_unknown_operator:
.str "nan://GM0:SC0:MC0:BS0:HW0::HW0:1::vector1401::op:702::nan://GM0:SC0:MC0:BS0:HW0::HW0:2::vector1402"
expr_wrong_owner:
.str "nan://GM0:SC0:MC0:BS0:HW0::HW0:3::vector1401::op:701::nan://GM0:SC0:MC0:BS0:HW0::HW0:2::vector1402"
expr_bad_operator:
.str "nan://GM0:SC0:MC0:BS0:HW0::HW0:1::vector1401::op:x::nan://GM0:SC0:MC0:BS0:HW0::HW0:2::vector1402"
