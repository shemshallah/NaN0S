; a64asm - AArch64 assembler written in NaN16 (round 28). Two-pass, fixed 4-byte instructions, flat byte output.
; Replaces tools/a64.awk. Input: A64 source text (4 chars/word LE, NUL-terminated) at SRC. Output: raw bytes at OUT.
; stdout: 'Y' or 'N', newline, then the emitted bytes via PUTC (same protocol as nasm1).
; Subset: movz movk mov add adds sub subs cmp neg and orr eor ands bic orn tst mvn lsl lsr asr ubfx sbfx ubfm sbfm mul udiv sdiv umulh smulh
;   madd msub rev rev16 ldr str ldrb strb ldrh strh (offset, register, post-index) b bl b.cc br blr ret cbz cbnz adr csel csinc cset mrs nop wfi isb
; Directives: .byte .word(32-bit) .quad .ascii .asciz .space .align(2^n) .org .equ NAME expr. Comments: ; and //.
.equ SRC 0x20000
.equ OUT 0x24000
.equ LAB 0x30000
.equ V_PASS 0x4000
.equ V_PC 0x4001
.equ V_BASE 0x4002
.equ V_ERR 0x4003
.equ V_NLAB 0x4004
.equ V_PB 0x400B
.equ V_OBP 0x400C
.equ V_SRCB 0x400D
.equ V_OUTB 0x400E
.equ V_LABB 0x400F
.equ V_ACC 0x4011
.equ V_SGN 0x4012
.equ V_OPN 0x4015
.equ V_AUX0 0x4016
.equ V_TMP 0x4020
.equ V_CW 0x4009
.equ V_CN 0x400A
.equ V_SRCP 0x4008
.equ V_OPP 0x4024
.equ V_IDN 0x4025
.equ V_IDH 0x4026
.equ V_T0 0x4027
.equ V_T1 0x4028
.equ V_T2 0x4029
.equ OPR 0x4100
.equ IDB 0x4140
_start:
  MOVI r0,0
  MOVI r13,1
  MOVI r14,0xF000
  MOVHI r14,0x0003
  ST r0,r0,#V_BASE
  ST r0,r0,#V_ERR
  ST r0,r0,#V_NLAB
  MOVI r4,0x0000
  MOVHI r4,0x0002
  ST r4,r0,#V_SRCB
  MOVI r4,0x4000
  MOVHI r4,0x0002
  ST r4,r0,#V_OUTB
  MOVI r4,0x0000
  MOVHI r4,0x0003
  ST r4,r0,#V_LABB
  CALL @pass1
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
  LD r2,r0,#V_SRCB
  ST r2,r0,#V_SRCP
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
  MOVI r4,47
  CMP r1,r4
  JMP[EQ] @pskip
  JMP @pstmt
pstmt:
  MOVI r4,46
  CMP r1,r4
  JMP[EQ] @pdir
  CALL @rdmn1
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
  CMP r1,r0
  JMP[EQ] @pl_done
  MOVI r4,10
  CMP r1,r4
  JMP[EQ] @pl_done
  MOVI r4,59
  CMP r1,r4
  JMP[EQ] @pl_done
  MOVI r4,47
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
  ST r12,r0,#V_T2
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
  MOVI r4,47
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
  LD r12,r0,#V_T2
  JMPR r12
di_err:
  CALL @bump_err
endins:
  CALL @skipline
  JMP @pl
e_form:
  CALL @bump_err
  JMP @endins
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
  ST r2,r0,#V_T1
  CALL @emitw
  LD r2,r0,#V_T1
  SHR r2,r2,16
  CALL @emitw
  SUB r14,r14,r13
  LD r15,r14,0
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
  CALL @rdhash1
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
  MOVI r4,88
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
; rdmn1: first char already in r1; reads identifier chars plus '.', djb2 upper-folded hash in r5
rdmn1:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r5,5381
  JMP @rm_a
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
rm1:
  CALL @getc
  MOVI r6,46
  CMP r1,r6
  JMP[EQ] @rm_a
  CALL @isid
  CMP r6,r0
  JMP[EQ] @rm2
rm_a:
  MOVI r6,97
  CMP r1,r6
  JMP[LT] @rm_b
  MOVI r6,123
  CMP r1,r6
  JMP[GE] @rm_b
  MOVI r6,32
  SUB r1,r1,r6
rm_b:
  SHL r6,r5,5
  ADD r5,r6,r5
  ADD r5,r5,r1
  JMP @rm1
rm2:
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
; ---------- operand parser: record n at OPR+8n = [type,A,B,C,D]; 1 reg(A=num,B=sf,C=sp) 2 imm(A) 3 mem(A=base,B=kind 0/1imm/2reg,C=imm|reg,D=lsl) 4 shift(A) 5 sym(A=hash,B=value,C=found)
parseop:
  ST r15,r14,0
  ADD r14,r14,r13
  LD r2,r0,#V_OPN
  SHL r2,r2,3
  MOVI r3,0x4100
  ADD r2,r2,r3
  ST r2,r0,#V_OPP
  ST r0,r2,0
  ST r0,r2,3
  ST r0,r2,4
  CALL @nextc
  MOVI r4,91
  CMP r1,r4
  JMP[EQ] @po_mem
  MOVI r4,35
  CMP r1,r4
  JMP[EQ] @po_imm
  MOVI r4,45
  CMP r1,r4
  JMP[EQ] @po_num
  MOVI r4,48
  CMP r1,r4
  JMP[LT] @po_idc
  MOVI r4,58
  CMP r1,r4
  JMP[LT] @po_num
po_idc:
  CALL @isid
  CMP r6,r0
  JMP[NE] @po_id
  JMP @po_err
po_num:
  CALL @ungetc
po_imm:
  CALL @expr
  LD r2,r0,#V_OPP
  MOVI r3,2
  ST r3,r2,0
  ST r8,r2,1
  JMP @po_x
po_err:
  CALL @bump_err
po_x:
  SUB r14,r14,r13
  LD r15,r14,0
  RET
po_id:
  CALL @rdid
  CALL @clsreg
  CMP r1,r0
  JMP[EQ] @po_nr
  LD r5,r0,#V_OPP
  MOVI r6,1
  ST r6,r5,0
  ST r2,r5,1
  ST r3,r5,2
  ST r4,r5,3
  JMP @po_x
po_nr:
  LD r5,r0,#V_IDH
  LD r6,r0,@hv_lsl
  CMP r5,r6
  JMP[EQ] @po_sh
  LD r6,r0,#V_LABB
  MOVI r7,2
  CALL @look
  LD r2,r0,#V_OPP
  MOVI r3,5
  ST r3,r2,0
  ST r5,r2,1
  CMP r1,r0
  JMP[EQ] @po_nf
  LD r4,r1,1
  ST r4,r2,2
  ST r13,r2,3
  JMP @po_x
po_nf:
  ST r0,r2,2
  ST r0,r2,3
  JMP @po_x
po_sh:
  CALL @nextc
  MOVI r4,35
  CMP r1,r4
  JMP[NE] @po_err
  CALL @expr
  LD r2,r0,#V_OPP
  MOVI r3,4
  ST r3,r2,0
  ST r8,r2,1
  JMP @po_x
po_mem:
  CALL @nextc
  CALL @rdid
  CALL @clsreg
  CMP r1,r0
  JMP[EQ] @po_err
  LD r5,r0,#V_OPP
  MOVI r6,3
  ST r6,r5,0
  ST r2,r5,1
  ST r0,r5,2
  ST r0,r5,3
  ST r0,r5,4
  CALL @nextc
  MOVI r4,93
  CMP r1,r4
  JMP[EQ] @po_x
  MOVI r4,44
  CMP r1,r4
  JMP[NE] @po_err
  CALL @nextc
  MOVI r4,35
  CMP r1,r4
  JMP[EQ] @pm_imm
  CALL @rdid
  CALL @clsreg
  CMP r1,r0
  JMP[EQ] @po_err
  LD r5,r0,#V_OPP
  MOVI r6,2
  ST r6,r5,2
  ST r2,r5,3
  CALL @nextc
  MOVI r4,93
  CMP r1,r4
  JMP[EQ] @po_x
  MOVI r4,44
  CMP r1,r4
  JMP[NE] @po_err
  CALL @nextc
  CALL @rdid
  CALL @nextc
  MOVI r4,35
  CMP r1,r4
  JMP[NE] @po_err
  CALL @expr
  LD r5,r0,#V_OPP
  ST r8,r5,4
  CALL @nextc
  JMP @po_x
pm_imm:
  CALL @expr
  LD r5,r0,#V_OPP
  MOVI r6,1
  ST r6,r5,2
  ST r8,r5,3
  CALL @nextc
  JMP @po_x
; rdid: r1 = first char; lowercase text -> IDB, length V_IDN, djb2(upper) -> V_IDH and r5; terminator pushed back
rdid:
  ST r15,r14,0
  ADD r14,r14,r13
  MOVI r5,5381
  MOVI r9,0x4140
  MOVI r10,0
rd_l:
  ADD r12,r1,r0
  MOVI r6,65
  CMP r1,r6
  JMP[LT] @rd_u1
  MOVI r6,91
  CMP r1,r6
  JMP[GE] @rd_u1
  MOVI r6,32
  ADD r12,r12,r6
rd_u1:
  MOVI r6,97
  CMP r1,r6
  JMP[LT] @rd_h
  MOVI r6,123
  CMP r1,r6
  JMP[GE] @rd_h
  MOVI r6,32
  SUB r1,r1,r6
rd_h:
  SHL r6,r5,5
  ADD r5,r6,r5
  ADD r5,r5,r1
  MOVI r6,15
  CMP r10,r6
  JMP[GE] @rd_n
  ADD r6,r9,r10
  ST r12,r6,0
rd_n:
  ADD r10,r10,r13
  CALL @getc
  CALL @isid
  CMP r6,r0
  JMP[NE] @rd_l
  CALL @ungetc
  ST r10,r0,#V_IDN
  ST r5,r0,#V_IDH
  SUB r14,r14,r13
  LD r15,r14,0
  RET
; clsreg: IDB/IDN -> r1 (1 = register) r2 number r3 sf r4 sp
clsreg:
  LD r5,r0,#V_IDN
  MOVI r9,0x4140
  LD r6,r9,0
  MOVI r7,2
  CMP r5,r7
  JMP[NE] @cr_z
  MOVI r7,115
  CMP r6,r7
  JMP[NE] @cr_z
  LD r7,r9,1
  MOVI r8,112
  CMP r7,r8
  JMP[NE] @cr_z
  MOVI r1,1
  MOVI r2,31
  MOVI r3,1
  MOVI r4,1
  RET
cr_z:
  MOVI r7,3
  CMP r5,r7
  JMP[NE] @cr_n
  LD r7,r9,1
  MOVI r8,122
  CMP r7,r8
  JMP[NE] @cr_n
  LD r7,r9,2
  MOVI r8,114
  CMP r7,r8
  JMP[NE] @cr_n
  MOVI r2,31
  MOVI r4,0
  MOVI r8,120
  CMP r6,r8
  JMP[NE] @cr_zw
  MOVI r1,1
  MOVI r3,1
  RET
cr_zw:
  MOVI r8,119
  CMP r6,r8
  JMP[NE] @cr_no
  MOVI r1,1
  MOVI r3,0
  RET
cr_n:
  MOVI r8,120
  CMP r6,r8
  JMP[EQ] @cr_x
  MOVI r8,119
  CMP r6,r8
  JMP[EQ] @cr_w
  JMP @cr_no
cr_x:
  MOVI r3,1
  JMP @cr_d
cr_w:
  MOVI r3,0
cr_d:
  MOVI r7,2
  CMP r5,r7
  JMP[LT] @cr_no
  MOVI r7,4
  CMP r5,r7
  JMP[GE] @cr_no
  LD r7,r9,1
  MOVI r8,48
  CMP r7,r8
  JMP[LT] @cr_no
  MOVI r8,58
  CMP r7,r8
  JMP[GE] @cr_no
  MOVI r8,48
  SUB r2,r7,r8
  MOVI r7,2
  CMP r5,r7
  JMP[EQ] @cr_ok
  LD r7,r9,2
  MOVI r8,48
  CMP r7,r8
  JMP[LT] @cr_no
  MOVI r8,58
  CMP r7,r8
  JMP[GE] @cr_no
  MOVI r8,10
  MUL r2,r2,r8
  MOVI r8,48
  SUB r7,r7,r8
  ADD r2,r2,r7
cr_ok:
  MOVI r8,30
  CMP r2,r8
  JMP[GT] @cr_no
  MOVI r1,1
  MOVI r4,0
  RET
cr_no:
  MOVI r1,0
  RET
; tgt: r9 = record ptr (sym) -> r1 ok, r2 = target - pc (bytes)
tgt:
  LD r1,r9,0
  MOVI r4,5
  CMP r1,r4
  JMP[NE] @tg_bad
  LD r2,r9,2
  LD r3,r9,3
  CMP r3,r0
  JMP[NE] @tg_ok
  LD r4,r0,#V_PASS
  MOVI r5,2
  CMP r4,r5
  JMP[NE] @tg_ok
  JMP @tg_bad
tg_ok:
  LD r3,r0,#V_BASE
  LD r4,r0,#V_PC
  ADD r3,r3,r4
  SUB r2,r2,r3
  MOVI r1,1
  RET
tg_bad:
  MOVI r1,0
  RET
; condv: r5 = hash -> r1 = code or 0xFFFFFFFF
condv:
  MOVI r6,@conds
  MOVI r7,2
  ST r15,r14,0
  ADD r14,r14,r13
  CALL @look
  SUB r14,r14,r13
  LD r15,r14,0
  CMP r1,r0
  JMP[EQ] @cv_no
  LD r1,r1,1
  RET
cv_no:
  MOVI r1,0xFFFF
  MOVHI r1,0xFFFF
  RET
; ---------- r28c: handlers + directives. Every handler builds the 32-bit word in r2 and jumps to fin (emit, then endins).
; Operand records (OPR): op1 0x4100, op2 0x4108, op3 0x4110, op4 0x4118; fields [type,A,B,C,D]; n = V_OPN.
.equ V_S0 0x4030
.equ V_S1 0x4031
fin:
  CALL @emitd
  JMP @endins
h_fix:
  LD r2,r0,#V_AUX0
  JMP @fin
h_movw:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  LD r1,r10,0
  MOVI r4,2
  CMP r1,r4
  JMP[NE] @e_form
  LD r1,r9,2
  MOVI r2,0x5280
  MOVI r3,0x8000
  CMP r1,r0
  ADD[NE] r2,r2,r3
  LD r3,r0,#V_AUX0
  MOVI r4,0x2000
  CMP r3,r0
  ADD[NE] r2,r2,r4
  SHL r2,r2,16
  LD r3,r10,1
  MOVI r4,0xFFFF
  CMP r3,r4
  JMP[GT] @e_form
  SHL r3,r3,5
  ADD r2,r2,r3
  LD r3,r9,1
  ADD r2,r2,r3
  LD r4,r0,#V_OPN
  MOVI r5,3
  CMP r4,r5
  JMP[LT] @fin
  LD r3,r11,1
  SHR r3,r3,4
  SHL r3,r3,21
  ADD r2,r2,r3
  JMP @fin
h_mov:
  MOVI r9,0x4100
  MOVI r10,0x4108
  LD r1,r10,0
  CMP r1,r13
  JMP[NE] @mv_i
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  MOVI r5,0x2A00
  MOVI r6,0x8000
  CMP r3,r0
  ADD[NE] r5,r5,r6
  SHL r5,r5,16
  MOVI r6,0x03E0
  ADD r5,r5,r6
  SHL r4,r4,16
  ADD r5,r5,r4
  ADD r2,r2,r5
  JMP @fin
mv_i:
  ST r0,r0,#V_AUX0
  JMP @h_movw
h_arith:
  MOVI r9,0x4100
  MOVI r10,0x4108
  LD r7,r0,#V_AUX0
  LD r8,r0,#V_OPN
  ADD r6,r7,r0
  MOVI r1,4
  CMP r7,r1
  JMP[EQ] @ar_cmp
  MOVI r1,5
  CMP r7,r1
  JMP[EQ] @ar_neg
  MOVI r1,3
  CMP r8,r1
  JMP[LT] @e_form
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  MOVI r5,0x4110
  SUB r1,r8,r1
  JMP @ar_go
ar_cmp:
  MOVI r6,3
  MOVI r1,2
  CMP r8,r1
  JMP[LT] @e_form
  MOVI r2,31
  LD r3,r9,2
  LD r4,r9,1
  MOVI r5,0x4108
  SUB r1,r8,r1
  JMP @ar_go
ar_neg:
  MOVI r6,2
  MOVI r1,2
  CMP r8,r1
  JMP[LT] @e_form
  LD r2,r9,1
  LD r3,r9,2
  MOVI r4,31
  MOVI r5,0x4108
  SUB r1,r8,r1
ar_go:
  MOVI r7,0
  CMP r1,r0
  JMP[EQ] @ar_ns
  LD r7,r5,9
ar_ns:
  SHL r6,r6,13
  MOVI r1,0x8000
  CMP r3,r0
  ADD[NE] r6,r6,r1
  LD r8,r5,0
  MOVI r1,2
  CMP r8,r1
  JMP[EQ] @ar_imm
  CMP r8,r13
  JMP[NE] @e_form
  MOVI r1,0x0B00
  ADD r6,r6,r1
  SHL r6,r6,16
  LD r8,r5,1
  SHL r8,r8,16
  ADD r6,r6,r8
  SHL r7,r7,10
  ADD r6,r6,r7
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
ar_imm:
  MOVI r1,0x1100
  ADD r6,r6,r1
  SHL r6,r6,16
  LD r8,r5,1
  MOVI r1,4095
  CMP r8,r1
  JMP[GT] @e_form
  SHL r8,r8,10
  ADD r6,r6,r8
  MOVI r1,12
  CMP r7,r1
  JMP[NE] @ar_i2
  MOVI r1,0x40
  SHL r1,r1,16
  ADD r6,r6,r1
ar_i2:
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
h_logic:
  MOVI r9,0x4100
  MOVI r10,0x4108
  LD r7,r0,#V_AUX0
  LD r8,r0,#V_OPN
  MOVI r1,6
  CMP r7,r1
  JMP[EQ] @lg_tst
  MOVI r1,7
  CMP r7,r1
  JMP[EQ] @lg_mvn
  MOVI r1,3
  CMP r8,r1
  JMP[LT] @e_form
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  MOVI r5,0x4110
  SUB r1,r8,r1
  MOVI r6,3
  BOOL.8 r6,r7,r6
  SHR r8,r7,2
  JMP @lg_go
lg_tst:
  MOVI r1,2
  CMP r8,r1
  JMP[LT] @e_form
  MOVI r2,31
  LD r3,r9,2
  LD r4,r9,1
  MOVI r5,0x4108
  SUB r1,r8,r1
  MOVI r6,3
  MOVI r8,0
  JMP @lg_go
lg_mvn:
  MOVI r1,2
  CMP r8,r1
  JMP[LT] @e_form
  LD r2,r9,1
  LD r3,r9,2
  MOVI r4,31
  MOVI r5,0x4108
  SUB r1,r8,r1
  MOVI r6,1
  MOVI r8,1
lg_go:
  MOVI r7,0
  CMP r1,r0
  JMP[EQ] @lg_ns
  LD r7,r5,9
lg_ns:
  LD r1,r5,0
  CMP r1,r13
  JMP[NE] @e_form
  SHL r6,r6,13
  SHL r8,r8,5
  ADD r6,r6,r8
  MOVI r1,0x0A00
  ADD r6,r6,r1
  MOVI r1,0x8000
  CMP r3,r0
  ADD[NE] r6,r6,r1
  SHL r6,r6,16
  LD r8,r5,1
  SHL r8,r8,16
  ADD r6,r6,r8
  SHL r7,r7,10
  ADD r6,r6,r7
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
h_shift:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  LD r7,r0,#V_AUX0
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  LD r5,r11,0
  CMP r5,r13
  JMP[EQ] @sh_reg
  LD r5,r11,1
  MOVI r6,32
  MOVI r1,64
  CMP r3,r0
  ADD[NE] r6,r1,r0
  CMP r5,r6
  JMP[GE] @e_form
  CMP r7,r0
  JMP[NE] @sh_r1
  SUB r8,r6,r5
  CMP r5,r0
  MOVI[EQ] r8,0
  SUB r1,r6,r13
  SUB r1,r1,r5
  JMP @sh_e
sh_r1:
  ADD r8,r5,r0
  SUB r1,r6,r13
sh_e:
  MOVI r6,0x5300
  MOVI r9,2
  CMP r7,r9
  MOVI[EQ] r6,0x1300
  MOVI r9,0x8040
  CMP r3,r0
  ADD[NE] r6,r6,r9
  SHL r6,r6,16
  SHL r8,r8,16
  ADD r6,r6,r8
  SHL r1,r1,10
  ADD r6,r6,r1
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
sh_reg:
  LD r5,r11,1
  MOVI r6,0x1AC0
  MOVI r9,0x8000
  CMP r3,r0
  ADD[NE] r6,r6,r9
  SHL r6,r6,16
  SHL r5,r5,16
  ADD r6,r6,r5
  MOVI r5,0x2000
  SHL r7,r7,10
  ADD r5,r5,r7
  ADD r6,r6,r5
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
h_bfx:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  MOVI r12,0x4118
  LD r7,r0,#V_AUX0
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  LD r5,r11,1
  LD r6,r12,1
  MOVI r1,2
  CMP r7,r1
  JMP[GE] @bf_m
  ADD r6,r5,r6
  SUB r6,r6,r13
bf_m:
  MOVI r8,0x5300
  MOVI r1,1
  BOOL.8 r1,r7,r1
  CMP r1,r0
  MOVI[NE] r8,0x1300
  MOVI r1,0x8040
  CMP r3,r0
  ADD[NE] r8,r8,r1
  SHL r8,r8,16
  SHL r5,r5,16
  ADD r8,r8,r5
  SHL r6,r6,10
  ADD r8,r8,r6
  SHL r4,r4,5
  ADD r8,r8,r4
  ADD r2,r2,r8
  JMP @fin
h_mul:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  LD r7,r0,#V_AUX0
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  LD r5,r11,1
  MOVI r6,@mul_t
  ADD r6,r6,r7
  LD r6,r6,0
  MOVI r1,3
  CMP r7,r1
  JMP[GE] @mu_g
  CMP r3,r0
  JMP[EQ] @mu_g
  MOVI r1,0x8000
  SHL r1,r1,16
  ADD r6,r6,r1
mu_g:
  SHL r5,r5,16
  ADD r6,r6,r5
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
mul_t:
.word 0x1B007C00,0x1AC00800,0x1AC00C00,0x9BC07C00,0x9B407C00
h_madd:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  MOVI r12,0x4118
  LD r7,r0,#V_AUX0
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  LD r5,r11,1
  LD r6,r12,1
  MOVI r1,0x1B00
  MOVI r8,0x8000
  CMP r3,r0
  ADD[NE] r1,r1,r8
  SHL r1,r1,16
  CMP r7,r0
  JMP[EQ] @ma_a
  ADD r1,r1,r8
ma_a:
  SHL r5,r5,16
  ADD r1,r1,r5
  SHL r6,r6,10
  ADD r1,r1,r6
  SHL r4,r4,5
  ADD r1,r1,r4
  ADD r2,r2,r1
  JMP @fin
h_rev:
  MOVI r9,0x4100
  MOVI r10,0x4108
  LD r7,r0,#V_AUX0
  LD r2,r9,1
  LD r3,r9,2
  LD r4,r10,1
  MOVI r6,0x5AC0
  MOVI r8,0x8000
  CMP r3,r0
  ADD[NE] r6,r6,r8
  SHL r6,r6,16
  MOVI r5,0x0800
  MOVI r8,0x0C00
  CMP r3,r0
  ADD[NE] r5,r8,r0
  MOVI r8,0x0400
  CMP r7,r0
  ADD[NE] r5,r8,r0
  ADD r6,r6,r5
  SHL r4,r4,5
  ADD r6,r6,r4
  ADD r2,r2,r6
  JMP @fin
pw:
.word 1,2,4,8
h_ldst:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  LD r7,r0,#V_AUX0
  LD r2,r9,1
  LD r3,r9,2
  MOVI r1,1
  BOOL.8 r8,r7,r1
  SHR r4,r7,1
  CMP r4,r0
  JMP[NE] @ls_bh
  MOVI r4,2
  CMP r3,r0
  MOVI[NE] r4,3
  JMP @ls_sz
ls_bh:
  SUB r4,r4,r13
ls_sz:
  SHL r5,r4,6
  MOVI r1,0x38
  ADD r5,r5,r1
  LD r6,r10,1
  LD r1,r0,#V_OPN
  MOVI r9,3
  CMP r1,r9
  JMP[GE] @ls_post
  LD r9,r10,2
  CMP r9,r0
  JMP[EQ] @ls_u0
  CMP r9,r13
  JMP[EQ] @ls_u1
  LD r9,r10,3
  LD r1,r10,4
  MOVI r12,0
  CMP r1,r0
  JMP[EQ] @ls_r2
  CMP r1,r4
  JMP[NE] @e_form
  MOVI r12,0x1000
ls_r2:
  SHL r1,r5,8
  MOVI r5,0x20
  CMP r8,r0
  JMP[NE] @ls_r3
  MOVI r5,0x60
ls_r3:
  ADD r1,r1,r5
  SHL r1,r1,16
  SHL r9,r9,16
  ADD r1,r1,r9
  MOVI r9,0x6800
  ADD r1,r1,r9
  ADD r1,r1,r12
  SHL r6,r6,5
  ADD r1,r1,r6
  ADD r2,r2,r1
  JMP @fin
ls_u0:
  MOVI r9,0
  JMP @ls_u
ls_u1:
  LD r9,r10,3
ls_u:
  MOVI r1,@pw
  ADD r1,r1,r4
  LD r1,r1,0
  MODU r12,r9,r1
  CMP r12,r0
  JMP[NE] @e_form
  DIVU r9,r9,r1
  MOVI r1,4095
  CMP r9,r1
  JMP[GT] @e_form
  ADD r1,r5,r13
  SHL r1,r1,8
  CMP r8,r0
  JMP[NE] @ls_u2
  MOVI r12,0x40
  ADD r1,r1,r12
ls_u2:
  SHL r1,r1,16
  SHL r9,r9,10
  ADD r1,r1,r9
  SHL r6,r6,5
  ADD r1,r1,r6
  ADD r2,r2,r1
  JMP @fin
ls_post:
  LD r9,r11,1
  MOVI r1,0x1FF
  BOOL.8 r9,r9,r1
  SHL r9,r9,12
  SHL r1,r5,8
  CMP r8,r0
  JMP[NE] @ls_p2
  MOVI r12,0x40
  ADD r1,r1,r12
ls_p2:
  SHL r1,r1,16
  ADD r1,r1,r9
  MOVI r9,0x0400
  ADD r1,r1,r9
  SHL r6,r6,5
  ADD r1,r1,r6
  ADD r2,r2,r1
  JMP @fin
h_b:
  MOVI r9,0x4100
  CALL @tgt
  CMP r1,r0
  JMP[EQ] @e_form
  SAR r2,r2,2
  MOVI r3,0xFFFF
  MOVHI r3,0x03FF
  BOOL.8 r2,r2,r3
  LD r7,r0,#V_AUX0
  MOVI r3,0x1400
  MOVI r4,0x9400
  CMP r7,r0
  ADD[NE] r3,r4,r0
  SHL r3,r3,16
  ADD r2,r2,r3
  JMP @fin
h_bcc:
  MOVI r9,0x4100
  CALL @tgt
  CMP r1,r0
  JMP[EQ] @e_form
  SAR r2,r2,2
  MOVI r3,0xFFFF
  MOVHI r3,0x0007
  BOOL.8 r2,r2,r3
  SHL r2,r2,5
  LD r7,r0,#V_AUX0
  ADD r2,r2,r7
  MOVI r3,0x5400
  SHL r3,r3,16
  ADD r2,r2,r3
  JMP @fin
h_br:
  MOVI r9,0x4100
  LD r7,r0,#V_AUX0
  LD r4,r9,1
  MOVI r2,0xD61F
  SHL r2,r2,16
  SHL r7,r7,21
  ADD r2,r2,r7
  SHL r4,r4,5
  ADD r2,r2,r4
  JMP @fin
h_cbz:
  MOVI r9,0x4100
  LD r7,r0,#V_AUX0
  LD r6,r9,1
  LD r8,r9,2
  MOVI r9,0x4108
  CALL @tgt
  CMP r1,r0
  JMP[EQ] @e_form
  SAR r2,r2,2
  MOVI r3,0xFFFF
  MOVHI r3,0x0007
  BOOL.8 r2,r2,r3
  SHL r2,r2,5
  ADD r2,r2,r6
  MOVI r3,0x3400
  SHL r7,r7,8
  ADD r3,r3,r7
  MOVI r4,0x8000
  CMP r8,r0
  ADD[NE] r3,r3,r4
  SHL r3,r3,16
  ADD r2,r2,r3
  JMP @fin
h_adr:
  MOVI r9,0x4100
  LD r6,r9,1
  MOVI r9,0x4108
  CALL @tgt
  CMP r1,r0
  JMP[EQ] @e_form
  MOVI r3,0xFFFF
  MOVHI r3,0x001F
  BOOL.8 r2,r2,r3
  MOVI r3,3
  BOOL.8 r4,r2,r3
  SHL r4,r4,29
  SHR r2,r2,2
  SHL r2,r2,5
  ADD r2,r2,r4
  ADD r2,r2,r6
  MOVI r3,0x1000
  SHL r3,r3,16
  ADD r2,r2,r3
  JMP @fin
h_csel:
  MOVI r9,0x4100
  MOVI r10,0x4108
  MOVI r11,0x4110
  MOVI r12,0x4118
  LD r1,r12,0
  MOVI r4,5
  CMP r1,r4
  JMP[NE] @e_form
  LD r2,r9,1
  ST r2,r0,#V_S0
  LD r2,r9,2
  LD r3,r10,1
  LD r4,r11,1
  LD r5,r0,#V_AUX0
  SHL r5,r5,10
  SHL r4,r4,16
  ADD r5,r5,r4
  SHL r3,r3,5
  ADD r5,r5,r3
  MOVI r3,0x1A80
  MOVI r4,0x8000
  CMP r2,r0
  ADD[NE] r3,r3,r4
  SHL r3,r3,16
  ADD r5,r5,r3
  ST r5,r0,#V_S1
  LD r5,r12,1
  CALL @condv
  MOVI r6,0xFFFF
  MOVHI r6,0xFFFF
  CMP r1,r6
  JMP[EQ] @e_form
  SHL r1,r1,12
  LD r2,r0,#V_S1
  ADD r2,r2,r1
  LD r3,r0,#V_S0
  ADD r2,r2,r3
  JMP @fin
h_cset:
  MOVI r9,0x4100
  MOVI r10,0x4108
  LD r1,r10,0
  MOVI r4,5
  CMP r1,r4
  JMP[NE] @e_form
  LD r2,r9,1
  ST r2,r0,#V_S0
  LD r2,r9,2
  MOVI r3,0x1A9F
  MOVI r4,0x8000
  CMP r2,r0
  ADD[NE] r3,r3,r4
  SHL r3,r3,16
  MOVI r4,0x07E0
  ADD r3,r3,r4
  ST r3,r0,#V_S1
  LD r5,r10,1
  CALL @condv
  MOVI r6,0xFFFF
  MOVHI r6,0xFFFF
  CMP r1,r6
  JMP[EQ] @e_form
  MOVI r4,1
  BOOL.6 r1,r1,r4
  SHL r1,r1,12
  LD r2,r0,#V_S1
  ADD r2,r2,r1
  LD r3,r0,#V_S0
  ADD r2,r2,r3
  JMP @fin
h_mrs:
  MOVI r9,0x4100
  MOVI r10,0x4108
  LD r2,r9,1
  LD r5,r10,1
  LD r6,r0,@hv_cntvct
  MOVI r3,0xE040
  CMP r5,r6
  JMP[EQ] @mrs_g
  LD r6,r0,@hv_cntfrq
  MOVI r3,0xE000
  CMP r5,r6
  JMP[NE] @e_form
mrs_g:
  ADD r2,r2,r3
  MOVI r3,0xD53B
  SHL r3,r3,16
  ADD r2,r2,r3
  JMP @fin
; ---------- directives (value lists end with ungetc of the terminator, then endins skips the line)
dnext:
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  RET[EQ]
  CALL @ungetc
  JMP @endins
d_byte:
  CALL @expr
  ADD r1,r8,r0
  CALL @emitb
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @d_byte
  CALL @ungetc
  JMP @endins
d_word:
  CALL @expr
  ADD r2,r8,r0
  CALL @emitd
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @d_word
  CALL @ungetc
  JMP @endins
d_quad:
  CALL @expr
  ADD r2,r8,r0
  CALL @emitd
  MOVI r2,0
  CALL @emitd
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @d_quad
  CALL @ungetc
  JMP @endins
d_space:
  CALL @expr
  ST r8,r0,#V_S0
ds_l:
  LD r2,r0,#V_S0
  CMP r2,r0
  JMP[EQ] @endins
  SUB r2,r2,r13
  ST r2,r0,#V_S0
  MOVI r1,0
  CALL @emitb
  JMP @ds_l
d_align:
  CALL @expr
  MOVI r9,1
da_p:
  CMP r8,r0
  JMP[EQ] @da_g
  ADD r9,r9,r9
  SUB r8,r8,r13
  JMP @da_p
da_g:
  ST r9,r0,#V_S0
da_l:
  LD r2,r0,#V_BASE
  LD r3,r0,#V_PC
  ADD r2,r2,r3
  LD r4,r0,#V_S0
  MODU r2,r2,r4
  CMP r2,r0
  JMP[EQ] @endins
  MOVI r1,0
  CALL @emitb
  JMP @da_l
d_org:
  CALL @expr
  ST r8,r0,#V_S0
do_l:
  LD r2,r0,#V_BASE
  LD r3,r0,#V_PC
  ADD r2,r2,r3
  LD r4,r0,#V_S0
  CMP r2,r4
  JMP[GE] @endins
  MOVI r1,0
  CALL @emitb
  JMP @do_l
d_equ:
  CALL @nextc
  CALL @rdhash1
  ST r5,r0,#V_S0
  CALL @nextc
  MOVI r4,44
  CMP r1,r4
  JMP[EQ] @eq_v
  CALL @ungetc
eq_v:
  CALL @expr
  LD r5,r0,#V_S0
  CALL @define
  JMP @endins
d_strz:
  MOVI r9,1
  ST r9,r0,#V_S1
  JMP @st_go
d_str:
  ST r0,r0,#V_S1
st_go:
  CALL @nextc
  MOVI r4,34
  CMP r1,r4
  JMP[NE] @e_form
st_l:
  CALL @getc
  CMP r1,r0
  JMP[EQ] @st_e
  MOVI r4,34
  CMP r1,r4
  JMP[EQ] @st_e
  MOVI r4,92
  CMP r1,r4
  JMP[NE] @st_c
  CALL @getc
  MOVI r4,110
  CMP r1,r4
  MOVI[EQ] r1,10
  MOVI r4,114
  CMP r1,r4
  MOVI[EQ] r1,13
st_c:
  CALL @emitb
  JMP @st_l
st_e:
  LD r2,r0,#V_S1
  CMP r2,r0
  JMP[EQ] @endins
  MOVI r1,0
  CALL @emitb
  JMP @endins
hv_lsl:
.word 193462576
hv_cntvct:
.word 3329589207
hv_cntfrq:
.word 429444019
mnem:
.word 2089329713,@h_movw,0
.word 2089329698,@h_movw,1
.word 193463543,@h_mov,0
.word 193450094,@h_arith,0
.word 2088885889,@h_arith,1
.word 193470255,@h_arith,2
.word 2089551202,@h_arith,3
.word 193452581,@h_arith,4
.word 193464287,@h_arith,5
.word 193450424,@h_logic,0
.word 193465816,@h_logic,1
.word 193454827,@h_logic,2
.word 2088896779,@h_logic,3
.word 193451347,@h_logic,4
.word 193465812,@h_logic,5
.word 193471296,@h_logic,6
.word 193463766,@h_logic,7
.word 193462576,@h_shift,0
.word 193462582,@h_shift,1
.word 193450603,@h_shift,2
.word 2089602522,@h_bfx,0
.word 2089530648,@h_bfx,1
.word 2089602511,@h_bfx,2
.word 2089530637,@h_bfx,3
.word 193463731,@h_mul,0
.word 2089604797,@h_mul,1
.word 2089532923,@h_mul,2
.word 237817808,@h_mul,3
.word 235445966,@h_mul,4
.word 2089313851,@h_madd,0
.word 2089334012,@h_madd,1
.word 193468658,@h_rev,0
.word 233972729,@h_rev,1
.word 193462087,@h_ldst,0
.word 193470238,@h_ldst,1
.word 2089281641,@h_ldst,2
.word 2089550624,@h_ldst,3
.word 2089281647,@h_ldst,4
.word 2089550630,@h_ldst,5
.word 177639,@h_b,0
.word 5862163,@h_b,1
.word 5862169,@h_br,0
.word 193451461,@h_br,1
.word 193452228,@h_cbz,0
.word 2088955922,@h_cbz,1
.word 193450108,@h_adr,0
.word 2088974124,@h_csel,0
.word 216673845,@h_csel,1
.word 2088974132,@h_cset,0
.word 193463639,@h_mrs,0
.word 193468656,@h_fix,3596551104
.word 193464626,@h_fix,3573751839
.word 193474123,@h_fix,3573751935
.word 193459299,@h_fix,3573759967
.word 2088897899,@h_bcc,0
.word 2088898184,@h_bcc,1
.word 2088897835,@h_bcc,2
.word 2088898000,@h_bcc,2
.word 2088897819,@h_bcc,3
.word 2088898128,@h_bcc,3
.word 2088898155,@h_bcc,4
.word 2088898257,@h_bcc,5
.word 2088898462,@h_bcc,6
.word 2088898446,@h_bcc,7
.word 2088897990,@h_bcc,8
.word 2088898132,@h_bcc,9
.word 2088897953,@h_bcc,10
.word 2088898133,@h_bcc,11
.word 2088897968,@h_bcc,12
.word 2088898118,@h_bcc,13
.word 2088897762,@h_bcc,14
.word 0,0,0
conds:
.word 5862267,0
.word 5862552,1
.word 5862203,2
.word 5862368,2
.word 5862187,3
.word 5862496,3
.word 5862523,4
.word 5862625,5
.word 5862830,6
.word 5862814,7
.word 5862358,8
.word 5862500,9
.word 5862321,10
.word 5862501,11
.word 5862336,12
.word 5862486,13
.word 5862130,14
.word 0,0
dirs:
.word 2088945209,@d_byte,0
.word 2089688929,@d_word,0
.word 2089479280,@d_quad,0
.word 214295310,@d_str,0
.word 214295327,@d_strz,0
.word 235531697,@d_space,0
.word 214050224,@d_align,0
.word 193465805,@d_org,0
.word 193454896,@d_equ,0
.word 0,0,0
