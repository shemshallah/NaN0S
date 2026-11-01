; vbe_test: 1024x768 linear mode, palette, NaNGlyph text
.org 8192
JMP @entry
.include "../lib/fb.nas"
.include "../lib/fbtext.nas"
.include "../lib/font7.nas"
entry:
MOVI r13,1
MOVI r14,30000
MOVI r1,768
MOVI r2,1024
SHL r2,r2,16
ADD r1,r1,r2
CALL @fb_init_mode
MOVI r1,1
CALL @fb_clear
MOVI r1,16
MOVI r2,16
MOVI r3,@s1
MOVI r4,15
CALL @fb_text7
MOVI r1,16
MOVI r2,60
MOVI r3,@s2
MOVI r4,16
CALL @fb_text7
HALT
s1:
.str "NaN/0S 1024x768 NaNGlyph: The quick brown fox jumps\nover the lazy dog 0123456789 {}[]<>=+-*/%&#@!?"
s2:
.str "Sierpinski colour index 16"
