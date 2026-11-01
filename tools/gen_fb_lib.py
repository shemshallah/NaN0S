#!/usr/bin/env python3
# SCAFFOLD: emit src/lib/fb.nas, the NaN16 framebuffer driver + a scratch 3x5 font.
# Runtime code is NaN16 only. The font is homebrew: 3 columns x 5 rows per glyph,
# drawn at 2x scale (6x10 cell) by fb_char3. ASCII 32..95 is covered; lowercase
# is folded to uppercase by fb_text3. Unknown glyphs render as space.
import os

# Complete printable ASCII 5x7 font. Rows are top to bottom, 5 columns each.
FONT_ROWS = {
' ': "00000/00000/00000/00000/00000/00000/00000",
'!': "00100/00100/00100/00100/00100/00000/00100",
'"': "01010/01010/00000/00000/00000/00000/00000",
'#': "01010/01010/11111/01010/11111/01010/01010",
'$': "00100/01111/10100/01110/00101/11110/00100",
'%': "11001/11010/00010/00100/01000/01011/10011",
'&': "01100/10010/10100/01000/10101/10010/01101",
"'": "00100/00100/00000/00000/00000/00000/00000",
'(': "00010/00100/01000/01000/01000/00100/00010",
')': "01000/00100/00010/00010/00010/00100/01000",
'*': "00000/10101/01110/11111/01110/10101/00000",
'+': "00000/00100/00100/11111/00100/00100/00000",
',': "00000/00000/00000/00000/00110/00100/01000",
'-': "00000/00000/00000/11111/00000/00000/00000",
'.': "00000/00000/00000/00000/00000/00110/00110",
'/': "00001/00010/00010/00100/01000/01000/10000",
'0': "01110/10001/10011/10101/11001/10001/01110",
'1': "00100/01100/00100/00100/00100/00100/01110",
'2': "01110/10001/00001/00010/00100/01000/11111",
'3': "11110/00001/00001/01110/00001/00001/11110",
'4': "00010/00110/01010/10010/11111/00010/00010",
'5': "11111/10000/11110/00001/00001/10001/01110",
'6': "00110/01000/10000/11110/10001/10001/01110",
'7': "11111/00001/00010/00100/01000/01000/01000",
'8': "01110/10001/10001/01110/10001/10001/01110",
'9': "01110/10001/10001/01111/00001/00010/01100",
':': "00000/00110/00110/00000/00110/00110/00000",
';': "00000/00110/00110/00000/00110/00100/01000",
'<': "00010/00100/01000/10000/01000/00100/00010",
'=': "00000/00000/11111/00000/11111/00000/00000",
'>': "01000/00100/00010/00001/00010/00100/01000",
'?': "01110/10001/00001/00010/00100/00000/00100",
'@': "01110/10001/00001/01101/10101/10101/01110",
'A': "01110/10001/10001/11111/10001/10001/10001",
'B': "11110/10001/10001/11110/10001/10001/11110",
'C': "01110/10001/10000/10000/10000/10001/01110",
'D': "11110/10001/10001/10001/10001/10001/11110",
'E': "11111/10000/10000/11110/10000/10000/11111",
'F': "11111/10000/10000/11110/10000/10000/10000",
'G': "01110/10001/10000/10111/10001/10001/01110",
'H': "10001/10001/10001/11111/10001/10001/10001",
'I': "11111/00100/00100/00100/00100/00100/11111",
'J': "00111/00010/00010/00010/00010/10010/01100",
'K': "10001/10010/10100/11000/10100/10010/10001",
'L': "10000/10000/10000/10000/10000/10000/11111",
'M': "10001/11011/10101/10101/10001/10001/10001",
'N': "10001/11001/10101/10011/10001/10001/10001",
'O': "01110/10001/10001/10001/10001/10001/01110",
'P': "11110/10001/10001/11110/10000/10000/10000",
'Q': "01110/10001/10001/10001/10101/10010/01101",
'R': "11110/10001/10001/11110/10100/10010/10001",
'S': "01111/10000/10000/01110/00001/00001/11110",
'T': "11111/00100/00100/00100/00100/00100/00100",
'U': "10001/10001/10001/10001/10001/10001/01110",
'V': "10001/10001/10001/10001/10001/01010/00100",
'W': "10001/10001/10001/10101/10101/10101/01010",
'X': "10001/10001/01010/00100/01010/10001/10001",
'Y': "10001/10001/01010/00100/00100/00100/00100",
'Z': "11111/00001/00010/00100/01000/10000/11111",
'[': "01110/01000/01000/01000/01000/01000/01110",
'\\': "10000/01000/01000/00100/00010/00010/00001",
']': "01110/00010/00010/00010/00010/00010/01110",
'^': "00100/01010/10001/00000/00000/00000/00000",
'_': "00000/00000/00000/00000/00000/00000/11111",
'`': "01000/00100/00000/00000/00000/00000/00000",
'a': "00000/00000/01110/00001/01111/10001/01111",
'b': "10000/10000/11110/10001/10001/10001/11110",
'c': "00000/00000/01110/10000/10000/10001/01110",
'd': "00001/00001/01111/10001/10001/10001/01111",
'e': "00000/00000/01110/10001/11111/10000/01110",
'f': "00110/01001/01000/11100/01000/01000/01000",
'g': "00000/01111/10001/10001/01111/00001/01110",
'h': "10000/10000/11110/10001/10001/10001/10001",
'i': "00100/00000/01100/00100/00100/00100/01110",
'j': "00010/00000/00110/00010/00010/10010/01100",
'k': "10000/10000/10010/10100/11000/10100/10010",
'l': "01100/00100/00100/00100/00100/00100/01110",
'm': "00000/00000/11010/10101/10101/10101/10101",
'n': "00000/00000/11110/10001/10001/10001/10001",
'o': "00000/00000/01110/10001/10001/10001/01110",
'p': "00000/11110/10001/10001/11110/10000/10000",
'q': "00000/01111/10001/10001/01111/00001/00001",
'r': "00000/00000/10110/11001/10000/10000/10000",
's': "00000/00000/01111/10000/01110/00001/11110",
't': "01000/01000/11100/01000/01000/01001/00110",
'u': "00000/00000/10001/10001/10001/10011/01101",
'v': "00000/00000/10001/10001/10001/01010/00100",
'w': "00000/00000/10001/10001/10101/10101/01010",
'x': "00000/00000/10001/01010/00100/01010/10001",
'y': "00000/10001/10001/10001/01111/00001/01110",
'z': "00000/00000/11111/00010/00100/01000/11111",
'{': "00010/00100/00100/01000/00100/00100/00010",
'|': "00100/00100/00100/00100/00100/00100/00100",
'}': "01000/00100/00100/00010/00100/00100/01000",
'~': "00000/00000/01000/10101/00010/00000/00000",
}
FONT5 = {k: v.split('/') for k, v in FONT_ROWS.items()}
# Curated Unicode glyphs for the UTF-8 decoder. Codepoint -> 7 rows x 5 cols.
UNICODE_ROWS = {
0x00B0: "01100/10010/01100/00000/00000/00000/00000",  # degree
0x00B1: "00100/00100/11111/00100/00100/00000/11111",  # plus-minus
0x00D7: "10001/01010/00100/01010/10001/00000/00000",  # multiply
0x00F7: "00100/00000/11111/00000/00100/00000/00000",  # divide
0x03C0: "00000/11111/01010/01010/01010/01010/01010",  # pi
0x2014: "00000/00000/00000/11111/00000/00000/00000",  # em dash
0x2190: "00000/00100/01000/11111/01000/00100/00000",  # left arrow
0x2191: "00100/01110/10101/00100/00100/00100/00000",  # up arrow
0x2192: "00000/00100/00010/11111/00010/00100/00000",  # right arrow
0x2193: "00100/00100/00100/10101/01110/00100/00000",  # down arrow
0x221E: "00000/00000/01010/10101/10101/01010/00000",  # infinity
0x2248: "00000/01010/10101/00000/01010/10101/00000",  # approx
0x2295: "00100/01010/10001/11111/10001/01010/00100",  # xor
0x2713: "00001/00010/00100/01000/10100/01000/00000",  # check
}
UNICODE = {k: v.split('/') for k, v in UNICODE_ROWS.items()}

CODE = r'''; fb.nas - NaN16 framebuffer driver for VGA mode 13h (320x200x8, linear A0000).
; Written in NaN16 only except for the kernel's mode-set and VPOKE/VPEEK mapping.
; API (r0=0, r13=1):
;   fb_init                 -> mode 13h, clear black
;   fb_exit                 -> text mode 3
;   fb_clear  r1=colour     -> FBFILL 64000
;   fb_put    r1=x r2=y r3=colour
;   fb_get    r1=x r2=y     -> r1=colour
;   fb_hline  r1=x0 r2=x1 r3=y r4=colour
;   fb_vline  r1=x r2=y0 r3=y1 r4=colour
;   fb_scroll r1=colour     -> shift 199 rows up, fill row 199
;   fb_present               -> VSYNC
;   fb_char3  r1=x r2=y r3=ascii r4=colour  (3x5 glyph, 2x scale)
;   fb_text3  r1=x r2=y r3=string r4=colour
; fb_char3 preserves r10..r14; fb_text3 clobbers r1..r12.
.equ FBW 320
.equ FBH 200
.equ FBSIZE 64000
.equ FBLAST 63680
.equ V_CLS 4
.equ V_DISPQ 24
.equ P_MISC 0x3C2
.equ P_SEQ 0x3C4
.equ P_SEQD 0x3C5
.equ P_CRTC 0x3D4
.equ P_CRTCD 0x3D5
.equ P_GC 0x3CE
.equ P_GCD 0x3CF
.equ P_ATTR 0x3C0
.equ P_STAT 0x3DA
fb_init:
ST r15,r0,@fbi_ret
CALL @fb_mode13
LD r15,r0,@fbi_ret
RET
fbi_ret:
.word 0
fb_exit:
ST r15,r0,@fbx_ret
CALL @fb_mode3
LD r15,r0,@fbx_ret
RET
fbx_ret:
.word 0
; ---- port primitives: the only hardware boundary is OUTB/INB ----
fb_out:
OUTB r2,r1
RET
fb_in:
INB r1,r1
RET
; ---- table writer: r1=index port, r2=data port, r3=table, r4=count ----
fb_tab_out:
ST r15,r0,@ftbo_ret
ST r1,r0,@ftbo_ip
ST r2,r0,@ftbo_dp
ST r3,r0,@ftbo_t
ST r4,r0,@ftbo_n
MOVI r5,0
ST r5,r0,@ftbo_i
ftbo_loop:
LD r5,r0,@ftbo_i
LD r6,r0,@ftbo_n
CMP r5,r6
JMP[GE] @ftbo_done
LD r1,r0,@ftbo_ip
ADD r2,r5,r0
CALL @fb_out
LD r1,r0,@ftbo_dp
LD r3,r0,@ftbo_t
ADD r3,r3,r5
LD r2,r3,0
CALL @fb_out
LD r5,r0,@ftbo_i
ADD r5,r5,r13
ST r5,r0,@ftbo_i
JMP @ftbo_loop
ftbo_done:
LD r15,r0,@ftbo_ret
RET
ftbo_ret:
.word 0
ftbo_ip:
.word 0
ftbo_dp:
.word 0
ftbo_t:
.word 0
ftbo_n:
.word 0
ftbo_i:
.word 0
; ---- VGA mode 13h, 320x200x8 linear, all register writes in NaN16 ----
fb_mode13:
ST r15,r0,@fm13_ret
MOVI r1,#P_MISC
MOVI r2,0x63
CALL @fb_out
MOVI r1,#P_SEQ
MOVI r2,#P_SEQD
MOVI r3,@seq13
MOVI r4,5
CALL @fb_tab_out
MOVI r1,#P_CRTC
MOVI r2,0x11
CALL @fb_out
MOVI r1,#P_CRTCD
CALL @fb_in
MOVI r2,0x7F
BOOL.8 r1,r1,r2
MOVI r2,#P_CRTCD
CALL @fb_out
MOVI r1,#P_CRTC
MOVI r2,#P_CRTCD
MOVI r3,@crtc13
MOVI r4,25
CALL @fb_tab_out
MOVI r1,#P_GC
MOVI r2,#P_GCD
MOVI r3,@gc13
MOVI r4,9
CALL @fb_tab_out
MOVI r1,#P_STAT
CALL @fb_in
MOVI r1,#P_ATTR
MOVI r2,#P_ATTR
MOVI r3,@attr13
MOVI r4,21
CALL @fb_tab_out
MOVI r1,#P_ATTR
MOVI r2,0x20
CALL @fb_out
MOVI r3,0x13
DISPSET r3
LD r15,r0,@fm13_ret
RET
fm13_ret:
.word 0
; ---- VGA text mode 3 restore, all register writes in NaN16 ----
fb_mode3:
ST r15,r0,@fm3_ret
MOVI r1,#P_MISC
MOVI r2,0x67
CALL @fb_out
MOVI r1,#P_SEQ
MOVI r2,#P_SEQD
MOVI r3,@seq3
MOVI r4,5
CALL @fb_tab_out
MOVI r1,#P_CRTC
MOVI r2,0x11
CALL @fb_out
MOVI r1,#P_CRTCD
CALL @fb_in
MOVI r2,0x7F
BOOL.8 r1,r1,r2
MOVI r2,#P_CRTCD
CALL @fb_out
MOVI r1,#P_CRTC
MOVI r2,#P_CRTCD
MOVI r3,@crtc3
MOVI r4,25
CALL @fb_tab_out
MOVI r1,#P_GC
MOVI r2,#P_GCD
MOVI r3,@gc3
MOVI r4,9
CALL @fb_tab_out
MOVI r1,#P_STAT
CALL @fb_in
MOVI r1,#P_ATTR
MOVI r2,#P_ATTR
MOVI r3,@attr3
MOVI r4,21
CALL @fb_tab_out
MOVI r1,#P_ATTR
MOVI r2,0x20
CALL @fb_out
MOVI r3,3
DISPSET r3
LD r15,r0,@fm3_ret
RET
fm3_ret:
.word 0
fb_clear:
MOVI r2,#FBSIZE
MOVI r3,0
FBFILL r2,r3,r1
RET
fb_put:
MOVI r5,#FBW
CMP r1,r5
RET[GE]
MOVI r5,#FBH
CMP r2,r5
RET[GE]
MOVI r5,#FBW
MUL r5,r2,r5
ADD r5,r5,r1
VPOKE r3,r5
RET
fb_get:
MOVI r5,#FBW
CMP r1,r5
JMP[GE] @fbg_zero
MOVI r5,#FBH
CMP r2,r5
JMP[GE] @fbg_zero
MOVI r5,#FBW
MUL r5,r2,r5
ADD r5,r5,r1
VPEEK r1,r5
RET
fbg_zero:
MOVI r1,0
RET
fb_hline:
CMP r1,r2
JMP[LE] @fbh_ok
MOVI r5,0
ADD r5,r1,r0
ADD r1,r2,r0
ADD r2,r5,r0
fbh_ok:
MOVI r5,#FBW
MUL r5,r3,r5
ADD r5,r5,r1
SUB r6,r2,r1
ADD r6,r6,r13
FBFILL r6,r5,r4
RET
fb_vline:
ST r15,r0,@fbv_ret
CMP r2,r3
JMP[LE] @fbv_ok
MOVI r5,0
ADD r5,r2,r0
ADD r2,r3,r0
ADD r3,r5,r0
fbv_ok:
fbv_loop:
ADD r1,r1,r0
CALL @fb_put
ADD r2,r2,r13
CMP r2,r3
JMP[LE] @fbv_loop
LD r15,r0,@fbv_ret
RET
fbv_ret:
.word 0
fb_scroll:
MOVI r2,#FBLAST
MOVI r3,0
MOVI r4,#FBW
FBCOPY r2,r3,r4
MOVI r2,#FBW
MOVI r3,#FBLAST
FBFILL r2,r3,r1
RET
fb_present:
VSYNC
RET
; ---- glyph renderer: 5 columns x 7 rows, 1x, 6x8 cell ----
fb_char5:
MOVI r5,32
CMP r3,r5
JMP[LT] @f5_uni
MOVI r5,126
CMP r3,r5
JMP[GT] @f5_uni
MOVI r5,32
SUB r3,r3,r5
JMP @f5_draw
f5_uni:
MOVI r5,@uni_cp
MOVI r6,#UNI_N
MOVI r7,0
f5_us:
CMP r7,r6
JMP[GE] @f5_fallback
LD r8,r5,0
CMP r8,r3
JMP[EQ] @f5_found
ADD r5,r5,r13
ADD r7,r7,r13
JMP @f5_us
f5_found:
MOVI r6,95
ADD r3,r7,r6
JMP @f5_draw
f5_fallback:
MOVI r3,31
f5_draw:
ST r1,r0,@f5_x
ST r2,r0,@f5_y
ST r4,r0,@f5_c
MOVI r5,5
MUL r3,r3,r5
MOVI r5,@font5
ADD r5,r5,r3
ST r5,r0,@f5_tab
MOVI r5,0
f5_col:
MOVI r6,5
CMP r5,r6
JMP[GE] @f5_done
LD r7,r0,@f5_tab
ADD r7,r7,r5
LD r8,r7,0
MOVI r6,0
f5_row:
MOVI r7,7
CMP r6,r7
JMP[GE] @f5_nextcol
MOVI r7,@mask7
ADD r7,r7,r6
LD r7,r7,0
BOOL.8 r9,r8,r7
CMP r9,r0
JMP[EQ] @f5_nextrow
LD r1,r0,@f5_x
ADD r1,r1,r5
LD r2,r0,@f5_y
ADD r2,r2,r6
MOVI r9,#FBW
MUL r9,r2,r9
ADD r9,r9,r1
LD r4,r0,@f5_c
VPOKE r4,r9
f5_nextrow:
ADD r6,r6,r13
JMP @f5_row
f5_nextcol:
ADD r5,r5,r13
JMP @f5_col
f5_done:
RET
f5_x:
.word 0
f5_y:
.word 0
f5_c:
.word 0
f5_tab:
.word 0
; ---- UTF-8 text: packed 4 bytes/word, 6x8 cells ----
fb_text5:
ST r15,r0,@ft5_ret
ST r1,r0,@ft5_x
ST r2,r0,@ft5_y
ST r4,r0,@ft5_c
ADD r10,r3,r0
MOVI r11,0
MOVI r12,0
ft5_loop:
CALL @fb_nextbyte
CMP r6,r0
JMP[EQ] @ft5_done
MOVI r5,10
CMP r6,r5
JMP[EQ] @ft5_nl
MOVI r5,0x80
CMP r6,r5
JMP[LT] @ft5_ascii
MOVI r5,0xE0
BOOL.8 r7,r6,r5
MOVI r5,0xC0
CMP r7,r5
JMP[EQ] @ft5_2
MOVI r5,0xF0
BOOL.8 r7,r6,r5
MOVI r5,0xE0
CMP r7,r5
JMP[EQ] @ft5_3
MOVI r5,0xF8
BOOL.8 r7,r6,r5
MOVI r5,0xF0
CMP r7,r5
JMP[EQ] @ft5_4
JMP @ft5_bad
ft5_ascii:
ADD r3,r6,r0
JMP @ft5_draw
ft5_2:
MOVI r5,0x1F
BOOL.8 r9,r6,r5
CALL @fb_nextbyte
MOVI r5,0x3F
BOOL.8 r6,r6,r5
SHL r9,r9,6
BOOL.14 r3,r9,r6
JMP @ft5_draw
ft5_3:
MOVI r5,0x0F
BOOL.8 r9,r6,r5
CALL @fb_nextbyte
MOVI r5,0x3F
BOOL.8 r8,r6,r5
CALL @fb_nextbyte
MOVI r5,0x3F
BOOL.8 r6,r6,r5
SHL r9,r9,12
SHL r8,r8,6
BOOL.14 r9,r9,r8
BOOL.14 r3,r9,r6
JMP @ft5_draw
ft5_4:
MOVI r5,0x07
BOOL.8 r9,r6,r5
CALL @fb_nextbyte
MOVI r5,0x3F
BOOL.8 r8,r6,r5
CALL @fb_nextbyte
MOVI r5,0x3F
BOOL.8 r7,r6,r5
CALL @fb_nextbyte
MOVI r5,0x3F
BOOL.8 r6,r6,r5
SHL r9,r9,18
SHL r8,r8,12
BOOL.14 r9,r9,r8
SHL r7,r7,6
BOOL.14 r9,r9,r7
BOOL.14 r3,r9,r6
JMP @ft5_draw
ft5_bad:
MOVI r3,63
ft5_draw:
LD r1,r0,@ft5_x
LD r2,r0,@ft5_y
LD r4,r0,@ft5_c
CALL @fb_char5
LD r1,r0,@ft5_x
MOVI r5,6
ADD r1,r1,r5
ST r1,r0,@ft5_x
JMP @ft5_loop
ft5_nl:
MOVI r1,0
ST r1,r0,@ft5_x
LD r2,r0,@ft5_y
MOVI r5,11
ADD r2,r2,r5
ST r2,r0,@ft5_y
JMP @ft5_loop
ft5_done:
LD r15,r0,@ft5_ret
RET
ft5_ret:
.word 0
ft5_x:
.word 0
ft5_y:
.word 0
ft5_c:
.word 0
fb_nextbyte:
ST r15,r0,@fnb_ret
CMP r12,r0
JMP[NE] @fnb_have
LD r11,r10,0
ADD r10,r10,r13
MOVI r12,4
fnb_have:
MOVI r5,255
BOOL.8 r6,r11,r5
SHR r11,r11,8
SUB r12,r12,r13
LD r15,r0,@fnb_ret
RET
fnb_ret:
.word 0
mask7:
.word 1,2,4,8,16,32,64
; ---- VGA register tables ----
seq13:
.word 3,1,15,0,14
crtc13:
.word 0x5F,0x4F,0x50,0x82,0x54,0x80,0xBF,0x1F,0x00,0x41,0x00,0x00,0x00,0x00,0x00,0x00
.word 0x9C,0x8E,0x8F,0x28,0x40,0x96,0xB9,0xA3,0xFF
gc13:
.word 0x00,0x00,0x00,0x00,0x00,0x40,0x05,0x0F,0xFF
attr13:
.word 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0x41,0,0x0F,0,0
seq3:
.word 3,0,3,0,2
crtc3:
.word 0x5F,0x4F,0x50,0x82,0x55,0x81,0xBF,0x1F,0x00,0x4F,0x0D,0x0E,0x00,0x00,0x00,0x00
.word 0x9C,0x8E,0x8F,0x28,0x1F,0x96,0xB9,0xA3,0xFF
gc3:
.word 0x00,0x00,0x00,0x00,0x00,0x10,0x0E,0x00,0xFF
attr3:
.word 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0x0C,0,0x0F,0x08,0
'''

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, 'src', 'lib', 'fb.nas')
    glyphs = []
    for code in range(32, 127):
        ch = chr(code)
        g = FONT5.get(ch, ["00000"]*7)
        if len(g) != 7 or any(len(r) != 5 for r in g):
            raise SystemExit('bad glyph for %r: %r' % (ch, g))
        glyphs.append((ch, g))
    uni = sorted(UNICODE.items())
    for cp, g in uni:
        if len(g) != 7 or any(len(r) != 5 for r in g):
            raise SystemExit('bad unicode glyph %04x: %r' % (cp, g))
        glyphs.append((cp, g))
    body = []
    body.append('; ---- 5x7 font: 95 ASCII glyphs + %d Unicode glyphs ----' % len(uni))
    body.append('font5:')
    for key, g in glyphs:
        body.append('; %r' % key)
        for col in range(5):
            v = 0
            for row in range(7):
                if g[row][col] == '1':
                    v |= 1 << row
            body.append('.word %d' % v)
    body.append('; ---- Unicode codepoint table (glyph index 95 + i) ----')
    body.append('uni_cp:')
    for cp, _ in uni:
        body.append('.word %d' % cp)
    text = '.equ UNI_N %d\n' % len(uni) + CODE + '\n'.join(body) + '\n'
    with open(out, 'w') as f:
        f.write(text)
    print('wrote %s: %d glyphs (%d ASCII + %d Unicode), %d words font' %
          (out, len(glyphs), len(glyphs)-len(uni), len(uni), len(glyphs)*5))

if __name__ == '__main__':
    main()
