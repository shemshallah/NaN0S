;  n16i_nest.nas - n16i running a second copy of n16i (labels renamed ni_ -> nj_) running a small guest.
; mode (patched by tools/ngate_n16i.sh): 0 = inner guest natively, 1 = under one n16i (outer copy native), 2 = under two n16i.
JMP @drv
.include "../tools/n16i.nas"
drv:
  MOVI r13,1
  LD r1,r0,@mode
  CMP r1,r0
  JMP[NE] @drv1
  JMP @ig_main
drv1:
  MOVI r2,1
  CMP r1,r2
  JMP[EQ] @gmain
  MOVI r1,@gmain
  MOVI r2,8192
  MOVI r3,8191
  CALL @n16i_run
  ST r1,r0,@res_steps
  HALT
mode:
.word 0
res_steps:
.word 0
.org 8192
gmain:
  MOVI r13,1
  MOVI r1,@ig_main
  MOVI r2,10240
  MOVI r3,2047
  CALL @n16j_run
  ST r1,r0,@res_in
  HALT
res_in:
.word 0

n16j_run:
  ST r15,r0,@nj_lnk
  ST r2,r0,@nj_gb
  ST r3,r0,@nj_mask
  ADD r12,r1,r0
  ADD r10,r2,r0
  MOVI r11,0
  ST r0,r0,@nj_steps
  MOVI r5,0
nj_z:
  ST r0,r5,@nj_regs
  ADD r5,r5,r13
  MOVI r4,16
  CMP r5,r4
  JMP[LT] @nj_z
nj_loop:
  LD r1,r0,@nj_mask
  BOOL.8 r1,r12,r1
  ADD r1,r1,r10
  ADD r12,r12,r13
  MOVI r4,65535
  BOOL.8 r12,r12,r4
  LD r4,r0,@nj_steps
  ADD r4,r4,r13
  ST r4,r0,@nj_steps
  LDN r2,r1,0
  MOVI r4,16
  CMP r2,r4
  JMP[GE] @nj_trapg
  LD r3,r1,0
  SHR r4,r3,24
  MOVI r5,255
  CMP r4,r5
  JMP[EQ] @nj_halt
  MOVI r5,67
  CMP r4,r5
  JMP[GT] @nj_trapo
  CMP r4,r0
  JMP[EQ] @nj_dec
  LD r5,r11,@nj_bit
  BOOL.8 r5,r5,r2
  CMP r5,r0
  JMP[EQ] @nj_loop
nj_dec:
  SHR r5,r3,20
  MOVI r6,15
  BOOL.8 r5,r5,r6
  SHR r6,r3,16
  MOVI r7,15
  BOOL.8 r6,r6,r7
  MOVI r7,65535
  BOOL.8 r7,r3,r7
  MOVI r8,15
  BOOL.8 r9,r7,r8
  LD r8,r6,@nj_regs
  LD r9,r9,@nj_regs
  LD r14,r4,@nj_optab
  JMPR r14
nj_t_st:
  ST r4,r5,@nj_regs
  JMP @nj_loop
nj_t_fk:
  MOVI[GT] r11,0
  MOVI[LT] r11,1
  MOVI[EQ] r11,2
  MOVI.8 r11,3
  JMP @nj_loop
nj_t_stf:
  MOVI[GT] r11,0
  MOVI[LT] r11,1
  MOVI[EQ] r11,2
  MOVI.8 r11,3
  ST r4,r5,@nj_regs
  JMP @nj_loop
nj_halt:
  LD r1,r0,@nj_steps
  LD r15,r0,@nj_lnk
  RET
nj_trapg:
  MOVI r1,33
  PUTC r1
  MOVI r1,71
  PUTC r1
  CALL @nj_hex4
  JMP @nj_halt
nj_trapo:
nj_h_bad:
  MOVI r1,33
  PUTC r1
  MOVI r1,79
  PUTC r1
  CALL @nj_hex4
  JMP @nj_halt
nj_hex4:
  ST r15,r0,@nj_hlnk
  SHR r1,r12,12
  MOVI r2,15
  BOOL.8 r1,r1,r2
  CALL @nj_hd
  SHR r1,r12,8
  BOOL.8 r1,r1,r2
  CALL @nj_hd
  SHR r1,r12,4
  BOOL.8 r1,r1,r2
  CALL @nj_hd
  BOOL.8 r1,r12,r2
  CALL @nj_hd
  LD r15,r0,@nj_hlnk
  RET
nj_hd:
  MOVI r3,10
  CMP r1,r3
  JMP[LT] @nj_hd_n
  MOVI r3,55
  ADD r1,r1,r3
  PUTC r1
  RET
nj_hd_n:
  MOVI r3,48
  ADD r1,r1,r3
  PUTC r1
  RET
nj_ea:
  ADD r14,r8,r7
  LD r1,r0,@nj_mask
  BOOL.8 r14,r14,r1
  ADD r14,r14,r10
  RET
nj_ea0:
  LD r1,r0,@nj_mask
  BOOL.8 r14,r8,r1
  ADD r14,r14,r10
  RET
nj_h_bool:
  MOVI r4,0
  MOVI r14,1
  BOOL.8 r14,r2,r14
  CMP r14,r0
  JMP[EQ] @nj_b2
  BOOL.1 r1,r8,r9
  BOOL.14 r4,r4,r1
nj_b2:
  MOVI r14,2
  BOOL.8 r14,r2,r14
  CMP r14,r0
  JMP[EQ] @nj_b3
  BOOL.2 r1,r8,r9
  BOOL.14 r4,r4,r1
nj_b3:
  MOVI r14,4
  BOOL.8 r14,r2,r14
  CMP r14,r0
  JMP[EQ] @nj_b4
  BOOL.4 r1,r8,r9
  BOOL.14 r4,r4,r1
nj_b4:
  MOVI r14,8
  BOOL.8 r14,r2,r14
  CMP r14,r0
  JMP[EQ] @nj_b5
  BOOL.8 r1,r8,r9
  BOOL.14 r4,r4,r1
nj_b5:
  CMP r4,r0
  JMP @nj_t_stf
nj_h_movi:
  ADD r4,r7,r0
  JMP @nj_t_st
nj_h_movhi:
  LD r4,r5,@nj_regs
  MOVI r14,65535
  BOOL.8 r4,r4,r14
  SHL r14,r7,16
  BOOL.14 r4,r4,r14
  JMP @nj_t_st
nj_h_add:
  ADD r4,r8,r9
  JMP @nj_t_stf
nj_h_sub:
  SUB r4,r8,r9
  JMP @nj_t_stf
nj_h_shl:
  MOVI r14,31
  BOOL.8 r14,r7,r14
  LD r14,r14,@nj_pow2
  MUL r4,r8,r14
  JMP @nj_t_stf
nj_h_shr:
  MOVI r14,31
  BOOL.8 r14,r7,r14
  LD r14,r14,@nj_pow2
  DIVU r4,r8,r14
  JMP @nj_t_stf
nj_h_cmp:
  CMP r8,r9
  JMP @nj_t_fk
nj_h_ld:
  CALL @nj_ea
  LD r4,r14,0
  JMP @nj_t_st
nj_h_st:
  CALL @nj_ea
  LD r4,r5,@nj_regs
  ST r4,r14,0
  JMP @nj_loop
nj_h_jmp:
  ADD r12,r7,r0
  JMP @nj_loop
nj_h_call:
  MOVI r14,15
  ST r12,r14,@nj_regs
  ADD r12,r7,r0
  JMP @nj_loop
nj_h_ret:
  MOVI r14,15
  LD r12,r14,@nj_regs
  MOVI r14,65535
  BOOL.8 r12,r12,r14
  JMP @nj_loop
nj_h_jmpr:
  MOVI r14,65535
  BOOL.8 r12,r8,r14
  JMP @nj_loop
nj_h_nop:
  JMP @nj_loop
nj_h_vpoke:
  LD r4,r5,@nj_regs
  VPOKE r4,r8
  JMP @nj_loop
nj_h_vpeek:
  VPEEK r4,r8
  JMP @nj_t_st
nj_h_key:
  KEY r4
  JMP @nj_t_st
nj_h_tick:
  LD r4,r0,@nj_steps
  MOVI r14,1000
  DIVU r4,r4,r14
  JMP @nj_t_st
nj_h_bswapm:
  CALL @nj_ea
  BSWAPM r14,0
  JMP @nj_loop
nj_h_putc:
  LD r4,r5,@nj_regs
  PUTC r4
  JMP @nj_loop
nj_h_stw:
  CALL @nj_ea0
  LD r4,r5,@nj_regs
  STW r4,r14,r9
  JMP @nj_loop
nj_h_ldn:
  CALL @nj_ea
  LDN r4,r14,0
  JMP @nj_t_st
nj_h_dispq:
  DISPQ r4
  JMP @nj_t_st
nj_h_dispset:
  LD r4,r5,@nj_regs
  DISPSET r4
  JMP @nj_loop
nj_h_keyq:
  KEYQ r4
  JMP @nj_t_st
nj_h_beep:
  LD r4,r5,@nj_regs
  BEEP r4
  JMP @nj_loop
nj_h_mul:
  MUL r4,r8,r9
  JMP @nj_t_stf
nj_h_mulh:
  MULH r4,r8,r9
  JMP @nj_t_stf
nj_h_mulhu:
  MULHU r4,r8,r9
  JMP @nj_t_stf
nj_h_div:
  DIV r4,r8,r9
  JMP @nj_t_stf
nj_h_mod:
  MOD r4,r8,r9
  JMP @nj_t_stf
nj_h_divu:
  DIVU r4,r8,r9
  JMP @nj_t_stf
nj_h_modu:
  MODU r4,r8,r9
  JMP @nj_t_stf
nj_h_sar:
  MOVI r14,31
  BOOL.8 r14,r7,r14
  LD r14,r14,@nj_pow2
  SHR r2,r8,31
  CMP r2,r0
  JMP[NE] @nj_sar_n
  DIVU r4,r8,r14
  JMP @nj_sar_f
nj_sar_n:
  BOOL.3 r2,r8,r8
  DIVU r2,r2,r14
  BOOL.3 r4,r2,r2
nj_sar_f:
  CMP r4,r0
  JMP @nj_t_stf
nj_h_cmps:
  CMPS r8,r9
  JMP @nj_t_fk
nj_h_addi:
  MOVI r14,32768
  BOOL.8 r14,r7,r14
  CMP r14,r0
  JMP[EQ] @nj_ai
  MOVHI r7,65535
nj_ai:
  ADD r4,r8,r7
  JMP @nj_t_stf
nj_h_ldb:
  ADD r14,r8,r7
  SHR r2,r14,2
  LD r1,r0,@nj_mask
  BOOL.8 r2,r2,r1
  ADD r2,r2,r10
  LD r3,r2,0
  MOVI r1,3
  BOOL.8 r1,r14,r1
  LD r1,r1,@nj_bpow
  DIVU r4,r3,r1
  MOVI r14,255
  BOOL.8 r4,r4,r14
  JMP @nj_t_st
nj_h_stb:
  ADD r14,r8,r7
  SHR r2,r14,2
  LD r1,r0,@nj_mask
  BOOL.8 r2,r2,r1
  ADD r2,r2,r10
  MOVI r1,3
  BOOL.8 r1,r14,r1
  LD r1,r1,@nj_bpow
  LD r3,r2,0
  MOVI r4,255
  MUL r4,r4,r1
  BOOL.4 r3,r3,r4
  LD r4,r5,@nj_regs
  MOVI r14,255
  BOOL.8 r4,r4,r14
  MUL r4,r4,r1
  BOOL.14 r3,r3,r4
  ST r3,r2,0
  JMP @nj_loop
nj_h_callr:
  MOVI r14,15
  ST r12,r14,@nj_regs
  MOVI r14,65535
  BOOL.8 r12,r8,r14
  JMP @nj_loop
nj_h_bcopy:
  LD r1,r5,@nj_regs
  CMP r9,r0
  JMP[EQ] @nj_loop
  CMP r1,r8
  JMP[GT] @nj_bc_back
  MOVI r2,0
nj_bc_f:
  ADD r3,r8,r2
  ADD r4,r1,r2
  CALL @nj_cp1
  ADD r2,r2,r13
  CMP r2,r9
  JMP[LT] @nj_bc_f
  JMP @nj_loop
nj_bc_back:
  ADD r2,r9,r0
nj_bc_b:
  SUB r2,r2,r13
  ADD r3,r8,r2
  ADD r4,r1,r2
  CALL @nj_cp1
  CMP r2,r0
  JMP[NE] @nj_bc_b
  JMP @nj_loop
nj_cp1:
  LD r14,r0,@nj_mask
  BOOL.8 r3,r3,r14
  ADD r3,r3,r10
  BOOL.8 r4,r4,r14
  ADD r4,r4,r10
  LDN r14,r3,0
  LD r3,r3,0
  STW r3,r4,r14
  RET
nj_h_bfill:
  LD r1,r5,@nj_regs
  MOVI r2,0
  CMP r9,r0
  JMP[EQ] @nj_loop
nj_bf:
  ADD r4,r1,r2
  LD r14,r0,@nj_mask
  BOOL.8 r4,r4,r14
  ADD r4,r4,r10
  ST r8,r4,0
  ADD r2,r2,r13
  CMP r2,r9
  JMP[LT] @nj_bf
  JMP @nj_loop
nj_h_fadd:
  FADD r4,r8,r9
  JMP @nj_t_stf
nj_h_fsub:
  FSUB r4,r8,r9
  JMP @nj_t_stf
nj_h_fmul:
  FMUL r4,r8,r9
  JMP @nj_t_stf
nj_h_fdiv:
  FDIV r4,r8,r9
  JMP @nj_t_stf
nj_h_fsqrt:
  FSQRT r4,r8
  JMP @nj_t_stf
nj_h_fcmp:
  FCMP r8,r9
  JMP @nj_t_fk
nj_h_cvtif:
  CVTIF r4,r8
  JMP @nj_t_stf
nj_h_cvtfi:
  CVTFI r4,r8
  JMP @nj_t_stf
nj_h_nop2:
  JMP @nj_loop
nj_h_fbinfo:
  FBINFO r4
  JMP @nj_t_st
nj_h_vsync:
  VSYNC
  JMP @nj_loop
nj_h_fbcopy:
  LD r4,r5,@nj_regs
  FBCOPY r4,r8,r9
  JMP @nj_loop
nj_h_fbfill:
  LD r4,r5,@nj_regs
  FBFILL r4,r8,r9
  JMP @nj_loop
nj_h_outb:
  LD r4,r5,@nj_regs
  OUTB r4,r8
  JMP @nj_loop
nj_h_inb:
  INB r4,r8
  JMP @nj_t_st
nj_h_inw:
  INW r4,r8
  JMP @nj_t_st
nj_h_outw:
  LD r4,r5,@nj_regs
  OUTW r4,r8
  JMP @nj_loop
nj_h_outsw:
  LD r4,r5,@nj_regs
  OUTSW r4,r8,r9
  JMP @nj_loop
nj_h_outl:
  LD r4,r5,@nj_regs
  OUTL r4,r8
  JMP @nj_loop
nj_lnk:
.word 0
nj_hlnk:
.word 0
nj_gb:
.word 0
nj_mask:
.word 0
nj_steps:
.word 0
nj_regs:
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
nj_bit:
.word 1,2,4,8
nj_bpow:
.word 1,256,65536,16777216
nj_pow2:
.word 1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768
.word 65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432,67108864,134217728,268435456,536870912,1073741824,2147483648
nj_optab:
.word @nj_h_bool,@nj_h_movi,@nj_h_movhi,@nj_h_add,@nj_h_sub,@nj_h_shl,@nj_h_shr,@nj_h_cmp
.word @nj_h_ld,@nj_h_st,@nj_h_jmp,@nj_h_call,@nj_h_ret,@nj_h_jmpr,@nj_h_bad,@nj_h_nop
.word @nj_h_vpoke,@nj_h_vpeek,@nj_h_key,@nj_h_tick,@nj_h_bswapm,@nj_h_putc,@nj_h_stw,@nj_h_ldn
.word @nj_h_dispq,@nj_h_dispset,@nj_h_keyq,@nj_h_beep,@nj_h_bad,@nj_h_bad,@nj_h_bad,@nj_h_bad
.word @nj_h_mul,@nj_h_mulh,@nj_h_mulhu,@nj_h_div,@nj_h_mod,@nj_h_divu,@nj_h_modu,@nj_h_sar
.word @nj_h_cmps,@nj_h_addi,@nj_h_ldb,@nj_h_stb,@nj_h_callr,@nj_h_bcopy,@nj_h_bfill,@nj_h_nop2
.word @nj_h_fadd,@nj_h_fsub,@nj_h_fmul,@nj_h_fdiv,@nj_h_fsqrt,@nj_h_fcmp,@nj_h_cvtif,@nj_h_cvtfi
.word @nj_h_jmp,@nj_h_call,@nj_h_fbinfo,@nj_h_vsync,@nj_h_fbcopy,@nj_h_fbfill,@nj_h_outb,@nj_h_inb
.word @nj_h_inw,@nj_h_outw,@nj_h_outsw,@nj_h_outl

.org 10240
ig_main:
  MOVI r13,1
  MOVI r1,@ig_s
ig_p:
  LD r2,r1,0
  CMP r2,r0
  JMP[EQ] @ig_d
  PUTC r2
  ADD r1,r1,r13
  JMP @ig_p
ig_d:
  MOVI r1,1
  MOVI r3,0
ig_l:
  MUL r4,r1,r1
  ADD r3,r3,r4
  ADD r1,r1,r13
  MOVI r4,101
  CMP r1,r4
  JMP[LT] @ig_l
  CALL @ig_h
  MOVI r4,1000
  DIVU r3,r3,r4
  CALL @ig_h
  HALT
ig_h:
  ADD r10,r3,r0
  MOVI r9,8
ig_h1:
  SHR r7,r10,28
  MOVI r8,10
  CMP r7,r8
  JMP[LT] @ig_hd
  MOVI r8,55
  JMP @ig_hp
ig_hd:
  MOVI r8,48
ig_hp:
  ADD r7,r7,r8
  PUTC r7
  SHL r10,r10,4
  SUB r9,r9,r13
  CMP r9,r0
  JMP[NE] @ig_h1
  MOVI r7,10
  PUTC r7
  RET
ig_s:
.word 78,97,78,49,54,32,105,110,32,78,97,78,49,54,32,105,110,32,78,97,78,49,54,58,32,115,117,109,32,111,102,32,115,113,117,97,114,101,115,32,49,46,46,49,48,48,32,61,32,48,120,53,50,57,65,69,10,0
