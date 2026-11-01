; n16de_test.nas - pair-vote encode/decode smoke test. Prints to COM1.
.org 0
JMP @main
.include "../lib/n16de.nas"
main:
MOVI r13,1
MOVI r1,0x1234
MOVI r2,4096
CALL @n16_encode
MOVI r1,4096
CALL @n16_decode
MOVI r3,0x1234
CMP r1,r3
JMP[NE] @fail
CMP r2,r0
JMP[EQ] @fail
MOVI r1,0xABCD
MOVI r2,4098
CALL @n16_encode
MOVI r1,4098
CALL @n16_decode
MOVI r3,0xABCD
CMP r1,r3
JMP[NE] @fail
CMP r2,r0
JMP[EQ] @fail
MOVI r1,@s_pass
CALL @puts
HALT
fail:
MOVI r1,@s_fail
CALL @puts
HALT
puts:
MOVI r4,255
p1:
LD r2,r1,0
MOVI r3,4
p2:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @p2
ADD r1,r1,r13
JMP @p1
s_pass:
.str "N16DE PASS\n"
s_fail:
.str "N16DE FAIL\n"
