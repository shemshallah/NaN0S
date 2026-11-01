; a64.nas - AArch64 backend slice. Fixed 32-bit little-endian instructions.
a64_emit_nop:
  MOVI r1,0x201F
  MOVHI r1,0xD503
  JMP @common_emit32
a64_emit_ret:
  MOVI r1,0x03C0
  MOVHI r1,0xD65F
  JMP @common_emit32
; r3 = register number 0..30
a64_emit_br:
  MOVI r1,0x0000
  MOVHI r1,0xD61F
  MOVI r4,5
  MUL r3,r3,r4
  BOOL.14 r1,r1,r3
  JMP @common_emit32
; r1 = imm16, r3 = Rd, r4 = shift (0,16,32,48)
a64_emit_movz:
  ST r15,r0,@am_ret
  ST r1,r0,@am_imm
  ST r3,r0,@am_rd
  ST r4,r0,@am_sh
  MOVI r1,0x0000
  MOVHI r1,0xD280
  LD r5,r0,@am_imm
  SHL r5,r5,5
  BOOL.14 r1,r1,r5
  LD r5,r0,@am_sh
  SHR r5,r5,4
  SHL r5,r5,21
  BOOL.14 r1,r1,r5
  LD r5,r0,@am_rd
  BOOL.14 r1,r1,r5
  CALL @common_emit32
  LD r15,r0,@am_ret
  RET
am_ret:
.word 0
am_imm:
.word 0
am_rd:
.word 0
am_sh:
.word 0
; r3 = Rd, r4 = Rn, r5 = Rm
a64_emit_add:
  ST r15,r0,@aa_ret
  MOVI r1,0x0000
  MOVHI r1,0x8B00
  SHL r6,r5,16
  BOOL.14 r1,r1,r6
  SHL r6,r4,5
  BOOL.14 r1,r1,r6
  BOOL.14 r1,r1,r3
  CALL @common_emit32
  LD r15,r0,@aa_ret
  RET
aa_ret:
.word 0
; r1 = imm16
a64_emit_svc:
  ST r15,r0,@as_ret
  MOVI r6,0x0001
  MOVHI r6,0xD400
  SHL r1,r1,5
  BOOL.14 r6,r6,r1
  ADD r1,r6,r0
  CALL @common_emit32
  LD r15,r0,@as_ret
  RET
as_ret:
.word 0
