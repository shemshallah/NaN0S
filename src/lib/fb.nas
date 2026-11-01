.equ UNI_N 14
; fb.nas - NaN16 framebuffer driver for VGA mode 13h (320x200x8, linear A0000).
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
MOVI r1,320
ST r1,r0,@fb_w
MOVI r1,200
ST r1,r0,@fb_h
CALL @fb_mode13
LD r15,r0,@fbi_ret
RET
; fb_init_mode r1 = (w<<16)|h : linear 8bpp VBE mode, EGA palette loaded; r1=0 -> 320x200 VGA
fb_init_mode:
ST r15,r0,@fim_ret
CMP r1,r0
JMP[NE] @fim_vbe
CALL @fb_init
JMP @fim_done
fim_vbe:
DISPSET r1
SHR r2,r1,16
ST r2,r0,@fb_w
MOVI r3,0xFFFF
BOOL.8 r3,r1,r3
ST r3,r0,@fb_h
CALL @fb_pal
fim_done:
LD r15,r0,@fim_ret
RET
fim_ret:
.word 0
; fb_pal: load the DAC from pal_tab (index, r, g, b 6-bit) until index 0xFFFF
fb_pal:
ST r15,r0,@fp_ret
MOVI r5,@pal_tab
fp_loop:
LD r6,r5,0
MOVI r7,0xFFFF
CMP r6,r7
JMP[EQ] @fp_done
ST r5,r0,@fp_p
MOVI r1,0x3C8
ADD r2,r6,r0
CALL @fb_out
LD r5,r0,@fp_p
LD r2,r5,1
MOVI r1,0x3C9
CALL @fb_out
LD r5,r0,@fp_p
LD r2,r5,2
MOVI r1,0x3C9
CALL @fb_out
LD r5,r0,@fp_p
LD r2,r5,3
MOVI r1,0x3C9
CALL @fb_out
LD r5,r0,@fp_p
MOVI r6,4
ADD r5,r5,r6
JMP @fp_loop
fp_done:
LD r15,r0,@fp_ret
RET
fp_ret:
.word 0
fp_p:
.word 0
fb_w:
.word 320
fb_h:
.word 200
; palette: 0-15 EGA, 16 lattice bright #42ef8a, 17 lattice dim #10311e, 18 panel #181536, 19 button, 20 lattice blank stage #311610 (HTML NaN-FALSE hue 10)
pal_tab:
.word 0,0,0,0
.word 1,0,0,42
.word 2,0,42,0
.word 3,0,42,42
.word 4,42,0,0
.word 5,42,0,42
.word 6,42,21,0
.word 7,42,42,42
.word 8,21,21,21
.word 9,21,21,63
.word 10,21,63,21
.word 11,21,63,63
.word 12,63,21,21
.word 13,63,21,63
.word 14,63,63,21
.word 15,63,63,63
.word 16,16,59,34
.word 17,4,12,7
.word 18,6,5,13
.word 19,30,30,40
.word 20,12,5,4
.word 0xFFFF
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
LD r2,r0,@fb_w
LD r3,r0,@fb_h
MUL r2,r2,r3
MOVI r3,0
FBFILL r2,r3,r1
RET
fb_put:
LD r5,r0,@fb_w
CMP r1,r5
RET[GE]
LD r5,r0,@fb_h
CMP r2,r5
RET[GE]
LD r5,r0,@fb_w
MUL r5,r2,r5
ADD r5,r5,r1
VPOKE r3,r5
RET
fb_get:
LD r5,r0,@fb_w
CMP r1,r5
JMP[GE] @fbg_zero
LD r5,r0,@fb_h
CMP r2,r5
JMP[GE] @fbg_zero
LD r5,r0,@fb_w
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
LD r5,r0,@fb_w
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
LD r4,r0,@fb_w
LD r2,r0,@fb_h
SUB r2,r2,r13
MUL r3,r2,r4
ADD r2,r3,r0
MOVI r3,0
FBCOPY r2,r3,r4
LD r2,r0,@fb_w
LD r4,r0,@fb_h
SUB r4,r4,r13
MUL r3,r4,r2
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
LD r9,r0,@fb_w
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
; ---- 5x7 font: 95 ASCII glyphs + 14 Unicode glyphs ----
font5:
; ' '
.word 0
.word 0
.word 0
.word 0
.word 0
; '!'
.word 0
.word 0
.word 95
.word 0
.word 0
; '"'
.word 0
.word 3
.word 0
.word 3
.word 0
; '#'
.word 20
.word 127
.word 20
.word 127
.word 20
; '$'
.word 36
.word 42
.word 127
.word 42
.word 18
; '%'
.word 67
.word 51
.word 8
.word 102
.word 97
; '&'
.word 54
.word 73
.word 85
.word 34
.word 80
; "'"
.word 0
.word 0
.word 3
.word 0
.word 0
; '('
.word 0
.word 28
.word 34
.word 65
.word 0
; ')'
.word 0
.word 65
.word 34
.word 28
.word 0
; '*'
.word 42
.word 28
.word 62
.word 28
.word 42
; '+'
.word 8
.word 8
.word 62
.word 8
.word 8
; ','
.word 0
.word 64
.word 48
.word 16
.word 0
; '-'
.word 8
.word 8
.word 8
.word 8
.word 8
; '.'
.word 0
.word 0
.word 96
.word 96
.word 0
; '/'
.word 64
.word 48
.word 8
.word 6
.word 1
; '0'
.word 62
.word 81
.word 73
.word 69
.word 62
; '1'
.word 0
.word 66
.word 127
.word 64
.word 0
; '2'
.word 66
.word 97
.word 81
.word 73
.word 70
; '3'
.word 65
.word 73
.word 73
.word 73
.word 54
; '4'
.word 24
.word 20
.word 18
.word 127
.word 16
; '5'
.word 39
.word 69
.word 69
.word 69
.word 57
; '6'
.word 60
.word 74
.word 73
.word 73
.word 48
; '7'
.word 1
.word 113
.word 9
.word 5
.word 3
; '8'
.word 54
.word 73
.word 73
.word 73
.word 54
; '9'
.word 6
.word 73
.word 73
.word 41
.word 30
; ':'
.word 0
.word 0
.word 54
.word 54
.word 0
; ';'
.word 0
.word 64
.word 54
.word 22
.word 0
; '<'
.word 8
.word 20
.word 34
.word 65
.word 0
; '='
.word 20
.word 20
.word 20
.word 20
.word 20
; '>'
.word 0
.word 65
.word 34
.word 20
.word 8
; '?'
.word 2
.word 1
.word 81
.word 9
.word 6
; '@'
.word 50
.word 73
.word 121
.word 65
.word 62
; 'A'
.word 126
.word 9
.word 9
.word 9
.word 126
; 'B'
.word 127
.word 73
.word 73
.word 73
.word 54
; 'C'
.word 62
.word 65
.word 65
.word 65
.word 34
; 'D'
.word 127
.word 65
.word 65
.word 65
.word 62
; 'E'
.word 127
.word 73
.word 73
.word 73
.word 65
; 'F'
.word 127
.word 9
.word 9
.word 9
.word 1
; 'G'
.word 62
.word 65
.word 73
.word 73
.word 58
; 'H'
.word 127
.word 8
.word 8
.word 8
.word 127
; 'I'
.word 65
.word 65
.word 127
.word 65
.word 65
; 'J'
.word 32
.word 64
.word 65
.word 63
.word 1
; 'K'
.word 127
.word 8
.word 20
.word 34
.word 65
; 'L'
.word 127
.word 64
.word 64
.word 64
.word 64
; 'M'
.word 127
.word 2
.word 12
.word 2
.word 127
; 'N'
.word 127
.word 2
.word 4
.word 8
.word 127
; 'O'
.word 62
.word 65
.word 65
.word 65
.word 62
; 'P'
.word 127
.word 9
.word 9
.word 9
.word 6
; 'Q'
.word 62
.word 65
.word 81
.word 33
.word 94
; 'R'
.word 127
.word 9
.word 25
.word 41
.word 70
; 'S'
.word 70
.word 73
.word 73
.word 73
.word 49
; 'T'
.word 1
.word 1
.word 127
.word 1
.word 1
; 'U'
.word 63
.word 64
.word 64
.word 64
.word 63
; 'V'
.word 31
.word 32
.word 64
.word 32
.word 31
; 'W'
.word 63
.word 64
.word 56
.word 64
.word 63
; 'X'
.word 99
.word 20
.word 8
.word 20
.word 99
; 'Y'
.word 3
.word 4
.word 120
.word 4
.word 3
; 'Z'
.word 97
.word 81
.word 73
.word 69
.word 67
; '['
.word 0
.word 127
.word 65
.word 65
.word 0
; '\\'
.word 1
.word 6
.word 8
.word 48
.word 64
; ']'
.word 0
.word 65
.word 65
.word 127
.word 0
; '^'
.word 4
.word 2
.word 1
.word 2
.word 4
; '_'
.word 64
.word 64
.word 64
.word 64
.word 64
; '`'
.word 0
.word 1
.word 2
.word 0
.word 0
; 'a'
.word 32
.word 84
.word 84
.word 84
.word 120
; 'b'
.word 127
.word 68
.word 68
.word 68
.word 56
; 'c'
.word 56
.word 68
.word 68
.word 68
.word 32
; 'd'
.word 56
.word 68
.word 68
.word 68
.word 127
; 'e'
.word 56
.word 84
.word 84
.word 84
.word 24
; 'f'
.word 8
.word 126
.word 9
.word 1
.word 2
; 'g'
.word 12
.word 82
.word 82
.word 82
.word 62
; 'h'
.word 127
.word 4
.word 4
.word 4
.word 120
; 'i'
.word 0
.word 68
.word 125
.word 64
.word 0
; 'j'
.word 32
.word 64
.word 68
.word 61
.word 0
; 'k'
.word 127
.word 16
.word 40
.word 68
.word 0
; 'l'
.word 0
.word 65
.word 127
.word 64
.word 0
; 'm'
.word 124
.word 4
.word 120
.word 4
.word 120
; 'n'
.word 124
.word 4
.word 4
.word 4
.word 120
; 'o'
.word 56
.word 68
.word 68
.word 68
.word 56
; 'p'
.word 126
.word 18
.word 18
.word 18
.word 12
; 'q'
.word 12
.word 18
.word 18
.word 18
.word 126
; 'r'
.word 124
.word 8
.word 4
.word 4
.word 8
; 's'
.word 72
.word 84
.word 84
.word 84
.word 36
; 't'
.word 4
.word 63
.word 68
.word 64
.word 32
; 'u'
.word 60
.word 64
.word 64
.word 32
.word 124
; 'v'
.word 28
.word 32
.word 64
.word 32
.word 28
; 'w'
.word 60
.word 64
.word 48
.word 64
.word 60
; 'x'
.word 68
.word 40
.word 16
.word 40
.word 68
; 'y'
.word 14
.word 80
.word 80
.word 80
.word 62
; 'z'
.word 68
.word 100
.word 84
.word 76
.word 68
; '{'
.word 0
.word 8
.word 54
.word 65
.word 0
; '|'
.word 0
.word 0
.word 127
.word 0
.word 0
; '}'
.word 0
.word 65
.word 54
.word 8
.word 0
; '~'
.word 8
.word 4
.word 8
.word 16
.word 8
; 176
.word 2
.word 5
.word 5
.word 2
.word 0
; 177
.word 68
.word 68
.word 95
.word 68
.word 68
; 215
.word 17
.word 10
.word 4
.word 10
.word 17
; 247
.word 4
.word 4
.word 21
.word 4
.word 4
; 960
.word 2
.word 126
.word 2
.word 126
.word 2
; 8212
.word 8
.word 8
.word 8
.word 8
.word 8
; 8592
.word 8
.word 28
.word 42
.word 8
.word 8
; 8593
.word 4
.word 2
.word 63
.word 2
.word 4
; 8594
.word 8
.word 8
.word 42
.word 28
.word 8
; 8595
.word 8
.word 16
.word 63
.word 16
.word 8
; 8734
.word 24
.word 36
.word 24
.word 36
.word 24
; 8776
.word 36
.word 18
.word 36
.word 18
.word 36
; 8853
.word 28
.word 42
.word 73
.word 42
.word 28
; 10003
.word 16
.word 40
.word 20
.word 2
.word 1
; ---- Unicode codepoint table (glyph index 95 + i) ----
uni_cp:
.word 176
.word 177
.word 215
.word 247
.word 960
.word 8212
.word 8592
.word 8593
.word 8594
.word 8595
.word 8734
.word 8776
.word 8853
.word 10003
