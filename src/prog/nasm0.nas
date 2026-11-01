; nasm0 - the NaN16 assembler written in NaN16 (round 08). Reads packed source text (4 chars/word, LE, NUL-terminated)
; at #SRC and emits NaN words (STW) at #OUT. Two passes over the SAME parser: pass 1 counts words and defines labels
; (unresolved @refs read 0), pass 2 stores. Every stored word is mirror-checked: BSWAPM, LDN must equal rot2(n), BSWAPM back.
; Region bases (SRC/OUT/LAB/EXP/EXPC) are 32-bit values in VARS (V_SRCB..), so buffers may live anywhere in a flat NaN memory.
; Conventions: r0=0 r13=1 r14=SP(grows up) r15=link. Every routine clobbers r1..r9 ONLY; r10..r12 survive calls.
; Grammar v0: label:  .word expr,..  .org expr  .str "..." (\n \r \t \0 \\ \")  .equ NAME expr  MNEM[.N|[PRED]] operands
; operands: rN  | expr = term{(+|-)term}  term = decimal | 0xHEX | @label | #EQU ; unary '-' allowed. Hash h=(h<<5)+h+c from 5381.
.equ SRC 2048
.equ EXP 5120
.equ EXPC 6144
.equ VARS 6272
.equ OUT 6400
.equ LAB 7424
.equ STACK 7936
.equ V_PASS 6272
.equ V_IDX 6273
.equ V_CW 6274
.equ V_CN 6275
.equ V_SRCP 6276
.equ V_PB 6277
.equ V_NLAB 6278
.equ V_ERR 6279
.equ V_MIRR 6280
.equ V_OP 6281
.equ V_FORM 6282
.equ V_N 6283
.equ V_D 6284
.equ V_A 6285
.equ V_I 6286
.equ V_ACC 6287
.equ V_SGN 6288
.equ V_H 6289
.equ V_EXPN 6290
.equ V_FIRST 6291
.equ V_DIFF 6292
.equ V_SRCB 6293
.equ V_OUTB 6294
.equ V_LABB 6295
.equ V_EXPB 6296
.equ V_EXPCB 6297
; ---- run: one full pass over the source (V_PASS = 1 or 2 set by caller)
run:
ST r15,r14,0
ADD r14,r14,r13
LD r2,r0,#V_SRCB
ST r2,r0,#V_SRCP
ST r0,r0,#V_CN
ST r0,r0,#V_PB
ST r0,r0,#V_IDX
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
LD r2,r0,#V_PASS
CMP r2,r13
JMP[NE] @pskip
LD r8,r0,#V_IDX
CALL @define
JMP @pskip
pdir:
CALL @rdhash
MOVI r6,@dirs
MOVI r7,2
CALL @look
CMP r1,r0
JMP[EQ] @pbad
LD r2,r1,1
CMP r2,r13
JMP[EQ] @d_word
MOVI r4,2
CMP r2,r4
JMP[EQ] @d_str
MOVI r4,4
CMP r2,r4
JMP[EQ] @d_org
JMP @d_equ
pbad:
LD r2,r0,#V_ERR
ADD r2,r2,r13
ST r2,r0,#V_ERR
JMP @pskip
pdone:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- directives
d_word:
CALL @expr
MOVI r1,10
BOOL.12 r2,r8,r8
CALL @emit
CALL @nextc
MOVI r4,44
CMP r1,r4
JMP[EQ] @d_word
CALL @ungetc
JMP @pskip
d_equ:
CALL @nextc
CALL @rdhash1
ST r5,r0,#V_H
CALL @expr
LD r5,r0,#V_H
LD r2,r0,#V_PASS
CMP r2,r13
JMP[NE] @pskip
CALL @define
JMP @pskip
; .org expr - pad to an absolute word index (both passes)
d_org:
CALL @expr
LD r2,r0,#V_IDX
CMP r8,r2
JMP[LT] @pbad
LD r3,r0,#V_PASS
MOVI r4,2
CMP r3,r4
JMP[NE] @org_set
org_pad:
LD r2,r0,#V_IDX
CMP r2,r8
JMP[GE] @org_set
MOVI r1,10
MOVI r2,0
CALL @emit
JMP @org_pad
org_set:
ST r8,r0,#V_IDX
JMP @pskip
d_str:
CALL @nextc
MOVI r10,0
MOVI r11,0
ds1:
CALL @getc
CMP r1,r0
JMP[EQ] @ds_end
MOVI r4,34
CMP r1,r4
JMP[EQ] @ds_end
MOVI r4,92
CMP r1,r4
JMP[NE] @ds_put
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
ds_put:
CALL @spush
JMP @ds1
ds_end:
MOVI r1,0
CALL @spush
ds_pad:
CMP r11,r0
JMP[EQ] @pskip
MOVI r1,0
CALL @spush
JMP @ds_pad
; spush: r1=char; r10=acc r11=count. Packs LE: acc=(acc>>8)|(c<<24); at 4 chars emits a +q/+q data word.
spush:
SHR r10,r10,8
SHL r2,r1,24
BOOL.14 r10,r10,r2
ADD r11,r11,r13
MOVI r4,4
CMP r11,r4
RET[NE]
ST r15,r14,0
ADD r14,r14,r13
MOVI r1,10
BOOL.12 r2,r10,r10
CALL @emit
SUB r14,r14,r13
LD r15,r14,0
MOVI r10,0
MOVI r11,0
RET
; ---- instruction: r5 = mnemonic hash
do_ins:
ST r15,r14,0
ADD r14,r14,r13
MOVI r6,@mnem
MOVI r7,3
CALL @look
CMP r1,r0
JMP[EQ] @di_err
LD r2,r1,1
ST r2,r0,#V_OP
LD r2,r1,2
ST r2,r0,#V_FORM
MOVI r2,15
ST r2,r0,#V_N
ST r0,r0,#V_D
ST r0,r0,#V_A
ST r0,r0,#V_I
CALL @getc
MOVI r4,46
CMP r1,r4
JMP[EQ] @di_dot
MOVI r4,91
CMP r1,r4
JMP[EQ] @di_pred
CALL @ungetc
JMP @dl
di_dot:
CALL @getc
CALL @tnum
ST r8,r0,#V_N
JMP @dl
di_pred:
CALL @rdhash
MOVI r6,@preds
MOVI r7,2
CALL @look
CMP r1,r0
JMP[EQ] @di_err
LD r2,r1,1
ST r2,r0,#V_N
CALL @getc
dl:
LD r9,r0,#V_FORM
MOVI r4,15
BOOL.8 r10,r9,r4
CMP r10,r0
JMP[EQ] @de
SHR r9,r9,4
ST r9,r0,#V_FORM
CALL @nextc
MOVI r4,44
CMP r1,r4
JMP[NE] @dl1
CALL @nextc
dl1:
MOVI r4,4
CMP r10,r4
JMP[EQ] @dl_imm
MOVI r4,5
CMP r10,r4
JMP[EQ] @dl_imm
CALL @getc
CALL @tnum
JMP @dl_set
dl_imm:
CALL @ungetc
CALL @expr
dl_set:
MOVI r4,5
CMP r10,r4
JMP[NE] @dls0
SHR r4,r8,16
MOVI r5,15
BOOL.8 r4,r4,r5
ST r4,r0,#V_A
SHR r4,r8,20
BOOL.8 r4,r4,r5
ST r4,r0,#V_D
JMP @dls3
dls0:
MOVI r4,1
CMP r10,r4
JMP[NE] @dls2
ST r8,r0,#V_D
JMP @dl
dls2:
MOVI r4,2
CMP r10,r4
JMP[NE] @dls3
ST r8,r0,#V_A
JMP @dl
dls3:
ST r8,r0,#V_I
JMP @dl
de:
LD r1,r0,#V_OP
SHL r2,r1,24
LD r3,r0,#V_D
SHL r3,r3,20
BOOL.14 r2,r2,r3
LD r3,r0,#V_A
SHL r3,r3,16
BOOL.14 r2,r2,r3
LD r3,r0,#V_I
MOVI r4,65535
BOOL.8 r3,r3,r4
BOOL.14 r2,r2,r3
LD r1,r0,#V_N
CALL @emit
LD r1,r0,#V_OP
SHR r1,r1,8
CMP r1,r0
JMP[EQ] @di_x
LD r3,r0,#V_D
SHL r3,r3,20
MOVI r2,512
SHL r2,r2,16
BOOL.14 r2,r2,r3
LD r3,r0,#V_I
SHR r3,r3,16
MOVI r4,65535
BOOL.8 r3,r3,r4
BOOL.14 r2,r2,r3
LD r1,r0,#V_N
CALL @emit
di_x:
CALL @skipline
SUB r14,r14,r13
LD r15,r14,0
RET
di_err:
LD r2,r0,#V_ERR
ADD r2,r2,r13
ST r2,r0,#V_ERR
JMP @di_x
; ---- emit: r1=class n, r2=payload. Always counts; pass 2 also STW + mirror check. clobbers r3..r6
emit:
LD r3,r0,#V_IDX
ADD r4,r3,r13
ST r4,r0,#V_IDX
LD r4,r0,#V_PASS
MOVI r5,2
CMP r4,r5
RET[NE]
LD r4,r0,#V_OUTB
ADD r3,r3,r4
STW r2,r3,r1
BSWAPM r3,0
LDN r4,r3,0
BSWAPM r3,0
MOVI r5,3
BOOL.8 r5,r1,r5
SHL r5,r5,2
SHR r6,r1,2
BOOL.14 r5,r5,r6
CMP r4,r5
RET[EQ]
LD r4,r0,#V_MIRR
ADD r4,r4,r13
ST r4,r0,#V_MIRR
RET
; ---- define: r5=hash r8=value -> label/equ table (2 words/entry, hash 0 ends). pass 1 only
define:
LD r2,r0,#V_NLAB
SHL r3,r2,1
LD r4,r0,#V_LABB
ADD r3,r3,r4
ST r5,r3,0
ST r8,r3,1
ADD r2,r2,r13
ST r2,r0,#V_NLAB
ST r0,r3,2
RET
; ---- look: r5=hash r6=table r7=stride -> r1=entry address or 0
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
; ---- expr: reads from stream, r8 = value. term = @label | #EQU | number, joined by + -, unary - allowed
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
; term: r1 = first char (consumed) -> r8
term:
ST r15,r14,0
ADD r14,r14,r13
MOVI r4,64
CMP r1,r4
JMP[EQ] @tm_l
MOVI r4,35
CMP r1,r4
JMP[EQ] @tm_l
CALL @tnum
JMP @tm_x
tm_l:
CALL @rdhash
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
LD r2,r0,#V_ERR
ADD r2,r2,r13
ST r2,r0,#V_ERR
tm_x:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- tnum: r1 = first digit (consumed). decimal or 0xHEX -> r8; the terminator is pushed back
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
; ---- rdhash1 (r1 = first char already read) / rdhash (fresh): r5 = hash of [A-Za-z0-9_]*, terminator pushed back
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
SHL r6,r5,5
ADD r5,r6,r5
ADD r5,r5,r1
JMP @rh1
rh2:
CALL @ungetc
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- isid: r1 char -> r6 = 1 if [0-9A-Z_a-z] else 0 (clobbers r7)
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
; ---- source reader. getc -> r1 (0 at end; clobbers r2,r3). ungetc: push r1 back. nextc: next non-blank (space/tab/CR) char.
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
.include "nasm0_tables.nas"
