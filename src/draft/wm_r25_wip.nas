; wm.nas - NaN/0S window manager, pure NaN16. No native GUI code. Runtime screen size (fb_w/fb_h), NaNGlyph 8x13 cells.
; Needs fb.nas (fb_w, fb_h, FBFILL/FBCOPY) and fbtext.nas+font7.nas (fb_char7, fb_text7). r0=0, r13=1, r14=software stack (grows up).
; Window table: 8 windows x 32 words at WT. Z-order list ZO (bottom..top); focus = top.
;   0 ALIVE 1 X 2 Y 3 W 4 H 5 TITLE 6 KIND 7..14 A0..A7 (app words) 15 FLAGS (bit0 = enlarged) 16..19 saved X Y W H
; Each window owns an 8192-word private buffer at 0x40000 + id*8192 (up to 128 cols x 64 rows of cells).
; Kind table @kt: 4 words per kind = init, draw, key, tick (code addresses, called by CALLR).
;   init(r1=id)  draw(r1=id) body redraw  key(r1=id,r3=key)  tick(r1=id)
; Geometry: border 1px, title bar 15px at y+1, body origin (x+2, y+18), body size (w-4, h-20).
.equ WT 26624
.equ ZO 26880
.equ STK 31400
.equ MAXW 8
.equ TB 15
.equ TOPH 17
.equ W_ALIVE 0
.equ W_X 1
.equ W_Y 2
.equ W_W 3
.equ W_H 4
.equ W_TITLE 5
.equ W_KIND 6
.equ W_A0 7
.equ W_A1 8
.equ W_A2 9
.equ W_A3 10
.equ W_A4 11
.equ W_A5 12
.equ W_A6 13
.equ W_A7 14
.equ W_FLAGS 15
.equ W_SX 16
.equ W_SY 17
.equ W_SW 18
.equ W_SH 19
.equ C_DESK 18
.equ C_BAR 0
.equ C_FOC 3
.equ C_BLUR 8
.equ C_TITLE_F 1
.equ C_TITLE_B 8
.equ C_BODY 0
.equ C_TXT 15
.equ C_YEL 14
.equ C_CLOSE 4
.equ C_ENL 2
; ---- rect (clipped to the screen): r1=x r2=y r3=w r4=h r5=colour ; clobbers r1-r8 ----
wm_rect:
LD r6,r0,@fb_w
CMP r1,r6
RET[GE]
ADD r7,r1,r3
CMP r7,r6
JMP[LE] @wr_xok
SUB r3,r6,r1
wr_xok:
LD r6,r0,@fb_h
CMP r2,r6
RET[GE]
ADD r7,r2,r4
CMP r7,r6
JMP[LE] @wr_yok
SUB r4,r6,r2
wr_yok:
LD r6,r0,@fb_w
MUL r6,r2,r6
ADD r6,r6,r1
wr_loop:
CMP r4,r0
RET[EQ]
FBFILL r3,r6,r5
LD r7,r0,@fb_w
ADD r6,r6,r7
SUB r4,r4,r13
JMP @wr_loop
; ---- puthex: r1=x r2=y r3=value r4=ndigits r5=colour ; clobbers r1-r9 ----
wm_puthex:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,@ph_y
ST r3,r0,@ph_v
ST r4,r0,@ph_n
ST r5,r0,@ph_c
SUB r6,r4,r13
MOVI r7,8
MUL r6,r6,r7
ADD r1,r1,r6
ST r1,r0,@ph_x
ph_loop:
LD r4,r0,@ph_n
CMP r4,r0
JMP[EQ] @ph_done
SUB r4,r4,r13
ST r4,r0,@ph_n
LD r3,r0,@ph_v
MOVI r5,15
BOOL.8 r6,r3,r5
SHR r3,r3,4
ST r3,r0,@ph_v
MOVI r5,10
CMP r6,r5
JMP[LT] @ph_dec
MOVI r5,55
JMP @ph_ch
ph_dec:
MOVI r5,48
ph_ch:
ADD r3,r6,r5
LD r1,r0,@ph_x
LD r2,r0,@ph_y
LD r4,r0,@ph_c
CALL @fb_char7
LD r1,r0,@ph_x
MOVI r5,8
SUB r1,r1,r5
ST r1,r0,@ph_x
JMP @ph_loop
ph_done:
SUB r14,r14,r13
LD r15,r14,0
RET
ph_x:
.word 0
ph_y:
.word 0
ph_v:
.word 0
ph_n:
.word 0
ph_c:
.word 0
; ---- wm_wbase: r1=id -> r1=address of window record ----
wm_wbase:
SHL r1,r1,5
MOVI r2,#WT
ADD r1,r1,r2
RET
; ---- wm_vbuf: r1=id -> r1=address of window private buffer (0x40000 + id*8192) ----
wm_vbuf:
SHL r1,r1,13
MOVI r2,0
MOVHI r2,4
ADD r1,r1,r2
RET
; ---- wm_init: clear table ----
wm_init:
MOVI r1,#WT
MOVI r2,0
MOVI r3,256
BFILL r1,r2,r3
ST r0,r0,@wm_zn
RET
; ---- wm_kcall: r1=id r2=slot r3=arg ; dispatch to the window kind ----
wm_kcall:
ST r15,r14,0
ADD r14,r14,r13
SHL r5,r1,5
MOVI r6,#WT
ADD r5,r5,r6
LD r6,r5,#W_KIND
SHL r6,r6,2
ADD r6,r6,r2
MOVI r7,@kt
ADD r6,r6,r7
LD r6,r6,0
CALLR r6
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- z-order ----
; wm_zpush r1=id
wm_zpush:
LD r2,r0,@wm_zn
MOVI r3,#ZO
ADD r3,r3,r2
ST r1,r3,0
ADD r2,r2,r13
ST r2,r0,@wm_zn
RET
; wm_zremove r1=id (no-op if absent)
wm_zremove:
LD r2,r0,@wm_zn
MOVI r3,0
zr_find:
CMP r3,r2
RET[GE]
MOVI r4,#ZO
ADD r4,r4,r3
LD r5,r4,0
CMP r5,r1
JMP[EQ] @zr_shift
ADD r3,r3,r13
JMP @zr_find
zr_shift:
ADD r6,r3,r13
CMP r6,r2
JMP[GE] @zr_done
MOVI r4,#ZO
ADD r4,r4,r6
LD r5,r4,0
SUB r4,r4,r13
ST r5,r4,0
ADD r3,r3,r13
JMP @zr_shift
zr_done:
SUB r2,r2,r13
ST r2,r0,@wm_zn
RET
; wm_top -> r1=id of focused window or 0xFFFF
wm_top:
LD r2,r0,@wm_zn
CMP r2,r0
JMP[EQ] @zt_none
SUB r2,r2,r13
MOVI r3,#ZO
ADD r3,r3,r2
LD r1,r3,0
RET
zt_none:
MOVI r1,0xFFFF
RET
; wm_raise r1=id -> to top, full redraw
wm_raise:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@rz_id
CALL @wm_zremove
LD r1,r0,@rz_id
CALL @wm_zpush
MOVI r1,1
ST r1,r0,@wm_redraw
SUB r14,r14,r13
LD r15,r14,0
RET
rz_id:
.word 0
; wm_cycle: send the bottom window to the top (Tab)
wm_cycle:
ST r15,r14,0
ADD r14,r14,r13
LD r2,r0,@wm_zn
MOVI r3,2
CMP r2,r3
JMP[LT] @wc_done
MOVI r3,#ZO
LD r1,r3,0
CALL @wm_raise
wc_done:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- wm_open: r1=kind r2=x r3=y r4=w r5=h r6=title -> r1=id or 0xFFFF ----
wm_open:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@wo_k
ST r2,r0,@wo_x
ST r3,r0,@wo_y
ST r4,r0,@wo_w
ST r5,r0,@wo_h
ST r6,r0,@wo_t
MOVI r7,0
wo_find:
MOVI r8,#MAXW
CMP r7,r8
JMP[GE] @wo_full
SHL r9,r7,5
MOVI r10,#WT
ADD r9,r9,r10
LD r10,r9,#W_ALIVE
CMP r10,r0
JMP[EQ] @wo_got
ADD r7,r7,r13
JMP @wo_find
wo_full:
MOVI r1,0xFFFF
SUB r14,r14,r13
LD r15,r14,0
RET
wo_got:
ST r7,r0,@wo_id
MOVI r10,1
ST r10,r9,#W_ALIVE
LD r10,r0,@wo_x
ST r10,r9,#W_X
LD r10,r0,@wo_y
ST r10,r9,#W_Y
LD r10,r0,@wo_w
ST r10,r9,#W_W
LD r10,r0,@wo_h
ST r10,r9,#W_H
LD r10,r0,@wo_t
ST r10,r9,#W_TITLE
LD r10,r0,@wo_k
ST r10,r9,#W_KIND
MOVI r10,0
ST r10,r9,#W_A0
ST r10,r9,#W_A1
ST r10,r9,#W_A2
ST r10,r9,#W_A3
ST r10,r9,#W_A4
ST r10,r9,#W_A5
ST r10,r9,#W_A6
ST r10,r9,#W_A7
ST r10,r9,#W_FLAGS
LD r1,r0,@wo_id
CALL @wm_vbuf
MOVI r2,0
MOVI r3,8192
BFILL r1,r2,r3
LD r1,r0,@wo_id
MOVI r2,0
CALL @wm_kcall
LD r1,r0,@wo_id
CALL @wm_zpush
MOVI r1,1
ST r1,r0,@wm_redraw
LD r1,r0,@wo_id
SUB r14,r14,r13
LD r15,r14,0
RET
wo_k:
.word 0
wo_x:
.word 0
wo_y:
.word 0
wo_w:
.word 0
wo_h:
.word 0
wo_t:
.word 0
wo_id:
.word 0
; ---- wm_close: r1=id ----
wm_close:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@wcl_id
CALL @wm_zremove
LD r1,r0,@wcl_id
CALL @wm_wbase
ST r0,r1,#W_ALIVE
MOVI r1,1
ST r1,r0,@wm_redraw
SUB r14,r14,r13
LD r15,r14,0
RET
wcl_id:
.word 0
; ---- wm_covered: r1=id -> r1=1 if a higher window overlaps it ----
wm_covered:
ST r1,r0,@cv_id
LD r2,r0,@wm_zn
MOVI r3,0
cv_find:
CMP r3,r2
JMP[GE] @cv_no
MOVI r4,#ZO
ADD r4,r4,r3
LD r5,r4,0
LD r6,r0,@cv_id
CMP r5,r6
JMP[EQ] @cv_found
ADD r3,r3,r13
JMP @cv_find
cv_found:
ST r3,r0,@cv_j
LD r1,r0,@cv_id
SHL r1,r1,5
MOVI r2,#WT
ADD r1,r1,r2
ST r1,r0,@cv_a
cv_next:
LD r3,r0,@cv_j
ADD r3,r3,r13
ST r3,r0,@cv_j
LD r2,r0,@wm_zn
CMP r3,r2
JMP[GE] @cv_no
MOVI r4,#ZO
ADD r4,r4,r3
LD r5,r4,0
SHL r5,r5,5
MOVI r6,#WT
ADD r5,r5,r6
LD r7,r0,@cv_a
LD r8,r7,#W_X
LD r9,r7,#W_W
ADD r9,r8,r9
LD r10,r5,#W_X
CMP r9,r10
JMP[LE] @cv_next
LD r11,r5,#W_W
ADD r11,r10,r11
CMP r11,r8
JMP[LE] @cv_next
LD r8,r7,#W_Y
LD r9,r7,#W_H
ADD r9,r8,r9
LD r10,r5,#W_Y
CMP r9,r10
JMP[LE] @cv_next
LD r11,r5,#W_H
ADD r11,r10,r11
CMP r11,r8
JMP[LE] @cv_next
MOVI r1,1
RET
cv_no:
MOVI r1,0
RET
cv_id:
.word 0
cv_j:
.word 0
cv_a:
.word 0
; ---- wm_enlarge: r1=id r2=fit_w r3=fit_h (0 = fill the screen below the top bar). Toggles enlarged/restored. UNTESTED (r25 WIP) ----
wm_enlarge:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,@en_fw
ST r3,r0,@en_fh
CALL @wm_wbase
ST r1,r0,@en_b
LD r2,r1,#W_FLAGS
CMP r2,r0
JMP[NE] @en_restore
LD r2,r1,#W_X
ST r2,r1,#W_SX
LD r2,r1,#W_Y
ST r2,r1,#W_SY
LD r2,r1,#W_W
ST r2,r1,#W_SW
LD r2,r1,#W_H
ST r2,r1,#W_SH
MOVI r2,1
ST r2,r1,#W_FLAGS
LD r4,r0,@fb_w
LD r5,r0,@en_fw
CMP r5,r0
JMP[EQ] @en_w
CMP r5,r4
JMP[GE] @en_w
ADD r4,r5,r0
en_w:
ST r4,r1,#W_W
LD r5,r0,@fb_w
SUB r5,r5,r4
SHR r5,r5,1
ST r5,r1,#W_X
LD r4,r0,@fb_h
MOVI r6,#TOPH
SUB r4,r4,r6
LD r5,r0,@en_fh
CMP r5,r0
JMP[EQ] @en_h
CMP r5,r4
JMP[GE] @en_h
ADD r4,r5,r0
en_h:
ST r4,r1,#W_H
LD r5,r0,@fb_h
SUB r5,r5,r6
SUB r5,r5,r4
SHR r5,r5,1
ADD r5,r5,r6
ST r5,r1,#W_Y
JMP @en_done
en_restore:
LD r2,r1,#W_SX
ST r2,r1,#W_X
LD r2,r1,#W_SY
ST r2,r1,#W_Y
LD r2,r1,#W_SW
ST r2,r1,#W_W
LD r2,r1,#W_SH
ST r2,r1,#W_H
ST r0,r1,#W_FLAGS
en_done:
MOVI r1,1
ST r1,r0,@wm_redraw
SUB r14,r14,r13
LD r15,r14,0
RET
en_fw:
.word 0
en_fh:
.word 0
en_b:
.word 0
; ---- wm_draw_window: r1=id (border, 15px title bar, enlarge + close boxes, then the app's draw). UNTESTED (r25 WIP) ----
wm_draw_window:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@dw_id
CALL @wm_top
LD r2,r0,@dw_id
MOVI r3,0
CMP r1,r2
JMP[NE] @dw_cx
MOVI r3,1
dw_cx:
ST r3,r0,@dw_foc
LD r1,r0,@dw_id
CALL @wm_wbase
ST r1,r0,@dw_b
LD r2,r1,#W_Y
LD r3,r1,#W_W
LD r4,r1,#W_H
LD r1,r1,#W_X
LD r5,r0,@dw_foc
MOVI r6,#C_BLUR
CMP r5,r0
JMP[EQ] @dw_bc
MOVI r6,#C_FOC
dw_bc:
ADD r5,r6,r0
CALL @wm_rect
LD r9,r0,@dw_b
LD r1,r9,#W_X
ADD r1,r1,r13
LD r2,r9,#W_Y
ADD r2,r2,r13
LD r3,r9,#W_W
SUB r3,r3,r13
SUB r3,r3,r13
MOVI r4,#TB
LD r5,r0,@dw_foc
MOVI r6,#C_TITLE_B
CMP r5,r0
JMP[EQ] @dw_tc
MOVI r6,#C_TITLE_F
dw_tc:
ADD r5,r6,r0
CALL @wm_rect
LD r9,r0,@dw_b
LD r1,r9,#W_X
ADD r1,r1,r13
LD r2,r9,#W_Y
MOVI r3,16
ADD r2,r2,r3
LD r3,r9,#W_W
SUB r3,r3,r13
SUB r3,r3,r13
LD r4,r9,#W_H
MOVI r5,17
SUB r4,r4,r5
MOVI r5,#C_BODY
CALL @wm_rect
LD r9,r0,@dw_b
LD r1,r9,#W_X
MOVI r5,5
ADD r1,r1,r5
LD r2,r9,#W_Y
MOVI r5,2
ADD r2,r2,r5
MOVI r3,@s_nan0s
MOVI r4,#C_YEL
CALL @fb_text7
LD r9,r0,@dw_b
LD r1,r9,#W_X
MOVI r5,58
ADD r1,r1,r5
LD r2,r9,#W_Y
MOVI r5,2
ADD r2,r2,r5
LD r3,r9,#W_TITLE
MOVI r4,#C_TXT
CALL @fb_text7
LD r9,r0,@dw_b
LD r1,r9,#W_X
LD r3,r9,#W_W
ADD r1,r1,r3
MOVI r5,16
SUB r1,r1,r5
LD r2,r9,#W_Y
MOVI r5,2
ADD r2,r2,r5
MOVI r3,13
MOVI r4,13
MOVI r5,#C_CLOSE
CALL @wm_rect
LD r9,r0,@dw_b
LD r1,r9,#W_X
LD r3,r9,#W_W
ADD r1,r1,r3
MOVI r5,13
SUB r1,r1,r5
LD r2,r9,#W_Y
MOVI r5,3
ADD r2,r2,r5
MOVI r3,120
MOVI r4,#C_TXT
CALL @fb_char7
LD r9,r0,@dw_b
LD r1,r9,#W_X
LD r3,r9,#W_W
ADD r1,r1,r3
MOVI r5,31
SUB r1,r1,r5
LD r2,r9,#W_Y
MOVI r5,2
ADD r2,r2,r5
MOVI r3,13
MOVI r4,13
MOVI r5,#C_ENL
CALL @wm_rect
LD r9,r0,@dw_b
LD r1,r9,#W_X
LD r3,r9,#W_W
ADD r1,r1,r3
MOVI r5,28
SUB r1,r1,r5
LD r2,r9,#W_Y
MOVI r5,3
ADD r2,r2,r5
MOVI r3,43
MOVI r4,#C_TXT
CALL @fb_char7
LD r1,r0,@dw_id
MOVI r2,1
CALL @wm_kcall
SUB r14,r14,r13
LD r15,r14,0
RET
dw_id:
.word 0
dw_foc:
.word 0
dw_b:
.word 0
s_nan0s:
.str "NaN/0S"
; ---- wm_draw_all: desktop + top bar + every window bottom to top. UNTESTED (r25 WIP) ----
wm_draw_all:
ST r15,r14,0
ADD r14,r14,r13
MOVI r1,#C_DESK
CALL @fb_clear
MOVI r1,0
MOVI r2,0
LD r3,r0,@fb_w
MOVI r4,#TOPH
MOVI r5,#C_BAR
CALL @wm_rect
MOVI r1,6
MOVI r2,2
MOVI r3,@s_nan0s
MOVI r4,#C_YEL
CALL @fb_text7
MOVI r1,64
MOVI r2,2
MOVI r3,@s_hint
MOVI r4,#C_TXT
CALL @fb_text7
ST r0,r0,@da_i
da_loop:
LD r1,r0,@da_i
LD r2,r0,@wm_zn
CMP r1,r2
JMP[GE] @da_done
MOVI r3,#ZO
ADD r3,r3,r1
LD r1,r3,0
CALL @wm_draw_window
LD r1,r0,@da_i
ADD r1,r1,r13
ST r1,r0,@da_i
JMP @da_loop
da_done:
SUB r14,r14,r13
LD r15,r14,0
RET
da_i:
.word 0
s_hint:
.str "TAB FOCUS  F2 MOVE  F3 ENLARGE  F5 SETTINGS  F6 NANNET  F7 SYSTEM  ESC CLOSE"
wm_zn:
.word 0
wm_redraw:
.word 0
