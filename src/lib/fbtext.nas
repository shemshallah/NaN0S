; fbtext.nas - NaNGlyph 7x11 text (cell 8x13). Needs fb.nas (fb_w, fb_nextbyte). r0=0, r13=1.
;   fb_char7 r1=x r2=y r3=ascii r4=colour   (clobbers r1-r12)
;   fb_text7 r1=x r2=y r3=string r4=colour  (.str packed 4/word, \n = newline, clobbers r1-r12)
;   t7_clip: if non-zero, glyph cells that would end beyond this x are skipped
fb_char7:
MOVI r5,32
CMP r3,r5
JMP[LT] @f7_q
MOVI r5,126
CMP r3,r5
JMP[GT] @f7_q
JMP @f7_ok
f7_q:
MOVI r3,63
f7_ok:
ST r1,r0,@f7_x
ST r2,r0,@f7_y
ST r4,r0,@f7_c
MOVI r5,32
SUB r3,r3,r5
MOVI r5,11
MUL r3,r3,r5
MOVI r5,@font7
ADD r5,r5,r3
ST r5,r0,@f7_tab
MOVI r6,0
f7_row:
MOVI r7,11
CMP r6,r7
JMP[GE] @f7_done
LD r7,r0,@f7_tab
ADD r7,r7,r6
LD r8,r7,0
CMP r8,r0
JMP[EQ] @f7_nextrow
LD r9,r0,@f7_y
ADD r9,r9,r6
LD r10,r0,@fb_w
MUL r9,r9,r10
LD r10,r0,@f7_x
ADD r9,r9,r10
MOVI r11,64
f7_col:
CMP r11,r0
JMP[EQ] @f7_nextrow
BOOL.8 r12,r8,r11
CMP r12,r0
JMP[EQ] @f7_skip
LD r4,r0,@f7_c
VPOKE r4,r9
f7_skip:
ADD r9,r9,r13
SHR r11,r11,1
JMP @f7_col
f7_nextrow:
ADD r6,r6,r13
JMP @f7_row
f7_done:
RET
f7_x:
.word 0
f7_y:
.word 0
f7_c:
.word 0
f7_tab:
.word 0
t7_clip:
.word 0
fb_text7:
ST r15,r0,@ft7_ret
ST r1,r0,@ft7_x
ST r1,r0,@ft7_x0
ST r2,r0,@ft7_y
ST r4,r0,@ft7_c
ADD r10,r3,r0
MOVI r11,0
MOVI r12,0
ft7_loop:
CALL @fb_nextbyte
CMP r6,r0
JMP[EQ] @ft7_done
MOVI r5,10
CMP r6,r5
JMP[EQ] @ft7_nl
LD r1,r0,@ft7_x
LD r5,r0,@t7_clip
CMP r5,r0
JMP[EQ] @ft7_draw
MOVI r7,8
ADD r7,r1,r7
CMP r7,r5
JMP[GT] @ft7_adv
ft7_draw:
ADD r3,r6,r0
LD r2,r0,@ft7_y
LD r4,r0,@ft7_c
ST r10,r0,@ft7_p
ST r11,r0,@ft7_w
ST r12,r0,@ft7_n
CALL @fb_char7
LD r10,r0,@ft7_p
LD r11,r0,@ft7_w
LD r12,r0,@ft7_n
ft7_adv:
LD r1,r0,@ft7_x
MOVI r5,8
ADD r1,r1,r5
ST r1,r0,@ft7_x
JMP @ft7_loop
ft7_nl:
LD r1,r0,@ft7_x0
ST r1,r0,@ft7_x
LD r2,r0,@ft7_y
MOVI r5,13
ADD r2,r2,r5
ST r2,r0,@ft7_y
JMP @ft7_loop
ft7_done:
LD r15,r0,@ft7_ret
RET
ft7_ret:
.word 0
ft7_x:
.word 0
ft7_x0:
.word 0
ft7_y:
.word 0
ft7_c:
.word 0
ft7_p:
.word 0
ft7_w:
.word 0
ft7_n:
.word 0
