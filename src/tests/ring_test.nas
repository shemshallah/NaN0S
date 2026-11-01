; C1 ring test: sleep until TICK>=8000 (keys pile up unread), then drain with KEYQ printing each, then 'E'.
main:
MOVI r13,1
MOVI r11,8000
w:
TICK r2
CMP r2,r11
JMP[LT] @w
d:
KEYQ r2
CMP r2,r0
JMP[EQ] @done
MOVI r9,75
PUTC r9
MOVI r8,8
pl:
SHR r5,r2,28
SHL r2,r2,4
MOVI r6,10
CMP r5,r6
MOVI r4,48
MOVI[GE] r4,87
ADD r4,r4,r5
PUTC r4
SUB r8,r8,r13
JMP[NE] @pl
MOVI r9,10
PUTC r9
JMP @d
done:
MOVI r9,69
PUTC r9
HALT
