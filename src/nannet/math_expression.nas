; Binary typed mathematical expression parser/executor.
; Grammar:
;   <canonical-left-route>::op:<decimal-id>::<canonical-right-route>
; nmr_expr_resolve ABI: r1=byte pointer to expression.
; Returns r1=left object ID,r2=right object ID,r3=operator ID,
;         r4=output kind,r5=program ID,r6=left payload ptr,r7=right payload ptr,r8=status.
; Status: 0 success, 1 malformed expression, 2 left route failure,
;         3 right route failure, 4 typed operator resolution failure.
nmr_expr_resolve:
ST r15,r0,@nmr_expr_resolve_ret
ST r1,r0,@nmr_expr_input
CALL @nmr_addr_parse
CMP r3,r0
JMP[NE] @nmr_expr_bad
ST r1,r0,@nmr_expr_left_point
ST r2,r0,@nmr_expr_left_len
ST r4,r0,@nmr_expr_left_key
ST r5,r0,@nmr_expr_delim
CMP r5,r0
JMP[EQ] @nmr_expr_bad
; Skip exact "::op:" delimiter and parse a bounded decimal operator ID.
ADDI r5,r5,5
ST r5,r0,@nmr_expr_cursor
MOVI r7,0
MOVI r8,0
MOVI r9,10
nmr_expr_op_digit:
LD r5,r0,@nmr_expr_cursor
LDB r10,r5,0
MOVI r11,58
CMP r10,r11
JMP[EQ] @nmr_expr_op_done
MOVI r11,48
CMP r10,r11
JMP[LT] @nmr_expr_bad
MOVI r11,57
CMP r10,r11
JMP[GT] @nmr_expr_bad
MOVI r11,48
SUB r10,r10,r11
MUL r7,r7,r9
ADD r7,r7,r10
ADDI r8,r8,1
MOVI r11,5
CMP r8,r11
JMP[GT] @nmr_expr_bad
ADDI r5,r5,1
ST r5,r0,@nmr_expr_cursor
JMP @nmr_expr_op_digit
nmr_expr_op_done:
CMP r8,r0
JMP[EQ] @nmr_expr_bad
CMP r7,r0
JMP[EQ] @nmr_expr_bad
MOVI r11,65535
CMP r7,r11
JMP[GT] @nmr_expr_bad
ST r7,r0,@nmr_expr_op_id
; Require the exact "::" separator before the right endpoint.
LD r5,r0,@nmr_expr_cursor
ADDI r5,r5,1
LDB r10,r5,0
MOVI r11,58
CMP r10,r11
JMP[NE] @nmr_expr_bad
ADDI r5,r5,1
LDB r10,r5,0
CMP r10,r11
JMP[NE] @nmr_expr_bad
ADDI r5,r5,1
ST r5,r0,@nmr_expr_right_route
; Parse right endpoint; nested operation delimiters are not allowed.
ADD r1,r5,r0
CALL @nmr_addr_parse
CMP r3,r0
JMP[NE] @nmr_expr_right_error
CMP r5,r0
JMP[NE] @nmr_expr_bad
ST r1,r0,@nmr_expr_right_point
ST r2,r0,@nmr_expr_right_len
ST r4,r0,@nmr_expr_right_key
; Resolve left endpoint against key kind, object ID and owner point.
LD r1,r0,@nmr_expr_left_key
LD r2,r0,@nmr_expr_left_len
LD r3,r0,@nmr_expr_left_point
CALL @nmr_route_resolve
CMP r3,r0
JMP[NE] @nmr_expr_left_error
ST r1,r0,@nmr_expr_left_id
; Resolve right endpoint with the same owner/type checks.
LD r1,r0,@nmr_expr_right_key
LD r2,r0,@nmr_expr_right_len
LD r3,r0,@nmr_expr_right_point
CALL @nmr_route_resolve
CMP r3,r0
JMP[NE] @nmr_expr_right_error
ST r1,r0,@nmr_expr_right_id
; Registry is authoritative for signature, output kind and guest program.
LD r1,r0,@nmr_expr_left_id
LD r2,r0,@nmr_expr_right_id
LD r3,r0,@nmr_expr_op_id
CALL @nmr_resolve
CMP r3,r0
JMP[NE] @nmr_expr_operator_error
ST r1,r0,@nmr_expr_out_kind
ST r2,r0,@nmr_expr_program
ST r4,r0,@nmr_expr_left_data
ST r5,r0,@nmr_expr_right_data
LD r1,r0,@nmr_expr_left_id
LD r2,r0,@nmr_expr_right_id
LD r3,r0,@nmr_expr_op_id
LD r4,r0,@nmr_expr_out_kind
LD r5,r0,@nmr_expr_program
LD r6,r0,@nmr_expr_left_data
LD r7,r0,@nmr_expr_right_data
MOVI r8,0
LD r15,r0,@nmr_expr_resolve_ret
RET
nmr_expr_bad:
MOVI r1,0
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,0
MOVI r6,0
MOVI r7,0
MOVI r8,1
LD r15,r0,@nmr_expr_resolve_ret
RET
nmr_expr_left_error:
MOVI r1,0
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,0
MOVI r6,0
MOVI r7,0
MOVI r8,2
LD r15,r0,@nmr_expr_resolve_ret
RET
nmr_expr_right_error:
MOVI r1,0
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,0
MOVI r6,0
MOVI r7,0
MOVI r8,3
LD r15,r0,@nmr_expr_resolve_ret
RET
nmr_expr_operator_error:
MOVI r1,0
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,0
MOVI r6,0
MOVI r7,0
MOVI r8,4
LD r15,r0,@nmr_expr_resolve_ret
RET
nmr_expr_resolve_ret:
.word 0

; nmr_expr_execute ABI: r1=expression byte pointer,r2=dimension,r3=output word pointer.
; Returns r1=output kind,r2=program ID,r3=status,r4=output word pointer.
; This first execution form takes the dimension from the caller; shape metadata is next.
nmr_expr_execute:
ST r15,r0,@nmr_expr_execute_ret
ST r1,r0,@nmr_expr_input
ST r2,r0,@nmr_expr_exec_dim
ST r3,r0,@nmr_expr_exec_out
LD r1,r0,@nmr_expr_input
CALL @nmr_expr_resolve
ST r8,r0,@nmr_expr_status
CMP r8,r0
JMP[NE] @nmr_expr_execute_error
ST r4,r0,@nmr_expr_out_kind
ST r5,r0,@nmr_expr_program
ST r6,r0,@nmr_expr_left_data
ST r7,r0,@nmr_expr_right_data
LD r1,r0,@nmr_expr_program
LD r2,r0,@nmr_expr_left_data
LD r3,r0,@nmr_expr_right_data
LD r4,r0,@nmr_expr_exec_dim
LD r5,r0,@nmr_expr_exec_out
CALL @nmr_execute
ST r1,r0,@nmr_expr_result_ptr
ST r3,r0,@nmr_expr_status
CMP r3,r0
JMP[NE] @nmr_expr_execute_error
LD r1,r0,@nmr_expr_out_kind
LD r2,r0,@nmr_expr_program
LD r4,r0,@nmr_expr_result_ptr
MOVI r3,0
LD r15,r0,@nmr_expr_execute_ret
RET
nmr_expr_execute_error:
MOVI r1,0
MOVI r2,0
LD r3,r0,@nmr_expr_status
MOVI r4,0
LD r15,r0,@nmr_expr_execute_ret
RET
nmr_expr_execute_ret:
.word 0
nmr_expr_input:
.word 0
nmr_expr_delim:
.word 0
nmr_expr_cursor:
.word 0
nmr_expr_op_id:
.word 0
nmr_expr_left_point:
.word 0
nmr_expr_left_len:
.word 0
nmr_expr_left_key:
.word 0
nmr_expr_right_route:
.word 0
nmr_expr_right_point:
.word 0
nmr_expr_right_len:
.word 0
nmr_expr_right_key:
.word 0
nmr_expr_left_id:
.word 0
nmr_expr_right_id:
.word 0
nmr_expr_out_kind:
.word 0
nmr_expr_program:
.word 0
nmr_expr_left_data:
.word 0
nmr_expr_right_data:
.word 0
nmr_expr_exec_dim:
.word 0
nmr_expr_exec_out:
.word 0
nmr_expr_result_ptr:
.word 0
nmr_expr_status:
.word 0
