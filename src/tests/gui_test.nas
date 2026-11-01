; NaN/0S GUI self-test, pure NaN16. Exercises wm.nas: open/close/z-order/raise/cycle/covered/slot reuse/overflow,
; and reads pixels back from the framebuffer to check focus colours. Prints one line per check via PUTC, then GUI PASS or GUI FAIL.
.org 8192
JMP @t_entry
.include "../lib/fb.nas"
.include "../lib/wm.nas"
kt:
.word @t_nop,@t_nop,@t_nop,@t_nop
t_nop:
RET
t_entry:
MOVI r13,1
MOVI r14,#STK
ST r0,r0,@t_fail
CALL @fb_init
CALL @wm_init
; T1 open A(10,20,100,60) B(60,40,100,60) C(200,100,80,50)
MOVI r1,0
MOVI r2,10
MOVI r3,20
MOVI r4,100
MOVI r5,60
MOVI r6,@t_title
CALL @wm_open
ST r1,r0,@t_a
MOVI r1,0
MOVI r2,60
MOVI r3,40
MOVI r4,100
MOVI r5,60
MOVI r6,@t_title
CALL @wm_open
ST r1,r0,@t_b
MOVI r1,0
MOVI r2,200
MOVI r3,100
MOVI r4,80
MOVI r5,50
MOVI r6,@t_title
CALL @wm_open
ST r1,r0,@t_c
LD r1,r0,@wm_zn
MOVI r2,3
CMP r1,r2
CALL @t_eq
MOVI r1,49
CALL @t_rep
; T2 top is C
CALL @wm_top
LD r2,r0,@t_c
CMP r1,r2
CALL @t_eq
MOVI r1,50
CALL @t_rep
; T3 covered: A yes (B overlaps above), B no, C no
LD r1,r0,@t_a
CALL @wm_covered
MOVI r2,1
CMP r1,r2
CALL @t_eq
MOVI r1,51
CALL @t_rep
LD r1,r0,@t_b
CALL @wm_covered
CMP r1,r0
CALL @t_eq
MOVI r1,52
CALL @t_rep
LD r1,r0,@t_c
CALL @wm_covered
CMP r1,r0
CALL @t_eq
MOVI r1,53
CALL @t_rep
; T4 pixels: C focus title colour 1 at (260,105), B blur title colour 8 at (140,45), A blur 8 at (90,25)
CALL @wm_draw_all
MOVI r1,260
MOVI r2,105
CALL @fb_get
MOVI r2,#C_TITLE_F
CMP r1,r2
CALL @t_eq
MOVI r1,54
CALL @t_rep
MOVI r1,140
MOVI r2,45
CALL @fb_get
MOVI r2,#C_TITLE_B
CMP r1,r2
CALL @t_eq
MOVI r1,55
CALL @t_rep
MOVI r1,90
MOVI r2,25
CALL @fb_get
MOVI r2,#C_TITLE_B
CMP r1,r2
CALL @t_eq
MOVI r1,56
CALL @t_rep
; T5 raise A: top==A, pixel A title focus, C blur
LD r1,r0,@t_a
CALL @wm_raise
CALL @wm_top
LD r2,r0,@t_a
CMP r1,r2
CALL @t_eq
MOVI r1,57
CALL @t_rep
CALL @wm_draw_all
MOVI r1,90
MOVI r2,25
CALL @fb_get
MOVI r2,#C_TITLE_F
CMP r1,r2
CALL @t_eq
MOVI r1,65
CALL @t_rep
MOVI r1,260
MOVI r2,105
CALL @fb_get
MOVI r2,#C_TITLE_B
CMP r1,r2
CALL @t_eq
MOVI r1,66
CALL @t_rep
; after raise A is on top of B where they overlap: pixel (80,45) is inside A? A spans y 20..80 x 10..110: A body is drawn last -> black (0) or A's content
MOVI r1,80
MOVI r2,60
CALL @fb_get
MOVI r2,#C_BODY
CMP r1,r2
CALL @t_eq
MOVI r1,67
CALL @t_rep
; T6 cycle: z was [B,C,A]; Tab sends B to the top
CALL @wm_cycle
CALL @wm_top
LD r2,r0,@t_b
CMP r1,r2
CALL @t_eq
MOVI r1,68
CALL @t_rep
; T7 close B: zn 2, alive 0, top is A
LD r1,r0,@t_b
CALL @wm_close
LD r1,r0,@wm_zn
MOVI r2,2
CMP r1,r2
CALL @t_eq
MOVI r1,69
CALL @t_rep
LD r1,r0,@t_b
CALL @wm_wbase
LD r1,r1,#W_ALIVE
CMP r1,r0
CALL @t_eq
MOVI r1,70
CALL @t_rep
CALL @wm_top
LD r2,r0,@t_a
CMP r1,r2
CALL @t_eq
MOVI r1,71
CALL @t_rep
; T8 slot reuse: the next open returns B's id
MOVI r1,0
MOVI r2,30
MOVI r3,30
MOVI r4,50
MOVI r5,40
MOVI r6,@t_title
CALL @wm_open
LD r2,r0,@t_b
CMP r1,r2
CALL @t_eq
MOVI r1,72
CALL @t_rep
; T9 overflow: 3 alive again, 5 more fit, the 6th fails
ST r0,r0,@t_n
t_fill:
MOVI r1,0
MOVI r2,30
MOVI r3,30
MOVI r4,50
MOVI r5,40
MOVI r6,@t_title
CALL @wm_open
LD r10,r0,@t_n
ADD r10,r10,r13
ST r10,r0,@t_n
MOVI r2,5
CMP r10,r2
JMP[LT] @t_fill
MOVI r1,0
MOVI r2,30
MOVI r3,30
MOVI r4,50
MOVI r5,40
MOVI r6,@t_title
CALL @wm_open
MOVI r2,0xFFFF
CMP r1,r2
CALL @t_eq
MOVI r1,73
CALL @t_rep
; T10 rect + readback
MOVI r1,300
MOVI r2,180
MOVI r3,10
MOVI r4,5
MOVI r5,9
CALL @wm_rect
MOVI r1,305
MOVI r2,182
CALL @fb_get
MOVI r2,9
CMP r1,r2
CALL @t_eq
MOVI r1,74
CALL @t_rep
MOVI r1,299
MOVI r2,182
CALL @fb_get
MOVI r2,9
CMP r1,r2
CALL @t_ne
MOVI r1,75
CALL @t_rep
CALL @fb_exit
LD r1,r0,@t_fail
CMP r1,r0
JMP[NE] @t_bad
MOVI r1,71
PUTC r1
MOVI r1,85
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,10
PUTC r1
HALT
t_bad:
MOVI r1,71
PUTC r1
MOVI r1,85
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,10
PUTC r1
HALT
; t_eq / t_ne: consume the flags of the CMP just before the CALL (CALL keeps flags); result in t_ok
t_eq:
MOVI r9,1
JMP[EQ] @t_eq1
MOVI r9,0
t_eq1:
ST r9,r0,@t_ok
RET
t_ne:
MOVI r9,1
JMP[NE] @t_ne1
MOVI r9,0
t_ne1:
ST r9,r0,@t_ok
RET
; t_rep: r1 = id character; prints "<id>" then "+" or "-" and newline, records failure
t_rep:
PUTC r1
LD r2,r0,@t_ok
MOVI r3,43
CMP r2,r0
JMP[NE] @t_rp
MOVI r3,45
MOVI r4,1
ST r4,r0,@t_fail
t_rp:
PUTC r3
MOVI r3,10
PUTC r3
RET
t_ok:
.word 0
t_n:
.word 0
t_fail:
.word 0
t_a:
.word 0
t_b:
.word 0
t_c:
.word 0
t_title:
.str "T"
