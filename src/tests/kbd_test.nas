; kbd_test: raw keyboard driver test. Prints 'E' + 8 hex digits (event) + LF on serial for every press.
.org 8192
JMP @entry
.include "../lib/kbd.nas"
entry:
MOVI r13,1
MOVI r14,30000
CALL @kbd_init
main:
CALL @kbd_poll
CALL @kbd_get
CMP r1,r0
JMP[EQ] @main
ADD r2,r1,r0
MOVI r9,69
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
JMP @main
