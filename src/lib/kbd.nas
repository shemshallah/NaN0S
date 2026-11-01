; kbd.nas - raw PS/2 scancode-set-1 keyboard driver, pure NaN16 (hand-edited source; the Python generator was removed).
; API (r13=1, r14=soft stack; clobbers r1-r12):
;   kbd_init  : DISPSET raw mode, clear state/queue
;   kbd_poll  : drain KEYQ, track Shift/Ctrl/Alt/Caps, push press events into a 16-entry ring
;   kbd_get   : r1 = next event or 0
;   kbd_mods  : r1 = current mods (1 shift,2 ctrl,4 alt,8 caps)
; event = code | mods<<16 ; see generator header for the code map. F1..F12 = 0x101..0x10C, arrows 0x110..0x113.
kbd_init:
MOVI r2,0xFFFF
SHL r2,r2,16
MOVI r1,1
ADD r1,r1,r2
DISPSET r1
ST r0,r0,@kb_e0
ST r0,r0,@kb_sh
ST r0,r0,@kb_ct
ST r0,r0,@kb_al
ST r0,r0,@kb_cp
ST r0,r0,@kb_h
ST r0,r0,@kb_t
RET
kbd_mods:
LD r1,r0,@kb_cp
SHL r1,r1,1
LD r2,r0,@kb_al
ADD r1,r1,r2
SHL r1,r1,1
LD r2,r0,@kb_ct
ADD r1,r1,r2
SHL r1,r1,1
LD r2,r0,@kb_sh
ADD r1,r1,r2
RET
kbd_get:
LD r2,r0,@kb_h
LD r3,r0,@kb_t
CMP r2,r3
JMP[NE] @kg_have
MOVI r1,0
RET
kg_have:
MOVI r4,@kb_q
ADD r4,r4,r2
LD r1,r4,0
ADD r2,r2,r13
MOVI r5,15
BOOL.8 r2,r2,r5
ST r2,r0,@kb_h
RET
kbd_poll:
ST r15,r14,0
ADD r14,r14,r13
kp_loop:
KEYQ r2
CMP r2,r0
JMP[EQ] @kp_done
MOVI r3,0xE0
CMP r2,r3
JMP[NE] @kp_n1
MOVI r3,1
ST r3,r0,@kb_e0
JMP @kp_loop
kp_n1:
MOVI r3,0xE1
CMP r2,r3
JMP[NE] @kp_n2
JMP @kp_loop
kp_n2:
MOVI r3,0x80
BOOL.8 r4,r2,r3
SHR r4,r4,7
ST r4,r0,@kp_brk
MOVI r3,0x7F
BOOL.8 r2,r2,r3
LD r5,r0,@kb_e0
ST r0,r0,@kb_e0
ST r2,r0,@kp_sc
ST r5,r0,@kp_e
; modifiers
MOVI r3,0x2A
CMP r2,r3
JMP[EQ] @kp_shift
MOVI r3,0x36
CMP r2,r3
JMP[EQ] @kp_shift
MOVI r3,0x1D
CMP r2,r3
JMP[EQ] @kp_ctrl
MOVI r3,0x38
CMP r2,r3
JMP[EQ] @kp_alt
MOVI r3,0x3A
CMP r2,r3
JMP[EQ] @kp_caps
; ordinary key: only on make
LD r4,r0,@kp_brk
CMP r4,r0
JMP[NE] @kp_loop
CMP r5,r0
JMP[NE] @kp_ext
LD r6,r0,@kb_sh
LD r7,r0,@kb_cp
MOVI r8,@kt_n
ADD r8,r8,r2
LD r9,r8,0
; caps affects letters only
MOVI r10,97
CMP r9,r10
JMP[LT] @kp_nocap
MOVI r10,122
CMP r9,r10
JMP[GT] @kp_nocap
BOOL.6 r6,r6,r7
kp_nocap:
CMP r6,r0
JMP[EQ] @kp_have
MOVI r8,@kt_s
ADD r8,r8,r2
LD r9,r8,0
kp_have:
CMP r9,r0
JMP[EQ] @kp_loop
JMP @kp_push
kp_ext:
MOVI r8,@kt_e
ADD r8,r8,r2
LD r9,r8,0
CMP r9,r0
JMP[EQ] @kp_loop
kp_push:
ST r9,r0,@kp_code
CALL @kbd_mods
LD r9,r0,@kp_code
SHL r1,r1,16
ADD r9,r9,r1
LD r2,r0,@kb_t
ADD r3,r2,r13
MOVI r5,15
BOOL.8 r3,r3,r5
LD r4,r0,@kb_h
CMP r3,r4
JMP[EQ] @kp_loop
MOVI r6,@kb_q
ADD r6,r6,r2
ST r9,r6,0
ST r3,r0,@kb_t
JMP @kp_loop
kp_shift:
LD r4,r0,@kp_e
CMP r4,r0
JMP[NE] @kp_loop
LD r4,r0,@kp_brk
MOVI r5,1
SUB r5,r5,r4
ST r5,r0,@kb_sh
JMP @kp_loop
kp_ctrl:
LD r4,r0,@kp_brk
MOVI r5,1
SUB r5,r5,r4
ST r5,r0,@kb_ct
JMP @kp_loop
kp_alt:
LD r4,r0,@kp_brk
MOVI r5,1
SUB r5,r5,r4
ST r5,r0,@kb_al
JMP @kp_loop
kp_caps:
LD r4,r0,@kp_brk
CMP r4,r0
JMP[NE] @kp_loop
LD r5,r0,@kb_cp
MOVI r6,1
BOOL.6 r5,r5,r6
ST r5,r0,@kb_cp
JMP @kp_loop
kp_done:
SUB r14,r14,r13
LD r15,r14,0
RET
kb_e0:
.word 0
kb_sh:
.word 0
kb_ct:
.word 0
kb_al:
.word 0
kb_cp:
.word 0
kb_h:
.word 0
kb_t:
.word 0
kp_brk:
.word 0
kp_sc:
.word 0
kp_e:
.word 0
kp_code:
.word 0
kb_q:
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
kt_n:
.word 0,27,49,50,51,52,53,54,55,56,57,48,45,61,8,9
.word 113,119,101,114,116,121,117,105,111,112,91,93,13,0,97,115
.word 100,102,103,104,106,107,108,59,39,96,0,92,122,120,99,118
.word 98,110,109,44,46,47,0,42,0,32,0,257,258,259,260,261
.word 262,263,264,265,266,0,0,0,0,0,45,0,0,0,43,0
.word 0,0,0,0,0,0,0,267,268,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
kt_s:
.word 0,27,33,64,35,36,37,94,38,42,40,41,95,43,8,9
.word 81,87,69,82,84,89,85,73,79,80,123,125,13,0,65,83
.word 68,70,71,72,74,75,76,58,34,126,0,124,90,88,67,86
.word 66,78,77,60,62,63,0,42,0,32,0,257,258,259,260,261
.word 262,263,264,265,266,0,0,0,0,0,45,0,0,0,43,0
.word 0,0,0,0,0,0,0,267,268,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
kt_e:
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,13,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,47,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,276,272,278,0,274,0,275,0,277
.word 273,279,280,127,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
