; F2 clock test: prints 'T' + 8 hex digits of TICK (ms) every 500 ms of TICK time, forever. Host script timestamps each line.
main:
MOVI r13,1
TICK r1
MOVI r11,500
ADD r10,r1,r11
wl:
TICK r2
CMP r2,r10
JMP[LT] @wl
MOVI r9,84
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
ADD r10,r10,r11
JMP @wl
