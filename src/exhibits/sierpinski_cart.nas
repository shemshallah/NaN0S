; EXHIBIT CARTRIDGE: Sierpinski / rule 90, real VGA pixels. Palette matches the HTML
; reference in Download (NaN Lattice): bright #42F08B (16) on dark green #10311C (17),
; same rule-90 pattern with cyclic edges and the same "time flows up" history.
; Badge: RE-CREATION. Runtime code and glyphs are NaN16 only.
; Top 320x128 pixels: live rule-90 lattice, one pixel per cell.
; Bottom 72 pixels: a scrollable museum label drawn with the homebrew 3x5 font.
; The lattice keeps evolving while the label scrolls. [1] is not used here.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_KEYQ 6
.equ V_TICK 7
.equ V_SCROLL 12
.equ SBUF 200000
.equ NBUF 210000
.equ PANELH 72
.equ PANELROWS 6
.equ NLINES 35
.equ FRAME 33
.org 8192
JMP @cart_entry
.include "../lib/fb.nas"
cart_entry:
ST r15,r0,@s_ret
MOVI r13,1
CALL @fb_init
; HTML palette: dark-green field (17), bright cells (16). Panel repaints black.
MOVI r1,17
CALL @fb_clear
; ---- geometry from the CURRENT framebuffer: stage = full width, up to the panel ----
LD r1,r0,@fb_w
ST r1,r0,@s_w
LD r2,r0,@fb_h
MOVI r3,#PANELH
SUB r2,r2,r3
ST r2,r0,@s_stage
SUB r1,r2,r13
LD r3,r0,@s_w
MUL r1,r1,r3
ST r1,r0,@s_last
; ---- seed the lattice: all zero, one cell in the centre ----
MOVI r1,0
LD r3,r0,@s_w
sseed:
LA r6,#SBUF
ADD r6,r6,r1
MOVI r5,2
MOVI r4,6
STW r5,r6,r4
LA r6,#NBUF
ADD r6,r6,r1
STW r5,r6,r4
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sseed
LD r2,r0,@s_w
SHR r2,r2,1
LA r6,#SBUF
ADD r6,r6,r2
MOVI r5,3
MOVI r4,6
STW r5,r6,r4
CALL @s_draw_panel
CALL @s_drawrow
TICK r3
ST r3,r0,@s_last
s_loop:
CALL @s_frame
s_poll:
KEYQ r1
MOVI r4,255
BOOL.8 r1,r1,r4
CMP r1,r0
JMP[EQ] @s_tick
MOVI r4,27
CMP r1,r4
JMP[EQ] @s_exit
MOVI r4,0x80
CMP r1,r4
JMP[EQ] @s_up
MOVI r4,0x81
CMP r1,r4
JMP[EQ] @s_down
MOVI r4,0x82
CMP r1,r4
JMP[EQ] @s_pgup
MOVI r4,0x83
CMP r1,r4
JMP[EQ] @s_pgdn
JMP @s_tick
s_up:
LD r2,r0,@s_scroll
CMP r2,r0
JMP[EQ] @s_tick
SUB r2,r2,r13
ST r2,r0,@s_scroll
CALL @s_draw_panel
JMP @s_tick
s_down:
LD r2,r0,@s_scroll
MOVI r3,#NLINES
MOVI r4,#PANELROWS
SUB r3,r3,r4
CMP r2,r3
JMP[GE] @s_tick
ADD r2,r2,r13
ST r2,r0,@s_scroll
CALL @s_draw_panel
JMP @s_tick
s_pgup:
LD r2,r0,@s_scroll
MOVI r3,7
CMP r2,r3
JMP[LT] @s_pgup0
SUB r2,r2,r3
JMP @s_pgup_store
s_pgup0:
MOVI r2,0
s_pgup_store:
ST r2,r0,@s_scroll
CALL @s_draw_panel
JMP @s_tick
s_pgdn:
LD r2,r0,@s_scroll
MOVI r3,#NLINES
MOVI r4,#PANELROWS
SUB r3,r3,r4
MOVI r4,7
ADD r2,r2,r4
CMP r2,r3
JMP[LE] @s_pgdn_store
ADD r2,r3,r0
s_pgdn_store:
ST r2,r0,@s_scroll
CALL @s_draw_panel
JMP @s_tick
s_tick:
TICK r3
LD r4,r0,@s_last
SUB r5,r3,r4
MOVI r6,#FRAME
CMP r5,r6
JMP[LT] @s_poll
ST r3,r0,@s_last
JMP @s_loop
s_exit:
CALL @fb_exit
LD r15,r0,@s_ret
RET
s_ret:
.word 0
s_last:
.word 0
s_scroll:
.word 0
s_i:
.word 0
s_w:
.word 320
s_stage:
.word 128
s_last:
.word 40640
; ---- one generation: XOR left/right, copy, hardware-blit scroll, draw ----
s_frame:
ST r15,r0,@sf_ret
LD r3,r0,@s_w
MOVI r1,0
sf_x:
ADD r5,r1,r0
CMP r5,r0
JMP[NE] @sf_left
LD r5,r0,@s_w
SUB r5,r5,r13
JMP @sf_left_ok
sf_left:
SUB r5,r5,r13
sf_left_ok:
LA r6,#SBUF
ADD r5,r5,r6
LD r7,r5,0
BOOL.8 r7,r7,r13
ADD r5,r1,r0
ADD r5,r5,r13
CMP r5,r3
JMP[LT] @sf_right_ok
MOVI r5,0
sf_right_ok:
LA r6,#SBUF
ADD r5,r5,r6
LD r8,r5,0
BOOL.8 r8,r8,r13
BOOL.6 r9,r7,r8
LA r6,#NBUF
ADD r6,r6,r1
MOVI r5,2
BOOL.14 r5,r5,r9
MOVI r4,6
STW r5,r6,r4
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sf_x
MOVI r1,0
sf_copy:
LA r6,#NBUF
ADD r6,r6,r1
LD r7,r6,0
LA r6,#SBUF
ADD r6,r6,r1
MOVI r4,6
STW r7,r6,r4
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sf_copy
; scroll only the stage: copy stageH-1 rows up (src=width), fill the new last row dark green
LD r1,r0,@s_last
MOVI r2,0
LD r3,r0,@s_w
FBCOPY r1,r2,r3
LD r1,r0,@s_w
LD r2,r0,@s_last
MOVI r3,17
FBFILL r1,r2,r3
CALL @s_drawrow
LD r15,r0,@sf_ret
RET
sf_ret:
.word 0
; ---- draw state at the stage bottom row: only set bright pixels (HTML 16), field is 17 ----
s_drawrow:
LD r3,r0,@s_w
LD r4,r0,@s_last
MOVI r1,0
sdr:
LA r6,#SBUF
ADD r6,r6,r1
LD r7,r6,0
BOOL.8 r7,r7,r13
CMP r7,r0
JMP[EQ] @sdr_next
ADD r6,r4,r1
MOVI r5,16
VPOKE r5,r6
sdr_next:
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sdr
RET
; ---- panel: 6 lines, 3x5 font at 2x, 6x10 cell, x=4 y=stageH+i*11 ----
s_draw_panel:
ST r15,r0,@sdp_ret
LD r1,r0,@s_w
MOVI r3,#PANELH
MUL r1,r1,r3
LD r2,r0,@s_stage
LD r3,r0,@s_w
MUL r2,r2,r3
MOVI r3,0
FBFILL r1,r2,r3
MOVI r1,0
ST r1,r0,@s_i
sdp_loop:
LD r1,r0,@s_i
MOVI r2,#PANELROWS
CMP r1,r2
JMP[GE] @sdp_done
LD r2,r0,@s_scroll
ADD r2,r2,r1
MOVI r3,#NLINES
CMP r2,r3
JMP[GE] @sdp_done
LD r1,r0,@s_i
LD r2,r0,@s_stage
MOVI r6,11
MUL r6,r1,r6
ADD r2,r2,r6
MOVI r1,4
MOVI r4,15
LD r5,r0,@s_scroll
LD r6,r0,@s_i
ADD r5,r5,r6
MOVI r6,@s_lines
ADD r6,r6,r5
LD r3,r6,0
CALL @fb_text5
LD r1,r0,@s_i
ADD r1,r1,r13
ST r1,r0,@s_i
JMP @sdp_loop
sdp_done:
LD r15,r0,@sdp_ret
RET
sdp_ret:
.word 0
; ---- panel text: one .str per line, uppercase, 52 columns max ----
SP000:
.str "NaN/0S  SIERPINSKI - RULE 90 - NAN16 LATTICE"
SP001:
.str "WACLAW SIERPINSKI DESCRIBED THIS"
SP002:
.str "FRACTAL IN 1915. IT APPEARS IN"
SP003:
.str "PASCAL'S TRIANGLE MODULO 2."
SP004:
.str "RULE 90: EACH CELL IS THE XOR"
SP005:
.str "OF ITS TWO NEIGHBOURS ABOVE."
SP006:
.str "FRACTAL DIMENSION ~ 1.585"
SP007:
.str "PASCAL MOD 2: 0 XOR 1 = 1"
SP008:
.str "ROW N OF PASCAL'S TRIANGLE HAS"
SP009:
.str "2^POPCOUNT(N) ODD ENTRIES. THE"
SP010:
.str "ODD ENTRIES ARE THIS TRIANGLE."
SP011:
.str "THE ARROWHEAD CURVE IS A"
SP012:
.str "SINGLE CLOSED FRACTAL."
SP013:
.str "RULE 90 IS WOLFRAM'S ELEMENTARY"
SP014:
.str "CELLULAR AUTOMATON NUMBER 90."
SP015:
.str "PEOPLE:"
SP016:
.str "WACLAW SIERPINSKI 1882-1969 DEAD"
SP017:
.str "STEPHEN WOLFRAM 1959- LIVING"
SP018:
.str "JOHN VON NEUMANN 1903-1957 DEAD"
SP019:
.str "JOHN CONWAY 1937-2020 DEAD"
SP020:
.str "BENOIT MANDELBROT 1924-2010 DEAD"
SP021:
.str "NAN/0S DEV NOTE:"
SP022:
.str "I LOVE TRIANGLES!"
SP023:
.str "EACH CELL IS A REAL NAN16 WORD:"
SP024:
.str "CLASS NIBBLE 6 IS XOR, PAYLOAD"
SP025:
.str "BIT 0 IS THE STATE. BIT 1 IS THE GUARD,"
SP026:
.str "SO FALSE STAYS A NaN. TIME FLOWS UP."
SP027:
.str "BSWAPM SENDS 6 TO 9 (XNOR)."
SP028:
.str "UP/DOWN SCROLL. LEFT/RIGHT PAGE."
SP029:
.str "ESC RETURNS TO THE MUSEUM."
SP030:
.str "SOURCES: SIERPINSKI 1915,"
SP031:
.str "WOLFRAM, A NEW KIND OF SCIENCE,"
SP032:
.str "2002, PASCAL'S TRIANGLE MOD 2."
SP033:
.str ""
SP034:
.str "THE FRACTAL IS 320X128 PIXELS"
SP035:
.str "HTML COLORS #42F08B ON #10311C"
; ---- pointer table ----
s_lines:
.word @SP000
.word @SP001
.word @SP002
.word @SP003
.word @SP004
.word @SP005
.word @SP006
.word @SP007
.word @SP008
.word @SP009
.word @SP010
.word @SP011
.word @SP012
.word @SP013
.word @SP014
.word @SP015
.word @SP016
.word @SP017
.word @SP018
.word @SP019
.word @SP020
.word @SP021
.word @SP022
.word @SP023
.word @SP024
.word @SP025
.word @SP026
.word @SP027
.word @SP028
.word @SP029
.word @SP030
.word @SP031
.word @SP032
.word @SP033
.word @SP034
.word @SP035
