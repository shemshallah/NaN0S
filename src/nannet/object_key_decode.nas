; Decode canonical object keys returned by nmr_addr_parse.
; ABI: r1=key byte pointer, r2=key byte length.
; Returns r1=object kind (4 vector, 8 hypergraph), r2=numeric ID (1..9999), r3=status.
; Status: 0 success, 1 malformed/unknown kind, 2 invalid numeric ID.
nmr_key_decode:
ST r15,r0,@nmr_key_ret
ST r1,r0,@nmr_key_ptr
ST r2,r0,@nmr_key_len
; Try "vector" (6-byte prefix).
MOVI r8,6
CMP r2,r8
JMP[LT] @nmr_key_try_hyper
MOVI r4,@nmr_key_vector
SHL r4,r4,2
LD r5,r0,@nmr_key_ptr
MOVI r6,6
nmr_key_vec_cmp:
CMP r6,r0
JMP[EQ] @nmr_key_vec_match
LDB r7,r4,0
LDB r8,r5,0
CMP r7,r8
JMP[NE] @nmr_key_try_hyper
ADDI r4,r4,1
ADDI r5,r5,1
MOVI r8,1
SUB r6,r6,r8
JMP @nmr_key_vec_cmp
nmr_key_vec_match:
MOVI r1,4
MOVI r8,6
JMP @nmr_key_parse_suffix
nmr_key_try_hyper:
MOVI r8,10
CMP r2,r8
JMP[LT] @nmr_key_bad
MOVI r4,@nmr_key_hyper
SHL r4,r4,2
LD r5,r0,@nmr_key_ptr
MOVI r6,10
nmr_key_hyper_cmp:
CMP r6,r0
JMP[EQ] @nmr_key_hyper_match
LDB r7,r4,0
LDB r9,r5,0
CMP r7,r9
JMP[NE] @nmr_key_bad
ADDI r4,r4,1
ADDI r5,r5,1
MOVI r9,1
SUB r6,r6,r9
JMP @nmr_key_hyper_cmp
nmr_key_hyper_match:
MOVI r1,8
MOVI r8,10
nmr_key_parse_suffix:
ST r1,r0,@nmr_key_kind
LD r5,r0,@nmr_key_ptr
ADD r5,r5,r8
ST r5,r0,@nmr_key_scan
LD r6,r0,@nmr_key_len
SUB r6,r6,r8
CMP r6,r0
JMP[EQ] @nmr_key_bad
MOVI r7,0
MOVI r9,0
nmr_key_digit_loop:
LD r5,r0,@nmr_key_scan
LDB r10,r5,0
MOVI r11,48
CMP r10,r11
JMP[LT] @nmr_key_bad
MOVI r11,57
CMP r10,r11
JMP[GT] @nmr_key_bad
SUB r10,r10,r11
MOVI r11,9
ADD r10,r10,r11
MOVI r11,10
MUL r7,r7,r11
ADD r7,r7,r10
ADDI r9,r9,1
MOVI r11,4
CMP r9,r11
JMP[GT] @nmr_key_bad
ADDI r5,r5,1
ST r5,r0,@nmr_key_scan
CMP r9,r6
JMP[LT] @nmr_key_digit_loop
CMP r7,r0
JMP[EQ] @nmr_key_id_bad
MOVI r11,9999
CMP r7,r11
JMP[GT] @nmr_key_id_bad
LD r1,r0,@nmr_key_kind
ADD r2,r7,r0
MOVI r3,0
LD r15,r0,@nmr_key_ret
RET
nmr_key_bad:
MOVI r1,0
MOVI r2,0
MOVI r3,1
LD r15,r0,@nmr_key_ret
RET
nmr_key_id_bad:
MOVI r1,0
MOVI r2,0
MOVI r3,2
LD r15,r0,@nmr_key_ret
RET
nmr_key_ret:
.word 0
nmr_key_ptr:
.word 0
nmr_key_len:
.word 0
nmr_key_kind:
.word 0
nmr_key_scan:
.word 0
.org 18300
nmr_key_vector:
.str "vector"
nmr_key_hyper:
.str "hypergraph"
