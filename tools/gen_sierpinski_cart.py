#!/usr/bin/env python3
# SCAFFOLD: emit src/exhibits/sierpinski_cart.nas. Runtime code is NaN16 only.
import os

LINES = [
"SIERPINSKI TRIANGLE",
"Waclaw Sierpinski described this",
"fractal in 1915. It appears in",
"Pascal's triangle modulo 2.",
"Rule 90: each cell is the XOR",
"of its two neighbours above.",
"",
"NERDY FACTS",
"Fractal dimension = log2(3)",
"= 1.584962500721156...",
"Row n of Pascal's triangle has",
"2^popcount(n) odd entries. The",
"odd entries are exactly this",
"triangle. The arrowhead curve",
"is a single closed fractal.",
"Rule 90 is Wolfram's elementary",
"cellular automaton number 90.",
"",
"PEOPLE",
"Waclaw Sierpinski 1882-1969 DEAD",
"Stephen Wolfram 1959- LIVING",
"John von Neumann 1903-1957 DEAD",
"John Conway 1937-2020 DEAD",
"Benoit Mandelbrot 1924-2010 DEAD",
"",
"NaN/0S Dev note: I love triangles,",
"and this is my favorite exhibit.",
"",
"Each cell is a real NaN16 word:",
"class nibble 6 is XOR, payload",
"bit 0 is the state. The animation",
"is Boole's table doing geometry.",
"",
"[UP/DOWN] scroll details",
"[LEFT/RIGHT] page",
"[1] 80x25  [2] 40x25",
"[ESC] back to the museum",
"",
"Sources: Sierpinski 1915,",
"Wolfram, A New Kind of Science,",
"2002, Pascal's triangle mod 2.",
]

CODE = r'''; EXHIBIT CARTRIDGE: Sierpinski triangle / elementary cellular automaton rule 90.
; Badge: RE-CREATION. Runtime code and data are NaN16 only.
; Loaded at SLOT by the museum shell. The top of the screen is a live rule-90
; lattice. The bottom panel is a scrollable museum label. The animation keeps
; running while the label scrolls: UP/DOWN move one line, LEFT/RIGHT move eight.
; [1] switches to 80x25, [2] to 40x25, so the lattice width, height and panel
; geometry all scale from DISPQ. [ESC] restores 80x25 and returns to the shell.
; A cell is a real NaN16 word: class nibble 6 (XOR) is its truth table and
; payload bit 0 is the state. The next row is XOR(left neighbour, right neighbour).
.equ SLOT 8192
.equ V_PUTS 1
.equ V_HEX 2
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_KEYQ 6
.equ V_TICK 7
.equ V_SCROLL 12
.equ SBUF 4096
.equ NBUF 4224
.equ NLINES 41
.equ FRAME 40
.org 8192
cart_entry:
ST r15,r0,@s_ret
MOVI r13,1
MOVI r3,3
DISPSET r3
CALL @s_setup
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
MOVI r4,49
CMP r1,r4
JMP[EQ] @s_mode80
MOVI r4,50
CMP r1,r4
JMP[EQ] @s_mode40
JMP @s_tick
s_up:
LD r2,r0,@s_panel_scroll
CMP r2,r0
JMP[EQ] @s_tick
SUB r2,r2,r13
ST r2,r0,@s_panel_scroll
CALL @s_draw_panel
JMP @s_tick
s_down:
LD r2,r0,@s_panel_scroll
MOVI r3,#NLINES
LD r4,r0,@s_panel_lines
SUB r3,r3,r4
CMP r3,r0
JMP[GE] @s_down_ok
MOVI r3,0
s_down_ok:
CMP r2,r3
JMP[GE] @s_tick
ADD r2,r2,r13
ST r2,r0,@s_panel_scroll
CALL @s_draw_panel
JMP @s_tick
s_pgup:
LD r2,r0,@s_panel_scroll
MOVI r3,8
CMP r2,r3
JMP[LT] @s_pgup0
SUB r2,r2,r3
JMP @s_pgup_store
s_pgup0:
MOVI r2,0
s_pgup_store:
ST r2,r0,@s_panel_scroll
CALL @s_draw_panel
JMP @s_tick
s_pgdn:
LD r2,r0,@s_panel_scroll
MOVI r3,#NLINES
LD r4,r0,@s_panel_lines
SUB r3,r3,r4
CMP r3,r0
JMP[GE] @s_pgdn_ok
MOVI r3,0
s_pgdn_ok:
MOVI r4,8
ADD r2,r2,r4
CMP r2,r3
JMP[LE] @s_pgdn_store
ADD r2,r3,r0
s_pgdn_store:
ST r2,r0,@s_panel_scroll
CALL @s_draw_panel
JMP @s_tick
s_mode80:
MOVI r3,3
DISPSET r3
CALL @s_setup
JMP @s_tick
s_mode40:
MOVI r3,1
DISPSET r3
CALL @s_setup
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
MOVI r3,3
DISPSET r3
CALL #V_CLS
LD r15,r0,@s_ret
RET
s_ret:
.word 0
s_last:
.word 0
s_cols:
.word 80
s_rows:
.word 25
s_anim_h:
.word 15
s_panel_top:
.word 16
s_panel_lines:
.word 8
s_panel_scroll:
.word 0
sattr:
.word 0
scols:
.word 80
; ---- layout from DISPQ: H = rows - 10, panel header at H+1, 8 text rows ----
s_layout:
ST r15,r0,@sl_ret
DISPQ r8
MOVI r9,255
BOOL.8 r3,r8,r9
ST r3,r0,@s_cols
SHR r8,r8,8
BOOL.8 r4,r8,r9
ST r4,r0,@s_rows
MOVI r5,10
SUB r5,r4,r5
MOVI r6,4
CMP r5,r6
JMP[GE] @sl_h_ok
ADD r5,r6,r0
sl_h_ok:
ST r5,r0,@s_anim_h
ADD r6,r5,r13
ST r6,r0,@s_panel_top
SUB r7,r4,r6
SUB r7,r7,r13
CMP r7,r0
JMP[GE] @sl_pl_ok
MOVI r7,0
sl_pl_ok:
ST r7,r0,@s_panel_lines
MOVI r8,#NLINES
SUB r8,r8,r7
CMP r8,r0
JMP[GE] @sl_max_ok
MOVI r8,0
sl_max_ok:
LD r9,r0,@s_panel_scroll
CMP r9,r8
JMP[LE] @sl_scroll_ok
ST r8,r0,@s_panel_scroll
sl_scroll_ok:
LD r15,r0,@sl_ret
RET
sl_ret:
.word 0
; ---- setup: clear screen, seed one cell, title, panel, first row ----
s_setup:
ST r15,r0,@ss_ret
CALL @s_layout
MOVI r1,0
LD r3,r0,@s_cols
LD r4,r0,@s_rows
MUL r5,r3,r4
MOVI r6,0x0720
ss_clear:
CMP r1,r5
JMP[GE] @ss_seed
VPOKE r6,r1
ADD r1,r1,r13
JMP @ss_clear
ss_seed:
MOVI r1,0
LD r3,r0,@s_cols
ss_z:
MOVI r6,#SBUF
ADD r6,r6,r1
ST r0,r6,0
MOVI r6,#NBUF
ADD r6,r6,r1
ST r0,r6,0
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @ss_z
SHR r2,r3,1
MOVI r6,#SBUF
ADD r6,r6,r2
ST r13,r6,0
MOVI r1,@s_title
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
LD r8,r0,@s_cols
CALL @sputs
CALL @s_draw_panel
LD r3,r0,@s_cols
LD r4,r0,@s_anim_h
ADD r1,r3,r0
MUL r5,r4,r3
ADD r5,r5,r3
MOVI r6,0x0720
ss_ca:
CMP r1,r5
JMP[GE] @ss_first
VPOKE r6,r1
ADD r1,r1,r13
JMP @ss_ca
ss_first:
CALL @s_drawrow
TICK r3
ST r3,r0,@s_last
LD r15,r0,@ss_ret
RET
ss_ret:
.word 0
; ---- one frame: rule 90, shift the lattice up, draw the new bottom row ----
s_frame:
ST r15,r0,@sf_ret
LD r3,r0,@s_cols
MOVI r1,0
sf_x:
ADD r5,r1,r0
CMP r5,r0
JMP[NE] @sf_left_dec
ADD r5,r3,r0
SUB r5,r5,r13
JMP @sf_left_ready
sf_left_dec:
SUB r5,r5,r13
sf_left_ready:
MOVI r6,#SBUF
ADD r5,r5,r6
LD r7,r5,0
ADD r5,r1,r0
ADD r5,r5,r13
CMP r5,r3
JMP[LT] @sf_right_ready
MOVI r5,0
sf_right_ready:
MOVI r6,#SBUF
ADD r5,r5,r6
LD r8,r5,0
BOOL.6 r9,r7,r8
MOVI r6,#NBUF
ADD r6,r6,r1
ST r9,r6,0
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sf_x
MOVI r1,0
sf_copy:
MOVI r6,#NBUF
ADD r6,r6,r1
LD r7,r6,0
MOVI r6,#SBUF
ADD r6,r6,r1
ST r7,r6,0
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sf_copy
LD r4,r0,@s_anim_h
MOVI r5,1
sf_row:
CMP r5,r4
JMP[GE] @sf_fill
ADD r7,r5,r0
ADD r7,r7,r13
MUL r7,r7,r3
MUL r8,r5,r3
ADD r9,r3,r0
sf_col:
VPEEK r11,r7
VPOKE r11,r8
ADD r7,r7,r13
ADD r8,r8,r13
SUB r9,r9,r13
JMP[NE] @sf_col
ADD r5,r5,r13
JMP @sf_row
sf_fill:
LD r4,r0,@s_anim_h
MUL r7,r4,r3
MOVI r8,0
sf_fill_loop:
MOVI r9,0x08B0
ADD r6,r7,r8
VPOKE r9,r6
ADD r8,r8,r13
CMP r8,r3
JMP[LT] @sf_fill_loop
CALL @s_drawrow
LD r15,r0,@sf_ret
RET
sf_ret:
.word 0
; ---- draw state at the bottom animation row ----
s_drawrow:
LD r3,r0,@s_cols
LD r4,r0,@s_anim_h
MUL r5,r4,r3
MOVI r1,0
sdr_loop:
MOVI r6,#SBUF
ADD r6,r6,r1
LD r7,r6,0
MOVI r9,0x08B0
CMP r7,r0
MOVI[NE] r9,0x0ADB
ADD r6,r5,r1
VPOKE r9,r6
ADD r1,r1,r13
CMP r1,r3
JMP[LT] @sdr_loop
RET
; ---- panel: header + 8 scrollable lines ----
s_draw_panel:
ST r15,r0,@sdp_ret
LD r3,r0,@s_cols
LD r4,r0,@s_panel_top
MUL r1,r4,r3
LD r5,r0,@s_rows
MUL r5,r5,r3
MOVI r6,0x0720
sdp_clear:
CMP r1,r5
JMP[GE] @sdp_head
VPOKE r6,r1
ADD r1,r1,r13
JMP @sdp_clear
sdp_head:
MUL r2,r4,r3
MOVI r1,@s_pheader
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
LD r8,r0,@s_cols
CALL @sputs
MOVI r11,0
LD r12,r0,@s_panel_lines
sdp_line:
CMP r11,r12
JMP[GE] @sdp_done
LD r7,r0,@s_panel_scroll
ADD r7,r7,r11
MOVI r6,#NLINES
CMP r7,r6
JMP[GE] @sdp_done
MOVI r6,@s_lines
ADD r6,r6,r7
LD r1,r6,0
LD r6,r0,@s_panel_top
ADD r6,r6,r13
ADD r6,r6,r11
LD r3,r0,@s_cols
MUL r2,r6,r3
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
LD r8,r0,@s_cols
CALL @sputs
ADD r11,r11,r13
JMP @sdp_line
sdp_done:
LD r15,r0,@sdp_ret
RET
sdp_ret:
.word 0
; ---- local puts: dynamic 40/80 columns, same 4-chars-per-word format ----
sputs:
ST r3,r0,@sattr
ST r8,r0,@scols
spw:
LD r4,r1,0
MOVI r9,4
spc:
MOVI r8,255
BOOL.8 r7,r4,r8
CMP r7,r0
RET[EQ]
MOVI r8,10
CMP r7,r8
JMP[EQ] @spnl
LD r3,r0,@sattr
BOOL.14 r3,r7,r3
VPOKE r3,r2
ADD r2,r2,r13
ADD r5,r5,r13
JMP @spnx
spnl:
SUB r2,r2,r5
ADD r2,r2,r6
LD r8,r0,@scols
ADD r2,r2,r8
BOOL.12 r5,r6,r6
spnx:
SHR r4,r4,8
SUB r9,r9,r13
JMP[NE] @spc
ADD r1,r1,r13
JMP @spw
s_title:
.str "SIERPINSKI - RULE 90 - NAN16 LATTICE"
s_pheader:
.str "DETAILS  UP/DOWN line  LEFT/RIGHT page  ESC shell"
'''

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"')

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, 'src', 'exhibits', 'sierpinski_cart.nas')
    body = ['; ---- panel text: one .str per line ----']
    for i, line in enumerate(LINES):
        body.append('SP%03d:' % i)
        body.append('.str "%s"' % esc(line))
    body.append('; ---- pointer table ----')
    body.append('s_lines:')
    for i in range(len(LINES)):
        body.append('.word @SP%03d' % i)
    with open(out, 'w') as f:
        f.write(CODE + '\n'.join(body) + '\n')
    print('wrote %s: %d lines' % (out, len(LINES)))

if __name__ == '__main__':
    main()
