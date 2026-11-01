; retro_test.nas - safe LE/BE clock, contractive fixed-point loop, and a capped
; toy singularity loop. Nothing here touches a real cryptographic primitive.
; Prints a transcript to COM1 and PASS/FAIL.
main:
MOVI r13,1
; ---- LE/BE clock ----
TICK r3
ST r3,r0,@tickv
MOVI r1,@s_le
CALL @puts
LD r1,r0,@tickv
CALL @puthex
MOVI r1,0xFFFF
MOVHI r1,0xFFFF
LD r3,r0,@tickv
SUB r4,r1,r3
ST r4,r0,@revv
MOVI r1,@s_be
CALL @puts
LD r1,r0,@revv
CALL @puthex
; ---- contractive fixed point: 100 -> 50 -> ... -> 0 ----
MOVI r1,100
MOVI r2,0
fix:
CMP r1,r0
JMP[EQ] @fixdone
SHR r1,r1,1
ADD r2,r2,r13
JMP @fix
fixdone:
ST r2,r0,@fixn
MOVI r1,@s_fix
CALL @puts
LD r1,r0,@fixn
CALL @puthex
; ---- capped toy singularity: 1000 iterations, sealed state ----
MOVI r1,0x1234
MOVI r2,0
sing:
MOVI r3,1000
CMP r2,r3
JMP[GE] @singdone
MOVI r4,0x4E6D
MOVHI r4,0x41C6
MUL r1,r1,r4
MOVI r4,12345
ADD r1,r1,r4
MOVI r4,0x7FFF
BOOL.8 r1,r1,r4
ADD r2,r2,r13
JMP @sing
singdone:
ST r2,r0,@singn
ST r1,r0,@singseal
MOVI r1,@s_sing
CALL @puts
LD r1,r0,@singn
CALL @puthex
MOVI r1,@s_seal
CALL @puts
LD r1,r0,@singseal
CALL @puthex
; ---- verdict ----
LD r1,r0,@fixn
MOVI r2,7
CMP r1,r2
JMP[NE] @bad
LD r1,r0,@singn
MOVI r2,1000
CMP r1,r2
JMP[NE] @bad
MOVI r1,@s_pass
CALL @puts
HALT
bad:
MOVI r1,@s_fail
CALL @puts
HALT
; ---- scaffold strings ----
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
puthex:
MOVI r7,7
MOVI r2,8
ph1:
SHR r3,r1,28
SHL r1,r1,4
MOVI r4,48
ADD r4,r4,r3
MOVI r5,10
CMP r3,r5
ADD[GE] r4,r4,r7
PUTC r4
SUB r2,r2,r13
JMP[NE] @ph1
RET
tickv:
.word 0
revv:
.word 0
fixn:
.word 0
singn:
.word 0
singseal:
.word 0
s_le:
.str "LE="
s_be:
.str " BE="
s_fix:
.str " FIX="
s_sing:
.str " SING="
s_seal:
.str " SEAL="
s_pass:
.str " RETRO PASS\n"
s_fail:
.str " RETRO FAIL\n"
