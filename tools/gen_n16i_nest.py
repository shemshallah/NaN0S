#!/usr/bin/env python3
# SCAFFOLD: writes src/tests/n16i_nest.nas: n16i running a second copy of n16i (labels ni_ -> nj_) running a tiny guest.
import os,re
d=os.path.dirname(__file__)
body=open(os.path.join(d,'../src/tools/n16i.nas')).read()
body=re.sub(r'\bni_','nj_',body).replace('n16i_run','n16j_run')
body='\n'.join(l for l in body.split('\n') if not l.startswith(';'))
src=''';  n16i_nest.nas - n16i running a second copy of n16i (labels renamed ni_ -> nj_) running a small guest.
; mode (patched by tools/n16i_check.py): 0 = inner guest natively, 1 = under one n16i (outer copy native), 2 = under two n16i.
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
'''+body+'''
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
'''+'.word '+','.join(str(ord(c)) for c in "NaN16 in NaN16 in NaN16: sum of squares 1..100 = 0x529AE\n")+',0\n'

open(os.path.join(d,'../src/tests/n16i_nest.nas'),'w').write(src)
