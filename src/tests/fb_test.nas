; MODE 13h framebuffer smoke test: set 320x200 white-on-black, draw a cross,
; wait for a key, restore text mode 3, halt. NaN16 only.
.equ V_KEY 5
main:
MOVI r13,1
MOVI r3,0x13
DISPSET r3
MOVI r5,15
; horizontal line y=100
MOVI r6,32000
MOVI r4,320
h:
VPOKE r5,r6
ADD r6,r6,r13
SUB r4,r4,r13
JMP[NE] @h
; vertical line x=160
MOVI r6,160
MOVI r4,200
v:
VPOKE r5,r6
MOVI r7,320
ADD r6,r6,r7
SUB r4,r4,r13
JMP[NE] @v
KEY r1
MOVI r3,3
DISPSET r3
HALT
