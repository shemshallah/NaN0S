; S1 key-ring test: drains KEYQ until ENTER (13). The gate builds this image
; with key bytes A, B, ENTER preloaded and runs the reference with --keys
; "A,B,ENTER"; expected serial: AB\r
main:
MOVI r13,1
l:
KEYQ r1
CMP r1,r0
JMP[EQ] @l
PUTC r1
MOVI r3,13
CMP r1,r3
JMP[NE] @l
HALT
