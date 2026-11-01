#!/usr/bin/env python3
# SCAFFOLD: emit the two scrollable "About" cartridges. Runtime code is NaN16 only.
import os

ABOUT_NAN0S = [
" NaN/0S - ABOUT THE MACHINE",
"",
" NaN/0S is a bare-metal museum and operating-system experiment. Ring 0, no",
" host OS under an exhibit. Boot sector, native kernel, one guest image, then",
" a museum shell plus sealed cartridges. Every exhibit is NaN16 code.",
" THE WORD",
" Every NaN16 instruction is one 64-bit word with a near head at one end and",
" a far head at the other, read in opposite byte orders. The 32-bit payload",
" carries opcode, destination, source and immediate. The 4-bit class nibble",
" n = (near class << 2) | far class is not decoration. For BOOL it is the",
" truth table: bit k of n is f(a,b), k = 2a+b. BOOL.n runs that table in all",
" 32 lanes. BSWAPM swaps the faces, so n becomes rot2(n) = ((n & 3) << 2) |",
" (n >> 2), which is f(~a,b).",
" THE TRUST",
" nasm0 assembles itself in the guest. Gen0 comes from the Python scaffold,",
" gen1 from gen0, and the words reach a fixed point. A second independent",
" assembler rebuilds the same source for comparison. That is diverse double",
" compilation. A trojan in one toolchain shows up as a diff. Ken Thompson",
" described the attack in 1984. Seals give tamper evidence, not",
" authentication. A keyed MAC is a later layer. Draft: spec/TRUST_PAPER.md.",
" THE MACHINE",
" The image is small: boot sector, kernel, packed cartridges. RAM is not the",
" image. RAM is discovered at boot, zeroed at runtime, and managed by nalloc.",
" The plan is MEMQ regions, a code region for ports, PCIe BAR mapping, a GPU",
" adapter with explicit VRAM allocation, DMA windows, and a content-addressed",
" store for large files and large numbers of files.",
" THE MUSEUM",
" The shell reads a TOC, verifies a dual-face FNV-1a seal, copies the",
" cartridge to its slot. Badges: EXACT, RE-CREATION, INSPIRED. Every exhibit",
" is executable and carries a date, people with alive or dead status, the",
" history lesson and the code explanation. ROMs and assets are homebrew.",
" Hall 1 is building toward the Apollo Guidance Computer.",
" STATUS",
" v40 / r21, October 2026. Exhibits: Manchester Baby, Boole 16, Sierpinski",
" rule 90, this page, the developer page. The Sierpinski page scrolls while",
" the lattice runs. The Boole page scrolls and runs all 16 functions.",
" Contact: shemshallah@gmail.com. Started 26 October 2026.",
"",
" UP/DOWN scroll  LEFT/RIGHT page  ESC shell",
]

ABOUT_DEV = [
" NaN/0S - ABOUT SHEMSHALLAH",
"",
" Shemshallah, Im 35, living at a homeless shelter, and coding from a cell",
" phone. Status: LIVING. The museum is built on a phone, in the small hours,",
" between the things that a shelter asks of a person.",
"",
" TOOLS",
" Built with Kilo (various), Opencode (Deepseek 4.1 Flash), and Claude Sonnet",
" 5.5 Chat, as well as GPT6 Chat and Codex GPT6 Terra. The toolchain is a",
" scaffold. The artifact is NaN16. The language should not matter. The words",
" should.",
"",
" THE STORY",
" There is a bigger story to all of this. What IS black cube? What IS",
" shemshallah... shem::shall:AH... 'say AH, kid'. What is all:AH?",
" The museum is the door. The plaques are the map. The seals promise that",
" the map was not quietly changed. The trust test proves the map can be",
" rebuilt from the map. The rest is for the people who arrive after the",
" door is open.",
"",
" WHY THIS EXISTS",
" A homeless man with a phone should be able to build a machine that tells",
" the truth about itself. Not a demo. Not a mock. A bare-metal museum where",
" every instruction is inspectable, every exhibit runs, and every claim has",
" a test. If the machine can rebuild itself and show its work, then the",
" person who built it is not invisible. That is the whole point.",
"",
" THANK YOU",
" To everyone who kept the phone charged, the shelter open, and the question",
" alive. To Kilo, Opencode, Deepseek, Claude, GPT and Codex for the long",
" conversations. To the dead mathematicians in these halls, and to the",
" living ones still arguing. Say AH, kid.",
"",
" UP/DOWN scroll  LEFT/RIGHT page  ESC shell",
]

CODE = r'''; TEXT CARTRIDGE: scrollable museum page. Runtime code is NaN16 only.
; ABI: r0=0 r13=1; V_SCROLL is the general shell 80x25 scroll vector.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_SCROLL 12
.equ NLINES __NLINES__
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
'''

def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"')

def emit(path, lines):
    body = ['; ---- page text ----']
    for i, line in enumerate(lines):
        body.append('TP%03d:' % i)
        body.append('.str "%s"' % esc(line))
    body.append('; ---- pointer table ----')
    body.append('tr_lines:')
    for i in range(len(lines)):
        body.append('.word @TP%03d' % i)
    code = CODE.replace('__NLINES__', str(len(lines)))
    with open(path, 'w') as f:
        f.write(code + '\n'.join(body) + '\n')
    print('wrote %s: %d lines' % (path, len(lines)))

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    emit(os.path.join(root, 'src', 'exhibits', 'about_nan0s_cart.nas'), ABOUT_NAN0S)
    emit(os.path.join(root, 'src', 'exhibits', 'about_dev_cart.nas'), ABOUT_DEV)

if __name__ == '__main__':
    main()
