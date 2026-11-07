; NaN16 vector operation execution ABI.
; Program 78 = vector.add.i32.v1
; Input/output pointers are word addresses into the guest memory space.
; nmr_vector_add_v1: r1=left,r2=right,r3=dimension(1..16),r4=output
; Returns r1=output,r2=dimension,r3=status (0 success, 1 invalid).
; This is bounded exact signed-32-bit-word addition modulo 2^32.
nmr_vector_add_v1:
ST r15,r0,@nmr_vec_add_ret
ST r1,r0,@nmr_vec_left
ST r2,r0,@nmr_vec_right
ST r3,r0,@nmr_vec_dim
ST r4,r0,@nmr_vec_out
ST r4,r0,@nmr_vec_out_base
CMP r1,r0
JMP[EQ] @nmr_vec_add_bad
CMP r2,r0
JMP[EQ] @nmr_vec_add_bad
CMP r4,r0
JMP[EQ] @nmr_vec_add_bad
CMP r3,r0
JMP[EQ] @nmr_vec_add_bad
MOVI r5,16
CMP r3,r5
JMP[GT] @nmr_vec_add_bad
MOVI r6,0
ST r6,r0,@nmr_vec_index
nmr_vec_add_loop:
LD r8,r0,@nmr_vec_left
LD r9,r0,@nmr_vec_right
LD r10,r0,@nmr_vec_out
LD r11,r8,0
LD r12,r9,0
ADD r13,r11,r12
ST r13,r10,0
ADDI r8,r8,1
ADDI r9,r9,1
ADDI r10,r10,1
ST r8,r0,@nmr_vec_left
ST r9,r0,@nmr_vec_right
ST r10,r0,@nmr_vec_out
LD r6,r0,@nmr_vec_index
ADDI r6,r6,1
ST r6,r0,@nmr_vec_index
LD r7,r0,@nmr_vec_dim
CMP r6,r7
JMP[LT] @nmr_vec_add_loop
LD r1,r0,@nmr_vec_out_base
LD r2,r0,@nmr_vec_dim
MOVI r3,0
LD r15,r0,@nmr_vec_add_ret
RET
nmr_vec_add_bad:
MOVI r1,0
MOVI r2,0
MOVI r3,1
LD r15,r0,@nmr_vec_add_ret
RET
nmr_vec_add_ret:
.word 0
nmr_vec_left:
.word 0
nmr_vec_right:
.word 0
nmr_vec_dim:
.word 0
nmr_vec_out:
.word 0
nmr_vec_out_base:
.word 0
nmr_vec_index:
.word 0

; Registry program-ID dispatcher. Unknown IDs fail closed.
; nmr_execute: r1=program_id,r2=left,r3=right,r4=dimension,r5=output
; Returns r1=output,r2=dimension,r3=status.
nmr_execute:
ST r15,r0,@nmr_execute_ret
ST r1,r0,@nmr_exec_program
ST r2,r0,@nmr_exec_left
ST r3,r0,@nmr_exec_right
ST r4,r0,@nmr_exec_dim
ST r5,r0,@nmr_exec_out
MOVI r6,78
CMP r1,r6
JMP[EQ] @nmr_exec_vector_add
JMP @nmr_exec_unknown
nmr_exec_vector_add:
LD r1,r0,@nmr_exec_left
LD r2,r0,@nmr_exec_right
LD r3,r0,@nmr_exec_dim
LD r4,r0,@nmr_exec_out
CALL @nmr_vector_add_v1
LD r15,r0,@nmr_execute_ret
RET
nmr_exec_unknown:
MOVI r1,0
MOVI r2,0
MOVI r3,1
LD r15,r0,@nmr_execute_ret
RET
nmr_execute_ret:
.word 0
nmr_exec_program:
.word 0
nmr_exec_left:
.word 0
nmr_exec_right:
.word 0
nmr_exec_dim:
.word 0
nmr_exec_out:
.word 0
