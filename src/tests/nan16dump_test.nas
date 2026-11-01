; nan16dump_test.nas - NaN16 word inspector test.
.org 0
JMP @main
test_words:
MOVI r1,5
BOOL.8 r2,r3,r4
LD r5,r6,7
.include "../lib/nan16dump.nas"
main:
MOVI r13,1
MOVI r1,@test_words
CALL @nan16_dump
MOVI r1,@test_words
ADD r1,r1,r13
CALL @nan16_dump
MOVI r1,@test_words
MOVI r2,2
ADD r1,r1,r2
CALL @nan16_dump
MOVI r1,@s_pass
CALL @puts
HALT
s_pass:
.str "DUMP PASS\n"
