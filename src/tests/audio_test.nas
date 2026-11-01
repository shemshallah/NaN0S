; audio_test.nas - NaN16 PC speaker driver smoke test.
.org 0
JMP @main
.include "../lib/audio.nas"
main:
MOVI r13,1
MOVI r1,440
MOVI r2,200
CALL @audio_beep
CALL @audio_off
MOVI r1,@s_pass
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
.str "AUDIO PASS\n"
