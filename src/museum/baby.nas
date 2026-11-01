; EXHIBIT: Manchester Baby (SSEM, 21 June 1948) as a NaN16 emulation. 32 x 32-bit store lives in guest memory at SB (each line a NaN word).
; Accumulator r2, CI r1 (pre-incremented before fetch, as on the real machine). Functions: 0 JMP 1 JRP 2 LDN 3 STO 4/5 SUB 6 CMP 7 STP.
.equ SB 6144
.equ PERIOD 8191
baby_start:
CALL @vcls
; static screen
MOVI r1,@bs_title
MOVI r2,0
MOVI r3,0x7000
MOVI r5,0
MOVI r6,0
CALL @vputs
MOVI r1,@bs_labels
MOVI r2,1442
MOVI r3,0x0200
MOVI r5,2
MOVI r6,2
CALL @vputs
MOVI r1,@bs_panel
MOVI r2,198
MOVI r3,0x0F00
MOVI r5,38
MOVI r6,38
CALL @vputs
; load chosen store image (r10 holds image address from the plaque) into SB
MOVI r12,#SB
LD r10,r0,@bs_sel
BOOL.12 r3,r0,r0
bcp:
ADD r6,r3,r10
LD r4,r6,0
ADD r6,r3,r12
ST r4,r6,0
ADD r3,r3,r13
MOVI r5,32
CMP r3,r5
JMP[LT] @bcp
; machine state
MOVI r9,31
MOVI r14,7
MOVI r11,#PERIOD
BOOL.12 r1,r0,r0
BOOL.12 r2,r0,r0
BOOL.12 r10,r0,r0
TICK r3
ST r3,r0,@bs_t0
CALL @brender
bstep:
ADD r1,r1,r13
BOOL.8 r3,r1,r9
ADD r3,r3,r12
LD r3,r3,0
BOOL.8 r4,r3,r9
ADD r7,r4,r12
LD r6,r7,0
SHR r5,r3,13
BOOL.8 r5,r5,r14
LD r5,r5,@jtab
JMPR r5
bh0:
ADD r1,r6,r0
JMP @btick
bh1:
ADD r1,r1,r6
JMP @btick
bh2:
SUB r2,r0,r6
JMP @btick
bh3:
ST r2,r7,0
JMP @btick
bh4:
SUB r2,r2,r6
JMP @btick
bh6:
SHR r5,r2,31
ADD r1,r1,r5
JMP @btick
btick:
ADD r10,r10,r13
BOOL.8 r8,r10,r11
CMP r8,r0
JMP[NE] @bstep
CALL @brender
JMP @bstep
bh7:
; STP: final render, result banner, wait key, back to museum
CALL @brender
LD r1,r12,23
MOVI r2,1158
MOVI r3,0x0E00
CALL @vdec
MOVI r1,@bs_done
MOVI r2,1078
MOVI r3,0x0A00
MOVI r5,38
MOVI r6,38
CALL @vputs
TICK r3
LD r4,r0,@bs_t0
SUB r1,r3,r4
MOVI r4,18
BOOL.12 r5,r0,r0
bsec:
CMP r1,r4
JMP[LT] @bsec2
SUB r1,r1,r4
ADD r5,r5,r13
JMP @bsec
bsec2:
BOOL.12 r1,r5,r5
MOVI r2,1345
MOVI r3,0x0E00
CALL @vdec
KEY r1
JMP @menu
; render: tube + readouts. Preserves r1,r2,r10..r14. Clobbers r3..r9. ESC (polled here) returns to the museum.
brender:
ST r15,r0,@bs15
ST r1,r0,@bs1
ST r2,r0,@bs2
BOOL.12 r3,r0,r0
MOVI r7,162
brow:
SHL r4,r3,1
ADD r4,r4,r12
LD r5,r4,0
LD r6,r4,1
BOOL.12 r8,r0,r0
bcol:
BOOL.8 r9,r5,r13
SHR r5,r5,1
BOOL.8 r4,r6,r13
SHR r6,r6,1
SHL r4,r4,1
ADD r4,r4,r9
LD r4,r4,@chtab
VPOKE r4,r7
ADD r7,r7,r13
ADD r8,r8,r13
MOVI r9,32
CMP r8,r9
JMP[LT] @bcol
MOVI r9,48
ADD r7,r7,r9
ADD r3,r3,r13
MOVI r9,16
CMP r3,r9
JMP[LT] @brow
LD r1,r0,@bs1
MOVI r2,528
MOVI r3,0x0E00
CALL @vhex
LD r1,r0,@bs2
MOVI r2,608
MOVI r3,0x0E00
CALL @vhex
LD r1,r12,23
MOVI r2,688
MOVI r3,0x0E00
CALL @vdec
BOOL.12 r1,r10,r10
MOVI r2,768
MOVI r3,0x0E00
CALL @vdec
KEYQ r3
MOVI r4,255
BOOL.8 r3,r3,r4
MOVI r4,27
CMP r3,r4
JMP[EQ] @menu
LD r1,r0,@bs1
LD r2,r0,@bs2
LD r15,r0,@bs15
MOVI r9,31
RET
bs1:
.word 0
bs2:
.word 0
bs15:
.word 0
bs_t0:
.word 0
bs_sel:
.word 0
jtab:
.word @bh0
.word @bh1
.word @bh2
.word @bh3
.word @bh4
.word @bh4
.word @bh6
.word @bh7
chtab:
.word 0x0A20
.word 0x0ADF
.word 0x0ADC
.word 0x0ADB
bs_title:
.str " MANCHESTER BABY (SSEM) - 21 JUNE 1948 - running as NaN16 words on bare metal  "
bs_labels:
.str "WILLIAMS-KILBURN TUBE: 32 words x 32 bits\nbit 0 at left, two store lines per row\n"
bs_panel:
.str "PROGRAM: highest proper factor of N\nN = line 22 (negated). trial d counts down\n\n\nCI      0x\nA       0x\nTRIAL d   \nSTEPS     \n\nReal Baby: about 1100 instr/s.\nESC = back to museum"
bs_done:
.str "STOPPED. highest proper factor =\n\n\nNaN/0S wall time (seconds) ="
