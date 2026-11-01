; disasm_test.nas - NaN16 disassembler self-test. Prints to COM1.
; Part 1 disassembles real sample code (every operand form). Part 2 forges words with
; STW over all 16 class nibbles (ADD payload, then BOOL payload) to cover every predicate.
JMP @main
.include "../tools/disasm.nas"
main:
  MOVI r13,1
  MOVI r1,@sample
  MOVI r2,22
  CALL @dis_range
  MOVI r1,3
  MOVHI r1,786
  CALL @sweep
  MOVI r1,3
  MOVHI r1,18
  CALL @sweep
  MOVI r1,@s_done
  CALL @dis_puts
  HALT
sweep:
  ST r15,r0,@sw_lnk
  MOVI r6,0
  MOVI r7,@buf
  MOVI r8,16
sw1:
  STW r1,r7,r6
  ADD r7,r7,r13
  ADD r6,r6,r13
  CMP r6,r8
  JMP[NE] @sw1
  MOVI r1,@buf
  MOVI r2,16
  CALL @dis_range
  LD r15,r0,@sw_lnk
  RET
sw_lnk:
.word 0
s_done:
.str "DISASM DONE\n"
buf:
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
sample:
BOOL.6 r1,r2,r3
MOVI r1,42
MOVHI r2,4660
ADD r3,r1,r2
SUB[EQ] r4,r5,r6
SHL r1,r2,7
CMP r1,r2
LD[NE] r1,r2,16
ST r3,r0,512
JMP[LT] 100
CALL 200
RET
JMPR r15
NOP
BSWAPM r1,5
STW r1,r2,r3
DISPSET r3
OUTB r1,r2
JMPF 3000000
MUL r1,r2,r3
VSYNC
HALT
