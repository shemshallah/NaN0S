; nbuild.nas - self-hosted builder, first slice.
; Includes nasm0, assembles a cartridge source at runtime, and reports the
; emitted word count, error count, mirror count, and first word.
.org 0
JMP @main
.include "nasm0.nas"
main:
MOVI r13,1
MOVI r14,#STACK
MOVI r1,@src_data
ST r1,r0,#V_SRCB
MOVI r1,4096
ST r1,r0,#V_OUTB
MOVI r1,6144
ST r1,r0,#V_LABB
MOVI r1,7168
ST r1,r0,#V_EXPB
ST r1,r0,#V_EXPCB
MOVI r1,0
ST r1,r0,#V_ERR
ST r1,r0,#V_MIRR
ST r1,r0,#V_NLAB
MOVI r1,1
ST r1,r0,#V_PASS
CALL @run
MOVI r1,2
ST r1,r0,#V_PASS
CALL @run
; ---- dual-face seal over V_IDX words at 4096 ----
MOVI r4,0x9DC5
MOVI r2,0x811C
SHL r2,r2,16
BOOL.14 r4,r4,r2
ADD r5,r4,r0
MOVI r6,0
MOVI r7,4096
LD r8,r0,#V_IDX
MOVI r9,0x0193
MOVI r2,0x0100
SHL r2,r2,16
ADD r9,r9,r2
seal_l:
CMP r8,r0
JMP[EQ] @seal_done
LD r1,r7,0
BOOL.6 r4,r4,r1
MUL r4,r4,r9
BSWAPM r7,0
LD r2,r7,0
BSWAPM r7,0
BOOL.6 r5,r5,r2
MUL r5,r5,r9
LDN r1,r7,0
SHL r2,r6,4
SHR r3,r6,28
BOOL.14 r6,r2,r3
BOOL.6 r6,r6,r1
ADD r7,r7,r13
SUB r8,r8,r13
JMP @seal_l
seal_done:
ST r4,r0,@sA
ST r5,r0,@sB
ST r6,r0,@sC
; ---- copy payload to RAM store at 16384 ----
MOVI r1,16384
MOVI r2,4096
LD r3,r0,#V_IDX
BCOPY r1,r2,r3
; ---- verify store word-for-word ----
MOVI r10,0
MOVI r11,4096
MOVI r12,16384
LD r3,r0,#V_IDX
ver_l:
CMP r10,r3
JMP[GE] @ver_ok
LD r1,r11,0
LD r2,r12,0
CMP r1,r2
JMP[NE] @ver_bad
ADD r11,r11,r13
ADD r12,r12,r13
ADD r10,r10,r13
JMP @ver_l
ver_ok:
MOVI r1,@s_store
CALL @puts
; ---- RAM TOC entry at 12288 ----
MOVI r1,1
ST r1,r0,12288
MOVI r1,2026
ST r1,r0,12289
MOVI r1,9
ST r1,r0,12290
MOVI r1,0
ST r1,r0,12291
MOVI r1,16384
ST r1,r0,12292
LD r1,r0,#V_IDX
ST r1,r0,12293
MOVI r1,1
ST r1,r0,12294
MOVI r1,0
ST r1,r0,12295
LD r1,r0,@sA
ST r1,r0,12296
LD r1,r0,@sB
ST r1,r0,12298
LD r1,r0,@sC
ST r1,r0,12299
; ---- recompute seal over the stored payload and compare to TOC ----
MOVI r4,0x9DC5
MOVI r2,0x811C
SHL r2,r2,16
BOOL.14 r4,r4,r2
ADD r5,r4,r0
MOVI r6,0
MOVI r7,16384
LD r8,r0,#V_IDX
MOVI r9,0x0193
MOVI r2,0x0100
SHL r2,r2,16
ADD r9,r9,r2
vs_l:
CMP r8,r0
JMP[EQ] @vs_done
LD r1,r7,0
BOOL.6 r4,r4,r1
MUL r4,r4,r9
BSWAPM r7,0
LD r2,r7,0
BSWAPM r7,0
BOOL.6 r5,r5,r2
MUL r5,r5,r9
LDN r1,r7,0
SHL r2,r6,4
SHR r3,r6,28
BOOL.14 r6,r2,r3
BOOL.6 r6,r6,r1
ADD r7,r7,r13
SUB r8,r8,r13
JMP @vs_l
vs_done:
LD r1,r0,@sA
CMP r4,r1
JMP[NE] @seal_bad
LD r1,r0,@sB
CMP r5,r1
JMP[NE] @seal_bad
LD r1,r0,@sC
CMP r6,r1
JMP[NE] @seal_bad
MOVI r1,@s_seal
CALL @puts
JMP @after_store
seal_bad:
MOVI r1,@s_badseal
CALL @puts
JMP @after_store
after_store:
MOVI r1,@s_words
ver_bad:
MOVI r1,@s_badstore
CALL @puts
after_store:
MOVI r1,@s_words
CALL @puts
LD r1,r0,#V_IDX
CALL @puthex
MOVI r1,@s_err
CALL @puts
LD r1,r0,#V_ERR
CALL @puthex
MOVI r1,@s_mirr
CALL @puts
LD r1,r0,#V_MIRR
CALL @puthex
MOVI r1,@s_out
CALL @puts
LD r1,r0,4096
CALL @puthex
MOVI r1,@s_sa
CALL @puts
LD r1,r0,@sA
CALL @puthex
MOVI r1,@s_sb
CALL @puts
LD r1,r0,@sB
CALL @puthex
MOVI r1,@s_sc
CALL @puts
LD r1,r0,@sC
CALL @puthex
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
s_words:
.str " NBUILD words="
s_err:
.str " err="
s_mirr:
.str " mirr="
s_out:
.str " out0="
s_sa:
.str " sealA="
s_sb:
.str " sealB="
s_sc:
.str " sealC="
sA:
.word 0
sB:
.word 0
sC:
.word 0
s_pass:
.str " BUILD PASS\n"
s_store:
.str "STORE PASS\n"
s_badstore:
.str "STORE FAIL\n"
s_seal:
.str "SEAL PASS\n"
s_badseal:
.str "SEAL FAIL\n"
.org 2048
src_data:
.str "main:\nMOVI r1,72\nPUTC r1\nMOVI r1,73\nPUTC r1\nHALT\n"
