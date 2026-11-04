; NaN/0S GUI CARTRIDGE: desktop + overlapping windows, all NaN16.
; Programs: Terminal (virtual console), Sierpinski (stateless rule-90 pixel window),
; Monitor (double-endian timer lamps), Hex (live guest memory viewer).
; Keys (kbd.nas, 1024x768): TAB focus | F2 MOVE mode (arrows move, ENTER leaves) | F3 enlarge/restore | ESC close.
; Terminal commands (first letter): h c v w l m x t s(settings) n(nannet) u(utils) q. F5 Settings, F6 NaNNet, F7 System utilities (single-instance).
; Window manager: src/lib/wm.nas. Framebuffer: fb.nas. Text: NaNGlyph 8x13 cells (fbtext.nas+font7.nas). Keys: kbd.nas. No native GUI code.
.equ SLOT 8192
.equ PERIOD 100
.equ VCW 128
.org 8192
JMP @cart_entry
.include "../lib/fb.nas"
.include "../lib/fbtext.nas"
.include "../lib/font7.nas"
.include "../lib/kbd.nas"
.include "../lib/wm.nas"
cart_entry:
ST r15,r0,@g_ret
MOVI r13,1
MOVI r14,#STKL
MOVHI r14,#STKH
MOVI r1,768
MOVI r2,1024
SHL r2,r2,16
ADD r1,r1,r2
CALL @fb_init_mode
CALL @kbd_init
CALL @wm_init
ST r0,r0,@g_quit
ST r0,r0,@g_move
ST r0,r0,@g_cnt
; boot to the desktop with ONE terminal window (A2). Everything else (lattice,
; hex, monitor, settings, net, utilities) is launched from the terminal via
; `run <n>` / the named commands, which call gui_single/gui_open_new themselves.
MOVI r1,0
CALL @gui_open_new
MOVI r1,1
ST r1,r0,@wm_redraw
TICK r1
ST r1,r0,@g_last
g_loop:
LD r1,r0,@wm_redraw
CMP r1,r0
JMP[EQ] @g_nodraw
ST r0,r0,@wm_redraw
CALL @wm_draw_all
CALL @g_bar
g_nodraw:
LD r1,r0,@g_quit
CMP r1,r0
JMP[NE] @g_exit
LD r1,r0,@wm_zn
CMP r1,r0
JMP[EQ] @g_exit
CALL @kbd_poll
CALL @kbd_get
MOVI r4,0xFFFF
BOOL.8 r1,r1,r4
CMP r1,r0
JMP[EQ] @g_tick
ST r1,r0,@g_key
CALL @g_onkey
JMP @g_loop
g_tick:
TICK r1
LD r2,r0,@g_last
SUB r3,r1,r2
MOVI r4,#PERIOD
CMP r3,r4
JMP[LT] @g_loop
ST r1,r0,@g_last
CALL @g_ticks
CALL @g_bar
JMP @g_loop
g_exit:
MOVI r1,0xFFFF
SHL r1,r1,16
DISPSET r1
CALL @fb_exit
LD r15,r0,@g_ret
RET
g_ret:
.word 0
g_quit:
.word 0
g_move:
.word 0
g_cnt:
.word 0
g_last:
.word 0
g_key:
.word 0
; ---- top bar: MOVE flag and tick counter ----
g_bar:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@fb_w
MOVI r2,144
SUB r1,r1,r2
ST r1,r0,@gb_x
MOVI r2,1
MOVI r3,40
MOVI r4,15
MOVI r5,#C_BAR
CALL @wm_rect
LD r1,r0,@g_move
CMP r1,r0
JMP[EQ] @gb_clock
LD r1,r0,@gb_x
MOVI r2,2
MOVI r3,@s_move
MOVI r4,#C_YEL
CALL @fb_text7
gb_clock:
LD r1,r0,@gb_x
MOVI r2,46
ADD r1,r1,r2
MOVI r2,1
MOVI r3,96
MOVI r4,15
MOVI r5,#C_BAR
CALL @wm_rect
TICK r3
LD r1,r0,@gb_x
MOVI r2,70
ADD r1,r1,r2
MOVI r2,2
MOVI r4,8
MOVI r5,#C_TXT
CALL @wm_puthex
SUB r14,r14,r13
LD r15,r14,0
RET
gb_x:
.word 0
s_move:
.str "MOVE"
; ---- tick every live window ----
g_ticks:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,@gt_i
gt_loop:
LD r1,r0,@gt_i
MOVI r2,#MAXW
CMP r1,r2
JMP[GE] @gt_done
CALL @wm_wbase
LD r2,r1,#W_ALIVE
CMP r2,r0
JMP[EQ] @gt_next
LD r1,r0,@gt_i
MOVI r2,3
CALL @wm_kcall
gt_next:
LD r1,r0,@gt_i
ADD r1,r1,r13
ST r1,r0,@gt_i
JMP @gt_loop
gt_done:
SUB r14,r14,r13
LD r15,r14,0
RET
gt_i:
.word 0
; ---- open a window of kind r1 at (r2,r3) using the kind defaults ----
gui_open_at:
ST r15,r14,0
ADD r14,r14,r13
SHL r4,r1,2
MOVI r5,@kdef
ADD r4,r4,r5
LD r5,r4,0
LD r6,r4,1
LD r7,r4,2
ADD r4,r5,r0
ADD r5,r6,r0
ADD r6,r7,r0
CALL @wm_open
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- open kind r1 at a staggered position ----
gui_open_new:
ST r15,r14,0
ADD r14,r14,r13
LD r4,r0,@g_cnt
ADD r5,r4,r13
ST r5,r0,@g_cnt
MOVI r5,7
BOOL.8 r4,r4,r5
MOVI r5,28
MUL r2,r4,r5
MOVI r5,60
ADD r2,r2,r5
MOVI r5,22
MUL r3,r4,r5
MOVI r5,40
ADD r3,r3,r5
CALL @gui_open_at
SUB r14,r14,r13
LD r15,r14,0
RET
; kdef: w, h, title per kind
kdef:
.word 560,344,@t_term,0
.word 380,300,@t_lat,0
.word 250,96,@t_mon,0
.word 520,300,@t_hex,0
.word 520,300,@t_set,0
.word 520,260,@t_net,0
.word 560,300,@t_util,0
t_term:
.str "TERMINAL"
t_lat:
.str "SIERPINSKI"
t_mon:
.str "MONITOR"
t_hex:
.str "HEX"
kt:
.word @term_init,@term_draw,@term_key,@nop_k
.word @nop_k,@lat_draw,@nop_k,@lat_tick
.word @nop_k,@mon_draw,@nop_k,@mon_tick
.word @hex_init,@hex_draw,@hex_key,@nop_k
.word @st_init,@st_draw,@st_key,@st_tick
.word @nn_init,@nn_draw,@nn_key,@nn_tick
.word @ut_init,@ut_draw,@nop_k,@ut_tick
nop_k:
RET
; ---- global key handling ----
g_onkey:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@g_key
LD r2,r0,@st_pend
CMP r2,r0
JMP[EQ] @gk_np
CALL @st_pendkey
JMP @gk_ret
gk_np:
MOVI r2,0x105
CMP r1,r2
JMP[NE] @gk_n5
MOVI r1,4
CALL @gui_single
JMP @gk_ret
gk_n5:
MOVI r2,0x106
CMP r1,r2
JMP[NE] @gk_n6
MOVI r1,5
CALL @gui_single
JMP @gk_ret
gk_n6:
MOVI r2,0x107
CMP r1,r2
JMP[NE] @gk_n7
MOVI r1,6
CALL @gui_single
JMP @gk_ret
gk_n7:
MOVI r2,0x102
CMP r1,r2
JMP[NE] @gk_notf3
LD r2,r0,@g_move
MOVI r3,1
BOOL.6 r2,r2,r3
ST r2,r0,@g_move
CALL @g_bar
JMP @gk_ret
gk_notf3:
MOVI r2,0x103
CMP r1,r2
JMP[NE] @gk_notmove
CALL @g_enlarge
JMP @gk_ret
gk_notmove:
MOVI r2,27
CMP r1,r2
JMP[NE] @gk_notesc
CALL @wm_top
MOVI r2,0xFFFF
CMP r1,r2
JMP[EQ] @gk_ret
CALL @wm_close
JMP @gk_ret
gk_notesc:
MOVI r2,9
CMP r1,r2
JMP[NE] @gk_notab
CALL @wm_cycle
JMP @gk_ret
gk_notab:
LD r2,r0,@g_move
CMP r2,r0
JMP[EQ] @gk_app
CALL @g_movekey
JMP @gk_ret
gk_app:
CALL @wm_top
MOVI r2,0xFFFF
CMP r1,r2
JMP[EQ] @gk_ret
MOVI r2,2
LD r3,r0,@g_key
CALL @wm_kcall
gk_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- F3: enlarge/restore the focused window. Monitor fits its content (250x96), every other kind fills the screen ----
g_enlarge:
ST r15,r14,0
ADD r14,r14,r13
CALL @wm_top
MOVI r2,0xFFFF
CMP r1,r2
JMP[EQ] @ge_ret
ST r1,r0,@ge_id
CALL @wm_wbase
LD r3,r1,#W_KIND
MOVI r2,0
MOVI r4,2
CMP r3,r4
JMP[NE] @ge_go
MOVI r2,250
MOVI r3,96
JMP @ge_call
ge_go:
MOVI r3,0
ge_call:
LD r1,r0,@ge_id
CALL @wm_enlarge
ge_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
ge_id:
.word 0
; ---- move mode: arrows move the focused window by 8 px, ENTER leaves ----
g_movekey:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@g_key
MOVI r2,13
CMP r1,r2
JMP[NE] @gm_arrows
ST r0,r0,@g_move
CALL @g_bar
JMP @gm_ret
gm_arrows:
CALL @wm_top
MOVI r2,0xFFFF
CMP r1,r2
JMP[EQ] @gm_ret
CALL @wm_wbase
LD r3,r1,#W_X
LD r4,r1,#W_Y
LD r5,r1,#W_W
LD r6,r1,#W_H
LD r7,r0,@g_key
LD r8,r1,#W_FLAGS
CMP r8,r0
JMP[NE] @gm_ret
MOVI r8,0x110
CMP r7,r8
JMP[EQ] @gm_up
MOVI r8,0x111
CMP r7,r8
JMP[EQ] @gm_down
MOVI r8,0x112
CMP r7,r8
JMP[EQ] @gm_left
MOVI r8,0x113
CMP r7,r8
JMP[EQ] @gm_right
JMP @gm_ret
gm_up:
MOVI r8,#TOPH
ADD r8,r8,r13
CMP r4,r8
JMP[LT] @gm_ret
MOVI r8,8
SUB r4,r4,r8
JMP @gm_store
gm_down:
MOVI r8,8
ADD r9,r4,r6
ADD r9,r9,r8
LD r10,r0,@fb_h
CMP r9,r10
JMP[GT] @gm_ret
ADD r4,r4,r8
JMP @gm_store
gm_left:
MOVI r8,8
CMP r3,r8
JMP[LT] @gm_ret
SUB r3,r3,r8
JMP @gm_store
gm_right:
MOVI r8,8
ADD r9,r3,r5
ADD r9,r9,r8
LD r10,r0,@fb_w
CMP r9,r10
JMP[GT] @gm_ret
ADD r3,r3,r8
gm_store:
ST r3,r1,#W_X
ST r4,r1,#W_Y
MOVI r1,1
ST r1,r0,@wm_redraw
gm_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; ====================== TERMINAL (virtual console) ======================
; A0 cols  A1 rows  A2 cursor col  A3 cursor row  A4 scrolled flag
term_init:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ti_id
CALL @term_fit
LD r1,r0,@ti_id
MOVI r2,@s_banner
CALL @vc_puts
SUB r14,r14,r13
LD r15,r14,0
RET
ti_id:
.word 0
; ---- term_fit: r1=id. cols = (W-4)/8 (max VCW), rows = (H-20)/13 (max 64), cursor clamped. Derived from the window size at every draw. ----
term_fit:
ST r15,r14,0
ADD r14,r14,r13
CALL @wm_wbase
LD r2,r1,#W_W
MOVI r3,4
SUB r2,r2,r3
SHR r2,r2,3
MOVI r3,#VCW
CMP r2,r3
JMP[LE] @tf_c
ADD r2,r3,r0
tf_c:
ST r2,r1,#W_A0
LD r4,r1,#W_A2
CMP r4,r2
JMP[LT] @tf_k
SUB r4,r2,r13
ST r4,r1,#W_A2
tf_k:
LD r2,r1,#W_H
MOVI r3,20
SUB r2,r2,r3
MOVI r3,13
DIVU r2,r2,r3
MOVI r3,64
CMP r2,r3
JMP[LE] @tf_r
ADD r2,r3,r0
tf_r:
ST r2,r1,#W_A1
LD r4,r1,#W_A3
CMP r4,r2
JMP[LT] @tf_d
SUB r4,r2,r13
ST r4,r1,#W_A3
tf_d:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- g_clr: r1=id. Clear the body (x+2,y+18,w-4,h-20) to C_BODY ----
g_clr:
ST r15,r14,0
ADD r14,r14,r13
CALL @wm_wbase
LD r2,r1,#W_Y
LD r3,r1,#W_W
LD r4,r1,#W_H
LD r1,r1,#W_X
MOVI r5,2
ADD r1,r1,r5
MOVI r5,18
ADD r2,r2,r5
MOVI r5,4
SUB r3,r3,r5
MOVI r5,20
SUB r4,r4,r5
MOVI r5,#C_BODY
CALL @wm_rect
SUB r14,r14,r13
LD r15,r14,0
RET
s_banner:
.str "NaN/0S TERMINAL\nh = help\n> "
; ---- vc_putc: r1=id r2=char ----
vc_putc:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@vp_id
ST r2,r0,@vp_ch
CALL @wm_wbase
ST r1,r0,@vp_wb
LD r2,r0,@vp_ch
MOVI r3,10
CMP r2,r3
JMP[EQ] @vp_nl
MOVI r3,13
CMP r2,r3
JMP[EQ] @vp_nl
MOVI r3,8
CMP r2,r3
JMP[EQ] @vp_bs
LD r1,r0,@vp_id
CALL @wm_vbuf
LD r4,r0,@vp_wb
LD r5,r4,#W_A3
MOVI r6,#VCW
MUL r5,r5,r6
LD r6,r4,#W_A2
ADD r5,r5,r6
ADD r5,r1,r5
LD r2,r0,@vp_ch
ST r2,r5,0
ADD r6,r6,r13
ST r6,r4,#W_A2
LD r7,r4,#W_A0
CMP r6,r7
JMP[LT] @vp_done
vp_nl:
LD r4,r0,@vp_wb
ST r0,r4,#W_A2
LD r5,r4,#W_A3
ADD r5,r5,r13
LD r6,r4,#W_A1
CMP r5,r6
JMP[LT] @vp_nl2
SUB r5,r6,r13
ST r5,r4,#W_A3
MOVI r7,1
ST r7,r4,#W_A4
LD r1,r0,@vp_id
CALL @wm_vbuf
LD r4,r0,@vp_wb
LD r6,r4,#W_A1
SUB r6,r6,r13
MOVI r7,#VCW
MUL r6,r6,r7
ADD r2,r1,r7
BCOPY r1,r2,r6
LD r5,r4,#W_A3
MOVI r7,#VCW
MUL r5,r5,r7
ADD r5,r1,r5
MOVI r2,0
MOVI r3,#VCW
BFILL r5,r2,r3
JMP @vp_done
vp_nl2:
ST r5,r4,#W_A3
JMP @vp_done
vp_bs:
LD r4,r0,@vp_wb
LD r6,r4,#W_A2
MOVI r7,2
CMP r6,r7
JMP[LE] @vp_done
SUB r6,r6,r13
ST r6,r4,#W_A2
LD r1,r0,@vp_id
CALL @wm_vbuf
LD r4,r0,@vp_wb
LD r5,r4,#W_A3
MOVI r7,#VCW
MUL r5,r5,r7
LD r6,r4,#W_A2
ADD r5,r5,r6
ADD r5,r1,r5
ST r0,r5,0
vp_done:
SUB r14,r14,r13
LD r15,r14,0
RET
vp_id:
.word 0
vp_ch:
.word 0
vp_wb:
.word 0
; ---- vc_puts: r1=id r2=string (word address, packed 4 bytes/word) ----
vc_puts:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@vs_id
SHL r2,r2,2
ST r2,r0,@vs_p
vs_loop:
LD r2,r0,@vs_p
LDB r3,r2,0
CMP r3,r0
JMP[EQ] @vs_done
ADD r2,r2,r13
ST r2,r0,@vs_p
LD r1,r0,@vs_id
ADD r2,r3,r0
CALL @vc_putc
JMP @vs_loop
vs_done:
SUB r14,r14,r13
LD r15,r14,0
RET
vs_id:
.word 0
vs_p:
.word 0
; ---- vc_cell: r1=id r2=col r3=row r4=char r5=colour : clear an 8x13 cell, draw the NaNGlyph ----
vc_cell:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,@vl_c
ST r3,r0,@vl_r
ST r4,r0,@vl_ch
ST r5,r0,@vl_col
CALL @wm_wbase
LD r2,r1,#W_X
LD r3,r1,#W_Y
MOVI r6,2
ADD r2,r2,r6
MOVI r6,18
ADD r3,r3,r6
LD r4,r0,@vl_c
MOVI r5,8
MUL r4,r4,r5
ADD r2,r2,r4
LD r4,r0,@vl_r
MOVI r5,13
MUL r4,r4,r5
ADD r3,r3,r4
ST r2,r0,@vl_x
ST r3,r0,@vl_y
ADD r1,r2,r0
ADD r2,r3,r0
MOVI r3,8
MOVI r4,13
MOVI r5,#C_BODY
CALL @wm_rect
LD r3,r0,@vl_ch
MOVI r4,32
CMP r3,r4
JMP[LE] @vl_done
LD r1,r0,@vl_x
LD r2,r0,@vl_y
LD r4,r0,@vl_col
CALL @fb_char7
vl_done:
SUB r14,r14,r13
LD r15,r14,0
RET
vl_c:
.word 0
vl_r:
.word 0
vl_ch:
.word 0
vl_col:
.word 0
vl_x:
.word 0
vl_y:
.word 0
; ---- term_cursor: r1=id -> draw '_' at the cursor ----
term_cursor:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@tc_id
CALL @wm_wbase
LD r2,r1,#W_A2
LD r3,r1,#W_A3
LD r1,r0,@tc_id
MOVI r4,95
MOVI r5,10
CALL @vc_cell
SUB r14,r14,r13
LD r15,r14,0
RET
tc_id:
.word 0
; ---- term_draw: r1=id, full body redraw ----
term_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@td_id
CALL @term_fit
LD r1,r0,@td_id
CALL @g_clr
LD r1,r0,@td_id
CALL @wm_wbase
ST r1,r0,@td_wb
LD r1,r0,@td_id
CALL @wm_vbuf
ST r1,r0,@td_buf
ST r0,r0,@td_r
td_row:
LD r4,r0,@td_wb
LD r1,r0,@td_r
LD r2,r4,#W_A1
CMP r1,r2
JMP[GE] @td_cur
ST r0,r0,@td_c
td_col:
LD r4,r0,@td_wb
LD r1,r0,@td_c
LD r2,r4,#W_A0
CMP r1,r2
JMP[GE] @td_nextrow
LD r2,r0,@td_r
MOVI r3,#VCW
MUL r2,r2,r3
ADD r2,r2,r1
LD r3,r0,@td_buf
ADD r2,r2,r3
LD r4,r2,0
MOVI r5,32
CMP r4,r5
JMP[LE] @td_skip
LD r1,r0,@td_id
LD r2,r0,@td_c
LD r3,r0,@td_r
MOVI r5,#C_TXT
CALL @vc_cell
td_skip:
LD r1,r0,@td_c
ADD r1,r1,r13
ST r1,r0,@td_c
JMP @td_col
td_nextrow:
LD r1,r0,@td_r
ADD r1,r1,r13
ST r1,r0,@td_r
JMP @td_row
td_cur:
LD r1,r0,@td_id
CALL @term_cursor
SUB r14,r14,r13
LD r15,r14,0
RET
td_id:
.word 0
td_wb:
.word 0
td_buf:
.word 0
td_r:
.word 0
td_c:
.word 0
; ---- term_key: r1=id r3=key ----
term_key:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@tk_id
ST r3,r0,@tk_k
MOVI r4,13
CMP r3,r4
JMP[EQ] @tk_enter
MOVI r4,8
CMP r3,r4
JMP[EQ] @tk_bs
MOVI r4,32
CMP r3,r4
JMP[LT] @tk_ret
MOVI r4,126
CMP r3,r4
JMP[GT] @tk_ret
; printable
CALL @wm_wbase
LD r2,r1,#W_A2
LD r3,r1,#W_A3
ST r2,r0,@tk_c
ST r3,r0,@tk_r
ST r0,r1,#W_A4
LD r1,r0,@tk_id
LD r2,r0,@tk_k
CALL @vc_putc
LD r1,r0,@tk_id
CALL @wm_wbase
LD r5,r1,#W_A4
CMP r5,r0
JMP[NE] @tk_full
LD r1,r0,@tk_id
LD r2,r0,@tk_c
LD r3,r0,@tk_r
LD r4,r0,@tk_k
MOVI r5,#C_TXT
CALL @vc_cell
LD r1,r0,@tk_id
CALL @term_cursor
JMP @tk_ret
tk_full:
LD r1,r0,@tk_id
CALL @wm_wbase
ST r0,r1,#W_A4
LD r1,r0,@tk_id
CALL @term_draw
JMP @tk_ret
tk_bs:
CALL @wm_wbase
LD r2,r1,#W_A2
LD r3,r1,#W_A3
MOVI r5,2
CMP r2,r5
JMP[LE] @tk_ret
LD r1,r0,@tk_id
MOVI r4,0
MOVI r5,#C_TXT
CALL @vc_cell
LD r1,r0,@tk_id
MOVI r2,8
CALL @vc_putc
LD r1,r0,@tk_id
CALL @term_cursor
JMP @tk_ret
tk_enter:
CALL @wm_wbase
LD r5,r1,#W_A3
MOVI r6,#VCW
MUL r5,r5,r6
MOVI r6,2
ADD r5,r5,r6
ST r5,r0,@tk_off
LD r1,r0,@tk_id
CALL @wm_vbuf
LD r5,r0,@tk_off
ADD r5,r1,r5
LD r4,r5,0
MOVI r6,65
CMP r4,r6
JMP[LT] @tk_lc
MOVI r6,90
CMP r4,r6
JMP[GT] @tk_lc
MOVI r6,32
ADD r4,r4,r6
tk_lc:
ST r4,r0,@tk_cmd
tk_docmd:
LD r1,r0,@tk_id
MOVI r2,10
CALL @vc_putc
LD r1,r0,@tk_id
LD r4,r0,@tk_cmd
CALL @term_cmd
LD r1,r0,@tk_id
CALL @wm_wbase
ST r0,r1,#W_A4
LD r1,r0,@tk_id
CALL @wm_wbase
LD r2,r1,#W_A2
CMP r2,r0
JMP[NE] @tk_nopr
LD r1,r0,@tk_id
MOVI r2,@s_prompt
CALL @vc_puts
tk_nopr:
LD r1,r0,@tk_id
CALL @term_draw
tk_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
tk_id:
.word 0
tk_k:
.word 0
tk_c:
.word 0
tk_r:
.word 0
tk_off:
.word 0
tk_cmd:
.word 0
s_prompt:
.str "> "
; ---- term_cmd: r1=id r4=command char ----
term_cmd:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@tm_id
CMP r4,r0
JMP[EQ] @tm_done
MOVI r5,104
CMP r4,r5
JMP[EQ] @tm_help
MOVI r5,118
CMP r4,r5
JMP[EQ] @tm_ver
MOVI r5,99
CMP r4,r5
JMP[EQ] @tm_clear
MOVI r5,119
CMP r4,r5
JMP[EQ] @tm_wins
MOVI r5,108
CMP r4,r5
JMP[EQ] @tm_lat
MOVI r5,109
CMP r4,r5
JMP[EQ] @tm_mon
MOVI r5,120
CMP r4,r5
JMP[EQ] @tm_hex
MOVI r5,116
CMP r4,r5
JMP[EQ] @tm_term
MOVI r5,113
CMP r4,r5
JMP[EQ] @tm_quit
MOVI r5,115
CMP r4,r5
JMP[EQ] @tm_set
MOVI r5,110
CMP r4,r5
JMP[EQ] @tm_net
MOVI r5,117
CMP r4,r5
JMP[EQ] @tm_utl
MOVI r2,@s_unk
CALL @vc_puts
JMP @tm_done
tm_help:
MOVI r2,@s_help
CALL @vc_puts
JMP @tm_done
tm_ver:
MOVI r2,@s_ver
CALL @vc_puts
JMP @tm_done
tm_clear:
CALL @wm_vbuf
MOVI r2,0
MOVI r3,8192
BFILL r1,r2,r3
LD r1,r0,@tm_id
CALL @wm_wbase
ST r0,r1,#W_A2
ST r0,r1,#W_A3
JMP @tm_done
tm_wins:
LD r1,r0,@tm_id
MOVI r2,@s_wins
CALL @vc_puts
LD r3,r0,@wm_zn
MOVI r4,48
ADD r2,r3,r4
LD r1,r0,@tm_id
CALL @vc_putc
LD r1,r0,@tm_id
MOVI r2,10
CALL @vc_putc
JMP @tm_done
tm_lat:
MOVI r1,1
CALL @gui_open_new
JMP @tm_done
tm_mon:
MOVI r1,2
CALL @gui_open_new
JMP @tm_done
tm_hex:
MOVI r1,3
CALL @gui_open_new
JMP @tm_done
tm_term:
MOVI r1,0
CALL @gui_open_new
JMP @tm_done
tm_set:
MOVI r1,4
CALL @gui_single
JMP @tm_done
tm_net:
MOVI r1,5
CALL @gui_single
JMP @tm_done
tm_utl:
MOVI r1,6
CALL @gui_single
JMP @tm_done
tm_quit:
MOVI r1,1
ST r1,r0,@g_quit
tm_done:
SUB r14,r14,r13
LD r15,r14,0
RET
tm_id:
.word 0
s_help:
.str "h c v w  l m x t  s n u  q\nl lattice m monitor\nx hex t term w count\ns settings n nannet u utils\nq quit gui\n"
s_ver:
.str "NaN/0S GUI r26\npure NaN16 wm\n"
s_wins:
.str "WINDOWS "
s_unk:
.str "?\n"
; ====================== r26: TEXT HELPERS, SETTINGS (F5), NaNNet (F6), UTILITIES (F7) ======================
; All pure NaN16. Text goes through NaNGlyph (fb_text7 / fb_char7); strings are 4 chars per word, so a CPUID register IS a string word.
; Scratch above the window buffers (0x40000..0x4FFFF): IDBUF 0x50000 (256 words), ATAT 0x50200 (4 slots x 16), PCIT 0x50300 (entries x 4).
.equ PCIMAX 12
.equ MODE_TMO 10000
.equ C_CY 11
.equ C_GRN 10
.equ C_DIM 8
; tx_org r1=id : tx_x = X+8, tx_y = Y+22 (text origin of the window body)
tx_org:
SHL r1,r1,5
MOVI r2,#WTL
MOVHI r2,#WTH
ADD r1,r1,r2
LD r2,r1,#W_X
MOVI r3,8
ADD r2,r2,r3
ST r2,r0,@tx_x
LD r2,r1,#W_Y
MOVI r3,22
ADD r2,r2,r3
ST r2,r0,@tx_y
RET
tx_x:
.word 0
tx_y:
.word 0
; tx_s r1=xoff r2=row r3=string r4=colour
tx_s:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@tx_x
ADD r1,r1,r5
MOVI r5,13
MUL r2,r2,r5
LD r5,r0,@tx_y
ADD r2,r2,r5
CALL @fb_text7
SUB r14,r14,r13
LD r15,r14,0
RET
; tx_c r1=xoff r2=row r3=ascii r4=colour
tx_c:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@tx_x
ADD r1,r1,r5
MOVI r5,13
MUL r2,r2,r5
LD r5,r0,@tx_y
ADD r2,r2,r5
CALL @fb_char7
SUB r14,r14,r13
LD r15,r14,0
RET
; tx_h r1=xoff r2=row r3=value r4=ndigits r5=colour (hex)
tx_h:
ST r15,r14,0
ADD r14,r14,r13
LD r6,r0,@tx_x
ADD r1,r1,r6
MOVI r6,13
MUL r2,r2,r6
LD r6,r0,@tx_y
ADD r2,r2,r6
CALL @wm_puthex
SUB r14,r14,r13
LD r15,r14,0
RET
; tx_d r1=xoff r2=row r3=value r4=colour (decimal, left aligned; leaves the end x in td2_x)
tx_d:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@tx_x
ADD r1,r1,r5
ST r1,r0,@td2_x
MOVI r5,13
MUL r2,r2,r5
LD r5,r0,@tx_y
ADD r2,r2,r5
ST r2,r0,@td2_y
ST r4,r0,@td2_c
MOVI r5,10
MOVI r6,0
td2_div:
MODU r7,r3,r5
DIVU r3,r3,r5
MOVI r8,@td2_b
ADD r8,r8,r6
ST r7,r8,0
ADD r6,r6,r13
CMP r3,r0
JMP[NE] @td2_div
ST r6,r0,@td2_n
td2_out:
LD r6,r0,@td2_n
CMP r6,r0
JMP[EQ] @td2_done
SUB r6,r6,r13
ST r6,r0,@td2_n
MOVI r8,@td2_b
ADD r8,r8,r6
LD r3,r8,0
MOVI r5,48
ADD r3,r3,r5
LD r1,r0,@td2_x
LD r2,r0,@td2_y
LD r4,r0,@td2_c
CALL @fb_char7
LD r1,r0,@td2_x
MOVI r5,8
ADD r1,r1,r5
ST r1,r0,@td2_x
JMP @td2_out
td2_done:
SUB r14,r14,r13
LD r15,r14,0
RET
td2_x:
.word 0
td2_y:
.word 0
td2_c:
.word 0
td2_n:
.word 0
td2_b:
.word 0,0,0,0,0,0,0,0,0,0,0,0
; tx_end -> r1 = x offset just after the last tx_d number
tx_end:
LD r1,r0,@td2_x
LD r2,r0,@tx_x
SUB r1,r1,r2
RET
; tx_wh r1=xoff r2=row r3=w r4=h r5=colour of w r6=colour of h : "W x H"
tx_wh:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,@wh_r
ST r4,r0,@wh_h
ST r6,r0,@wh_ch
ADD r4,r5,r0
ST r5,r0,@wh_cw
CALL @tx_d
CALL @tx_end
ST r1,r0,@wh_x
MOVI r2,8
ADD r1,r1,r2
LD r2,r0,@wh_r
MOVI r3,120
MOVI r4,#C_DIM
CALL @tx_c
LD r1,r0,@wh_x
MOVI r2,24
ADD r1,r1,r2
LD r2,r0,@wh_r
LD r3,r0,@wh_h
LD r4,r0,@wh_ch
CALL @tx_d
SUB r14,r14,r13
LD r15,r14,0
RET
wh_r:
.word 0
wh_h:
.word 0
wh_cw:
.word 0
wh_ch:
.word 0
wh_x:
.word 0
; gui_single r1=kind : raise the live window of that kind, or open one centred below the bar
gui_single:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@gs_k
MOVI r2,0
gs_l:
MOVI r3,#MAXW
CMP r2,r3
JMP[GE] @gs_new
SHL r4,r2,5
MOVI r5,#WTL
MOVHI r5,#WTH
ADD r4,r4,r5
LD r5,r4,#W_ALIVE
CMP r5,r0
JMP[EQ] @gs_n
LD r5,r4,#W_KIND
LD r6,r0,@gs_k
CMP r5,r6
JMP[EQ] @gs_have
gs_n:
ADD r2,r2,r13
JMP @gs_l
gs_have:
ADD r1,r2,r0
CALL @wm_raise
JMP @gs_ret
gs_new:
LD r1,r0,@gs_k
SHL r4,r1,2
MOVI r5,@kdef
ADD r4,r4,r5
LD r5,r4,0
LD r6,r0,@fb_w
MOVI r2,0
CMP r6,r5
JMP[LE] @gs_go
SUB r2,r6,r5
SHR r2,r2,1
gs_go:
MOVI r3,40
CALL @gui_open_at
gs_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
gs_k:
.word 0
; ====================== SETTINGS (kind 4) ======================
; A0 selected row (0 x86, 1 Galaxy A32 5G, 2 RISC-V disabled, 3 custom)  A1 custom W  A2 custom H  A3 custom field (0 W, 1 H)  A5 message code
; A mode change arms a 10 s TICK countdown: ENTER keeps, ESC (or the timeout) reverts to the previous mode. While armed g_onkey routes every key to st_pendkey.
st_init:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@st_wid
CALL @wm_wbase
MOVI r2,800
ST r2,r1,#W_A1
MOVI r2,600
ST r2,r1,#W_A2
SUB r14,r14,r13
LD r15,r14,0
RET
st_wid:
.word 0
st_pend:
.word 0
st_t0:
.word 0
st_ow:
.word 0
st_oh:
.word 0
st_sec:
.word 0
st_items:
.word @s_i0,1024,768,15
.word @s_i1,720,1600,15
.word @s_i2,0,0,8
.word @s_i3,0,0,15
st_msgs:
.word @s_e,@s_m1,@s_m2,@s_m3,@s_m4,@s_m5
t_set:
.str "SETTINGS"
s_st0:
.str "DISPLAY MODE"
s_cur:
.str "CURRENT"
s_i0:
.str "X86 PC"
s_i1:
.str "GALAXY A32 5G"
s_i2:
.str "RISC-V"
s_i3:
.str "CUSTOM"
s_dis:
.str "DISABLED"
s_e:
.str ""
s_m1:
.str "RISC-V IS NOT AVAILABLE"
s_m2:
.str "OUT OF RANGE: W 320-1920 (X8) H 200-1600 W*H<=2M"
s_m3:
.str "MODE KEPT"
s_m4:
.str "REVERTED TO THE PREVIOUS MODE"
s_m5:
.str "THAT MODE IS ALREADY ACTIVE"
s_sh1:
.str "UP/DOWN SELECT   ENTER APPLY"
s_sh2:
.str "CUSTOM: LEFT/RIGHT FIELD  0-9  BKSP"
s_keep:
.str "KEEP THIS MODE?  ENTER = KEEP   ESC = REVERT"
s_secs:
.str " SEC UNTIL AUTOMATIC REVERT"
; st_draw r1=id
st_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@sd_id
CALL @g_clr
LD r1,r0,@sd_id
CALL @tx_org
LD r1,r0,@sd_id
CALL @wm_wbase
ST r1,r0,@sd_wb
MOVI r1,0
MOVI r2,0
MOVI r3,@s_st0
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,1
MOVI r3,@s_cur
MOVI r4,#C_CY
CALL @tx_s
MOVI r1,72
MOVI r2,1
LD r3,r0,@fb_w
LD r4,r0,@fb_h
MOVI r5,#C_TXT
MOVI r6,#C_TXT
CALL @tx_wh
ST r0,r0,@sd_i
sd_l:
LD r1,r0,@sd_i
MOVI r2,4
CMP r1,r2
JMP[GE] @sd_after
SHL r5,r1,2
MOVI r6,@st_items
ADD r5,r5,r6
ST r5,r0,@sd_p
LD r6,r5,3
LD r3,r0,@sd_wb
LD r4,r3,#W_A0
CMP r1,r4
JMP[NE] @sd_nsel
MOVI r6,#C_YEL
MOVI r1,0
LD r2,r0,@sd_i
MOVI r3,3
ADD r2,r2,r3
MOVI r3,62
MOVI r4,#C_YEL
ST r6,r0,@sd_col
CALL @tx_c
LD r6,r0,@sd_col
sd_nsel:
ST r6,r0,@sd_col
LD r5,r0,@sd_p
LD r3,r5,0
MOVI r1,16
LD r2,r0,@sd_i
MOVI r5,3
ADD r2,r2,r5
LD r4,r0,@sd_col
CALL @tx_s
LD r1,r0,@sd_i
MOVI r2,3
CMP r1,r2
JMP[EQ] @sd_cust
MOVI r2,2
CMP r1,r2
JMP[EQ] @sd_dis
LD r5,r0,@sd_p
LD r3,r5,1
LD r4,r5,2
MOVI r1,136
LD r2,r0,@sd_i
MOVI r6,3
ADD r2,r2,r6
LD r5,r0,@sd_col
ADD r6,r5,r0
CALL @tx_wh
JMP @sd_next
sd_dis:
MOVI r1,136
LD r2,r0,@sd_i
MOVI r6,3
ADD r2,r2,r6
MOVI r3,@s_dis
LD r4,r0,@sd_col
CALL @tx_s
JMP @sd_next
sd_cust:
LD r5,r0,@sd_wb
LD r3,r5,#W_A1
LD r4,r5,#W_A2
LD r6,r5,#W_A3
MOVI r8,15
MOVI r9,15
CMP r6,r0
MOVI[EQ] r8,14
CMP r6,r13
MOVI[EQ] r9,14
MOVI r1,136
LD r2,r0,@sd_i
MOVI r6,3
ADD r2,r2,r6
ADD r5,r8,r0
ADD r6,r9,r0
CALL @tx_wh
sd_next:
LD r1,r0,@sd_i
ADD r1,r1,r13
ST r1,r0,@sd_i
JMP @sd_l
sd_after:
LD r5,r0,@sd_wb
LD r6,r5,#W_A5
MOVI r7,@st_msgs
ADD r7,r7,r6
LD r3,r7,0
MOVI r1,0
MOVI r2,8
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,10
MOVI r3,@s_sh1
MOVI r4,#C_DIM
CALL @tx_s
MOVI r1,0
MOVI r2,11
MOVI r3,@s_sh2
MOVI r4,#C_DIM
CALL @tx_s
LD r5,r0,@st_pend
CMP r5,r0
JMP[EQ] @sd_done
MOVI r1,0
MOVI r2,13
MOVI r3,@s_keep
MOVI r4,#C_YEL
CALL @tx_s
TICK r5
LD r6,r0,@st_t0
SUB r5,r5,r6
MOVI r6,1000
DIVU r5,r5,r6
MOVI r6,10
MOVI r3,0
CMP r5,r6
JMP[GE] @sd_z
SUB r3,r6,r5
sd_z:
MOVI r1,0
MOVI r2,14
MOVI r4,#C_GRN
CALL @tx_d
CALL @tx_end
MOVI r2,14
MOVI r3,@s_secs
MOVI r4,#C_GRN
CALL @tx_s
sd_done:
SUB r14,r14,r13
LD r15,r14,0
RET
sd_id:
.word 0
sd_wb:
.word 0
sd_i:
.word 0
sd_p:
.word 0
sd_col:
.word 0
; st_key r1=id r3=key
st_key:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@sk_id
ST r3,r0,@sk_k
CALL @wm_wbase
ST r1,r0,@sk_wb
ST r0,r1,#W_A5
LD r3,r0,@sk_k
LD r4,r1,#W_A0
MOVI r5,0x110
CMP r3,r5
JMP[EQ] @sk_up
MOVI r5,0x111
CMP r3,r5
JMP[EQ] @sk_dn
MOVI r5,13
CMP r3,r5
JMP[EQ] @sk_apply
MOVI r5,3
CMP r4,r5
JMP[NE] @sk_draw
MOVI r5,0x112
CMP r3,r5
JMP[EQ] @sk_f0
MOVI r5,0x113
CMP r3,r5
JMP[EQ] @sk_f1
MOVI r5,8
CMP r3,r5
JMP[EQ] @sk_bs
MOVI r5,48
CMP r3,r5
JMP[LT] @sk_draw
MOVI r5,57
CMP r3,r5
JMP[GT] @sk_draw
MOVI r5,48
SUB r3,r3,r5
LD r6,r1,#W_A3
ADD r7,r1,r6
LD r8,r7,#W_A1
MOVI r9,10
MUL r8,r8,r9
ADD r8,r8,r3
MOVI r9,9999
CMP r8,r9
JMP[GT] @sk_draw
ST r8,r7,#W_A1
JMP @sk_draw
sk_bs:
LD r6,r1,#W_A3
ADD r7,r1,r6
LD r8,r7,#W_A1
MOVI r9,10
DIVU r8,r8,r9
ST r8,r7,#W_A1
JMP @sk_draw
sk_f0:
ST r0,r1,#W_A3
JMP @sk_draw
sk_f1:
ST r13,r1,#W_A3
JMP @sk_draw
sk_up:
CMP r4,r0
JMP[EQ] @sk_draw
SUB r4,r4,r13
ST r4,r1,#W_A0
JMP @sk_draw
sk_dn:
MOVI r5,3
CMP r4,r5
JMP[GE] @sk_draw
ADD r4,r4,r13
ST r4,r1,#W_A0
JMP @sk_draw
sk_apply:
CALL @st_do
sk_draw:
LD r1,r0,@sk_id
CALL @st_draw
SUB r14,r14,r13
LD r15,r14,0
RET
sk_id:
.word 0
sk_k:
.word 0
sk_wb:
.word 0
; st_do : apply the selected row (A5 gets a message when nothing is applied)
st_do:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@sk_wb
LD r4,r1,#W_A0
MOVI r5,2
CMP r4,r5
JMP[EQ] @sdo_rv
MOVI r5,3
CMP r4,r5
JMP[EQ] @sdo_cu
SHL r4,r4,2
MOVI r5,@st_items
ADD r4,r4,r5
LD r2,r4,1
LD r3,r4,2
JMP @sdo_go
sdo_cu:
LD r2,r1,#W_A1
LD r3,r1,#W_A2
MOVI r5,0xFFF8
BOOL.8 r2,r2,r5
MOVI r5,320
CMP r2,r5
JMP[LT] @sdo_bad
MOVI r5,1920
CMP r2,r5
JMP[GT] @sdo_bad
MOVI r5,200
CMP r3,r5
JMP[LT] @sdo_bad
MOVI r5,1600
CMP r3,r5
JMP[GT] @sdo_bad
MUL r5,r2,r3
MOVI r6,0x8480
MOVHI r6,0x1E
CMP r5,r6
JMP[GT] @sdo_bad
ST r2,r1,#W_A1
sdo_go:
LD r5,r0,@fb_w
CMP r2,r5
JMP[NE] @sdo_diff
LD r5,r0,@fb_h
CMP r3,r5
JMP[EQ] @sdo_same
sdo_diff:
CALL @st_apply
JMP @sdo_ret
sdo_same:
MOVI r5,5
JMP @sdo_msg
sdo_bad:
MOVI r5,2
JMP @sdo_msg
sdo_rv:
MOVI r5,1
sdo_msg:
ST r5,r1,#W_A5
sdo_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; st_apply r2=w r3=h : remember the current mode, arm the countdown, switch
; st_mode r1 = w<<16|h : switch the display, re-fit every window, reseed the lattice, redraw
st_mode:
ST r15,r14,0
ADD r14,r14,r13
CALL @fb_init_mode
CALL @st_refit
ST r0,r0,@ls_w
ST r13,r0,@wm_redraw
SUB r14,r14,r13
LD r15,r14,0
RET
; st_refit : un-enlarge, then clamp every live window into the new screen
st_refit:
MOVI r1,0
srf_l:
MOVI r2,#MAXW
CMP r1,r2
RET[GE]
SHL r2,r1,5
MOVI r3,#WTL
MOVHI r3,#WTH
ADD r2,r2,r3
LD r3,r2,#W_ALIVE
CMP r3,r0
JMP[EQ] @srf_n
LD r3,r2,#W_FLAGS
CMP r3,r0
JMP[EQ] @srf_c
LD r3,r2,#W_SX
ST r3,r2,#W_X
LD r3,r2,#W_SY
ST r3,r2,#W_Y
LD r3,r2,#W_SW
ST r3,r2,#W_W
LD r3,r2,#W_SH
ST r3,r2,#W_H
ST r0,r2,#W_FLAGS
srf_c:
LD r4,r2,#W_W
LD r5,r0,@fb_w
CMP r4,r5
JMP[LE] @srf_w
ADD r4,r5,r0
ST r4,r2,#W_W
srf_w:
LD r6,r2,#W_H
LD r5,r0,@fb_h
MOVI r7,#TOPH
SUB r5,r5,r7
CMP r6,r5
JMP[LE] @srf_h
ADD r6,r5,r0
ST r6,r2,#W_H
srf_h:
LD r3,r2,#W_X
ADD r7,r3,r4
LD r5,r0,@fb_w
CMP r7,r5
JMP[LE] @srf_x
SUB r3,r5,r4
ST r3,r2,#W_X
srf_x:
LD r3,r2,#W_Y
ADD r7,r3,r6
LD r5,r0,@fb_h
CMP r7,r5
JMP[LE] @srf_y
SUB r3,r5,r6
srf_y:
MOVI r7,#TOPH
CMP r3,r7
JMP[GE] @srf_s
ADD r3,r7,r0
srf_s:
ST r3,r2,#W_Y
srf_n:
ADD r1,r1,r13
JMP @srf_l
; st_revert : back to the remembered mode
; st_pendkey r1=key : while the countdown runs ENTER keeps and ESC reverts; every other key is ignored
st_pendkey:
ST r15,r14,0
ADD r14,r14,r13
MOVI r2,13
CMP r1,r2
JMP[EQ] @pk_keep
MOVI r2,27
CMP r1,r2
JMP[EQ] @pk_rev
JMP @pk_ret
pk_keep:
ST r0,r0,@st_pend
MOVI r5,3
JMP @pk_msg
pk_rev:
CALL @st_revert
MOVI r5,4
pk_msg:
LD r1,r0,@st_wid
CALL @wm_wbase
ST r5,r1,#W_A5
ST r13,r0,@wm_redraw
pk_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; st_tick r1=id : countdown; revert at 10 s, redraw the banner once per second
st_tick:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@stt_id
LD r2,r0,@st_pend
CMP r2,r0
JMP[EQ] @stt_ret
TICK r2
LD r3,r0,@st_t0
SUB r2,r2,r3
MOVI r3,#MODE_TMO
CMP r2,r3
JMP[LT] @stt_wait
CALL @st_revert
LD r1,r0,@st_wid
CALL @wm_wbase
MOVI r2,4
ST r2,r1,#W_A5
JMP @stt_ret
stt_wait:
MOVI r3,1000
DIVU r2,r2,r3
LD r3,r0,@st_sec
CMP r2,r3
JMP[EQ] @stt_ret
ST r2,r0,@st_sec
LD r1,r0,@stt_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @stt_full
LD r1,r0,@stt_id
CALL @st_draw
JMP @stt_ret
stt_full:
ST r13,r0,@wm_redraw
stt_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
stt_id:
.word 0
; ====================== NaNNet (kind 5): connection UI, no NIC driver yet ======================
; A0 selected row (0 connect, 1 address mode, 2 DNS mode)  A1 0 DHCP / 1 STATIC  A2 0 AUTO / 1 MANUAL  A3 link (0 idle, 1 probing, 2 no driver, 3 no adapter)  A4 probe start (TICK)
nn_init:
ST r15,r14,0
ADD r14,r14,r13
CALL @pci_scan
CALL @pci_nic
SUB r14,r14,r13
LD r15,r14,0
RET
nn_nic:
.word 0
t_net:
.str "NaNNet"
s_n0:
.str "NaNNet  NETWORK CONTROL  (DRIVER PENDING)"
s_n1:
.str "ADAPTER"
s_n2:
.str "STATUS"
s_n3:
.str "NONE ON PCI BUS 0"
s_n4:
.str "CONNECT"
s_n5:
.str "ADDRESS"
s_n6:
.str "DNS"
s_n7:
.str "HOST"
s_n8:
.str "NAN0S"
s_nh:
.str "UP/DOWN SELECT   ENTER OR LEFT/RIGHT CHANGE"
s_dhcp:
.str "DHCP"
s_stat:
.str "STATIC"
s_auto:
.str "AUTO"
s_man:
.str "MANUAL"
s_l0:
.str "DISCONNECTED"
s_l1:
.str "PROBING"
s_l2:
.str "ADAPTER FOUND, NO DRIVER YET (STUB)"
s_l3:
.str "NO ADAPTER FOUND"
s_io:
.str "IO"
nn_ls:
.word @s_l0,@s_l1,@s_l2,@s_l3
; nn_draw r1=id
nn_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@nd_id
CALL @g_clr
LD r1,r0,@nd_id
CALL @tx_org
LD r1,r0,@nd_id
CALL @wm_wbase
ST r1,r0,@nd_wb
MOVI r1,0
MOVI r2,0
MOVI r3,@s_n0
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,2
MOVI r3,@s_n1
MOVI r4,#C_CY
CALL @tx_s
LD r5,r0,@nn_nic
CMP r5,r0
JMP[NE] @nd_have
MOVI r1,72
MOVI r2,2
MOVI r3,@s_n3
MOVI r4,#C_DIM
CALL @tx_s
JMP @nd_stat
nd_have:
LD r3,r5,1
SHR r3,r3,16
MOVI r1,72
MOVI r2,2
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
MOVI r1,104
MOVI r2,2
MOVI r3,58
MOVI r4,#C_DIM
CALL @tx_c
LD r5,r0,@nn_nic
LD r3,r5,1
MOVI r6,0xFFFF
BOOL.8 r3,r3,r6
MOVI r1,112
MOVI r2,2
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
MOVI r1,168
MOVI r2,2
MOVI r3,@s_io
MOVI r4,#C_CY
CALL @tx_s
LD r5,r0,@nn_nic
LD r3,r5,3
MOVI r6,0xFFFC
BOOL.8 r3,r3,r6
MOVI r1,192
MOVI r2,2
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
nd_stat:
MOVI r1,0
MOVI r2,3
MOVI r3,@s_n2
MOVI r4,#C_CY
CALL @tx_s
LD r5,r0,@nd_wb
LD r6,r5,#W_A3
MOVI r7,@nn_ls
ADD r7,r7,r6
LD r3,r7,0
MOVI r1,72
MOVI r2,3
MOVI r4,#C_TXT
MOVI r8,2
CMP r6,r8
JMP[LT] @nd_sc
MOVI r4,#C_YEL
nd_sc:
CALL @tx_s
LD r5,r0,@nd_wb
LD r6,r5,#W_A3
CMP r6,r13
JMP[NE] @nd_rows
LD r5,r0,@nd_wb
LD r6,r5,#W_A4
TICK r7
SUB r7,r7,r6
MOVI r6,250
DIVU r7,r7,r6
MOVI r6,3
BOOL.8 r7,r7,r6
ADD r7,r7,r13
ST r7,r0,@nd_dots
ST r0,r0,@nd_i
nd_dl:
LD r1,r0,@nd_i
LD r2,r0,@nd_dots
CMP r1,r2
JMP[GE] @nd_rows
MOVI r2,8
MUL r1,r1,r2
MOVI r2,128
ADD r1,r1,r2
MOVI r2,3
MOVI r3,46
MOVI r4,#C_TXT
CALL @tx_c
LD r1,r0,@nd_i
ADD r1,r1,r13
ST r1,r0,@nd_i
JMP @nd_dl
nd_rows:
ST r0,r0,@nd_i
nd_rl:
LD r1,r0,@nd_i
MOVI r2,3
CMP r1,r2
JMP[GE] @nd_host
LD r5,r0,@nd_wb
LD r6,r5,#W_A0
MOVI r4,#C_TXT
CMP r1,r6
JMP[NE] @nd_nsel
MOVI r4,#C_YEL
ST r4,r0,@nd_col
MOVI r1,0
LD r2,r0,@nd_i
MOVI r3,5
ADD r2,r2,r3
MOVI r3,62
CALL @tx_c
LD r4,r0,@nd_col
LD r1,r0,@nd_i
nd_nsel:
ST r4,r0,@nd_col
MOVI r7,@nn_lab
LD r1,r0,@nd_i
ADD r7,r7,r1
LD r3,r7,0
MOVI r1,16
LD r2,r0,@nd_i
MOVI r5,5
ADD r2,r2,r5
LD r4,r0,@nd_col
CALL @tx_s
LD r1,r0,@nd_i
CMP r1,r0
JMP[EQ] @nd_next
LD r5,r0,@nd_wb
ADD r6,r5,r1
LD r7,r6,#W_A0
SUB r8,r1,r13
SHL r8,r8,1
ADD r8,r8,r7
MOVI r9,@nn_val
ADD r8,r8,r9
LD r3,r8,0
MOVI r1,88
LD r2,r0,@nd_i
MOVI r5,5
ADD r2,r2,r5
LD r4,r0,@nd_col
CALL @tx_s
nd_next:
LD r1,r0,@nd_i
ADD r1,r1,r13
ST r1,r0,@nd_i
JMP @nd_rl
nd_host:
MOVI r1,0
MOVI r2,9
MOVI r3,@s_n7
MOVI r4,#C_CY
CALL @tx_s
MOVI r1,72
MOVI r2,9
MOVI r3,@s_n8
MOVI r4,#C_TXT
CALL @tx_s
MOVI r1,0
MOVI r2,11
MOVI r3,@s_nh
MOVI r4,#C_DIM
CALL @tx_s
SUB r14,r14,r13
LD r15,r14,0
RET
nd_id:
.word 0
nd_wb:
.word 0
nd_i:
.word 0
nd_col:
.word 0
nd_dots:
.word 0
nn_lab:
.word @s_n4,@s_n5,@s_n6
nn_val:
.word @s_dhcp,@s_stat,@s_auto,@s_man
; nn_key r1=id r3=key : UP/DOWN row, ENTER on CONNECT probes, ENTER/LEFT/RIGHT flips ADDRESS (DHCP/STATIC) and DNS (AUTO/MANUAL) by XOR
nn_key:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@nk_id
CALL @wm_wbase
LD r4,r1,#W_A0
LD r3,r0,@g_key
MOVI r5,0x110
CMP r3,r5
JMP[EQ] @nk_up
MOVI r5,0x111
CMP r3,r5
JMP[EQ] @nk_dn
MOVI r5,13
CMP r3,r5
JMP[EQ] @nk_act
MOVI r5,0x112
CMP r3,r5
JMP[EQ] @nk_tog
MOVI r5,0x113
CMP r3,r5
JMP[EQ] @nk_tog
JMP @nk_draw
nk_up:
CMP r4,r0
JMP[EQ] @nk_draw
SUB r4,r4,r13
ST r4,r1,#W_A0
JMP @nk_draw
nk_dn:
MOVI r5,2
CMP r4,r5
JMP[GE] @nk_draw
ADD r4,r4,r13
ST r4,r1,#W_A0
JMP @nk_draw
nk_act:
CMP r4,r0
JMP[NE] @nk_tog
ST r13,r1,#W_A3
TICK r5
ST r5,r1,#W_A4
JMP @nk_draw
nk_tog:
CMP r4,r0
JMP[EQ] @nk_draw
ADD r6,r1,r4
LD r7,r6,#W_A0
BOOL.6 r7,r7,r13
ST r7,r6,#W_A0
nk_draw:
LD r1,r0,@nk_id
CALL @nn_draw
SUB r14,r14,r13
LD r15,r14,0
RET
nk_id:
.word 0
; nn_tick r1=id : probe ends after 1.5 s (found -> no driver stub, none -> no adapter); dots animate while probing
nn_tick:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@nt_id
CALL @wm_wbase
LD r2,r1,#W_A3
CMP r2,r13
JMP[NE] @nt_ret
LD r3,r1,#W_A4
TICK r4
SUB r4,r4,r3
MOVI r5,1500
CMP r4,r5
JMP[LT] @nt_anim
LD r5,r0,@nn_nic
MOVI r6,2
CMP r5,r0
MOVI[EQ] r6,3
ST r6,r1,#W_A3
nt_anim:
LD r1,r0,@nt_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @nt_ret
LD r1,r0,@nt_id
CALL @nn_draw
nt_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
nt_id:
.word 0
; ====================== PCI (bus 0) ======================
; entries x4 words at PCIT: bdf, ven<<16|dev, class code dword (class<<24|sub<<16|progif<<8|rev), BAR0. Every word is stored as CLASS 6 (STW) and read back with LDN: a bad head or foreign class drops the entry (gate-style integrity).
; pci_rd r1=bdf r2=offset -> r1 = config dword (OUTL 0xCF8, then two INW at 0xCFC/0xCFE). Clobbers r1-r7.
pci_rd:
SHL r3,r1,8
BOOL.14 r3,r3,r2
MOVI r4,0
MOVHI r4,0x8000
BOOL.14 r3,r3,r4
MOVI r5,0xCF8
OUTL r3,r5
MOVI r5,0xCFC
INW r6,r5
MOVI r5,0xCFE
INW r7,r5
SHL r7,r7,16
BOOL.14 r1,r6,r7
RET
pci_scan:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,@pci_n
ST r0,r0,@ps_d
ps_dl:
LD r1,r0,@ps_d
MOVI r2,32
CMP r1,r2
JMP[GE] @ps_done
ST r0,r0,@ps_f
ST r0,r0,@ps_mf
ps_fl:
LD r1,r0,@ps_f
MOVI r2,8
CMP r1,r2
JMP[GE] @ps_dn
LD r1,r0,@ps_d
SHL r1,r1,3
LD r2,r0,@ps_f
ADD r1,r1,r2
ST r1,r0,@ps_b
MOVI r2,0
CALL @pci_rd
ST r1,r0,@ps_v
MOVI r2,0xFFFF
BOOL.8 r3,r1,r2
CMP r3,r2
JMP[EQ] @ps_nf
CMP r3,r0
JMP[EQ] @ps_nf
LD r2,r0,@ps_f
CMP r2,r0
JMP[NE] @ps_st
LD r1,r0,@ps_b
MOVI r2,12
CALL @pci_rd
SHR r1,r1,23
MOVI r2,1
BOOL.8 r1,r1,r2
ST r1,r0,@ps_mf
ps_st:
LD r4,r0,@pci_n
MOVI r5,#PCIMAX
CMP r4,r5
JMP[GE] @ps_nf
SHL r4,r4,2
MOVI r5,0x300
MOVHI r5,5
ADD r4,r4,r5
ST r4,r0,@ps_e
MOVI r6,6
LD r1,r0,@ps_b
STW r1,r4,r6
LD r1,r0,@ps_v
MOVI r2,0xFFFF
BOOL.8 r3,r1,r2
SHL r3,r3,16
SHR r1,r1,16
BOOL.14 r1,r1,r3
LD r4,r0,@ps_e
ADD r5,r4,r13
MOVI r6,6
STW r1,r5,r6
LD r1,r0,@ps_b
MOVI r2,8
CALL @pci_rd
LD r4,r0,@ps_e
MOVI r5,2
ADD r5,r4,r5
MOVI r6,6
STW r1,r5,r6
LD r1,r0,@ps_b
MOVI r2,16
CALL @pci_rd
LD r4,r0,@ps_e
MOVI r5,3
ADD r5,r4,r5
MOVI r6,6
STW r1,r5,r6
LD r4,r0,@pci_n
ADD r4,r4,r13
ST r4,r0,@pci_n
ps_nf:
LD r1,r0,@ps_f
LD r2,r0,@ps_mf
CMP r2,r0
JMP[NE] @ps_nx
CMP r1,r0
JMP[NE] @ps_nx
MOVI r1,7
ps_nx:
ADD r1,r1,r13
ST r1,r0,@ps_f
JMP @ps_fl
ps_dn:
LD r1,r0,@ps_d
ADD r1,r1,r13
ST r1,r0,@ps_d
JMP @ps_dl
ps_done:
SUB r14,r14,r13
LD r15,r14,0
RET
pci_n:
.word 0
ps_d:
.word 0
ps_f:
.word 0
ps_mf:
.word 0
ps_b:
.word 0
ps_v:
.word 0
ps_e:
.word 0
; pci_nic : nn_nic = first class-2 (network) entry whose words still read back as class 6, else 0
pci_nic:
ST r0,r0,@nn_nic
MOVI r1,0
pn_l:
LD r2,r0,@pci_n
CMP r1,r2
RET[GE]
SHL r3,r1,2
MOVI r4,0x300
MOVHI r4,5
ADD r3,r3,r4
ADD r5,r3,r13
LDN r6,r5,0
MOVI r7,6
CMP r6,r7
JMP[NE] @pn_n
LD r6,r3,2
SHR r6,r6,24
MOVI r7,2
CMP r6,r7
JMP[NE] @pn_n
ST r3,r0,@nn_nic
RET
pn_n:
ADD r1,r1,r13
JMP @pn_l
; ====================== MODE RECORD: DOUBLE-ENDIAN SAVE ======================
; The mode to revert to is kept as a class-6 word plus its BSWAPM mirror (class rot2(6)=9, payload byte-reversed).
; st_load re-mirrors a scratch copy, so a damaged word fails the class check or the payload compare and falls back to 1024x768.
; st_save r2=w r3=h
st_save:
SHL r4,r2,16
ADD r4,r4,r3
MOVI r5,@sv_rec
MOVI r6,6
STW r4,r5,r6
ADD r7,r5,r13
MOVI r8,1
BCOPY r7,r5,r8
BSWAPM r7,0
RET
; st_load -> r1 = w<<16|h
st_load:
MOVI r5,@sv_rec
LDN r6,r5,0
MOVI r7,6
CMP r6,r7
JMP[NE] @sl_bad
ADD r7,r5,r13
LDN r6,r7,0
MOVI r8,9
CMP r6,r8
JMP[NE] @sl_bad
ADD r9,r7,r13
MOVI r8,1
BCOPY r9,r7,r8
BSWAPM r9,0
LDN r6,r9,0
MOVI r8,6
CMP r6,r8
JMP[NE] @sl_bad
LD r10,r9,0
LD r11,r5,0
CMP r10,r11
JMP[NE] @sl_bad
ADD r1,r11,r0
RET
sl_bad:
MOVI r1,768
MOVI r2,1024
SHL r2,r2,16
ADD r1,r1,r2
RET
sv_rec:
.word 0,0,0
; st_apply r2=w r3=h : save the current mode (double-endian), arm the countdown, switch
st_apply:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,@sa_w
ST r3,r0,@sa_h
LD r2,r0,@fb_w
LD r3,r0,@fb_h
CALL @st_save
ST r13,r0,@st_pend
ST r0,r0,@st_sec
TICK r5
ST r5,r0,@st_t0
LD r2,r0,@sa_w
SHL r1,r2,16
LD r3,r0,@sa_h
ADD r1,r1,r3
CALL @st_mode
SUB r14,r14,r13
LD r15,r14,0
RET
sa_w:
.word 0
sa_h:
.word 0
; st_revert : back to the saved mode
st_revert:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,@st_pend
CALL @st_load
CALL @st_mode
SUB r14,r14,r13
LD r15,r14,0
RET
; ====================== UTILITIES (kind 6) ======================
; CPUID registers are stored as words: EBX,EDX,ECX of leaf 0 ARE the vendor string (4 chars per word), leaves 0x80000002-4 are the brand string.
; TSC low is also shown through its mirror: a class-6 word, BSWAPM, payload = the byte-reversed (big-endian face) value.
.equ IDBUF 0x50000
ut_init:
ST r15,r14,0
ADD r14,r14,r13
CALL @ut_cpu
CALL @ut_atas
CALL @pci_scan
CALL @ut_mem
TICK r1
ST r1,r0,@ut_t0
RDTSC r2,r0
ST r2,r0,@ut_c0
SUB r14,r14,r13
LD r15,r14,0
RET
; ut_mem: guest word-space size by address aliasing (write a marker at Q+n, see whether Q changed; Q's word is saved/restored),
; and the CPU's long-mode bit (CPUID 0x80000001 EDX bit 29) for the ARCH row.
ut_mem:
MOVI r5,@ut_pr
LD r6,r5,0
ST r6,r0,@um_sv
MOVI r8,0
MOVHI r8,1
um_l:
MOVI r9,0
MOVHI r9,0x1000
CMP r8,r9
JMP[GT] @um_fin
MOVI r5,@ut_pr
ADD r10,r5,r8
ST r0,r5,0
LD r6,r0,@um_pat
ST r6,r10,0
LD r7,r5,0
CMP r7,r6
JMP[EQ] @um_fin
LD r7,r10,0
CMP r7,r6
JMP[NE] @um_fin
ST r0,r10,0
ADD r8,r8,r8
JMP @um_l
um_fin:
ST r8,r0,@um_w
MOVI r5,@ut_pr
LD r6,r0,@um_sv
ST r6,r5,0
ST r0,r0,@um_lm
MOVI r1,0
MOVHI r1,0x8000
MOVI r2,0
CPUID r3,r1,r2
MOVI r4,1
MOVHI r4,0x8000
CMP r3,r4
RET[LT]
MOVI r1,1
MOVHI r1,0x8000
MOVI r2,3
CPUID r3,r1,r2
SHR r3,r3,29
BOOL.8 r3,r3,r13
ST r3,r0,@um_lm
RET
ut_pr:
.word 0
um_sv:
.word 0
um_w:
.word 0
um_lm:
.word 0
um_pat:
.word 0x5A5AC3C3
ut_cpu:
MOVI r1,0
MOVI r5,@ut_cv
MOVI r2,1
CPUID r3,r1,r2
ST r3,r5,0
MOVI r2,3
CPUID r3,r1,r2
ST r3,r5,1
MOVI r2,2
CPUID r3,r1,r2
ST r3,r5,2
MOVI r1,1
MOVI r2,0
CPUID r3,r1,r2
ST r3,r0,@ut_sig
MOVI r2,2
CPUID r3,r1,r2
ST r3,r0,@ut_ecx
MOVI r2,3
CPUID r3,r1,r2
ST r3,r0,@ut_edx
LD r3,r0,@ut_sig
SHR r4,r3,8
MOVI r5,15
BOOL.8 r4,r4,r5
CMP r4,r5
JMP[NE] @uc_f
SHR r6,r3,20
MOVI r7,255
BOOL.8 r6,r6,r7
ADD r4,r4,r6
uc_f:
ST r4,r0,@ut_fam
SHR r4,r3,4
BOOL.8 r4,r4,r5
SHR r6,r3,16
BOOL.8 r6,r6,r5
SHL r6,r6,4
BOOL.14 r4,r4,r6
ST r4,r0,@ut_mod
BOOL.8 r4,r3,r5
ST r4,r0,@ut_stp
MOVI r1,0
MOVHI r1,0x8000
MOVI r2,0
CPUID r3,r1,r2
MOVI r4,4
MOVHI r4,0x8000
CMP r3,r4
RET[LT]
ST r0,r0,@uc_l
uc_l1:
LD r6,r0,@uc_l
MOVI r7,3
CMP r6,r7
RET[GE]
MOVI r1,2
MOVHI r1,0x8000
ADD r1,r1,r6
MOVI r2,0
uc_r:
MOVI r7,4
CMP r2,r7
JMP[GE] @uc_ln
CPUID r3,r1,r2
SHL r8,r6,2
ADD r8,r8,r2
MOVI r9,@ut_br
ADD r8,r8,r9
ST r3,r8,0
ADD r2,r2,r13
JMP @uc_r
uc_ln:
LD r6,r0,@uc_l
ADD r6,r6,r13
ST r6,r0,@uc_l
JMP @uc_l1
uc_l:
.word 0
; ut_atas : IDENTIFY all four slots (primary/secondary x master/slave)
ut_atas:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,@ua_s
ua_l:
LD r1,r0,@ua_s
MOVI r2,4
CMP r1,r2
JMP[GE] @ua_d
CALL @ut_ide
LD r1,r0,@ua_s
ADD r1,r1,r13
ST r1,r0,@ua_s
JMP @ua_l
ua_d:
SUB r14,r14,r13
LD r15,r14,0
RET
ua_s:
.word 0
; ut_ide r1=slot : entry at ATAT+slot*16 = present, LBA28 sectors, model (10 words, byte-swapped pairs fixed), terminator. Every wait is bounded; a floating bus (0xFF / 0) or an ATAPI signature means no ATA drive.
ut_ide:
SHL r12,r1,4
MOVI r2,0x200
MOVHI r2,5
ADD r12,r12,r2
ST r0,r12,0
ST r0,r12,12
MOVI r10,0x1F0
MOVI r2,2
CMP r1,r2
MOVI[GE] r10,0x170
MOVI r11,0xA0
MOVI r2,1
BOOL.8 r3,r1,r2
CMP r3,r0
MOVI[NE] r11,0xB0
MOVI r4,6
ADD r2,r10,r4
OUTB r11,r2
MOVI r4,7
ADD r5,r10,r4
INB r3,r5
INB r3,r5
INB r3,r5
INB r3,r5
MOVI r6,0xFF
CMP r3,r6
RET[EQ]
CMP r3,r0
RET[EQ]
MOVI r4,0xEC
OUTB r4,r5
LA r8,200000
ui_b:
INB r3,r5
MOVI r6,0x80
BOOL.8 r7,r3,r6
CMP r7,r0
JMP[EQ] @ui_bd
SUB r8,r8,r13
JMP[NE] @ui_b
RET
ui_bd:
CMP r3,r0
RET[EQ]
MOVI r4,4
ADD r6,r10,r4
INB r7,r6
MOVI r4,5
ADD r6,r10,r4
INB r9,r6
BOOL.14 r7,r7,r9
CMP r7,r0
RET[NE]
LA r8,200000
ui_d:
INB r3,r5
MOVI r6,9
BOOL.8 r7,r3,r6
CMP r7,r0
JMP[NE] @ui_dd
SUB r8,r8,r13
JMP[NE] @ui_d
RET
ui_dd:
MOVI r6,1
BOOL.8 r7,r3,r6
CMP r7,r0
RET[NE]
MOVI r2,0
MOVHI r2,5
MOVI r8,256
ui_r:
INW r3,r10
ST r3,r2,0
ADD r2,r2,r13
SUB r8,r8,r13
JMP[NE] @ui_r
MOVI r2,0
MOVHI r2,5
LD r3,r2,60
LD r4,r2,61
SHL r4,r4,16
BOOL.14 r3,r3,r4
ST r3,r12,1
MOVI r8,0
ui_m:
MOVI r9,10
CMP r8,r9
JMP[GE] @ui_md
SHL r4,r8,1
ADD r4,r4,r2
LD r5,r4,27
LD r6,r4,28
MOVI r9,255
SHR r7,r5,8
BOOL.8 r5,r5,r9
SHL r5,r5,8
BOOL.14 r7,r7,r5
SHR r4,r6,8
BOOL.8 r6,r6,r9
SHL r6,r6,8
BOOL.14 r4,r4,r6
SHL r4,r4,16
BOOL.14 r7,r7,r4
ADD r4,r12,r8
ADD r4,r4,r13
ADD r4,r4,r13
ST r7,r4,0
ADD r8,r8,r13
JMP @ui_m
ui_md:
ST r13,r12,0
RET
; ut_tick r1=id : TSC over >= 500 ms of TICK -> MHz; refreshes the window when it is not covered
ut_tick:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ud_id
TICK r2
LD r3,r0,@ut_t0
SUB r4,r2,r3
MOVI r5,500
CMP r4,r5
JMP[LT] @utk_ret
RDTSC r6,r0
LD r7,r0,@ut_c0
SUB r8,r6,r7
ST r8,r0,@ut_dl
MOVI r9,1000
MUL r9,r4,r9
DIVU r8,r8,r9
ST r8,r0,@ut_mhz
ST r2,r0,@ut_t0
ST r6,r0,@ut_c0
ST r6,r0,@ut_lo
RDTSC r10,r13
ST r10,r0,@ut_hi
MOVI r5,@ut_tw
MOVI r7,6
STW r6,r5,r7
ADD r8,r5,r13
MOVI r9,1
BCOPY r8,r5,r9
BSWAPM r8,0
LD r10,r8,0
ST r10,r0,@ut_be
LD r1,r0,@ud_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @utk_ret
LD r1,r0,@ud_id
CALL @ut_draw
utk_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
ux_lab:
MOVI r4,#C_CY
JMP @tx_s
ux_h8:
MOVI r4,8
MOVI r5,#C_TXT
JMP @tx_h
ut_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ud_id
CALL @g_clr
LD r1,r0,@ud_id
CALL @tx_org
LD r1,r0,@ud_id
CALL @wm_wbase
LD r2,r1,#W_H
MOVI r3,22
SUB r2,r2,r3
MOVI r3,13
DIVU r2,r2,r3
ST r2,r0,@ud_rows
MOVI r1,0
MOVI r2,0
MOVI r3,@s_u0
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,1
MOVI r3,@s_ucpu
CALL @ux_lab
MOVI r1,40
MOVI r2,1
MOVI r3,@ut_cv
MOVI r4,#C_TXT
CALL @tx_s
MOVI r1,0
MOVI r2,2
MOVI r3,@s_unm
CALL @ux_lab
MOVI r1,40
MOVI r2,2
MOVI r3,@ut_br
MOVI r4,#C_TXT
CALL @tx_s
MOVI r1,0
MOVI r2,3
MOVI r3,@s_usig
CALL @ux_lab
MOVI r1,40
MOVI r2,3
LD r3,r0,@ut_sig
CALL @ux_h8
MOVI r1,120
MOVI r2,3
MOVI r3,@s_ufam
CALL @ux_lab
MOVI r1,152
MOVI r2,3
LD r3,r0,@ut_fam
MOVI r4,#C_TXT
CALL @tx_d
MOVI r1,200
MOVI r2,3
MOVI r3,@s_umod
CALL @ux_lab
MOVI r1,232
MOVI r2,3
LD r3,r0,@ut_mod
MOVI r4,2
MOVI r5,#C_TXT
CALL @tx_h
MOVI r1,272
MOVI r2,3
MOVI r3,@s_ustp
CALL @ux_lab
MOVI r1,304
MOVI r2,3
LD r3,r0,@ut_stp
MOVI r4,1
MOVI r5,#C_TXT
CALL @tx_h
MOVI r1,0
MOVI r2,4
MOVI r3,@s_uedx
CALL @ux_lab
MOVI r1,40
MOVI r2,4
LD r3,r0,@ut_edx
CALL @ux_h8
MOVI r1,120
MOVI r2,4
MOVI r3,@s_uecx
CALL @ux_lab
MOVI r1,152
MOVI r2,4
LD r3,r0,@ut_ecx
CALL @ux_h8
MOVI r1,0
MOVI r2,5
MOVI r3,@s_utsc
CALL @ux_lab
MOVI r1,40
MOVI r2,5
LD r3,r0,@ut_hi
CALL @ux_h8
MOVI r1,112
MOVI r2,5
LD r3,r0,@ut_lo
CALL @ux_h8
MOVI r1,200
MOVI r2,5
MOVI r3,@s_ube
CALL @ux_lab
MOVI r1,232
MOVI r2,5
LD r3,r0,@ut_be
MOVI r4,8
MOVI r5,#C_YEL
CALL @tx_h
MOVI r1,0
MOVI r2,6
MOVI r3,@s_umhz
CALL @ux_lab
MOVI r1,40
MOVI r2,6
LD r3,r0,@ut_mhz
MOVI r4,#C_GRN
CALL @tx_d
MOVI r1,120
MOVI r2,6
MOVI r3,@s_uarch
CALL @ux_lab
MOVI r1,160
MOVI r2,6
MOVI r3,@s_ux86
MOVI r4,#C_GRN
CALL @tx_s
LD r5,r0,@um_lm
CMP r5,r0
JMP[EQ] @ud_nolm
MOVI r1,192
MOVI r2,6
MOVI r3,@s_ulm
MOVI r4,#C_YEL
CALL @tx_s
ud_nolm:
MOVI r1,0
MOVI r2,7
MOVI r3,@s_umem
CALL @ux_lab
MOVI r1,40
MOVI r2,7
LD r3,r0,@um_w
MOVI r4,#C_TXT
CALL @tx_d
MOVI r1,112
MOVI r2,7
MOVI r3,@s_uwd
MOVI r4,#C_DIM
CALL @tx_s
MOVI r1,160
MOVI r2,7
LD r3,r0,@um_w
SHR r3,r3,17
MOVI r4,#C_GRN
CALL @tx_d
MOVI r1,200
MOVI r2,7
MOVI r3,@s_umb
MOVI r4,#C_DIM
CALL @tx_s
MOVI r1,0
MOVI r2,12
MOVI r3,@s_uvr
CALL @ux_lab
LD r3,r0,@fb_w
LD r4,r0,@fb_h
MUL r3,r3,r4
SHR r3,r3,10
MOVI r1,40
MOVI r2,12
MOVI r4,#C_TXT
CALL @tx_d
MOVI r1,100
MOVI r2,12
MOVI r3,@s_ukb
MOVI r4,#C_DIM
CALL @tx_s
MOVI r1,136
MOVI r2,12
LD r3,r0,@fb_w
MOVI r4,#C_GRN
CALL @tx_d
MOVI r1,184
MOVI r2,12
MOVI r3,@s_uxx
MOVI r4,#C_DIM
CALL @tx_s
MOVI r1,200
MOVI r2,12
LD r3,r0,@fb_h
MOVI r4,#C_GRN
CALL @tx_d
ST r0,r0,@ud_i
ud_al:
LD r1,r0,@ud_i
MOVI r2,4
CMP r1,r2
JMP[GE] @ud_pci
SHL r2,r1,4
MOVI r3,0x200
MOVHI r3,5
ADD r2,r2,r3
ST r2,r0,@ud_e
MOVI r3,@ut_an
ADD r3,r3,r1
LD r3,r3,0
MOVI r5,8
ADD r2,r1,r5
ST r2,r0,@ud_r
MOVI r1,0
MOVI r4,#C_CY
CALL @tx_s
LD r6,r0,@ud_e
LD r5,r6,0
CMP r5,r0
JMP[NE] @ud_have
MOVI r1,104
LD r2,r0,@ud_r
MOVI r3,@s_unone
MOVI r4,#C_DIM
CALL @tx_s
JMP @ud_an
ud_have:
LD r3,r6,1
SHR r3,r3,11
MOVI r1,104
LD r2,r0,@ud_r
MOVI r4,#C_TXT
CALL @tx_d
MOVI r1,160
LD r2,r0,@ud_r
MOVI r3,@s_umb
MOVI r4,#C_DIM
CALL @tx_s
LD r6,r0,@ud_e
MOVI r5,2
ADD r3,r6,r5
MOVI r1,184
LD r2,r0,@ud_r
MOVI r4,#C_TXT
CALL @tx_s
ud_an:
LD r1,r0,@ud_i
ADD r1,r1,r13
ST r1,r0,@ud_i
JMP @ud_al
ud_pci:
MOVI r1,0
MOVI r2,13
MOVI r3,@s_upci
CALL @ux_lab
MOVI r1,40
MOVI r2,13
LD r3,r0,@pci_n
MOVI r4,#C_GRN
CALL @tx_d
ST r0,r0,@ud_i
ud_pl:
LD r6,r0,@ud_i
LD r7,r0,@pci_n
CMP r6,r7
JMP[GE] @ud_done
LD r8,r0,@ud_rows
MOVI r9,14
ADD r9,r9,r6
CMP r9,r8
JMP[GE] @ud_done
ST r9,r0,@ud_r
SHL r6,r6,2
MOVI r7,0x300
MOVHI r7,5
ADD r6,r6,r7
ST r6,r0,@ud_e
LD r3,r6,0
SHR r3,r3,8
MOVI r1,0
LD r2,r0,@ud_r
MOVI r4,2
MOVI r5,#C_DIM
CALL @tx_h
LD r6,r0,@ud_e
LD r3,r6,0
SHR r3,r3,3
MOVI r5,31
BOOL.8 r3,r3,r5
MOVI r1,24
LD r2,r0,@ud_r
MOVI r4,2
MOVI r5,#C_DIM
CALL @tx_h
LD r6,r0,@ud_e
LD r3,r6,0
MOVI r5,7
BOOL.8 r3,r3,r5
MOVI r1,48
LD r2,r0,@ud_r
MOVI r4,1
MOVI r5,#C_DIM
CALL @tx_h
LD r6,r0,@ud_e
LD r3,r6,1
SHR r3,r3,16
MOVI r1,72
LD r2,r0,@ud_r
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
LD r6,r0,@ud_e
LD r3,r6,1
MOVI r5,0xFFFF
BOOL.8 r3,r3,r5
MOVI r1,112
LD r2,r0,@ud_r
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
LD r6,r0,@ud_e
LD r3,r6,2
SHR r3,r3,24
MOVI r1,160
LD r2,r0,@ud_r
MOVI r4,2
MOVI r5,#C_YEL
CALL @tx_h
LD r6,r0,@ud_e
LD r3,r6,2
SHR r3,r3,16
MOVI r5,255
BOOL.8 r3,r3,r5
MOVI r1,184
LD r2,r0,@ud_r
MOVI r4,2
MOVI r5,#C_YEL
CALL @tx_h
LD r1,r0,@ud_i
ADD r1,r1,r13
ST r1,r0,@ud_i
JMP @ud_pl
ud_done:
SUB r14,r14,r13
LD r15,r14,0
RET
ud_id:
.word 0
ud_rows:
.word 0
ud_i:
.word 0
ud_e:
.word 0
ud_r:
.word 0
ut_cv:
.word 0,0,0,0
ut_br:
.word 0,0,0,0,0,0,0,0,0,0,0,0,0
ut_sig:
.word 0
ut_ecx:
.word 0
ut_edx:
.word 0
ut_fam:
.word 0
ut_mod:
.word 0
ut_stp:
.word 0
ut_t0:
.word 0
ut_c0:
.word 0
ut_dl:
.word 0
ut_mhz:
.word 0
ut_hi:
.word 0
ut_lo:
.word 0
ut_be:
.word 0
ut_tw:
.word 0,0
t_util:
.str "SYSTEM"
ut_an:
.word @s_ua0,@s_ua1,@s_ua2,@s_ua3
s_u0:
.str "SYSTEM UTILITIES"
s_ucpu:
.str "CPU"
s_unm:
.str "NAME"
s_usig:
.str "SIG"
s_ufam:
.str "FAM"
s_umod:
.str "MOD"
s_ustp:
.str "STP"
s_uedx:
.str "EDX"
s_uecx:
.str "ECX"
s_utsc:
.str "TSC"
s_ube:
.str "BE"
s_umhz:
.str "MHZ"
s_ua0:
.str "ATA 0 M"
s_ua1:
.str "ATA 0 S"
s_ua2:
.str "ATA 1 M"
s_ua3:
.str "ATA 1 S"
s_unone:
.str "NONE"
s_umb:
.str "MB"
s_upci:
.str "PCI"
s_uarch:
.str "ARCH"
s_ux86:
.str "X86"
s_ulm:
.str "+LM"
s_umem:
.str "MEM"
s_uwd:
.str "WORDS"
s_uvr:
.str "VRAM"
s_ukb:
.str "KB"
s_uxx:
.str "x"
; ====================== SIERPINSKI (exact rule 90, cyclic edges, VRAM row cache) ======================
; State is global (one lattice window at a time). Cells are class-6 (XOR) NaN16 words, payload 1 = fire. Row n+1 = BOOL.6(left,right) with wrap-around edges.
; Both end cells of every new row are read back with LDN; a class other than 6 (a bad head) reseeds the lattice. Rows live in offscreen VRAM (ring of LSRD rows, stride fb_w) and are blitted with FBCOPY.
; Time flows UP (HTML reference): the stage starts blank (#311610), generation 1 enters at the bottom and every step scrolls the body up one pixel row; the seed row itself is never drawn.
.equ LSLIM 2000000
.equ LSRD 768
; lat_sync r1=id : load body geometry, reseed when the cell width changed
lat_sync:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ls_id
CALL @wm_wbase
ST r1,r0,@ls_wb
LD r2,r1,#W_W
MOVI r3,4
SUB r2,r2,r3
ST r2,r0,@ls_bw
LD r3,r1,#W_H
MOVI r4,20
SUB r3,r3,r4
ST r3,r0,@ls_bh
LD r6,r1,#W_X
ADD r6,r6,r13
ADD r6,r6,r13
LD r7,r1,#W_Y
MOVI r8,18
ADD r7,r7,r8
LD r9,r0,@fb_w
MUL r7,r7,r9
ADD r7,r7,r6
ST r7,r0,@ls_a
LD r4,r0,@ls_w
CMP r4,r2
JMP[EQ] @lsy_ok
ADD r1,r2,r0
CALL @lat_reset
lsy_ok:
SUB r14,r14,r13
LD r15,r14,0
RET
; lat_reset r1=cells : clear both row arrays, seed the centre cell, paint row 0, n=1
lat_reset:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ls_w
ST r0,r0,@ls_n
LD r2,r0,@fb_w
LD r3,r0,@fb_h
MUL r2,r2,r3
ST r2,r0,@ls_oc
LA r4,#LSLIM
MOVI r5,0
CMP r2,r4
JMP[GE] @lrs_rd
SUB r5,r4,r2
LD r6,r0,@fb_w
DIVU r5,r5,r6
MOVI r6,#LSRD
CMP r5,r6
JMP[LE] @lrs_rd
ADD r5,r6,r0
lrs_rd:
ST r5,r0,@ls_rd
MOVI r2,0
MOVHI r2,16
ST r2,r0,@ls_pa
MOVI r3,4096
ADD r3,r2,r3
ST r3,r0,@ls_pb
MOVI r6,6
MOVI r4,0
lrs_c:
CMP r4,r1
JMP[GE] @lrs_cd
ADD r5,r2,r4
STW r0,r5,r6
ADD r5,r3,r4
STW r0,r5,r6
ADD r4,r4,r13
JMP @lrs_c
lrs_cd:
SHR r4,r1,1
ADD r5,r2,r4
STW r13,r5,r6
SUB r14,r14,r13
LD r15,r14,0
RET
; lat_paint : paint the cell row ls_pa into cache row (ls_n mod ls_rd) as idle fill + fire runs (leaf)
lat_paint:
LD r2,r0,@ls_rd
CMP r2,r0
RET[EQ]
LD r1,r0,@ls_n
MODU r1,r1,r2
LD r3,r0,@fb_w
MUL r1,r1,r3
LD r4,r0,@ls_oc
ADD r1,r1,r4
LD r5,r0,@ls_w
MOVI r6,17
FBFILL r5,r1,r6
LD r7,r0,@ls_pa
MOVI r8,0
MOVI r6,16
lp_x:
CMP r8,r5
RET[GE]
ADD r9,r7,r8
LD r10,r9,0
CMP r10,r0
JMP[NE] @lp_run
ADD r8,r8,r13
JMP @lp_x
lp_run:
ADD r11,r8,r0
lp_e:
ADD r8,r8,r13
CMP r8,r5
JMP[GE] @lp_f
ADD r9,r7,r8
LD r10,r9,0
CMP r10,r0
JMP[NE] @lp_e
lp_f:
SUB r12,r8,r11
ADD r2,r1,r11
FBFILL r12,r2,r6
JMP @lp_x
; lat_step : next = rule 90 of cur (cyclic), swap, verify class, paint, n+1
lat_step:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@ls_pa
LD r2,r0,@ls_pb
LD r3,r0,@ls_w
MOVI r12,6
MOVI r4,0
lst_x:
CMP r4,r3
JMP[GE] @lst_d
SUB r5,r4,r13
CMP r4,r0
SUB[EQ] r5,r3,r13
ADD r6,r4,r13
CMP r6,r3
MOVI[EQ] r6,0
ADD r5,r1,r5
LD r7,r5,0
ADD r6,r1,r6
LD r9,r6,0
BOOL.6 r7,r7,r9
ADD r8,r2,r4
STW r7,r8,r12
ADD r4,r4,r13
JMP @lst_x
lst_d:
ST r2,r0,@ls_pa
ST r1,r0,@ls_pb
MOVI r6,6
LDN r5,r2,0
CMP r5,r6
JMP[NE] @lst_bad
LD r3,r0,@ls_w
ADD r3,r3,r2
SUB r3,r3,r13
LDN r5,r3,0
CMP r5,r6
JMP[NE] @lst_bad
CALL @lat_paint
LD r1,r0,@ls_n
ADD r1,r1,r13
ST r1,r0,@ls_n
JMP @lst_ret
lst_bad:
LD r1,r0,@ls_w
CALL @lat_reset
lst_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; lat_put r1=generated row, r2=screen row of the body : blit one cached row (leaf; idle fill when the row left the ring)
lat_put:
LD r3,r0,@ls_n
SUB r3,r3,r1
LD r4,r0,@ls_rd
CMP r3,r4
JMP[GT] @lpu_idle
CMP r4,r0
JMP[EQ] @lpu_idle
MODU r3,r1,r4
LD r4,r0,@fb_w
MUL r3,r3,r4
LD r5,r0,@ls_oc
ADD r3,r3,r5
MUL r6,r2,r4
LD r7,r0,@ls_a
ADD r6,r6,r7
LD r8,r0,@ls_bw
FBCOPY r8,r6,r3
RET
lpu_idle:
LD r4,r0,@fb_w
MUL r6,r2,r4
LD r7,r0,@ls_a
ADD r6,r6,r7
LD r8,r0,@ls_bw
MOVI r9,17
FBFILL r8,r6,r9
RET
lat_draw:
ST r15,r14,0
ADD r14,r14,r13
CALL @lat_sync
ST r0,r0,@ld_r
ld_loop:
LD r2,r0,@ld_r
LD r3,r0,@ls_bh
CMP r2,r3
JMP[GE] @ld_done
LD r4,r0,@ls_n
ADD r1,r2,r4
CMP r1,r3
JMP[LT] @ld_blank
SUB r1,r1,r3
CALL @lat_put
JMP @ld_next
ld_blank:
LD r5,r0,@fb_w
MUL r6,r2,r5
LD r7,r0,@ls_a
ADD r6,r6,r7
LD r8,r0,@ls_bw
MOVI r9,20
FBFILL r8,r6,r9
ld_next:
LD r2,r0,@ld_r
ADD r2,r2,r13
ST r2,r0,@ld_r
JMP @ld_loop
ld_done:
SUB r14,r14,r13
LD r15,r14,0
RET
ld_f:
.word 0
ld_r:
.word 0
; lat_tick r1=id : HTML pacing, 120 rows/s (speed 2 x 60 fps) from TICK ms, at most 16 rows per call, one lat_one per due row
lat_tick:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ls_id
TICK r2
LD r3,r0,@lp_last
ST r2,r0,@lp_last
CMP r3,r0
JMP[NE] @ltk_sub
ADD r3,r2,r0
ltk_sub:
SUB r4,r2,r3
MOVI r5,250
CMP r4,r5
JMP[LE] @ltk_dt
ADD r4,r5,r0
ltk_dt:
MOVI r5,120
MUL r4,r4,r5
LD r6,r0,@lp_acc
ADD r4,r4,r6
MOVI r5,1000
DIVU r6,r4,r5
MODU r4,r4,r5
ST r4,r0,@lp_acc
MOVI r5,16
CMP r6,r5
JMP[LE] @ltk_cap
ADD r6,r5,r0
ltk_cap:
ST r6,r0,@lp_cnt
ltk_loop:
LD r6,r0,@lp_cnt
CMP r6,r0
JMP[EQ] @ltk_end
SUB r6,r6,r13
ST r6,r0,@lp_cnt
CALL @lat_one
JMP @ltk_loop
ltk_end:
SUB r14,r14,r13
LD r15,r14,0
RET
lp_last:
.word 0
lp_acc:
.word 0
lp_cnt:
.word 0
; lat_one : advance one row (always, so history stays exact); touch the screen only when the window is not covered; rows enter at the bottom and everything scrolls up one pixel row per row (HTML copyWithin)
lat_one:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@ls_id
CALL @lat_sync
LD r1,r0,@ls_n
ST r1,r0,@lt_n0
CALL @lat_step
LD r1,r0,@ls_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @lt_done
lt_scroll:
LD r10,r0,@ls_a
LD r9,r0,@fb_w
LD r12,r0,@ls_bw
MOVI r11,1
lt_sl:
LD r2,r0,@ls_bh
CMP r11,r2
JMP[GE] @lt_sd
MUL r8,r11,r9
ADD r8,r10,r8
SUB r7,r11,r13
MUL r7,r7,r9
ADD r7,r10,r7
FBCOPY r12,r7,r8
ADD r11,r11,r13
JMP @lt_sl
lt_sd:
LD r1,r0,@lt_n0
LD r2,r0,@ls_bh
SUB r2,r2,r13
CALL @lat_put
lt_done:
SUB r14,r14,r13
LD r15,r14,0
RET
lt_n0:
.word 0
ls_id:
.word 0
ls_wb:
.word 0
ls_w:
.word 0
ls_n:
.word 0
ls_rd:
.word 0
ls_oc:
.word 0
ls_pa:
.word 0
ls_pb:
.word 0
ls_bw:
.word 0
ls_bh:
.word 0
ls_a:
.word 0
; ====================== MONITOR (double-endian timer) ======================
; Forward face T, reverse face FFFFFFFF-T; lamps show the low 16 bits of each.
mon_tick:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@mt_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @mt_done
LD r1,r0,@mt_id
CALL @mon_draw
mt_done:
SUB r14,r14,r13
LD r15,r14,0
RET
mt_id:
.word 0
mon_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@md_id
CALL @g_clr
LD r1,r0,@md_id
CALL @wm_wbase
ST r1,r0,@md_wb
LD r5,r1,#W_X
MOVI r6,8
ADD r5,r5,r6
ST r5,r0,@md_x
LD r5,r1,#W_Y
MOVI r6,22
ADD r5,r5,r6
ST r5,r0,@md_y
TICK r3
ST r3,r0,@md_t
LD r1,r0,@md_x
LD r2,r0,@md_y
MOVI r3,@s_fwd
MOVI r4,#C_TXT
CALL @fb_text7
LD r1,r0,@md_x
MOVI r5,32
ADD r1,r1,r5
LD r2,r0,@md_y
LD r3,r0,@md_t
MOVI r4,8
MOVI r5,#C_TXT
CALL @wm_puthex
LD r1,r0,@md_x
LD r2,r0,@md_y
MOVI r5,13
ADD r2,r2,r5
MOVI r3,@s_rev
MOVI r4,#C_TXT
CALL @fb_text7
LD r3,r0,@md_t
MOVI r4,0
SUB r3,r4,r3
SUB r3,r3,r13
LD r1,r0,@md_x
MOVI r5,32
ADD r1,r1,r5
LD r2,r0,@md_y
MOVI r5,13
ADD r2,r2,r5
MOVI r4,8
MOVI r5,#C_YEL
CALL @wm_puthex
LD r1,r0,@md_x
LD r2,r0,@md_y
MOVI r5,26
ADD r2,r2,r5
MOVI r3,@s_win
MOVI r4,#C_TXT
CALL @fb_text7
LD r3,r0,@wm_zn
LD r1,r0,@md_x
MOVI r5,32
ADD r1,r1,r5
LD r2,r0,@md_y
MOVI r5,26
ADD r2,r2,r5
MOVI r4,1
MOVI r5,#C_TXT
CALL @wm_puthex
LD r3,r0,@md_t
MOVI r4,32
LD r5,r0,@md_y
MOVI r6,43
ADD r5,r5,r6
CALL @mon_lamps
LD r3,r0,@md_t
MOVI r4,0
SUB r3,r4,r3
SUB r3,r3,r13
LD r5,r0,@md_y
MOVI r6,55
ADD r5,r5,r6
CALL @mon_lamps
SUB r14,r14,r13
LD r15,r14,0
RET
md_id:
.word 0
md_wb:
.word 0
md_x:
.word 0
md_y:
.word 0
md_t:
.word 0
s_fwd:
.str "FWD"
s_rev:
.str "REV"
s_win:
.str "WIN"
; mon_lamps: r3=value r5=y ; 16 lamps, bit 15 at the left, on=10 off=8
mon_lamps:
ST r15,r14,0
ADD r14,r14,r13
ST r3,r0,@ml_v
ST r5,r0,@ml_y
MOVI r10,0
ml_loop:
MOVI r2,16
CMP r10,r2
JMP[GE] @ml_done
LD r3,r0,@ml_v
BOOL.8 r4,r3,r13
SHR r3,r3,1
ST r3,r0,@ml_v
MOVI r5,#C_BLUR
CMP r4,r0
JMP[EQ] @ml_c
MOVI r5,10
ml_c:
ST r5,r0,@ml_col
MOVI r1,15
SUB r1,r1,r10
MOVI r6,14
MUL r1,r1,r6
LD r6,r0,@md_x
ADD r1,r1,r6
LD r2,r0,@ml_y
MOVI r3,11
MOVI r4,9
LD r5,r0,@ml_col
CALL @wm_rect
ADD r10,r10,r13
JMP @ml_loop
ml_done:
SUB r14,r14,r13
LD r15,r14,0
RET
ml_v:
.word 0
ml_y:
.word 0
ml_col:
.word 0
; ====================== HEX VIEWER ======================
; A0 = base word address. Two columns of AAAA PPPPPPPP (address, payload).
hex_init:
ST r15,r14,0
ADD r14,r14,r13
CALL @wm_wbase
MOVI r2,512
ST r2,r1,#W_A0
SUB r14,r14,r13
LD r15,r14,0
RET
hex_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@hd_id
CALL @g_clr
LD r1,r0,@hd_id
CALL @wm_wbase
ST r1,r0,@hd_wb
CALL @hex_geom
ST r0,r0,@hd_r
hd_row:
LD r2,r0,@hd_r
LD r3,r0,@hd_rows
CMP r2,r3
JMP[GE] @hd_done
ST r0,r0,@hd_c
hd_col:
LD r5,r0,@hd_c
LD r6,r0,@hd_cols
CMP r5,r6
JMP[GE] @hd_nextrow
LD r4,r0,@hd_wb
LD r2,r0,@hd_r
LD r6,r0,@hd_cols
MUL r2,r2,r6
ADD r2,r2,r5
LD r3,r4,#W_A0
ADD r2,r2,r3
MOVI r3,0x7FFF
BOOL.8 r2,r2,r3
ST r2,r0,@hd_a
LD r3,r2,0
ST r3,r0,@hd_p
MOVI r6,112
MUL r6,r5,r6
LD r1,r4,#W_X
MOVI r7,6
ADD r1,r1,r7
ADD r1,r1,r6
ST r1,r0,@hd_x
LD r2,r0,@hd_r
MOVI r7,13
MUL r2,r2,r7
LD r8,r4,#W_Y
MOVI r7,18
ADD r8,r8,r7
ADD r2,r2,r8
ST r2,r0,@hd_y
LD r3,r0,@hd_a
MOVI r4,4
MOVI r5,11
CALL @wm_puthex
LD r1,r0,@hd_x
MOVI r7,40
ADD r1,r1,r7
LD r2,r0,@hd_y
LD r3,r0,@hd_p
MOVI r4,8
MOVI r5,#C_TXT
CALL @wm_puthex
LD r5,r0,@hd_c
ADD r5,r5,r13
ST r5,r0,@hd_c
JMP @hd_col
hd_nextrow:
LD r2,r0,@hd_r
ADD r2,r2,r13
ST r2,r0,@hd_r
JMP @hd_row
hd_done:
SUB r14,r14,r13
LD r15,r14,0
RET
; hex_geom: r1=window record -> hd_cols = (W-4)/112 (1..8), hd_rows = (H-20)/13. Clobbers r2,r3 only.
hex_geom:
LD r2,r1,#W_W
MOVI r3,4
SUB r2,r2,r3
MOVI r3,112
DIVU r2,r2,r3
CMP r2,r0
JMP[NE] @hg_a
MOVI r2,1
hg_a:
MOVI r3,8
CMP r2,r3
JMP[LE] @hg_b
ADD r2,r3,r0
hg_b:
ST r2,r0,@hd_cols
LD r2,r1,#W_H
MOVI r3,20
SUB r2,r2,r3
MOVI r3,13
DIVU r2,r2,r3
ST r2,r0,@hd_rows
RET
hd_cols:
.word 0
hd_id:
.word 0
hd_wb:
.word 0
hd_rows:
.word 0
hd_r:
.word 0
hd_c:
.word 0
hd_a:
.word 0
hd_p:
.word 0
hd_x:
.word 0
hd_y:
.word 0
; hex_key: r1=id r3=key. Up/Down one row, Left/Right/PgUp/PgDn a page.
hex_key:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@hk_id
ST r3,r0,@hk_k
CALL @wm_wbase
CALL @hex_geom
LD r2,r0,@hd_cols
LD r5,r0,@hd_rows
MUL r5,r5,r2
LD r4,r1,#W_A0
LD r3,r0,@hk_k
MOVI r6,0x110
CMP r3,r6
JMP[EQ] @hk_up
MOVI r6,0x111
CMP r3,r6
JMP[EQ] @hk_dn
MOVI r6,0x112
CMP r3,r6
JMP[EQ] @hk_pu
MOVI r6,0x116
CMP r3,r6
JMP[EQ] @hk_pu
MOVI r6,0x113
CMP r3,r6
JMP[EQ] @hk_pd
MOVI r6,0x117
CMP r3,r6
JMP[EQ] @hk_pd
JMP @hk_ret
hk_up:
SUB r4,r4,r2
JMP @hk_set
hk_dn:
ADD r4,r4,r2
JMP @hk_set
hk_pu:
SUB r4,r4,r5
JMP @hk_set
hk_pd:
ADD r4,r4,r5
hk_set:
MOVI r6,0x7FFF
BOOL.8 r4,r4,r6
ST r4,r1,#W_A0
LD r1,r0,@hk_id
CALL @hex_draw
hk_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
hk_id:
.word 0
hk_k:
.word 0
