; nrun_test.nas - r29 mandate leg: the raw-NaN "runbig" replacement.
; ONE guest image does the whole scaffold chain with NO scaffold code:
;   (1) pack a mini .nas source (4 chars/word; the .str block below IS the packing),
;   (2) assemble it with the guest's own nasm0 (two passes, same run as the mkproof harness),
;   (3) RUN the emitted words under n16i.nas (the in-NaN NaN16 interpreter).
; The outer scaffold (nanchk.py + runbig.py) only loads THIS file into the model - it adds no logic.
; Expected output: "Hi" + newline, then "RUN PASS". steps>0 asserted before PASS.
JMP @nd_main
.include "../tools/n16i.nas"
.include "../prog/nasm0.nas"
; ---- self-chosen layout (V_* slots 6272..6297 stay where nasm0.nas expects them)
.equ STKB 24576
.equ SRCBS 28672
.equ OUTBS 36864
.equ LABBS 49152
nd_main:
  MOVI r13,1
  MOVI r14,#STKB
  ; ---- copy the source text (packed .str words) into the SRC area for nasm0
  MOVI r5,@nd_src
  MOVI r6,#SRCBS
  MOVI r7,32             ; the .str block is <= 32 words (padded with NULs/zeros)
nd_cp:
  LD r8,r5,0
  ST r8,r6,0
  ADD r5,r5,r13
  ADD r6,r6,r13
  SUB r7,r7,r13
  CMP r7,r0
  JMP[NE] @nd_cp
  ; ---- build params for nasm0
  MOVI r1,#SRCBS
  ST r1,r0,#V_SRCB
  MOVI r1,#OUTBS
  ST r1,r0,#V_OUTB
  MOVI r1,#LABBS
  ST r1,r0,#V_LABB
  ; ---- pass 1: labels
  MOVI r2,1
  ST r2,r0,#V_PASS
  CALL @run
  ; ---- pass 2: emit to OUTBS
  MOVI r2,2
  ST r2,r0,#V_PASS
  CALL @run
  ; ---- run the emitted program under the in-NaN interpreter
  MOVI r1,0              ; guest pc 0
  MOVI r2,#OUTBS         ; GB: host word addr of guest word 0
  MOVI r3,65535          ; guest mask (16-bit window, no overlap with driver)
  CALL @n16i_run         ; returns r1 = guest steps (clobbers r2..r12!)
  ; ---- checks: guest ran (>= 8 steps) AND left its marker at OUTBS+32
  MOVI r4,8
  CMP r1,r4
  JMP[LT] @nd_fail
  MOVI r2,#OUTBS         ; r2 was clobbered by the interpreter per its ABI
  MOVI r3,32
  ADD r3,r3,r2           ; r3 = OUTBS+32
  LD r3,r3,0
  MOVI r4,4660
  CMP r3,r4
  JMP[NE] @nd_fail
  ; ---- report
  CMP r1,r0
  JMP[EQ] @nd_fail
  MOVI r1,82
  PUTC r1
  MOVI r1,85
  PUTC r1
  MOVI r1,78
  PUTC r1
  MOVI r1,32
  PUTC r1
  MOVI r1,80
  PUTC r1
  MOVI r1,65
  PUTC r1
  MOVI r1,83
  PUTC r1
  MOVI r1,83
  PUTC r1
  MOVI r1,10
  PUTC r1
  HALT
nd_fail:
  MOVI r1,82
  PUTC r1
  MOVI r1,85
  PUTC r1
  MOVI r1,78
  PUTC r1
  MOVI r1,32
  PUTC r1
  MOVI r1,70
  PUTC r1
  MOVI r1,65
  PUTC r1
  MOVI r1,73
  PUTC r1
  MOVI r1,76
  PUTC r1
  MOVI r1,10
  PUTC r1
  HALT
; ---- the guest source nasm0 will assemble (minified, no comments; NUL+pad added by scaffold .str)
nd_src:
.str "  MOVI r13,1\n  MOVI r1,72\n  PUTC r1\n  MOVI r1,73\n  PUTC r1\n  MOVI r1,10\n  PUTC r1\n  MOVI r5,4660\n  ST r5,r0,32\n  HALT\n"
