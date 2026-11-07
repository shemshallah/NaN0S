; Canonical NaN route-address parser (guest-owned).
; ABI: r1=byte address of NUL-terminated route string.
; Returns r1=logical point (1..255), r2=object-key byte length, r3=status, r4=object-key byte pointer.
; Status: 0 success, 1 malformed syntax, 2 reserved/out-of-range point, 3 empty key.
nmr_addr_parse:
ST r15,r0,@nmr_addr_ret
ST r1,r0,@nmr_addr_tmp_ptr
MOVI r4,@nmr_addr_prefix
SHL r4,r4,2
LD r5,r0,@nmr_addr_tmp_ptr
MOVI r6,31
nmr_addr_prefix_loop:
CMP r6,r0
JMP[EQ] @nmr_addr_digits
LDB r7,r4,0
LDB r8,r5,0
CMP r7,r8
JMP[NE] @nmr_addr_syntax
ADDI r4,r4,1
ADDI r5,r5,1
MOVI r9,1
SUB r6,r6,r9
JMP @nmr_addr_prefix_loop
nmr_addr_digits:
MOVI r7,0
MOVI r10,10
MOVI r11,0
nmr_addr_digit_loop:
LDB r8,r5,0
MOVI r9,58
CMP r8,r9
JMP[EQ] @nmr_addr_digit_done
MOVI r9,48
CMP r8,r9
JMP[LT] @nmr_addr_syntax
MOVI r9,57
CMP r8,r9
JMP[GT] @nmr_addr_syntax
MOVI r9,48
SUB r8,r8,r9
MUL r7,r7,r10
ADD r7,r7,r8
ADDI r11,r11,1
MOVI r9,3
CMP r11,r9
JMP[GT] @nmr_addr_point_error
ADDI r5,r5,1
JMP @nmr_addr_digit_loop
nmr_addr_digit_done:
CMP r11,r0
JMP[EQ] @nmr_addr_point_error
CMP r7,r0
JMP[EQ] @nmr_addr_point_error
MOVI r9,255
CMP r7,r9
JMP[GT] @nmr_addr_point_error
; Require the exact :: endpoint separator.
MOVI r9,58
CMP r8,r9
JMP[NE] @nmr_addr_syntax
ADDI r5,r5,1
LDB r8,r5,0
CMP r8,r9
JMP[NE] @nmr_addr_syntax
ADDI r5,r5,1
; Object key is a non-empty printable ASCII token without another colon.
MOVI r2,0
ST r5,r0,@nmr_addr_tmp_key_ptr
ST r0,r0,@nmr_addr_op_ptr
nmr_addr_key_loop:
LDB r8,r5,0
CMP r8,r0
JMP[EQ] @nmr_addr_key_done
MOVI r9,33
CMP r8,r9
JMP[LT] @nmr_addr_syntax
MOVI r9,126
CMP r8,r9
JMP[GT] @nmr_addr_syntax
MOVI r9,58
CMP r8,r9
JMP[NE] @nmr_addr_key_char
; The only accepted key terminator is the typed operation marker "::op:".
LDB r10,r5,1
CMP r10,r9
JMP[NE] @nmr_addr_syntax
MOVI r11,111
LDB r10,r5,2
CMP r10,r11
JMP[NE] @nmr_addr_syntax
MOVI r11,112
LDB r10,r5,3
CMP r10,r11
JMP[NE] @nmr_addr_syntax
LDB r10,r5,4
CMP r10,r9
JMP[NE] @nmr_addr_syntax
ST r5,r0,@nmr_addr_op_ptr
JMP @nmr_addr_key_done
nmr_addr_key_char:
ADDI r2,r2,1
ADDI r5,r5,1
JMP @nmr_addr_key_loop
nmr_addr_key_done:
CMP r2,r0
JMP[EQ] @nmr_addr_key_error
ADD r1,r7,r0
LD r4,r0,@nmr_addr_tmp_key_ptr
LD r5,r0,@nmr_addr_op_ptr
MOVI r3,0
LD r15,r0,@nmr_addr_ret
RET
nmr_addr_syntax:
MOVI r1,0
MOVI r2,0
MOVI r3,1
LD r15,r0,@nmr_addr_ret
RET
nmr_addr_point_error:
MOVI r1,0
MOVI r2,0
MOVI r3,2
LD r15,r0,@nmr_addr_ret
RET
nmr_addr_key_error:
MOVI r1,0
MOVI r2,0
MOVI r3,3
LD r15,r0,@nmr_addr_ret
RET
nmr_addr_ret:
.word 0
nmr_addr_tmp_ptr:
.word 0
nmr_addr_tmp_key_ptr:
.word 0
nmr_addr_op_ptr:
.word 0
.org 18000
nmr_addr_prefix:
.str "nan://GM0:SC0:MC0:BS0:HW0::HW0:"
