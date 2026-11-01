; C1 key test: blocking KEY, print 'K' + 8 hex digits + LF on serial, forever.
main:
MOVI r13,1
kl:
KEY r2
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
JMP @kl
