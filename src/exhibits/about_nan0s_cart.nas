; TEXT CARTRIDGE: scrollable museum page. Runtime code is NaN16 only.
; ABI: r0=0 r13=1; V_SCROLL is the general shell 80x25 scroll vector.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_SCROLL 12
.equ NLINES 39
.equ VISIBLE 24
.org 8192
cart_entry:
ST r15,r0,@tr_ret
MOVI r13,1
MOVI r10,0
CALL @tr_render
tr_poll:
KEY r1
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @tr_exit
MOVI r4,0x80
CMP r1,r4
JMP[EQ] @tr_up
MOVI r4,0x81
CMP r1,r4
JMP[EQ] @tr_down
MOVI r4,0x82
CMP r1,r4
JMP[EQ] @tr_pgup
MOVI r4,0x83
CMP r1,r4
JMP[EQ] @tr_pgdn
JMP @tr_poll
tr_exit:
LD r15,r0,@tr_ret
RET
tr_ret:
.word 0
tr_up:
CMP r10,r0
JMP[EQ] @tr_poll
SUB r10,r10,r13
MOVI r1,0
SUB r1,r1,r13
MOVI r2,0x0720
CALL #V_SCROLL
CALL @tr_clr0
ADD r1,r10,r0
CALL @tr_lineptr
CMP r1,r0
JMP[EQ] @tr_foot
MOVI r2,0
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
JMP @tr_foot
tr_down:
MOVI r4,#NLINES
MOVI r5,#VISIBLE
SUB r4,r4,r5
CMP r10,r4
JMP[GE] @tr_poll
ADD r10,r10,r13
MOVI r1,1
MOVI r2,0x0720
CALL #V_SCROLL
CALL @tr_clr23
ADD r1,r10,r0
MOVI r5,#VISIBLE
SUB r5,r5,r13
ADD r1,r1,r5
CALL @tr_lineptr
CMP r1,r0
JMP[EQ] @tr_foot
MOVI r2,1840
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
JMP @tr_foot
tr_foot:
CALL @tr_footer
JMP @tr_poll
tr_pgup:
MOVI r4,10
CMP r10,r4
JMP[LT] @tr_pgup0
SUB r10,r10,r4
JMP @tr_redraw
tr_pgup0:
MOVI r10,0
JMP @tr_redraw
tr_pgdn:
MOVI r4,#NLINES
MOVI r5,#VISIBLE
SUB r4,r4,r5
MOVI r5,10
ADD r10,r10,r5
CMP r10,r4
JMP[LE] @tr_redraw
ADD r10,r4,r0
JMP @tr_redraw
tr_redraw:
CALL @tr_render
JMP @tr_poll
tr_render:
ST r15,r0,@trr_ret
CALL #V_CLS
MOVI r11,0
trr_loop:
MOVI r4,#VISIBLE
CMP r11,r4
JMP[GE] @trr_foot
ADD r1,r10,r0
ADD r1,r1,r11
CALL @tr_lineptr
CMP r1,r0
JMP[EQ] @trr_foot
MOVI r2,80
MUL r2,r11,r2
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
ADD r11,r11,r13
JMP @trr_loop
trr_foot:
CALL @tr_footer
LD r15,r0,@trr_ret
RET
trr_ret:
.word 0
tr_lineptr:
MOVI r3,#NLINES
CMP r1,r3
JMP[GE] @trl_none
MOVI r3,@tr_lines
ADD r3,r3,r1
LD r1,r3,0
RET
trl_none:
MOVI r1,0
RET
tr_clr0:
MOVI r4,0
MOVI r5,80
MOVI r6,0x0720
JMP @tr_fill
tr_clr23:
MOVI r4,1840
MOVI r5,1920
MOVI r6,0x0720
tr_fill:
CMP r4,r5
JMP[GE] @tr_fill_done
VPOKE r6,r4
ADD r4,r4,r13
JMP @tr_fill
tr_fill_done:
RET
tr_footer:
ST r15,r0,@trf_ret
MOVI r1,@tr_foot_str
MOVI r2,1920
MOVI r3,0x0E00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
ADD r1,r10,r0
ADD r1,r1,r13
MOVI r2,1982
MOVI r3,0x0E00
CALL #V_DEC
LD r15,r0,@trf_ret
RET
trf_ret:
.word 0
tr_foot_str:
.str "UP/DOWN scroll  LEFT/RIGHT page  ESC shell  line "
; ---- page text ----
TP000:
.str " NaN/0S - ABOUT THE MACHINE"
TP001:
.str ""
TP002:
.str " NaN/0S is a bare-metal museum and operating-system experiment. Ring 0, no"
TP003:
.str " host OS under an exhibit. Boot sector, native kernel, one guest image, then"
TP004:
.str " a museum shell plus sealed cartridges. Every exhibit is NaN16 code."
TP005:
.str " THE WORD"
TP006:
.str " Every NaN16 instruction is one 64-bit word with a near head at one end and"
TP007:
.str " a far head at the other, read in opposite byte orders. The 32-bit payload"
TP008:
.str " carries opcode, destination, source and immediate. The 4-bit class nibble"
TP009:
.str " n = (near class << 2) | far class is not decoration. For BOOL it is the"
TP010:
.str " truth table: bit k of n is f(a,b), k = 2a+b. BOOL.n runs that table in all"
TP011:
.str " 32 lanes. BSWAPM swaps the faces, so n becomes rot2(n) = ((n & 3) << 2) |"
TP012:
.str " (n >> 2), which is f(~a,b)."
TP013:
.str " THE TRUST"
TP014:
.str " nasm0 assembles itself in the guest. Gen0 comes from the Python scaffold,"
TP015:
.str " gen1 from gen0, and the words reach a fixed point. A second independent"
TP016:
.str " assembler rebuilds the same source for comparison. That is diverse double"
TP017:
.str " compilation. A trojan in one toolchain shows up as a diff. Ken Thompson"
TP018:
.str " described the attack in 1984. Seals give tamper evidence, not"
TP019:
.str " authentication. A keyed MAC is a later layer. Draft: spec/TRUST_PAPER.md."
TP020:
.str " THE MACHINE"
TP021:
.str " The image is small: boot sector, kernel, packed cartridges. RAM is not the"
TP022:
.str " image. RAM is discovered at boot, zeroed at runtime, and managed by nalloc."
TP023:
.str " The plan is MEMQ regions, a code region for ports, PCIe BAR mapping, a GPU"
TP024:
.str " adapter with explicit VRAM allocation, DMA windows, and a content-addressed"
TP025:
.str " store for large files and large numbers of files."
TP026:
.str " THE MUSEUM"
TP027:
.str " The shell reads a TOC, verifies a dual-face FNV-1a seal, copies the"
TP028:
.str " cartridge to its slot. Badges: EXACT, RE-CREATION, INSPIRED. Every exhibit"
TP029:
.str " is executable and carries a date, people with alive or dead status, the"
TP030:
.str " history lesson and the code explanation. ROMs and assets are homebrew."
TP031:
.str " Hall 1 is building toward the Apollo Guidance Computer."
TP032:
.str " STATUS"
TP033:
.str " v40 / r21, October 2026. Exhibits: Manchester Baby, Boole 16, Sierpinski"
TP034:
.str " rule 90, this page, the developer page. The Sierpinski page scrolls while"
TP035:
.str " the lattice runs. The Boole page scrolls and runs all 16 functions."
TP036:
.str " Contact: shemshallah@gmail.com. Started 26 October 2026."
TP037:
.str ""
TP038:
.str " UP/DOWN scroll  LEFT/RIGHT page  ESC shell"
; ---- pointer table ----
tr_lines:
.word @TP000
.word @TP001
.word @TP002
.word @TP003
.word @TP004
.word @TP005
.word @TP006
.word @TP007
.word @TP008
.word @TP009
.word @TP010
.word @TP011
.word @TP012
.word @TP013
.word @TP014
.word @TP015
.word @TP016
.word @TP017
.word @TP018
.word @TP019
.word @TP020
.word @TP021
.word @TP022
.word @TP023
.word @TP024
.word @TP025
.word @TP026
.word @TP027
.word @TP028
.word @TP029
.word @TP030
.word @TP031
.word @TP032
.word @TP033
.word @TP034
.word @TP035
.word @TP036
.word @TP037
.word @TP038
