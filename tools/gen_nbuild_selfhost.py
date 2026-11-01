#!/usr/bin/env python3
# SCAFFOLD: emit src/prog/nbuild_selfhost.nas. The generated builder is NaN16;
# it embeds the flattened nasm0 source as packed .word data and compares the
# in-guest assembly to the running nasm0 words.
import os, sys, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkproof
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
text = b'.word 0\n' + mkproof.minify(os.path.join(root, 'src/prog/nasm0.nas')) + b'\0'
text += b'\0' * (-len(text) % 4)
words = [struct.unpack('<I', text[i:i+4])[0] for i in range(0, len(text), 4)]
code = r'''; nbuild_selfhost.nas - generated. NaN16 only.
; Assembles the flattened nasm0 source with the running nasm0 and compares
; every emitted word (payload + class) to the running assembler.
.org 0
JMP @main
.include "nasm0.nas"
main:
MOVI r13,1
MOVI r14,20000
MOVI r1,@src_data
ST r1,r0,#V_SRCB
MOVI r1,8192
ST r1,r0,#V_OUTB
MOVI r1,12288
ST r1,r0,#V_LABB
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
LD r11,r0,#V_IDX
MOVI r12,662
CMP r11,r12
JMP[NE] @badcount
MOVI r11,661
MOVI r10,0
cmp_l:
CMP r10,r11
JMP[GE] @ok
MOVI r4,8193
ADD r4,r4,r10
LD r5,r4,0
LDN r6,r4,0
MOVI r4,1
ADD r4,r4,r10
LD r7,r4,0
LDN r8,r4,0
CMP r5,r7
JMP[NE] @bad
CMP r6,r8
JMP[NE] @bad
ADD r10,r10,r13
JMP @cmp_l
badcount:
MOVI r1,@s_badcount
CALL @puts
JMP @halt
bad:
ST r5,r0,@b_out
ST r7,r0,@b_run
MOVI r1,@s_bad
CALL @puts
ADD r1,r10,r0
CALL @puthex
MOVI r1,@s_outw
CALL @puts
LD r1,r0,@b_out
CALL @puthex
MOVI r1,@s_runw
CALL @puts
LD r1,r0,@b_run
CALL @puthex
MOVI r1,@s_nl
CALL @puts
JMP @halt
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
ok:
MOVI r1,@s_ok
CALL @puts
halt:
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
s_ok:
.str "SELFHOST PASS\n"
s_bad:
.str "SELFHOST WORD FAIL\n"
s_badcount:
.str "SELFHOST COUNT FAIL\n"
s_outw:
.str " out="
s_runw:
.str " run="
s_nl:
.str "\n"
b_out:
.word 0
b_run:
.word 0
.org 2048
src_data:
'''
lines = [code]
lines.append('; %d packed source words' % len(words))
for w in words:
    lines.append('.word 0x%08X' % w)
open(os.path.join(root, 'src/prog/nbuild_selfhost.nas'), 'w').write('\n'.join(lines) + '\n')
print('wrote nbuild_selfhost.nas: source words', len(words))
