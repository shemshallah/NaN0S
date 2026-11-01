; wm_test: draft window manager (src/lib/wm.nas) at 1024x768. 3 windows, NaNGlyph titles, one enlarged. Pure NaN16.
.org 8192
JMP @entry
.include "../lib/fb.nas"
.include "../lib/fbtext.nas"
.include "../lib/font7.nas"
.include "../lib/wm.nas"
kt:
.word @k_nop,@k_draw,@k_nop,@k_nop
k_nop:
RET
k_draw:
ST r15,r14,0
ADD r14,r14,r13
SHL r5,r1,5
MOVI r6,#WTL
MOVHI r6,#WTH
ADD r5,r5,r6
LD r1,r5,#W_X
MOVI r6,2
ADD r1,r1,r6
LD r2,r5,#W_Y
MOVI r6,18
ADD r2,r2,r6
LD r3,r5,#W_W
MOVI r6,4
SUB r3,r3,r6
LD r4,r5,#W_H
MOVI r6,20
SUB r4,r4,r6
MOVI r5,5
CALL @wm_rect
SUB r14,r14,r13
LD r15,r14,0
RET
entry:
MOVI r13,1
MOVI r14,#STKL
MOVHI r14,#STKH
MOVI r1,768
MOVI r2,1024
SHL r2,r2,16
ADD r1,r1,r2
CALL @fb_init_mode
CALL @wm_init
MOVI r1,0
MOVI r2,40
MOVI r3,60
MOVI r4,300
MOVI r5,200
MOVI r6,@ta
CALL @wm_open
MOVI r1,0
MOVI r2,200
MOVI r3,160
MOVI r4,360
MOVI r5,240
MOVI r6,@tb
CALL @wm_open
MOVI r1,0
MOVI r2,500
MOVI r3,300
MOVI r4,420
MOVI r5,260
MOVI r6,@tc
CALL @wm_open
MOVI r2,0
MOVI r3,0
CALL @wm_enlarge
CALL @wm_draw_all
HALT
ta:
.str "Terminal"
tb:
.str "Monitor"
tc:
.str "Hex"
