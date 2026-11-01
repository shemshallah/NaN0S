; translate_test.nas - three-file translator smoke test.
.org 0
JMP @main
.include "../translate/common.nas"
.include "../translate/x86.nas"
.include "../translate/a64.nas"
main:
MOVI r13,1
MOVI r2,16384
CALL @a64_emit_nop
MOVI r4,4
ADD r2,r2,r4
CALL @a64_emit_ret
MOVI r2,17408
CALL @x86_emit_ret
LD r1,r0,4096
MOVI r2,0x201F
MOVHI r2,0xD503
CMP r1,r2
JMP[NE] @fail
LD r1,r0,4097
MOVI r2,0x03C0
MOVHI r2,0xD65F
CMP r1,r2
JMP[NE] @fail
LD r1,r0,4352
MOVI r2,0xC3
CMP r1,r2
JMP[NE] @fail
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
.str "TRANSLATE PASS\n"
s_fail:
.str "TRANSLATE FAIL\n"
