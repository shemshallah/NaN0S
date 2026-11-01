; n16fuzz.nas - raw-NaN differential fuzzer cartridge (replaces the retired tools/n16i_fuzz.py; the "LCG/XS generator
; cart" mandated in r29h). The window at PROGB is built IN-GUEST from a seeded xorshift32 chain:
;   [0..11]  inner preload stub (fills r0..r9,r14,r15 from INIT window words, falls through),
;   [12..71] 60-word straight-line program (generated),
;   [72..]   reg-dump stub: r0..r9, 8 hex digits each, then HALT,
;   [800..811] 12 INIT words (continued xorshift stream).
; BOTH engines execute THE IDENTICAL window: mode 1 = under n16i.nas (N seeds in one image); mode 0 = the C core runs
; the window natively via JMPR (one nan_cli invocation per seed; the gate patches V_FMODE=0 and V_SEEDC). Host side is
; sh+awk only: it appends .org/.word patches (same trick as tools/ngate_n16i.sh) and diffs the serials. Program ops are
; pure ALU+FP with d,a in 0..7 and the b register clamped into {0..9,14} (MOVI[GE] r3,14 maps 10..15 -> 14), so BOTH
; engines' preloads fill every operand (r10..r13 are engine-internal in native mode and plain guest regs under n16i -
; they are never dumped and never operands). No memory ops in the generated program: the interp masks guest LD/ST into
; the 1024-window while the native engine would reach the whole 4M-word machine, so LD/ST/STW/LDB/STB/LDN/BSWAPM/
; BCOPY/BFILL are excluded from the op table BY DESIGN (BFILL would also give an unbounded 32-bit count). The dump
; stub keeps its digit mask in r10 (safe: clobbering the engine's r10 post-preload, machine HALTs at the stub's end).
; Floats (FADD..CVTFI) pass to the SAME host float unit of the SAME C core in both engines, so any serial difference
; is a REAL divergence, never a float-model artifact.
; COMMITTED SEMANTICS OPS.md anchors this: pred n = bitmask over k=2Z+L (ALWAYS 15, EQ 4, NE 3, LT 2, GE 5, GT 1, LE 6);
; SHL/SHR/SAR count = payload low 5 bits (NOT B); STW payload=r[d] addr=r[a] nibble=r[imm&15].
.equ PROGB 65536              ; window base (1024 words, mask 1023)
.equ STKB 24576
.equ V_FMODE 6300             ; 1 = interp (one image, N seeds); 0 = native per-seed (patched by tools/ngate_fuzz.sh)
.equ V_SEEDC 6301             ; first seed / current seed (patched)
.equ V_COUNT 6302             ; seeds in interp mode (patched)
JMP @fz_main
.include "../tools/n16i.nas"
; ---- window preload stub words (copied to PROGB+0): base r10 already holds GB (interp: INNER r10=0 uses window mask!)
fz_prem:
  LD r0,r10,800
  LD r1,r10,801
  LD r2,r10,802
  LD r3,r10,803
  LD r4,r10,804
  LD r5,r10,805
  LD r6,r10,806
  LD r7,r10,807
  LD r8,r10,808
  LD r9,r10,809
  LD r14,r10,810
  LD r15,r10,811
fz_prem_end:
; ---- reg-dump stub template: hex r0..r9 + newline, then HALT (position independent, no calls)
fz_stub:
  SHR r4,r0,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r0,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r1,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r1,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r2,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r2,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r3,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r3,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r4,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r5,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r5,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r6,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r6,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r7,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r7,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r8,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r8,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  SHR r4,r9,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,4
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,8
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,12
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,16
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,20
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,24
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  SHL r4,r9,28
  SHR r4,r4,28
  MOVI r10,10
  CMP r4,r10
  ADDI[GE] r4,r4,55
  ADDI[LT] r4,r4,48
  PUTC r4
  MOVI r4,10
  PUTC r4
  HALT                         ; stops BOTH engines: interp returns to the driver; native ends nan_cli (rc 3)
fz_stub_end:
; ---- driver ------------------------------------------------------------------
fz_main:
  MOVI r13,1
  MOVI r14,#STKB
  LA r1,@fz_prem
  LA r2,#PROGB
  MOVI r3,@fz_prem_end - @fz_prem
  BCOPY r2,r1,r3               ; window[0..11] = preload stub (classes preserved by BCOPY)
  LA r1,@fz_stub
  MOVI r3,72
  ADD r2,r2,r3                 ; r2 = PROGB + 72
  MOVI r3,@fz_stub_end - @fz_stub
  BCOPY r2,r1,r3               ; window[72..] = reg-dump stub + HALT
  LD r1,r0,#V_FMODE
  MOVI r2,1
  CMP r1,r2
  JMP[EQ] @fz_loop
fz_native:
  CALL @fz_mark
  CALL @fz_build
  LA r10,#PROGB                ; preload base register (native: physical r10 = GB)
  LA r3,#PROGB
  JMPR r3                      ; C core executes window[0..] natively; HALT inside stops the machine
fz_loop:
  LD r4,r0,#V_COUNT
  LD r5,r0,#V_SEEDC
  ADD r4,r4,r5                 ; end seed = first + count
  ST r4,r0,@fz_end             ; survive across n16i_run (it clobbers r1..r12,r14,r15)
fz_l1:
  ST r5,r0,#V_SEEDC
  CALL @fz_mark
  CALL @fz_build
  MOVI r1,0
  LA r2,#PROGB
  MOVI r3,1023
  CALL @n16i_run               ; r1 = guest steps; clobbers r1..r12,r14,r15; r13 stays 1
  LD r5,r0,#V_SEEDC
  LD r4,r0,@fz_end
  ADD r5,r5,r13
  CMP r5,r4
  JMP[NE] @fz_l1
  HALT
; ---- seed marker: 'M' + 4 hex digits (low 16 bits of V_SEEDC, uppercase) + newline.
; clobbers r5,r6,r7,r8 only; every digit uses a SHR/BOOL.8/mask fold so both engines agree
fz_mark:
  MOVI r6,77
  PUTC r6
  LD r6,r0,#V_SEEDC
  MOVI r5,10
  MOVI r8,15
  SHR r7,r6,12
  BOOL.8 r7,r7,r8               ; r7 = (seed>>12)&15
  CMP r7,r5
  ADDI[GE] r7,r7,55
  ADDI[LT] r7,r7,48
  PUTC r7
  SHR r7,r6,8
  BOOL.8 r7,r7,r8
  CMP r7,r5
  ADDI[GE] r7,r7,55
  ADDI[LT] r7,r7,48
  PUTC r7
  SHR r7,r6,4
  BOOL.8 r7,r7,r8
  CMP r7,r5
  ADDI[GE] r7,r7,55
  ADDI[LT] r7,r7,48
  PUTC r7
  BOOL.8 r7,r6,r8               ; r7 = seed&15
  CMP r7,r5
  ADDI[GE] r7,r7,55
  ADDI[LT] r7,r7,48
  PUTC r7
  MOVI r6,10
  PUTC r6
  RET
; ---- window builder (cart-level, identical execution in both modes): reseeds the xorshift32
; stream and STWs 60 generated program words into window[12..71] (nibble 15, always-executable)
; and 12 INIT words into window[800..811] (nibble 10 data). Program words: op from fz_ops[sv&31],
; d = sv2&7, a = (sv2>>3)&7, b = (sv3&15) clamped to {0..9,14} -> payload op<<24|d<<20|a<<16|b.
; INIT words = raw stream values (arbitrary u32 register balloons). Clobbers everything except
; r13 (stays 1) and r15 (saved/restored via @fz_lnk).
fz_build:
  ST r15,r0,@fz_lnk
  LD r3,r0,#V_SEEDC
  ST r3,r0,@fz_xsSt             ; stream state = seed
  LA r8,@fz_ops                 ; op table base
  LA r2,#PROGB                  ; word address of window[0]
  MOVI r3,12
  ADD r2,r2,r3                  ; STW target = window[12] (machine word PROGB+12)
  MOVI r7,0                     ; k = 0
  MOVI r14,60                   ; program-word boundary
  MOVI r9,15                    ; nibble for generated code words
fzb_1:
  CALL @fz_xs                   ; r4 = s0; clobbers r3,r4 only
  SHL r3,r4,27
  SHR r3,r3,27                  ; r3 = s0 & 31 (op index)
  ADD r3,r3,r8
  LD r4,r3,0                    ; r4 = op
  SHL r4,r4,24                  ; r4 = op<<24
  ADD r6,r4,r0                  ; r6 = payload so far
  CALL @fz_xs                   ; r4 = s1 (d,a)
  SHL r3,r4,29
  SHR r3,r3,29                  ; r3 = s1 & 7 (d)
  SHL r3,r3,20                  ; d<<20
  BOOL.6 r6,r6,r3               ; xor-merge (fields disjoint)
  SHR r4,r4,3
  SHL r3,r4,29
  SHR r3,r3,29                  ; r3 = (s1>>3)&7 (a)
  SHL r3,r3,16                  ; a<<16
  BOOL.6 r6,r6,r3
  CALL @fz_xs                   ; r4 = s2 (b)
  SHL r3,r4,28
  SHR r3,r3,28                  ; r3 = s2 & 15
  MOVI r5,10
  CMP r3,r5
  MOVI[GE] r3,14                ; clamp: 10..15 -> 14 (keeps r10..r13/r15 out as operands)
  BOOL.6 r6,r6,r3              ; payload complete
  STW r6,r2,r9                  ; mem[r2] = word(r6, nibble r9&15)
  ADD r2,r2,r13
  ADD r7,r7,r13
  CMP r7,r14
  JMP[NE] @fzb_1
  MOVI r9,10                    ; INIT = class-10 data words
  LA r2,#PROGB
  MOVI r3,800
  ADD r2,r2,r3                  ; target = window[800]
fzb_2:
  CALL @fz_xs
  ADD r6,r4,r0                  ; INIT value = raw stream word
  STW r6,r2,r9
  ADD r2,r2,r13
  ADD r7,r7,r13                 ; k = 60..71
  MOVI r3,72
  CMP r7,r3
  JMP[NE] @fzb_2
  LD r15,r0,@fz_lnk
  RET
; xorshift32 leaf: x ^= x<<13; x ^= x>>17; x ^= x<<5 (SHR/SHL native counts; BOOL.6 = A^B - the truth
; table is the NIBBLE: 6 = 0b0110 = XOR, 14 = 0b1110 would be OR and degenerates the stream to FFFF)
fz_xs:
  ST r15,r0,@fx_lnk
  LD r4,r0,@fz_xsSt
  SHL r3,r4,13
  BOOL.6 r4,r4,r3
  SHR r3,r4,17
  BOOL.6 r4,r4,r3
  SHL r3,r4,5
  BOOL.6 r4,r4,r3
  ST r4,r0,@fz_xsSt
  LD r15,r0,@fx_lnk
  RET
fz_end:
.word 0
fx_lnk:
.word 0
fz_lnk:
.word 0
fz_xsSt:
.word 0
; 32-entry op table, indexed by (stream&31). Pure ALU+FP, ALL unconditional under nibble 15:
; ADD/SUB/SHL/SHR/CMP, MUL/MULH/MULHU/DIV/MOD/DIVU/MODU/SAR/CMPS/ADDI, MOVI/MOVHI,
; FADD..CVTFI (0x37 included), NOP filler. NO mem ops (see header), NO BOOL (its nibble is its
; truth table - can't be "plain"), NO BCOPY/BFILL (unbounded counts / engine-internal masks).
fz_ops:
.word 3,4,5,6,7,32,33,34,35,36,37,38,39,40,41,1,2,48,49,50,51,52,53,54,55,15,15,15,15,15,15,15
; ---- gate-visible mode slots (defaults make a bare tools/nrun.sh run the interp pass)
.org 6300
fz_fmode:
.word 1
fz_seedc:
.word 41
fz_count:
.word 32
