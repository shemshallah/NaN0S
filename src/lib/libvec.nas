; NaN/0S lib behind the fixed jump-vector table (round 17 ABI).
; Vector table at guest words 1-31 (word 0 = shell entry JMP).
; Exhibits call lib via CALL @vector_N. Vector N contains JMP @lib_routine_N.
; Lib RETs back to the exhibit. Exhibits assemble independently with .org at SLOT.
; r0=0, r13=1, r14=SP, r15=link. Lib clobbers r3..r9 and r15 only.

.equ SLOT 4096          ; exhibit load/run address (fixed for all exhibits)

; ---- lib routines ----

; vputs: r1=string addr, r2=cell, r3=attr<<8, r5=col, r6=margin
lib_vputs:
vw:
LD r4,r1,0
MOVI r9,4
vc:
MOVI r8,255
BOOL.8 r7,r4,r8
CMP r7,r0
RET[EQ]
MOVI r8,10
CMP r7,r8
JMP[EQ] @vnl
BOOL.14 r8,r7,r3
VPOKE r8,r2
ADD r2,r2,r13
ADD r5,r5,r13
JMP @vnx
vnl:
SUB r2,r2,r5
ADD r2,r2,r6
MOVI r8,80
ADD r2,r2,r8
BOOL.12 r5,r6,r6
vnx:
SHR r4,r4,8
SUB r9,r9,r13
JMP[NE] @vc
ADD r1,r1,r13
JMP @vw

; vhex: r1=value, r2=cell, r3=attr<<8 -> 8 hex digits
lib_vhex:
MOVI r9,8
MOVI r4,10
MOVI r7,7
vh1:
SHR r5,r1,28
SHL r1,r1,4
MOVI r6,48
ADD r6,r6,r5
CMP r5,r4
ADD[GE] r6,r6,r7
BOOL.14 r6,r6,r3
VPOKE r6,r2
ADD r2,r2,r13
SUB r9,r9,r13
JMP[NE] @vh1
RET

; vdec: r1=value, r2=cell, r3=attr<<8 -> decimal
lib_vdec:
MOVI r8,0
MOVI r9,0
vd1:
LD r5,r8,@pw10
MOVI r6,0
vd2:
CMP r1,r5
JMP[LT] @vd3
SUB r1,r1,r5
ADD r6,r6,r13
JMP @vd2
vd3:
BOOL.14 r9,r9,r6
MOVI r7,9
CMP r8,r7
ADD[EQ] r9,r9,r13
CMP r9,r0
JMP[EQ] @vd4
MOVI r7,48
ADD r6,r6,r7
BOOL.14 r6,r6,r3
VPOKE r6,r2
ADD r2,r2,r13
vd4:
ADD r8,r8,r13
MOVI r7,10
CMP r8,r7
JMP[LT] @vd1
RET
pw10:
.word 1000000000
.word 100000000
.word 10000000
.word 1000000
.word 100000
.word 10000
.word 1000
.word 100
.word 10
.word 1

; vcls: clear screen
lib_vcls:
MOVI r3,3
DISPSET r3
RET

; key: blocking KEY -> r1
lib_key:
KEY r1
RET

; keyq: non-blocking KEYQ -> r1
lib_keyq:
KEYQ r1
RET

; tick: r1 = TICK
lib_tick:
TICK r1
RET

; putc: PUTC r1
lib_putc:
PUTC r1
RET

; bcopy: r1=src, r2=dst, r3=count (words)
lib_bcopy:
BCOPY r1,r2,r3
RET

; seal_verify: r1=addr, r2=length -> r1=1 OK / 0 BAD
lib_seal_verify:
; SEAL v2 (dual-face). In: r1=addr r2=len words r10=TOC entry (reads words 4,8,10,11). Out: r1 = 1 OK | 0 seal mismatch | 2 illegal head (gate) | 3 mirror law broken; r2 = failing word index (2,3).
; Per word: LDN gate check (FFFFFFFF = bad head); A=FNV1a/32 of near payload; B=FNV1a/32 of the FAR-face payload (BSWAPM, read, BSWAPM back); C=rol4(C)^class nibble n.
; Mirror law checked per word: far payload == bswap32(near payload) and far class == rot2(near class). Clobbers r1..r9,r11,r12.
MOVI r3,0x9DC5
MOVI r8,0x811C
SHL r8,r8,16
BOOL.14 r3,r3,r8
BOOL.12 r4,r3,r3
MOVI r5,0
MOVI r11,0x0193
MOVI r8,0x0100
SHL r8,r8,16
ADD r11,r11,r8
sv1:
CMP r2,r0
JMP[EQ] @sv9
LDN r7,r1,0
MOVI r8,16
CMP r7,r8
JMP[GE] @sv_gate
LD r6,r1,0
SHL r8,r5,4
SHR r9,r5,28
BOOL.14 r5,r8,r9
BOOL.6 r5,r5,r7
BOOL.6 r3,r3,r6
MUL r3,r3,r11
BSWAPM r1,0
LD r8,r1,0
LDN r9,r1,0
BSWAPM r1,0
MOVI r12,3
BOOL.8 r12,r7,r12
SHL r12,r12,2
SHR r7,r7,2
BOOL.14 r7,r7,r12
CMP r7,r9
JMP[NE] @sv_mir
MOVI r12,255
BOOL.8 r7,r6,r12
SHL r7,r7,24
MOVI r9,0xFF00
BOOL.8 r12,r6,r9
SHL r12,r12,8
BOOL.14 r7,r7,r12
SHR r12,r6,8
BOOL.8 r12,r12,r9
BOOL.14 r7,r7,r12
SHR r12,r6,24
BOOL.14 r7,r7,r12
CMP r7,r8
JMP[NE] @sv_mir
BOOL.6 r4,r4,r8
MUL r4,r4,r11
ADD r1,r1,r13
SUB r2,r2,r13
JMP @sv1
sv9:
LD r8,r10,8
CMP r3,r8
JMP[NE] @sv_bad
LD r8,r10,10
CMP r4,r8
JMP[NE] @sv_bad
LD r8,r10,11
CMP r5,r8
JMP[NE] @sv_bad
MOVI r1,1
RET
sv_bad:
MOVI r1,0
MOVI r2,0
RET
sv_gate:
LD r8,r10,4
SUB r2,r1,r8
MOVI r1,2
RET
sv_mir:
LD r8,r10,4
SUB r2,r1,r8
MOVI r1,3
RET

; seal_show: display seal info
lib_seal_show:
RET

; vscroll: general shell scroll. In: r1 = signed lines (+ up, - down),
; r2 = fill cell (attr<<8 | char; 0 means 0x0720, white space on black).
; Scrolls the 80x25 VGA text plane one cell at a time using only VPEEK/VPOKE.
; Preserves r1, r2 and the exhibit's r10..r14. Clobbers r3..r9, r15.
lib_vscroll:
MOVI r3,0
CMP r2,r0
JMP[NE] @vs_have_fill
MOVI r3,0x0720
JMP @vs_fill_ready
vs_have_fill:
BOOL.12 r3,r2,r2
vs_fill_ready:
CMP r1,r0
RET[EQ]
JMP[LT] @vs_down
; ---- scroll up: move rows (n..24) to (0..24-n), clear the last n rows ----
MOVI r4,80
MUL r4,r1,r4              ; r4 = n * 80
MOVI r5,0                 ; dst cell
MOVI r6,2000
SUB r6,r6,r4              ; count = 2000 - n*80
vs_up_copy:
CMP r6,r0
JMP[EQ] @vs_up_clear
VPEEK r7,r4
VPOKE r7,r5
ADD r4,r4,r13
ADD r5,r5,r13
SUB r6,r6,r13
JMP @vs_up_copy
vs_up_clear:
MOVI r6,2000
vs_up_cloop:
CMP r5,r6
JMP[GE] @vs_done
VPOKE r3,r5
ADD r5,r5,r13
JMP @vs_up_cloop
; ---- scroll down: move rows (0..24-n) to (n..24), clear the first n rows ----
vs_down:
MOVI r4,0
SUB r4,r4,r1              ; r4 = -n
MOVI r6,80
MUL r4,r4,r6              ; r4 = (-n) * 80
MOVI r5,1999              ; dst = last cell
MOVI r6,2000
SUB r6,r6,r4              ; count = 2000 - (-n)*80
MOVI r7,1999
SUB r7,r7,r4              ; src = last cell - (-n)*80
vs_dn_copy:
CMP r6,r0
JMP[EQ] @vs_dn_clear
VPEEK r8,r7
VPOKE r8,r5
SUB r7,r7,r13
SUB r5,r5,r13
SUB r6,r6,r13
JMP @vs_dn_copy
vs_dn_clear:
MOVI r5,0
vs_dn_cloop:
CMP r5,r4
JMP[GE] @vs_done
VPOKE r3,r5
ADD r5,r5,r13
JMP @vs_dn_cloop
vs_done:
RET
