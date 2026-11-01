; nasm1 — x86 emitter written in NaN16 (round 16). Two-pass, branch-relaxing, flat byte output.
; Input: x86 source text (4 chars/word LE, NUL-terminated) at SRC. Output: raw bytes at OUT.
; stdout: 'Y' or 'N' (errors), newline, then the emitted bytes via PUTC.
; Language: see spec/NANASM1_SPEC.md. Registers EAX..EDI AX..DI AL..BH XMM0-7 CR0 CR2 CR3 ES..GS.
; Operands: $expr | [disp+REG*scale] | @label | REG.  Directives: .byte .word .long .str .equ
; .org .align .base .code16 .code32
.equ SRC 0x20000
.equ OUT 0x24000
.equ LAB 0x30000
.equ LONGB 0x31000
.equ STACK 0x3F000
.equ V_PASS 0x4000
.equ V_PC 0x4001
.equ V_BASE 0x4002
.equ V_ERR 0x4003
.equ V_NLAB 0x4004
.equ V_REDO 0x4005
.equ V_BRN 0x4006
.equ V_MODE 0x4007
.equ V_SRCP 0x4008
.equ V_CW 0x4009
.equ V_CN 0x400A
.equ V_PB 0x400B
.equ V_OBP 0x400C
.equ V_SRCB 0x400D
.equ V_OUTB 0x400E
.equ V_LABB 0x400F
.equ V_LONGB 0x4010
.equ V_ACC 0x4011
.equ V_SGN 0x4012
.equ V_H 0x4013
.equ V_SZ 0x4014
.equ V_OPN 0x4015
.equ V_AUX0 0x4016
.equ V_MB 0x4017
.equ V_MI 0x4018
.equ V_MS 0x4019
.equ V_MD 0x401A
.equ V_MR 0x401B
.equ V_BT 0x401C
.equ V_BS 0x401D
.equ V_BL 0x401E
.equ V_BLN 0x401F
.equ V_TMP 0x4020
.equ V_TMPX 0x4021
.equ V_AUX1 0x4022
.equ V_AUX2 0x4023
.equ OPBASE 0x4030
_start:
  MOVI r0,0
  MOVI r13,1
  MOVI r14,0xF000
  MOVHI r14,0x0003
  ST r0,r0,#V_BASE
  ST r0,r0,#V_ERR
  ST r0,r0,#V_NLAB
  MOVI r4,1
  ST r4,r0,#V_MODE
  MOVI r4,0x0000
  MOVHI r4,0x0002
  ST r4,r0,#V_SRCB
  MOVI r4,0x4000
  MOVHI r4,0x0002
  ST r4,r0,#V_OUTB
  MOVI r4,0x0000
  MOVHI r4,0x0003
  ST r4,r0,#V_LABB
  MOVI r4,0x1000
  MOVHI r4,0x0003
  ST r4,r0,#V_LONGB
  CALL @pass1
  CALL @pass1
iter:
  CALL @pass1
  LD r4,r0,#V_REDO
  CMP r4,r0
  JMP[NE] @iter
  CALL @pass2
  LD r1,r0,#V_ERR
  MOVI r2,89
  CMP r1,r0
  MOVI[NE] r2,78
  PUTC r2
  MOVI r1,10
  PUTC r1
  LD r3,r0,#V_OUTB
  SHL r3,r3,2
  LD r4,r0,#V_PC
dump:
  CMP r4,r0
  JMP[EQ] @halt
  LDB r1,r3,0
  PUTC r1
  ADDI r3,r3,1
  SUB r4,r4,r13
  JMP @dump
halt:
  HALT
pass1:
  ST r13,r0,#V_PASS
  JMP @pass
pass2:
  MOVI r4,2
  ST r4,r0,#V_PASS
  LD r2,r0,#V_OUTB
  SHL r2,r2,2
  ST r2,r0,#V_OBP
pass:
  ST r0,r0,#V_PC
  ST r0,r0,#V_CN
  ST r0,r0,#V_PB
  ST r0,r0,#V_BRN
  ST r0,r0,#V_REDO
  LD r2,r0,#V_SRCB
  ST r2,r0,#V_SRCP
run:
  ST r15,r14,0
  ADD r14,r14,r13
pl:
  CALL @nextc
  CMP r1,r0
  JMP[EQ] @pdone
  MOVI r4,10
  CMP r1,r4
  JMP[EQ] @pl
  MOVI r4,59
  CMP r1,r4
  JMP[EQ] @pskip
  JMP @pstmt
pstmt:
  MOVI r4,46
  CMP r1,r4
  JMP[EQ] @pdir
  CALL @rdhash1
  CALL @getc
  MOVI r4,58
  CMP r1,r4
  JMP[EQ] @plabel
  CALL @ungetc
  CALL @do_ins
  JMP @pl
pskip:
  CALL @skipline
  JMP @pl
plabel:
  LD r2,r0,#V_BASE
  LD r3,r0,#V_PC
  ADD r8,r2,r3
  CALL @define
  CALL @nextc
pl_ws:
  MOVI r4,32
  CMP r1,r4
  JMP[NE] @pl_chk
  CALL @nextc
  JMP @pl_ws
pl_chk:
  CMP r1,r0
  JMP[EQ] @pl_done
  MOVI r4,10
  CMP r1,r4
  JMP[EQ] @pl_done
  JMP @pstmt
pl_done:
  CALL @ungetc
  JMP @pskip
pdir:
  CALL @rdhash
  MOVI r6,@dirs
  MOVI r7,3
  CALL @look
  CMP r1,r0
  JMP[EQ] @perr
  LD r12,r1,1
  JMPR r12
perr:
  CALL @bump_err
  JMP @pskip
pdone:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
do_ins:
  MOVI r6,@mnem
  MOVI r7,3
  CALL @look
  CMP r1,r0
  JMP[EQ] @di_err
  LD r12,r1,1
  LD r2,r1,2
  ST r2,r0,#V_AUX0
  ST r0,r0,#V_SZ
  ST r0,r0,#V_OPN
  CALL @nextc
  CMP r1,r0
  JMP[EQ] @di_go
  MOVI r4,10
  CMP r1,r4
  JMP[EQ] @di_nl
  MOVI r4,59
  CMP r1,r4
  JMP[EQ] @di_nl
  CALL @ungetc
  JMP @di_op
di_nl:
  CALL @ungetc
  JMP @di_go
di_op:
  CALL @parseop
  LD r4,r0,#V_OPN
  ADD r4,r4,r13
  ST r4,r0,#V_OPN
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @di_op
  CALL @ungetc
di_go:
  JMPR r12
di_err:
  CALL @bump_err
endins:
  CALL @skipline
  JMP @pl
parseop:
  ST r15,r14,0
  ADD r14,r14,r13
  CALL @nextc
  MOVI r4,37
  CMP r1,r4
  JMP[NE] @op_np
  CALL @nextc
op_np:
  MOVI r4,36
  CMP r1,r4
  JMP[EQ] @op_imm
  MOVI r4,91
  CMP r1,r4
  JMP[EQ] @op_mem
  MOVI r4,64
  CMP r1,r4
  JMP[EQ] @op_expr
  MOVI r4,35
  CMP r1,r4
  JMP[EQ] @op_expr
  CALL @rdhash1
  MOVI r6,@regs
  MOVI r7,2
  CALL @look
  CMP r1,r0
  JMP[EQ] @op_err
  LD r5,r1,1
  CALL @slot
  ST r13,r3,0
  ST r5,r3,1
  JMP @op_done
op_imm:
  CALL @expr
  ADD r5,r8,r0
  CALL @slot
  MOVI r4,2
  ST r4,r3,0
  ST r5,r3,1
  JMP @op_done
op_expr:
  CALL @ungetc
  CALL @expr
  ADD r5,r8,r0
  CALL @slot
  MOVI r4,2
  ST r4,r3,0
  ST r5,r3,1
  JMP @op_done
op_mem:
  CALL @memparse
  CALL @slot
  MOVI r4,3
  ST r4,r3,0
  LD r5,r0,#V_MB
  ST r5,r3,2
  LD r5,r0,#V_MI
  ST r5,r3,3
  LD r5,r0,#V_MS
  ST r5,r3,4
  LD r5,r0,#V_MD
  ST r5,r3,5
  JMP @op_done
op_err:
  CALL @bump_err
op_done:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
slot:
  LD r3,r0,#V_OPN
  SHL r3,r3,3
  ADDI r3,r3,#OPBASE
  RET
memparse:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r4,0xFF
  ST r4,r0,#V_MB
  ST r4,r0,#V_MI
  ST r13,r0,#V_MS
  ST r0,r0,#V_MD
  ST r0,r0,#V_TMPX
ml:
  CALL @nextc
  MOVI r4,93
  CMP r1,r4
  JMP[EQ] @mdone
  MOVI r4,43
  CMP r1,r4
  JMP[EQ] @mplus
  MOVI r4,45
  CMP r1,r4
  JMP[EQ] @mminus
  MOVI r4,48
  CMP r1,r4
  JMP[LT] @mident
  MOVI r4,58
  CMP r1,r4
  JMP[LT] @mnum
mident:
  MOVI r4,37
  CMP r1,r4
  JMP[EQ] @mpct
  MOVI r4,64
  CMP r1,r4
  JMP[EQ] @mat
  MOVI r4,35
  CMP r1,r4
  JMP[EQ] @mat
  JMP @mregid
mat:
  CALL @rdhash
  LD r6,r0,#V_LABB
  MOVI r7,2
  CALL @look
  JMP @mlab2
mlab2:
  CMP r1,r0
  JMP[EQ] @mmiss
  LD r8,r1,1
  JMP @mnum2
mmiss:
  MOVI r8,0
  LD r2,r0,#V_PASS
  MOVI r3,2
  CMP r2,r3
  JMP[NE] @mnum2
  CALL @bump_err
  JMP @mnum2
mpct:
  CALL @nextc
  JMP @mregid
mregid:
  CALL @rdhash1
  MOVI r6,@regs
  MOVI r7,2
  CALL @look
  CMP r1,r0
  JMP[NE] @mregfound
  LD r6,r0,#V_LABB
  MOVI r7,2
  CALL @look
  JMP @mlab2
mregfound:
  LD r5,r1,1
  CALL @nextc
  MOVI r4,42
  CMP r1,r4
  JMP[EQ] @mscale
  CALL @ungetc
  MOVI r6,1
  JMP @massign
mscale:
  ST r5,r0,#V_TMPX
  CALL @nextc
  CALL @tnum
  ADD r6,r8,r0
  LD r5,r0,#V_TMPX
  JMP @massign
massign:
  ADD r1,r5,r0
  CALL @rf
  ADD r5,r1,r0
  MOVI r4,1
  CMP r6,r4
  JMP[EQ] @mreg1
  ST r6,r0,#V_MS
  ST r5,r0,#V_MI
  JMP @mafter
mreg1:
  LD r4,r0,#V_MB
  MOVI r7,0xFF
  CMP r4,r7
  JMP[NE] @midx1
  ST r5,r0,#V_MB
  JMP @mafter
midx1:
  ST r5,r0,#V_MI
  JMP @mafter
mnum:
  CALL @tnum
  JMP @mnum2
mnum2:
  LD r4,r0,#V_TMPX
  CMP r4,r0
  JMP[EQ] @mnum3
  SUB r8,r0,r8
mnum3:
  LD r4,r0,#V_MD
  ADD r4,r4,r8
  ST r4,r0,#V_MD
  JMP @mafter
mplus:
  ST r0,r0,#V_TMPX
  JMP @ml
mminus:
  ST r13,r0,#V_TMPX
  JMP @ml
mafter:
  CALL @nextc
  MOVI r4,43
  CMP r1,r4
  JMP[EQ] @mplus
  MOVI r4,45
  CMP r1,r4
  JMP[EQ] @mminus
  MOVI r4,93
  CMP r1,r4
  JMP[EQ] @mdone
  CALL @bump_err
mdone:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
bump_err:
  LD r1,r0,#V_ERR
  ADD r1,r1,r13
  ST r1,r0,#V_ERR
  RET
emitb:
  LD r2,r0,#V_PC
  ADD r2,r2,r13
  ST r2,r0,#V_PC
  LD r3,r0,#V_PASS
  MOVI r4,2
  CMP r3,r4
  RET[NE]
  LD r3,r0,#V_OBP
  STB r1,r3,0
  ADD r3,r3,r13
  ST r3,r0,#V_OBP
  RET
emitw:
  ST r15,r14,0
  ADD r14,r14,r13
  ST r2,r0,#V_TMP
  MOVI r4,255
  BOOL.8 r1,r2,r4
  CALL @emitb
  LD r1,r0,#V_TMP
  SHR r1,r1,8
  CALL @emitb
  SUB r14,r14,r13
  LD r15,r14,0
  RET
emitd:
  ST r15,r14,0
  ADD r14,r14,r13
  ST r2,r0,#V_TMP
  CALL @emitw
  LD r2,r0,#V_TMP
  SHR r2,r2,16
  CALL @emitw
  SUB r14,r14,r13
  LD r15,r14,0
  RET
prefix:
  MOVI r4,2
  CMP r1,r4
  JMP[EQ] @pf2
  MOVI r4,4
  CMP r1,r4
  JMP[NE] @pfx
  LD r4,r0,#V_MODE
  CMP r4,r0
  JMP[EQ] @pf66
  RET
pf2:
  LD r4,r0,#V_MODE
  CMP r4,r0
  JMP[EQ] @pfx
pf66:
  MOVI r1,0x66
  JMP @emitb
pfx:
  RET
rf:
  MOVI r4,15
  BOOL.8 r1,r1,r4
  RET
fits8:
  ADD r2,r1,r0
  MOVI r4,0xFF80
  MOVHI r4,0xFFFF
  CMPS r2,r4
  JMP[LT] @f8n
  MOVI r4,127
  CMPS r2,r4
  JMP[GT] @f8n
  MOVI r9,1
  RET
f8n:
  MOVI r9,0
  RET
sz_of:
  LD r2,r0,#V_SZ
  CMP r2,r0
  JMP[NE] @sz_o
  LD r3,r0,#V_OPN
  MOVI r5,0
sz_l:
  CMP r5,r3
  JMP[EQ] @sz_z
  SHL r6,r5,3
  ADDI r6,r6,#OPBASE
  LD r7,r6,0
  MOVI r4,1
  CMP r7,r4
  JMP[NE] @sz_n
  LD r7,r6,1
  SHR r7,r7,4
  MOVI r4,2
  CMP r7,r4
  JMP[GT] @sz_n
  MOVI r4,0
  CMP r7,r4
  JMP[EQ] @sz_1
  MOVI r4,1
  CMP r7,r4
  JMP[EQ] @sz_2
  MOVI r1,4
  RET
sz_1:
  MOVI r1,1
  RET
sz_2:
  MOVI r1,2
  RET
sz_n:
  ADD r5,r5,r13
  JMP @sz_l
sz_z:
  MOVI r1,0
  RET
sz_o:
  ADD r1,r2,r0
  RET
sz_op:
  SHL r3,r2,3
  ADDI r3,r3,#OPBASE
  LD r4,r3,0
  MOVI r5,1
  CMP r4,r5
  JMP[NE] @so_z
  LD r4,r3,1
  SHR r4,r4,4
  MOVI r5,0
  CMP r4,r5
  JMP[EQ] @so_1
  MOVI r5,1
  CMP r4,r5
  JMP[EQ] @so_2
  MOVI r1,4
  RET
so_1:
  MOVI r1,1
  RET
so_2:
  MOVI r1,2
  RET
so_z:
  MOVI r1,0
  RET
define:
  ST r15,r14,0
  ADD r14,r14,r13
  LD r6,r0,#V_LABB
  MOVI r7,2
  CALL @look
  CMP r1,r0
  JMP[NE] @df_set
  LD r2,r0,#V_NLAB
  MOVI r4,511
  CMP r2,r4
  JMP[GE] @df_full
  SHL r3,r2,1
  LD r4,r0,#V_LABB
  ADD r3,r3,r4
  ST r5,r3,0
  ST r8,r3,1
  ADD r2,r2,r13
  ST r2,r0,#V_NLAB
  ST r0,r3,2
  JMP @df_x
df_set:
  ST r8,r1,1
  JMP @df_x
df_full:
  CALL @bump_err
df_x:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
look:
  LD r2,r6,0
  CMP r2,r0
  JMP[EQ] @lk0
  CMP r2,r5
  JMP[EQ] @lk2
  ADD r6,r6,r7
  JMP @look
lk0:
  MOVI r1,0
  RET
lk2:
  BOOL.12 r1,r6,r6
  RET
expr:
  ST r15,r14,0
  ADD r14,r14,r13
  ST r0,r0,#V_ACC
  ST r0,r0,#V_SGN
  CALL @nextc
  MOVI r4,45
  CMP r1,r4
  JMP[NE] @ex_t
  ST r13,r0,#V_SGN
  CALL @nextc
ex_t:
  CALL @term
  LD r2,r0,#V_SGN
  CMP r2,r0
  JMP[EQ] @ex_a
  SUB r8,r0,r8
ex_a:
  LD r2,r0,#V_ACC
  ADD r2,r2,r8
  ST r2,r0,#V_ACC
  CALL @nextc
  MOVI r4,43
  CMP r1,r4
  JMP[EQ] @ex_p
  MOVI r4,45
  CMP r1,r4
  JMP[EQ] @ex_m
  CALL @ungetc
  LD r8,r0,#V_ACC
  SUB r14,r14,r13
  LD r15,r14,0
  RET
ex_p:
  ST r0,r0,#V_SGN
  CALL @nextc
  JMP @ex_t
ex_m:
  ST r13,r0,#V_SGN
  CALL @nextc
  JMP @ex_t
term:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r4,48
  CMP r1,r4
  JMP[LT] @tm_l
  MOVI r4,58
  CMP r1,r4
  JMP[LT] @tm_num
  JMP @tm_l
tm_num:
  CALL @tnum
  JMP @tm_x
tm_l:
  MOVI r4,64
  CMP r1,r4
  JMP[EQ] @tm_lab
  MOVI r4,35
  CMP r1,r4
  JMP[EQ] @tm_lab
  CALL @rdhash1
  JMP @tm_lk
tm_lab:
  CALL @rdhash
tm_lk:
  LD r6,r0,#V_LABB
  MOVI r7,2
  CALL @look
  CMP r1,r0
  JMP[EQ] @tm_miss
  LD r8,r1,1
  JMP @tm_x
tm_miss:
  MOVI r8,0
  LD r2,r0,#V_PASS
  MOVI r3,2
  CMP r2,r3
  JMP[NE] @tm_x
  CALL @bump_err
tm_x:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
tnum:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r8,0
  MOVI r4,48
  CMP r1,r4
  JMP[NE] @tn_d
  CALL @getc
  MOVI r4,120
  CMP r1,r4
  JMP[EQ] @tn_h
tn_d:
  MOVI r4,48
  CMP r1,r4
  JMP[LT] @tn_e
  MOVI r4,58
  CMP r1,r4
  JMP[GE] @tn_e
  MOVI r4,48
  SUB r1,r1,r4
  SHL r5,r8,3
  SHL r6,r8,1
  ADD r8,r5,r6
  ADD r8,r8,r1
  CALL @getc
  JMP @tn_d
tn_h:
  CALL @getc
  MOVI r4,48
  CMP r1,r4
  JMP[LT] @tn_e
  MOVI r4,58
  CMP r1,r4
  JMP[LT] @th_d
  MOVI r4,65
  CMP r1,r4
  JMP[LT] @tn_e
  MOVI r4,71
  CMP r1,r4
  JMP[LT] @th_u
  MOVI r4,97
  CMP r1,r4
  JMP[LT] @tn_e
  MOVI r4,103
  CMP r1,r4
  JMP[GE] @tn_e
  MOVI r4,87
  JMP @th_a
th_u:
  MOVI r4,55
  JMP @th_a
th_d:
  MOVI r4,48
th_a:
  SUB r1,r1,r4
  SHL r8,r8,4
  ADD r8,r8,r1
  JMP @tn_h
tn_e:
  CALL @ungetc
  SUB r14,r14,r13
  LD r15,r14,0
  RET
rdhash1:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r5,5381
  JMP @rh_a
rdhash:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r5,5381
rh1:
  CALL @getc
  CALL @isid
  CMP r6,r0
  JMP[EQ] @rh2
rh_a:
  MOVI r6,97
  CMP r1,r6
  JMP[LT] @rh_b
  MOVI r6,123
  CMP r1,r6
  JMP[GE] @rh_b
  MOVI r6,32
  SUB r1,r1,r6
rh_b:
  SHL r6,r5,5
  ADD r5,r6,r5
  ADD r5,r5,r1
  JMP @rh1
rh2:
  CALL @ungetc
  SUB r14,r14,r13
  LD r15,r14,0
  RET
isid:
  MOVI r6,1
  MOVI r7,48
  CMP r1,r7
  JMP[LT] @isn
  MOVI r7,58
  CMP r1,r7
  RET[LT]
  MOVI r7,65
  CMP r1,r7
  JMP[LT] @isn
  MOVI r7,91
  CMP r1,r7
  RET[LT]
  MOVI r7,95
  CMP r1,r7
  RET[EQ]
  MOVI r7,97
  CMP r1,r7
  JMP[LT] @isn
  MOVI r7,123
  CMP r1,r7
  RET[LT]
isn:
  MOVI r6,0
  RET
getc:
  LD r2,r0,#V_PB
  CMP r2,r0
  JMP[EQ] @gc1
  ST r0,r0,#V_PB
  SUB r1,r2,r13
  RET
gc1:
  LD r2,r0,#V_CN
  CMP r2,r0
  JMP[NE] @gc2
  LD r3,r0,#V_SRCP
  LD r1,r3,0
  ST r1,r0,#V_CW
  ADD r3,r3,r13
  ST r3,r0,#V_SRCP
  MOVI r2,4
gc2:
  SUB r2,r2,r13
  ST r2,r0,#V_CN
  LD r1,r0,#V_CW
  SHR r3,r1,8
  ST r3,r0,#V_CW
  MOVI r3,255
  BOOL.8 r1,r1,r3
  RET
ungetc:
  ADD r2,r1,r13
  ST r2,r0,#V_PB
  RET
nextc:
  ST r15,r14,0
  ADD r14,r14,r13
nx1:
  CALL @getc
  MOVI r4,32
  CMP r1,r4
  JMP[EQ] @nx1
  MOVI r4,9
  CMP r1,r4
  JMP[EQ] @nx1
  MOVI r4,13
  CMP r1,r4
  JMP[EQ] @nx1
  SUB r14,r14,r13
  LD r15,r14,0
  RET
skipline:
  ST r15,r14,0
  ADD r14,r14,r13
sk1:
  CALL @getc
  CMP r1,r0
  JMP[EQ] @skx
  MOVI r4,10
  CMP r1,r4
  JMP[NE] @sk1
skx:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
h_byte1:
  LD r1,r0,#V_AUX0
  CALL @emitb
  JMP @endins
h_rep:
  MOVI r1,0xF3
  CALL @emitb
  LD r1,r0,#V_AUX0
  CALL @emitb
  JMP @endins
e_form:
  CALL @bump_err
  JMP @endins
m_movb:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @m_mov
m_movw:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @m_mov
m_movl:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @m_mov
m_mov:
  CALL @sz_of
  ADD r11,r1,r0
  LD r2,r0,#V_OPN
  MOVI r4,2
  CMP r2,r4
  JMP[NE] @e_form
  LD r4,r0,#OPBASE
  LD r5,r0,#OPBASE+1
  LD r6,r0,#OPBASE+8
  LD r7,r0,#OPBASE+9
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @mv_imm
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @mv_reg
  MOVI r8,3
  CMP r4,r8
  JMP[EQ] @mv_mem
  JMP @e_form
mv_imm:
  ADD r10,r5,r0
  MOVI r8,1
  CMP r6,r8
  JMP[EQ] @mv_ir
  MOVI r8,3
  CMP r6,r8
  JMP[EQ] @mv_im
  JMP @e_form
mv_ir:
  ADD r1,r7,r0
  SHR r1,r1,4
  MOVI r8,5
  CMP r1,r8
  JMP[EQ] @e_form
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  ADD r1,r7,r0
  CALL @rf
  ADD r12,r1,r0
  MOVI r1,0xB0
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_ir_op
  ADDI r1,r1,8
mv_ir_op:
  ADD r1,r1,r12
  CALL @emitb
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_ir8
  MOVI r8,2
  CMP r11,r8
  JMP[EQ] @mv_ir16
  ADD r2,r10,r0
  CALL @emitd
  JMP @endins
mv_ir8:
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
mv_ir16:
  ADD r2,r10,r0
  CALL @emitw
  JMP @endins
mv_im:
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xC6
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_im_op
  ADDI r1,r1,1
mv_im_op:
  CALL @emitb
  MOVI r1,0
  MOVI r2,1
  CALL @enc_rm
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_im8
  MOVI r8,2
  CMP r11,r8
  JMP[EQ] @mv_im16
  ADD r2,r10,r0
  CALL @emitd
  JMP @endins
mv_im8:
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
mv_im16:
  ADD r2,r10,r0
  CALL @emitw
  JMP @endins
mv_reg:
  ADD r10,r5,r0
  ADD r1,r5,r0
  SHR r1,r1,4
  MOVI r8,5
  CMP r1,r8
  JMP[EQ] @mv_sreg_st
  MOVI r8,4
  CMP r1,r8
  JMP[EQ] @mv_cr_st
  MOVI r8,1
  CMP r6,r8
  JMP[EQ] @mv_rr
  MOVI r8,3
  CMP r6,r8
  JMP[EQ] @mv_rm
  JMP @e_form
mv_rr:
  ADD r1,r7,r0
  SHR r1,r1,4
  MOVI r8,5
  CMP r1,r8
  JMP[EQ] @mv_sreg_ld
  MOVI r8,4
  CMP r1,r8
  JMP[EQ] @mv_cr_ld
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x88
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_rr_op
  ADDI r1,r1,1
mv_rr_op:
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
mv_rm:
  LD r1,r0,#OPBASE+10
  MOVI r8,0xFF
  CMP r1,r8
  JMP[NE] @mv_rm_n
  LD r1,r0,#OPBASE+11
  CMP r1,r8
  JMP[NE] @mv_rm_n
  ADD r1,r10,r0
  CALL @rf
  CMP r1,r0
  JMP[NE] @mv_rm_n
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xA2
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_ms_op
  ADDI r1,r1,1
mv_ms_op:
  CALL @emitb
  LD r2,r0,#OPBASE+13
  LD r8,r0,#V_MODE
  CMP r8,r0
  JMP[EQ] @mv_ms_w
  CALL @emitd
  JMP @endins
mv_ms_w:
  CALL @emitw
  JMP @endins
mv_rm_n:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x88
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_rm_op
  ADDI r1,r1,1
mv_rm_op:
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
mv_sreg_st:
  MOVI r1,0x8C
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
mv_cr_st:
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x20
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
mv_sreg_ld:
  MOVI r1,0x8E
  CALL @emitb
  ADD r1,r7,r0
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
mv_cr_ld:
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x22
  CALL @emitb
  ADD r1,r7,r0
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
mv_mem:
  ADD r10,r5,r0
  MOVI r8,1
  CMP r6,r8
  JMP[EQ] @mv_mr
  JMP @e_form
mv_mr:
  ADD r1,r7,r0
  SHR r1,r1,4
  MOVI r8,5
  CMP r1,r8
  JMP[EQ] @mv_sreg_ld2
  MOVI r8,4
  CMP r1,r8
  JMP[EQ] @mv_cr_ld2
  LD r1,r0,#OPBASE+2
  MOVI r8,0xFF
  CMP r1,r8
  JMP[NE] @mv_mr_n
  LD r1,r0,#OPBASE+3
  CMP r1,r8
  JMP[NE] @mv_mr_n
  ADD r1,r7,r0
  CALL @rf
  CMP r1,r0
  JMP[NE] @mv_mr_n
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xA0
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_ml_op
  ADDI r1,r1,1
mv_ml_op:
  CALL @emitb
  LD r2,r0,#OPBASE+5
  LD r8,r0,#V_MODE
  CMP r8,r0
  JMP[EQ] @mv_ml_w
  CALL @emitd
  JMP @endins
mv_ml_w:
  CALL @emitw
  JMP @endins
mv_mr_n:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x8A
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @mv_mr_op
  ADDI r1,r1,1
mv_mr_op:
  CALL @emitb
  ADD r1,r7,r0
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
mv_sreg_ld2:
  MOVI r1,0x8E
  CALL @emitb
  ADD r1,r7,r0
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
mv_cr_ld2:
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x22
  CALL @emitb
  ADD r1,r7,r0
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
m_movzxb:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @h_movzx
m_movzxw:
  MOVI r4,2
  ST r4,r0,#V_SZ
  MOVI r4,0xB7
  ST r4,r0,#V_AUX0
  JMP @h_movzx
m_movsxw:
  MOVI r4,2
  ST r4,r0,#V_SZ
  MOVI r4,0xBF
  ST r4,r0,#V_AUX0
  JMP @h_movsx
h_movzx:
  CALL @sz_of
  ADD r11,r1,r0
  CMP r11,r0
  JMP[EQ] @e_form
  LD r4,r0,#V_AUX0
  CMP r4,r0
  JMP[NE] @zx_have
  LD r4,r0,#OPBASE+1
  SHR r4,r4,4
  MOVI r8,0
  CMP r4,r8
  MOVI r4,0xB6
  MOVI[NE] r4,0xB7
zx_have:
  ST r4,r0,#V_TMPX
  LD r4,r0,#OPBASE+9
  SHR r4,r4,4
  MOVI r8,1
  CMP r4,r8
  JMP[NE] @zx_n
  MOVI r1,0x66
  CALL @emitb
zx_n:
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_TMPX
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
h_movsx:
  CALL @sz_of
  ADD r11,r1,r0
  CMP r11,r0
  JMP[EQ] @e_form
  LD r4,r0,#V_AUX0
  CMP r4,r0
  JMP[NE] @sx_have
  LD r4,r0,#OPBASE+1
  SHR r4,r4,4
  MOVI r8,0
  CMP r4,r8
  MOVI r4,0xBE
  MOVI[NE] r4,0xBF
sx_have:
  ST r4,r0,#V_TMPX
  LD r4,r0,#OPBASE+9
  SHR r4,r4,4
  MOVI r8,1
  CMP r4,r8
  JMP[NE] @sx_n
  MOVI r1,0x66
  CALL @emitb
sx_n:
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_TMPX
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
enc_rm:
  ST r15,r14,0
  ADD r14,r14,r13
  SHL r3,r2,3
  ADDI r3,r3,#OPBASE
  LD r4,r3,0
  MOVI r5,1
  CMP r4,r5
  JMP[NE] @er_mem
  LD r4,r3,1
  MOVI r5,15
  BOOL.8 r4,r4,r5
  SHL r1,r1,3
  MOVI r5,0xC0
  BOOL.14 r1,r1,r5
  BOOL.14 r1,r1,r4
  CALL @emitb
  JMP @er_x
er_mem:
  LD r4,r3,2
  LD r5,r3,3
  LD r6,r3,4
  LD r7,r3,5
  ST r4,r0,#V_MB
  ST r5,r0,#V_MI
  ST r6,r0,#V_MS
  ST r7,r0,#V_MD
  ST r1,r0,#V_MR
  MOVI r8,0xFF
  CMP r4,r8
  JMP[NE] @er_hb
  CMP r5,r8
  JMP[NE] @er_io
  LD r8,r0,#V_MODE
  CMP r8,r0
  JMP[EQ] @er_a16
  LD r1,r0,#V_MR
  SHL r1,r1,3
  MOVI r8,0x05
  BOOL.14 r1,r1,r8
  CALL @emitb
  LD r2,r0,#V_MD
  CALL @emitd
  JMP @er_x
er_a16:
  LD r1,r0,#V_MR
  SHL r1,r1,3
  MOVI r8,0x06
  BOOL.14 r1,r1,r8
  CALL @emitb
  LD r2,r0,#V_MD
  CALL @emitw
  JMP @er_x
er_io:
  LD r1,r0,#V_MR
  SHL r1,r1,3
  MOVI r8,0x04
  BOOL.14 r1,r1,r8
  CALL @emitb
  LD r1,r0,#V_MS
  SHR r1,r1,1
  MOVI r5,4
  CMP r1,r5
  MOVI[EQ] r1,3
  SHL r1,r1,6
  LD r5,r0,#V_MI
  SHL r5,r5,3
  BOOL.14 r1,r1,r5
  MOVI r8,5
  BOOL.14 r1,r1,r8
  CALL @emitb
  LD r2,r0,#V_MD
  CALL @emitd
  JMP @er_x
er_hb:
  MOVI r8,0xFF
  CMP r5,r8
  JMP[NE] @er_bb
  LD r9,r0,#V_MB
  LD r7,r0,#V_MD
  CMP r7,r0
  JMP[NE] @er_bd
  MOVI r8,5
  CMP r9,r8
  JMP[EQ] @er_b0
  LD r1,r0,#V_MR
  SHL r1,r1,3
  BOOL.14 r1,r1,r9
  CALL @emitb
  JMP @er_x
er_bd:
  ADD r1,r7,r0
  CALL @fits8
  CMP r9,r0
  JMP[EQ] @er_b32
er_b0:
  LD r9,r0,#V_MB
  LD r1,r0,#V_MR
  SHL r1,r1,3
  MOVI r8,0x40
  BOOL.14 r1,r1,r8
  BOOL.14 r1,r1,r9
  CALL @emitb
  LD r1,r0,#V_MD
  CALL @emitb
  JMP @er_x
er_b32:
  LD r9,r0,#V_MB
  LD r1,r0,#V_MR
  SHL r1,r1,3
  MOVI r8,0x80
  BOOL.14 r1,r1,r8
  BOOL.14 r1,r1,r9
  CALL @emitb
  LD r2,r0,#V_MD
  CALL @emitd
  JMP @er_x
er_bb:
  LD r5,r0,#V_MI
  MOVI r8,4
  CMP r5,r8
  JMP[EQ] @er_bad
  LD r7,r0,#V_MD
  LD r9,r0,#V_MB
  CMP r7,r0
  JMP[NE] @er_bbd
  MOVI r8,5
  CMP r9,r8
  JMP[EQ] @er_bb0
  MOVI r8,0
  JMP @er_bsib
er_bbd:
  ADD r1,r7,r0
  CALL @fits8
  CMP r9,r0
  JMP[EQ] @er_bb32
er_bb0:
  MOVI r8,0x40
  JMP @er_bsib
er_bb32:
  MOVI r8,0x80
er_bsib:
  LD r1,r0,#V_MR
  SHL r1,r1,3
  MOVI r5,0x04
  BOOL.14 r1,r1,r5
  BOOL.14 r1,r1,r8
  CALL @emitb
  LD r1,r0,#V_MS
  SHR r1,r1,1
  MOVI r5,4
  CMP r1,r5
  MOVI[EQ] r1,3
  SHL r1,r1,6
  LD r5,r0,#V_MI
  SHL r5,r5,3
  BOOL.14 r1,r1,r5
  LD r5,r0,#V_MB
  BOOL.14 r1,r1,r5
  CALL @emitb
  MOVI r5,0
  CMP r8,r5
  JMP[EQ] @er_x
  MOVI r5,0x40
  CMP r8,r5
  JMP[EQ] @er_bs8
  LD r2,r0,#V_MD
  CALL @emitd
  JMP @er_x
er_bs8:
  LD r1,r0,#V_MD
  CALL @emitb
  JMP @er_x
er_bad:
  CALL @bump_err
er_x:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
branch:
  ST r15,r14,0
  ADD r14,r14,r13
  ST r8,r0,#V_BT
  ST r9,r0,#V_BS
  ST r10,r0,#V_BL
  ST r11,r0,#V_BLN
  LD r4,r0,#V_BRN
  ADD r4,r4,r13
  ST r4,r0,#V_BRN
  SUB r4,r4,r13
  SHL r5,r4,3
  LD r2,r0,#V_LONGB
  ADD r6,r2,r5
  LD r6,r6,0
  LD r8,r0,#V_BT
  CMP r8,r0
  JMP[EQ] @br_short
  LD r7,r0,#V_BASE
  LD r1,r0,#V_PC
  ADD r7,r7,r1
  ADDI r7,r7,2
  SUB r1,r8,r7
  CALL @fits8
  CMP r6,r0
  JMP[NE] @br_long
  CMP r9,r0
  JMP[EQ] @br_grow
br_short:
  LD r1,r0,#V_BS
  CALL @emitb
  LD r7,r0,#V_BASE
  LD r1,r0,#V_PC
  ADD r7,r7,r1
  ADDI r7,r7,1
  LD r8,r0,#V_BT
  SUB r1,r8,r7
  CALL @emitb
  JMP @br_x
br_grow:
  LD r4,r0,#V_BRN
  SUB r4,r4,r13
  SHL r5,r4,3
  LD r2,r0,#V_LONGB
  ADD r5,r2,r5
  ST r13,r5,0
  MOVI r4,1
  ST r4,r0,#V_REDO
br_long:
  LD r11,r0,#V_BLN
  MOVI r8,6
  CMP r11,r8
  JMP[NE] @br_l5
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_BL
  CALL @emitb
  JMP @br_r32
br_l5:
  LD r1,r0,#V_BL
  CALL @emitb
br_r32:
  LD r7,r0,#V_BASE
  LD r1,r0,#V_PC
  ADD r7,r7,r1
  ADDI r7,r7,4
  LD r8,r0,#V_BT
  SUB r2,r8,r7
  CALL @emitd
br_x:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
h_alu:
  LD r4,r0,#V_AUX0
  MOVI r5,0xFF
  BOOL.8 r5,r4,r5
  ST r5,r0,#V_AUX1
  SHR r4,r4,8
  ST r4,r0,#V_AUX2
  CALL @sz_of
  ADD r11,r1,r0
  CMP r11,r0
  JMP[EQ] @e_form
  LD r4,r0,#OPBASE
  LD r5,r0,#OPBASE+1
  LD r6,r0,#OPBASE+8
  LD r7,r0,#OPBASE+9
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @alu_r
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @alu_i
  MOVI r8,3
  CMP r4,r8
  JMP[EQ] @alu_m
  JMP @e_form
alu_r:
  ADD r10,r5,r0
  ADD r1,r11,r0
  CALL @prefix
  LD r1,r0,#V_AUX2
  MOVI r8,1
  CMP r11,r8
  JMP[NE] @alu_r_op
  ADDI r1,r1,0
  JMP @alu_r_em
alu_r_op:
  ADDI r1,r1,1
alu_r_em:
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
alu_m:
  ADD r10,r7,r0
  ADD r1,r11,r0
  CALL @prefix
  LD r1,r0,#V_AUX2
  MOVI r8,1
  CMP r11,r8
  JMP[NE] @alu_m_op
  ADDI r1,r1,2
  JMP @alu_m_em
alu_m_op:
  ADDI r1,r1,3
alu_m_em:
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
alu_i:
  ADD r10,r5,r0
  MOVI r8,1
  CMP r6,r8
  JMP[EQ] @alu_ir
  MOVI r8,3
  CMP r6,r8
  JMP[EQ] @alu_im
  JMP @e_form
alu_ir:
  MOVI r8,1
  CMP r11,r8
  JMP[NE] @alu_ir_w
  ADD r1,r7,r0
  CALL @rf
  CMP r1,r0
  JMP[EQ] @alu_acc8
  JMP @alu_i8
alu_ir_w:
  ADD r1,r10,r0
  CALL @fits8
  CMP r9,r0
  JMP[NE] @alu_i83
  ADD r1,r7,r0
  CALL @rf
  CMP r1,r0
  JMP[EQ] @alu_accw
  JMP @alu_i32
alu_im:
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @alu_i8
  ADD r1,r10,r0
  CALL @fits8
  CMP r9,r0
  JMP[NE] @alu_i83
  JMP @alu_i32
alu_acc8:
  ADD r1,r11,r0
  CALL @prefix
  LD r1,r0,#V_AUX2
  ADDI r1,r1,4
  CALL @emitb
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
alu_accw:
  ADD r1,r11,r0
  CALL @prefix
  LD r1,r0,#V_AUX2
  ADDI r1,r1,5
  CALL @emitb
  MOVI r8,2
  CMP r11,r8
  JMP[EQ] @alu_ae16
  ADD r2,r10,r0
  CALL @emitd
  JMP @endins
alu_ae16:
  ADD r2,r10,r0
  CALL @emitw
  JMP @endins
alu_i8:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x80
  CALL @emitb
  JMP @alu_ib
alu_i83:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x83
  CALL @emitb
alu_ib:
  LD r1,r0,#V_AUX1
  MOVI r2,1
  CALL @enc_rm
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
alu_i32:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x81
  CALL @emitb
  LD r1,r0,#V_AUX1
  MOVI r2,1
  CALL @enc_rm
  MOVI r8,2
  CMP r11,r8
  JMP[EQ] @alu_i32w
  ADD r2,r10,r0
  CALL @emitd
  JMP @endins
alu_i32w:
  ADD r2,r10,r0
  CALL @emitw
  JMP @endins
h_test:
  CALL @sz_of
  ADD r11,r1,r0
  CMP r11,r0
  JMP[EQ] @e_form
  LD r4,r0,#OPBASE
  LD r5,r0,#OPBASE+1
  LD r6,r0,#OPBASE+8
  LD r7,r0,#OPBASE+9
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @ts_r
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @ts_i
  JMP @e_form
ts_r:
  ADD r10,r5,r0
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x84
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @ts_r_op
  ADDI r1,r1,1
ts_r_op:
  CALL @emitb
  ADD r1,r10,r0
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
ts_i:
  ADD r10,r5,r0
  MOVI r8,1
  CMP r6,r8
  JMP[NE] @ts_i_n
  ADD r1,r7,r0
  CALL @rf
  CMP r1,r0
  JMP[NE] @ts_i_n
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xA8
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @ts_a_op
  ADDI r1,r1,1
ts_a_op:
  CALL @emitb
  JMP @ts_ie
ts_i_n:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xF6
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @ts_n_op
  ADDI r1,r1,1
ts_n_op:
  CALL @emitb
  MOVI r1,0
  MOVI r2,1
  CALL @enc_rm
ts_ie:
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @ts_e8
  MOVI r8,2
  CMP r11,r8
  JMP[EQ] @ts_e16
  ADD r2,r10,r0
  CALL @emitd
  JMP @endins
ts_e8:
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
ts_e16:
  ADD r2,r10,r0
  CALL @emitw
  JMP @endins
h_group:
  CALL @sz_of
  ADD r11,r1,r0
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xF6
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @gr_op
  ADDI r1,r1,1
gr_op:
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
h_incdec:
  CALL @sz_of
  ADD r11,r1,r0
  LD r4,r0,#OPBASE
  LD r5,r0,#OPBASE+1
  CMP r11,r0
  JMP[EQ] @e_form
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @id_reg
  MOVI r8,3
  CMP r4,r8
  JMP[EQ] @id_mem
  JMP @e_form
id_reg:
  ADD r10,r5,r0
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @id_r8
  ADD r1,r11,r0
  CALL @prefix
  ADD r1,r10,r0
  CALL @rf
  ADDI r1,r1,0x40
  LD r4,r0,#V_AUX0
  CMP r4,r0
  JMP[EQ] @id_r_op
  ADDI r1,r1,8
id_r_op:
  CALL @emitb
  JMP @endins
id_r8:
  MOVI r1,0xFE
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
id_mem:
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xFE
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @id_m_op
  ADDI r1,r1,1
id_m_op:
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
h_shift:
  MOVI r2,1
  CALL @sz_op
  ADD r11,r1,r0
  LD r4,r0,#OPBASE
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @sh_cl
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @sh_imm
  JMP @e_form
sh_cl:
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0xD2
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @sh_c_op
  ADDI r1,r1,1
sh_c_op:
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
sh_imm:
  LD r5,r0,#OPBASE+1
  ADD r10,r5,r0
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  MOVI r8,1
  CMP r10,r8
  JMP[EQ] @sh_one
  MOVI r1,0xC0
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @sh_i_op
  ADDI r1,r1,1
sh_i_op:
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,1
  CALL @enc_rm
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
sh_one:
  MOVI r1,0xD0
  MOVI r8,1
  CMP r11,r8
  JMP[EQ] @sh_1_op
  ADDI r1,r1,1
sh_1_op:
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
m_jmp:
  LD r4,r0,#OPBASE
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @j_rel
  MOVI r1,0xFF
  CALL @emitb
  MOVI r1,4
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
j_rel:
  LD r8,r0,#OPBASE+1
  MOVI r9,0xEB
  MOVI r10,0xE9
  MOVI r11,5
  CALL @branch
  JMP @endins
m_call:
  LD r4,r0,#OPBASE
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @c_rel
  MOVI r1,0xFF
  CALL @emitb
  MOVI r1,2
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
c_rel:
  MOVI r1,0xE8
  CALL @emitb
  LD r8,r0,#OPBASE+1
  LD r7,r0,#V_BASE
  LD r1,r0,#V_PC
  ADD r7,r7,r1
  ADDI r7,r7,4
  SUB r2,r8,r7
  CALL @emitd
  JMP @endins
h_jcc:
  LD r4,r0,#OPBASE
  MOVI r8,2
  CMP r4,r8
  JMP[NE] @e_form
  LD r8,r0,#OPBASE+1
  LD r9,r0,#V_AUX0
  ADDI r9,r9,0x70
  LD r10,r0,#V_AUX0
  ADDI r10,r10,0x80
  MOVI r11,6
  CALL @branch
  JMP @endins
m_loop:
  MOVI r1,0xE2
  CALL @emitb
  LD r8,r0,#OPBASE+1
  LD r7,r0,#V_BASE
  LD r1,r0,#V_PC
  ADD r7,r7,r1
  ADDI r7,r7,1
  SUB r1,r8,r7
  CALL @emitb
  JMP @endins
m_jecxz:
  MOVI r1,0xE3
  CALL @emitb
  LD r8,r0,#OPBASE+1
  LD r7,r0,#V_BASE
  LD r1,r0,#V_PC
  ADD r7,r7,r1
  ADDI r7,r7,1
  SUB r1,r8,r7
  CALL @emitb
  JMP @endins
h_pushpop:
  CALL @sz_of
  ADD r11,r1,r0
  LD r4,r0,#OPBASE
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @pp_reg
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @pp_imm
  JMP @e_form
pp_reg:
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  LD r1,r0,#OPBASE+1
  CALL @rf
  ADD r10,r1,r0
  MOVI r1,0x50
  LD r4,r0,#V_AUX0
  CMP r4,r0
  JMP[EQ] @pp_op
  ADDI r1,r1,8
pp_op:
  ADD r1,r1,r10
  CALL @emitb
  JMP @endins
pp_imm:
  LD r4,r0,#V_AUX0
  CMP r4,r0
  JMP[NE] @e_form
  MOVI r1,0x68
  CALL @emitb
  LD r2,r0,#OPBASE+1
  LD r8,r0,#V_MODE
  CMP r8,r0
  JMP[EQ] @pp_i16
  CALL @emitd
  JMP @endins
pp_i16:
  CALL @emitw
  JMP @endins
h_lea:
  MOVI r2,1
  CALL @sz_op
  ADD r11,r1,r0
  LD r4,r0,#OPBASE
  MOVI r8,3
  CMP r4,r8
  JMP[NE] @e_form
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x8D
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
m_inout:
  LD r4,r0,#OPBASE
  LD r5,r0,#OPBASE+1
  LD r6,r0,#OPBASE+8
  LD r7,r0,#OPBASE+9
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @io_ii
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @io_r
  JMP @e_form
io_ii:
  MOVI r8,1
  CMP r6,r8
  JMP[NE] @e_form
  ADD r1,r7,r0
  CALL @rf
  CMP r1,r0
  JMP[NE] @e_form
  ADD r1,r7,r0
  SHR r1,r1,4
  MOVI r8,0
  CMP r1,r8
  MOVI r1,0xE4
  MOVI[NE] r1,0xE5
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @emitb
  JMP @endins
io_r:
  ADD r1,r5,r0
  CALL @rf
  MOVI r8,2
  CMP r1,r8
  JMP[NE] @io_out
  ADD r1,r7,r0
  CALL @rf
  CMP r1,r0
  JMP[NE] @e_form
  ADD r1,r7,r0
  SHR r1,r1,4
  MOVI r8,0
  CMP r1,r8
  MOVI r1,0xEC
  MOVI[NE] r1,0xED
  CALL @emitb
  JMP @endins
io_out:
  ADD r1,r5,r0
  CALL @rf
  CMP r1,r0
  JMP[NE] @e_form
  MOVI r8,1
  CMP r6,r8
  JMP[EQ] @io_od
  MOVI r8,2
  CMP r6,r8
  JMP[EQ] @io_oi
  JMP @e_form
io_od:
  ADD r1,r7,r0
  CALL @rf
  MOVI r8,2
  CMP r1,r8
  JMP[NE] @e_form
  ADD r1,r5,r0
  SHR r1,r1,4
  MOVI r8,0
  CMP r1,r8
  MOVI r1,0xEE
  MOVI[NE] r1,0xEF
  CALL @emitb
  JMP @endins
io_oi:
  ADD r1,r5,r0
  SHR r1,r1,4
  MOVI r8,0
  CMP r1,r8
  MOVI r1,0xE6
  MOVI[NE] r1,0xE7
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @emitb
  JMP @endins
m_int:
  MOVI r1,0xCD
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @emitb
  JMP @endins
h_gdt:
  LD r4,r0,#OPBASE
  MOVI r8,3
  CMP r4,r8
  JMP[NE] @e_form
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x01
  CALL @emitb
  LD r1,r0,#V_AUX0
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
m_ljmp:
  MOVI r1,0xEA
  CALL @emitb
  LD r2,r0,#OPBASE+9
  CALL @emitw
  LD r2,r0,#OPBASE+1
  CALL @emitw
  JMP @endins
m_shrd:
  LD r4,r0,#OPBASE
  MOVI r8,2
  CMP r4,r8
  JMP[NE] @e_form
  MOVI r2,2
  CALL @sz_op
  ADD r11,r1,r0
  CMP r11,r0
  JMP[EQ] @e_form
  ADD r1,r11,r0
  CALL @prefix
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0xAC
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,2
  CALL @enc_rm
  LD r1,r0,#OPBASE+1
  CALL @emitb
  JMP @endins
m_bt:
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0xA3
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
m_bswap:
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @rf
  ADDI r1,r1,0xC8
  CALL @emitb
  JMP @endins
h_sse3:
  MOVI r1,0xF3
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_AUX0
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
h_sse0:
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_AUX0
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
h_cvt:
  MOVI r1,0xF3
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_AUX0
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
m_movd:
  LD r4,r0,#OPBASE+1
  SHR r4,r4,4
  MOVI r8,3
  CMP r4,r8
  JMP[EQ] @md_x
  MOVI r1,0x66
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x6E
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
md_x:
  MOVI r1,0x66
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x7E
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
m_movql:
  MOVI r1,0xF3
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x7E
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
m_movqs:
  MOVI r1,0x66
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0xD6
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
h_movq:
  LD r4,r0,#OPBASE+1
  SHR r4,r4,4
  MOVI r8,3
  CMP r4,r8
  JMP[EQ] @mq_st
  MOVI r1,0xF3
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0x7E
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
mq_st:
  MOVI r1,0x66
  CALL @emitb
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0xD6
  CALL @emitb
  LD r1,r0,#OPBASE+1
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  JMP @endins
m_imul:
  LD r4,r0,#V_OPN
  MOVI r8,1
  CMP r4,r8
  JMP[EQ] @h_group
  LD r6,r0,#OPBASE+8
  MOVI r8,1
  CMP r6,r8
  JMP[NE] @e_form
  LD r4,r0,#OPBASE
  MOVI r8,2
  CMP r4,r8
  JMP[EQ] @im_imm
  MOVI r1,0x0F
  CALL @emitb
  MOVI r1,0xAF
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
im_imm:
  LD r10,r0,#OPBASE+1
  ADD r1,r10,r0
  CALL @fits8
  CMP r9,r0
  JMP[EQ] @im_i32
  MOVI r1,0x6B
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  ADD r1,r10,r0
  CALL @emitb
  JMP @endins
im_i32:
  MOVI r1,0x69
  CALL @emitb
  LD r1,r0,#OPBASE+9
  CALL @rf
  MOVI r2,1
  CALL @enc_rm
  ADD r2,r10,r0
  CALL @emitd
  JMP @endins
h_setcc:
  MOVI r1,0x0F
  CALL @emitb
  LD r1,r0,#V_AUX0
  ADDI r1,r1,0x90
  CALL @emitb
  MOVI r1,0
  MOVI r2,0
  CALL @enc_rm
  JMP @endins
d_byte:
  ST r15,r14,0
  ADD r14,r14,r13
db_l:
  CALL @expr
  ADD r1,r8,r0
  CALL @emitb
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @db_l
  CALL @ungetc
  SUB r14,r14,r13
  LD r15,r14,0
  JMP @endins
d_word:
  ST r15,r14,0
  ADD r14,r14,r13
dw_l:
  CALL @expr
  ADD r2,r8,r0
  CALL @emitw
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @dw_l
  CALL @ungetc
  SUB r14,r14,r13
  LD r15,r14,0
  JMP @endins
d_long:
  ST r15,r14,0
  ADD r14,r14,r13
dl_l:
  CALL @expr
  ADD r2,r8,r0
  CALL @emitd
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @dl_l
  CALL @ungetc
  SUB r14,r14,r13
  LD r15,r14,0
  JMP @endins
d_str:
  ST r15,r14,0
  ADD r14,r14,r13
  CALL @nextc
  MOVI r4,34
  CMP r1,r4
  JMP[NE] @ds_bad
ds_l:
  CALL @getc
  CMP r1,r0
  JMP[EQ] @ds_e
  MOVI r4,34
  CMP r1,r4
  JMP[EQ] @ds_e
  MOVI r4,92
  CMP r1,r4
  JMP[NE] @ds_p
  CALL @getc
  MOVI r4,110
  CMP r1,r4
  MOVI[EQ] r1,10
  MOVI r4,114
  CMP r1,r4
  MOVI[EQ] r1,13
  MOVI r4,116
  CMP r1,r4
  MOVI[EQ] r1,9
  MOVI r4,48
  CMP r1,r4
  MOVI[EQ] r1,0
ds_p:
  CALL @emitb
  JMP @ds_l
ds_bad:
  CALL @bump_err
ds_e:
  SUB r14,r14,r13
  LD r15,r14,0
  JMP @endins
d_equ:
  CALL @nextc
  CALL @rdhash1
  ADD r12,r5,r0
  CALL @expr
  ADD r5,r12,r0
  CALL @define
  JMP @endins
d_org:
  CALL @expr
  ADD r10,r8,r0
  LD r1,r0,#V_PC
  CMP r10,r1
  JMP[LT] @e_form
org_l:
  LD r1,r0,#V_PC
  CMP r1,r10
  JMP[EQ] @endins
  MOVI r1,0
  CALL @emitb
  JMP @org_l
d_align:
  CALL @expr
  ADD r10,r8,r0
  CMP r10,r0
  JMP[EQ] @e_form
  LD r1,r0,#V_PC
  ADD r1,r1,r10
  SUB r1,r1,r13
  ADD r3,r1,r0
  ADD r4,r10,r0
  DIVU r6,r3,r4
  MUL r7,r6,r4
al_l:
  LD r1,r0,#V_PC
  CMP r1,r7
  JMP[EQ] @endins
  MOVI r1,0
  CALL @emitb
  JMP @al_l
d_base:
  CALL @expr
  ST r8,r0,#V_BASE
  JMP @endins
d_code16:
  MOVI r4,0
  ST r4,r0,#V_MODE
  JMP @endins
d_code32:
  MOVI r4,1
  ST r4,r0,#V_MODE
  JMP @endins
m_inc_b:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @h_incdec
m_inc_w:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @h_incdec
m_inc_l:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @h_incdec
m_alu_b:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @h_alu
m_alu_w:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @h_alu
m_alu_l:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @h_alu
m_test_b:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @h_test
m_test_w:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @h_test
m_test_l:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @h_test
m_shift_b:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @h_shift
m_shift_w:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @h_shift
m_shift_l:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @h_shift
m_group_b:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @h_group
m_group_w:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @h_group
m_group_l:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @h_group
m_imul_b:
  MOVI r4,1
  ST r4,r0,#V_SZ
  JMP @m_imul
m_imul_w:
  MOVI r4,2
  ST r4,r0,#V_SZ
  JMP @m_imul
m_imul_l:
  MOVI r4,4
  ST r4,r0,#V_SZ
  JMP @m_imul
.include "nasm1_tables.nas"
