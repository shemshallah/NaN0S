; spanbench - texture-span inner loop in NaNVM1 (isa=1), the Quake D_DrawSpans8 shape: dest[x] = tex[(t>>16)*64 + (s>>16)], s,t 16.16 fixed.
; 200 rows x 320 pixels = 64000 pixels, drawn two ways, each checked against a slow reference (MUL/DIVU, no shifts) byte for byte.
; plain: 11 guest ops per pixel. x4: loop unrolled 4 times, 8.75 per pixel. TICK reports guest kilo-ops (model: steps/1000).
; Memory (bytes): texture 4096 B at 0x4000 (word 0x1000), fb1 0x80000, fb2 0xA0000, ref 0xC0000. All below 1M words.
.equ TEXB 0x4000
.equ DS 12483
.equ DT 6554
.equ V_T1 0x1F00
.equ V_T2 0x1F01
main:
MOVI r13,1
MOVI r14,0x7000
MOVI r1,@s_banner
CALL @puts
MOVI r1,0
fill:
MOVI r2,7
MUL r3,r1,r2
SHR r4,r1,6
MOVI r2,13
MUL r4,r4,r2
ADD r3,r3,r4
STB r3,r1,#TEXB
ADD r1,r1,r13
MOVI r2,4096
CMP r1,r2
JMP[LT] @fill
; ---- reference: s = s0 + x*DS, t = t0 + x*DT, texel index = (t DIVU 65536)*64 + (s DIVU 65536)
MOVI r9,0
MOVHI r9,12
MOVI r12,0
rr:
MOVI r2,3000
MUL r10,r12,r2
MOVI r2,1000
MUL r11,r12,r2
MOVI r8,0
rx:
MOVI r2,#DS
MUL r1,r8,r2
ADD r1,r1,r10
MOVI r2,#DT
MUL r2,r8,r2
ADD r2,r2,r11
MOVI r3,0
MOVHI r3,1
DIVU r1,r1,r3
DIVU r2,r2,r3
MOVI r3,64
MUL r2,r2,r3
ADD r1,r1,r2
LDB r4,r1,#TEXB
STB r4,r9,0
ADD r9,r9,r13
ADD r8,r8,r13
MOVI r2,320
CMP r8,r2
JMP[LT] @rx
ADD r12,r12,r13
MOVI r2,200
CMP r12,r2
JMP[LT] @rr
; ---- plain loop -> fb1
TICK r10
MOVI r9,0
MOVHI r9,8
MOVI r12,0
row1:
MOVI r2,3000
MUL r1,r12,r2
MOVI r2,1000
MUL r2,r12,r2
MOVI r3,#DS
MOVI r4,#DT
MOVI r8,320
px:
SHR r5,r1,16
SHR r6,r2,16
SHL r6,r6,6
ADD r5,r5,r6
LDB r7,r5,#TEXB
STB r7,r9,0
ADD r1,r1,r3
ADD r2,r2,r4
ADD r9,r9,r13
SUB r8,r8,r13
JMP[NE] @px
ADD r12,r12,r13
MOVI r5,200
CMP r12,r5
JMP[LT] @row1
TICK r11
SUB r10,r11,r10
ST r10,r0,#V_T1
; ---- unrolled x4 -> fb2
TICK r10
MOVI r9,0
MOVHI r9,10
MOVI r12,0
row2:
MOVI r2,3000
MUL r1,r12,r2
MOVI r2,1000
MUL r2,r12,r2
MOVI r3,#DS
MOVI r4,#DT
MOVI r8,80
px4:
SHR r5,r1,16
SHR r6,r2,16
SHL r6,r6,6
ADD r5,r5,r6
LDB r7,r5,#TEXB
STB r7,r9,0
ADD r1,r1,r3
ADD r2,r2,r4
SHR r5,r1,16
SHR r6,r2,16
SHL r6,r6,6
ADD r5,r5,r6
LDB r7,r5,#TEXB
STB r7,r9,1
ADD r1,r1,r3
ADD r2,r2,r4
SHR r5,r1,16
SHR r6,r2,16
SHL r6,r6,6
ADD r5,r5,r6
LDB r7,r5,#TEXB
STB r7,r9,2
ADD r1,r1,r3
ADD r2,r2,r4
SHR r5,r1,16
SHR r6,r2,16
SHL r6,r6,6
ADD r5,r5,r6
LDB r7,r5,#TEXB
STB r7,r9,3
ADD r1,r1,r3
ADD r2,r2,r4
ADDI r9,r9,4
SUB r8,r8,r13
JMP[NE] @px4
ADD r12,r12,r13
MOVI r5,200
CMP r12,r5
JMP[LT] @row2
TICK r11
SUB r10,r11,r10
ST r10,r0,#V_T2
; ---- report + verify
MOVI r1,@s_t1
CALL @puts
LD r1,r0,#V_T1
CALL @puthex
MOVI r1,@s_t2
CALL @puts
LD r1,r0,#V_T2
CALL @puthex
MOVI r1,@s_m1
CALL @puts
MOVI r1,0
MOVHI r1,8
MOVI r2,0
MOVHI r2,12
CALL @cmpfb
ST r1,r0,#V_T1
CALL @puthex
MOVI r1,@s_m2
CALL @puts
MOVI r1,0
MOVHI r1,10
MOVI r2,0
MOVHI r2,12
CALL @cmpfb
CALL @puthex
LD r2,r0,#V_T1
BOOL.14 r1,r1,r2
CMP r1,r0
MOVI r1,@s_pass
MOVI[NE] r1,@s_fail
CALL @puts
HALT
; cmpfb: r1,r2 = byte addresses of two 64000-byte buffers -> r1 = number of differing bytes
cmpfb:
MOVI r3,0
MOVI r4,0
MOVHI r4,1
MOVI r5,0
cb:
LDB r6,r1,0
LDB r7,r2,0
CMP r6,r7
ADD[NE] r3,r3,r13
ADD r1,r1,r13
ADD r2,r2,r13
ADD r5,r5,r13
MOVI r6,64000
CMP r5,r6
JMP[LT] @cb
BOOL.12 r1,r3,r3
RET
puts:
MOVI r4,255
pw:
LD r2,r1,0
MOVI r3,4
pt1:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @pt1
ADD r1,r1,r13
JMP @pw
puthex:
MOVI r3,8
MOVI r4,10
MOVI r7,7
ph1:
SHR r2,r1,28
SHL r1,r1,4
MOVI r6,48
ADD r6,r6,r2
CMP r2,r4
ADD[GE] r6,r6,r7
PUTC r6
SUB r3,r3,r13
JMP[NE] @ph1
RET
s_banner:
.str "spanbench: 200x320 texture spans, NaNVM1 ops\r\n"
s_t1:
.str "plain    kilo-ops="
s_t2:
.str "\r\nunrolled kilo-ops="
s_m1:
.str "\r\nmismatch plain="
s_m2:
.str " unrolled="
s_pass:
.str "\r\nPASS\r\n"
s_fail:
.str "\r\nFAIL\r\n"
