#!/usr/bin/env python3
# SCAFFOLD: emit src/exhibits/boole_cart.nas from the curated plaque line list.
# The emitted program itself is NaN16 only. This generator exists so the line
# table and the text can never drift apart, and so the museum text is easy to audit.
import os

LINES = [
" NaN/0S  BOOLE - THE LAWS OF THOUGHT - 1854",
" A NAN/0S MUSEUM EXHIBIT IN THE SPIRIT OF GEORGE BOOLE",
"",
" THE MAN",
" George Boole was born 2 November 1815 in Lincoln, Lincolnshire,",
" England, the son of a shoemaker and amateur optical instrument maker.",
" He left school at 16, taught, and taught himself mathematics from",
" books he borrowed. He never took a university degree as a student.",
" In 1849 he became the first professor of mathematics at Queen's",
" College, Cork, in Ireland, now University College Cork. He married",
" Mary Everest in 1855. He died on 8 December 1864 in Ballintemple,",
" Cork, aged 49, after a feverish illness. Status: DEAD.",
"",
" THE BOOKS",
" 1847: The Mathematical Analysis of Logic.",
" 1854: An Investigation of the Laws of Thought, on Which are Founded",
" the Mathematical Theories of Logic and Probabilities.",
" Boole wrote logic as algebra over the values 0 and 1. If x means",
" the class of things with property x, then x*y means both, 1-x means",
" not x, and x+y means either, when the classes do not overlap. He",
" turned reasoning into calculation. He did not use the truth-table",
" picture we use today, and his algebra was not yet a circuit diagram.",
"",
" THE TABLE",
" Two inputs a and b have four possible rows: 00, 01, 10, 11.",
" A two-input Boolean function must choose an output for each row, so",
" there are exactly 2^4 = 16 functions. Give each output pattern the",
" nibble n whose bit k is f(a,b) for k = 2*a+b. Then n itself is the",
" function. n=8 is AND, n=14 is OR, n=6 is XOR, n=7 is NAND, n=1 is",
" NOR, n=15 is TRUE, n=0 is FALSE. Every digital gate is one of these.",
" NAND and NOR alone can build any of the other 14, so either one is",
" universal. That is the table that made logic design mechanical.",
" IEEE header order needs PERM 0,1,2,3,8,9,10,11,4,5,6,7,12..15.",
" In NaN16 the class nibble is already n, so PERM is the identity.",
"",
" WHY IT MATTERED",
" Claude Shannon (1916-2001, DEAD) showed in his 1937 master's thesis,",
" published in 1938, that Boolean algebra describes relay switching",
" circuits. A closed contact can be 1 and an open contact 0, series is",
" AND, parallel is OR, and a relay contact can invert. From there came",
" logic gates, adders, instruction decoders, bitwise ALU operations,",
" memory address decoding, and essentially every CPU. Boole died long",
" before electronics. His two-value algebra became the language of it.",
"",
" THE NAN MAPPING",
" Every NaN16 instruction is one 64-bit word: near head, 32-bit payload,",
" far head. The near head is read little-endian from bytes 6 and 7. The",
" far head is read big-endian from bytes 0 and 1. Payload bytes 2..5 are",
" the opcode. The 4-bit class nibble n = (near class << 2) | far class.",
" For the BOOL op, n IS the truth table. BOOL.n d,a,b computes bit k of",
" the result from bit k of a and bit k of b through function n. It does",
" this independently in all 32 bit lanes. There is no lookup table and",
" no branch: the opcode nibble is the function. In this exhibit we write",
" BOOL.n into a code slot at run time, run it on a=CCCCCCCC and",
" b=AAAAAAAA, and every lane must return n, because n*0x11111111 is n",
" repeated in all eight nibbles. The result is not a coincidence: it is",
" the truth table executing itself.",
"",
" DOUBLE ENDIANNESS",
" A NaN16 word has two heads, one at each end, read in opposite byte",
" orders. The same 8 bytes therefore carry a near face and a far face.",
" BSWAPM reverses all 8 bytes, so it swaps the faces. For a BOOL word",
" with class n, the far face becomes rot2(n) = ((n & 3) << 2) | (n >> 2).",
" That is exactly f(~a,b): complement a and swap the input rows. The",
" mirror law BOOL.rot2(n)(a,b) = BOOL.n(~a,b) must hold. The seal checks",
" both faces, both payload hashes, and a class channel, so a word that",
" is legal on one face but lies on the other is refused. Endianness is",
" not a convention here. It is a second, independent view of every word.",
"",
" LIVING WORD LAB",
" The XOR word below has class n=6. Before BSWAPM the near face reads",
" n=6 and payload 00310002. After BSWAPM the near face reads n=9 and",
" payload 02003100. n=9 is XNOR, the complement-row twin of XOR. Both",
" faces are real. Both are checked. Both are part of the exhibit.",
"",
" WHAT THIS EXHIBIT DOES",
" [1] runs all 16 functions live and checks every lane and the mirror",
" law. [UP] and [DOWN] scroll this plaque one line. [LEFT] and [RIGHT]",
" move ten lines. [ESC] returns to the museum shell. The plaque, the",
" live table, and the word lab are all NaN16 code, assembled from",
" mnemonics by the NaN toolchain and sealed into cartridge 2.",
"",
" PEOPLE",
" George Boole 1815-1864 DEAD. Mary Everest Boole 1832-1916 DEAD,",
" mathematician and educational writer, his wife. Alicia Boole Stott",
" 1860-1940 DEAD, his daughter, known for four-dimensional polytopes.",
" Claude Shannon 1916-2001 DEAD. Augustus De Morgan 1806-1871 DEAD,",
" logician and Boole's correspondent. William Stanley Jevons 1835-1882",
" DEAD, built one of the first logic machines. Charles Sanders Peirce",
" 1839-1914 DEAD, extended Boolean algebra and truth-table ideas.",
"",
" SOURCES",
" Boole, The Mathematical Analysis of Logic (1847).",
" Boole, An Investigation of the Laws of Thought (1854).",
" Shannon, A Symbolic Analysis of Relay and Switching Circuits (1937",
" thesis, 1938 Trans. AIEE). Spec: NAN16_SPEC.md, NANVM1_SPEC.md.",
" This plaque is a modern reading. Badge: INSPIRED, not a copy of",
" Boole's notation and not a reconstruction of a historical machine.",
"",
" [1] live table   [UP/DOWN] scroll   [LEFT/RIGHT] page   [ESC] shell",
]

CODE = r'''; EXHIBIT CARTRIDGE: Boole - The Laws of Thought (1854), "16 functions, live".
; Badge: INSPIRED (modern truth-table reading of a 2-value logic; not Boole's own notation).
; Written ONLY in NaN16 (assembled by nanchk/nasm0 to dual-endian words). Packed as TOC entry 2
; by tools/mkimg1.py --cart auto:src/exhibits/boole_cart.nas
; ABI: r0=0, r13=1; lib via CALL #V_* clobbers r3..r9,r15 (and r1,r2 are consumed).
; Survivors across lib calls: r10,r11,r12,r14. Entry saves r15, exit restores it, then RET.
; Pager state: r10 = first visible plaque line. V_SCROLL is the general shell
; 80x25 scroll vector (vector 12): r1 = signed lines (+ up, - down), r2 = fill cell.
; Idea: the class nibble n of a BOOL word IS its truth table (bit k of n = f(a,b), k=2a+b).
; We assemble BOOL.n at run time (STW class n into a code slot), run it on
; a=CCCCCCCC b=AAAAAAAA, and the 32-lane result must be n*0x11111111. Mirror law:
; BOOL.rot2(n)(a,b) == BOOL.n(~a,b), rot2(n)=((n&3)<<2)|(n>>2) (what BSWAPM does to a word).
.equ SLOT 8192
.equ V_PUTS 1
.equ V_HEX 2
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_SCROLL 12
.equ NLINES 98
.equ VISIBLE 24
.org 8192
cart_entry:
ST r15,r0,@bl_ret
MOVI r13,1
MOVI r10,0
CALL @bl_render
bl_poll:
KEY r1
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @bl_exit
MOVI r4,0x80
CMP r1,r4
JMP[EQ] @bl_up
MOVI r4,0x81
CMP r1,r4
JMP[EQ] @bl_down
MOVI r4,0x82
CMP r1,r4
JMP[EQ] @bl_pgup
MOVI r4,0x83
CMP r1,r4
JMP[EQ] @bl_pgdn
MOVI r4,49
CMP r1,r4
JMP[EQ] @bl_run
JMP @bl_poll
bl_exit:
LD r15,r0,@bl_ret
RET
bl_ret:
.word 0
bl_save:
.word 0
; ---- scroll up one line: scroll the plane down, draw the new top line ----
bl_up:
CMP r10,r0
JMP[EQ] @bl_poll
SUB r10,r10,r13
MOVI r1,0
SUB r1,r1,r13
MOVI r2,0x0720
CALL #V_SCROLL
CALL @bl_clr0
ADD r1,r10,r0
CALL @bl_lineptr
CMP r1,r0
JMP[EQ] @bl_foot
MOVI r2,0
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
JMP @bl_foot
; ---- scroll down one line: scroll the plane up, draw the new bottom line ----
bl_down:
MOVI r4,#NLINES
MOVI r5,#VISIBLE
SUB r4,r4,r5
CMP r10,r4
JMP[GE] @bl_poll
ADD r10,r10,r13
MOVI r1,1
MOVI r2,0x0720
CALL #V_SCROLL
CALL @bl_clr23
ADD r1,r10,r0
MOVI r5,#VISIBLE
SUB r5,r5,r13
ADD r1,r1,r5
CALL @bl_lineptr
CMP r1,r0
JMP[EQ] @bl_foot
MOVI r2,1840
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
JMP @bl_foot
bl_foot:
CALL @bl_footer
JMP @bl_poll
; ---- page up / page down (ten lines) ----
bl_pgup:
MOVI r4,10
CMP r10,r4
JMP[LT] @bl_pgup0
SUB r10,r10,r4
JMP @bl_redraw
bl_pgup0:
MOVI r10,0
JMP @bl_redraw
bl_pgdn:
MOVI r4,#NLINES
MOVI r5,#VISIBLE
SUB r4,r4,r5
MOVI r5,10
ADD r10,r10,r5
CMP r10,r4
JMP[LE] @bl_redraw
ADD r10,r4,r0
JMP @bl_redraw
bl_redraw:
CALL @bl_render
JMP @bl_poll
; ---- render one page: 24 plaque lines + status footer on row 24 ----
bl_render:
ST r15,r0,@br_ret
CALL #V_CLS
MOVI r11,0
br_loop:
MOVI r4,#VISIBLE
CMP r11,r4
JMP[GE] @br_foot
ADD r1,r10,r0
ADD r1,r1,r11
CALL @bl_lineptr
CMP r1,r0
JMP[EQ] @br_foot
MOVI r2,80
MUL r2,r11,r2
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
ADD r11,r11,r13
JMP @br_loop
br_foot:
CALL @bl_footer
LD r15,r0,@br_ret
RET
br_ret:
.word 0
; ---- line pointer table lookup: in r1 = line index, out r1 = string ptr or 0 ----
bl_lineptr:
MOVI r3,#NLINES
CMP r1,r3
JMP[GE] @blp_none
MOVI r3,@bl_lines
ADD r3,r3,r1
LD r1,r3,0
RET
blp_none:
MOVI r1,0
RET
; ---- clear row 0 (cells 0..79) or row 23 (cells 1840..1919) ----
bl_clr0:
MOVI r4,0
MOVI r5,80
MOVI r6,0x0720
JMP @bl_fill
bl_clr23:
MOVI r4,1840
MOVI r5,1920
MOVI r6,0x0720
bl_fill:
CMP r4,r5
JMP[GE] @bl_fill_done
VPOKE r6,r4
ADD r4,r4,r13
JMP @bl_fill
bl_fill_done:
RET
; ---- footer: controls + first visible line number ----
bl_footer:
ST r15,r0,@blf_ret
MOVI r1,@s_footer
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
LD r15,r0,@blf_ret
RET
blf_ret:
.word 0
; ---- live table: 16 functions, every lane, mirror law, then the word lab ----
bl_run:
ST r10,r0,@bl_save
CALL #V_CLS
MOVI r1,@s_title
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@s_head
MOVI r2,160
MOVI r3,0x0E00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
BOOL.12 r12,r0,r0
BOOL.12 r14,r0,r0
bl_row:
SHL r4,r12,6
SHL r5,r12,4
ADD r11,r4,r5
MOVI r4,240
ADD r11,r11,r4
BOOL.12 r1,r12,r12
BOOL.12 r2,r11,r11
MOVI r3,0x0E00
CALL #V_DEC
LD r1,r12,@bl_names
MOVI r2,4
ADD r2,r2,r11
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r5,r0,@bl_a
LD r6,r0,@bl_b
BOOL.12 r2,r12,r12
CALL @bl_exec
BOOL.12 r10,r4,r4
BOOL.12 r1,r10,r10
MOVI r2,20
ADD r2,r2,r11
MOVI r3,0x0A00
CALL #V_HEX
SHL r5,r12,4
BOOL.14 r5,r5,r12
SHL r6,r5,8
BOOL.14 r5,r5,r6
SHL r6,r5,16
BOOL.14 r5,r5,r6
ST r5,r0,@bl_exp
BOOL.12 r1,r5,r5
MOVI r2,31
ADD r2,r2,r11
MOVI r3,0x0700
CALL #V_HEX
LD r5,r0,@bl_exp
CMP r10,r5
MOVI r1,@s_ok
MOVI[NE] r1,@s_bad
MOVI r3,0x0A00
MOVI[NE] r3,0x0C00
ADD[NE] r14,r14,r13
MOVI r2,42
ADD r2,r2,r11
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r4,3
BOOL.8 r2,r12,r4
SHL r2,r2,2
SHR r4,r12,2
BOOL.14 r2,r2,r4
LD r5,r0,@bl_a
LD r6,r0,@bl_b
CALL @bl_exec
BOOL.12 r10,r4,r4
BOOL.12 r2,r12,r12
LD r5,r0,@bl_na
LD r6,r0,@bl_b
CALL @bl_exec
CMP r4,r10
MOVI r1,@s_ok
MOVI[NE] r1,@s_bad
MOVI r3,0x0A00
MOVI[NE] r3,0x0C00
ADD[NE] r14,r14,r13
MOVI r2,50
ADD r2,r2,r11
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
ADD r12,r12,r13
MOVI r4,16
CMP r12,r4
JMP[LT] @bl_row
CMP r14,r0
MOVI r1,@s_allok
MOVI[NE] r1,@s_allbad
MOVI r3,0x0A00
MOVI[NE] r3,0x0C00
MOVI r2,1600
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r6,@bl_demo
MOVI r7,2
MOVHI r7,0x0031
MOVI r3,6
STW r7,r6,r3
LDN r10,r6,0
LD r11,r6,0
BSWAPM r6,0
LDN r12,r6,0
LD r14,r6,0
MOVI r1,@s_w1
MOVI r2,1760
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
BOOL.12 r1,r10,r10
MOVI r2,1779
MOVI r3,0x0E00
CALL #V_DEC
BOOL.12 r1,r11,r11
MOVI r2,1782
MOVI r3,0x0A00
CALL #V_HEX
MOVI r1,@s_w2
MOVI r2,1840
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
BOOL.12 r1,r12,r12
MOVI r2,1857
MOVI r3,0x0E00
CALL #V_DEC
BOOL.12 r1,r14,r14
MOVI r2,1860
MOVI r3,0x0A00
CALL #V_HEX
MOVI r1,@s_foot
MOVI r2,1920
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
KEY r1
LD r10,r0,@bl_save
JMP @bl_redraw
; ---- bl_exec: r2=class n, r5=a, r6=b -> r4 = BOOL.n(a,b). Assembles the BOOL word at run time (class n by STW) and runs it. ----
bl_exec:
ST r15,r0,@bl_lr
MOVI r7,6
MOVHI r7,0x0045
MOVI r8,@bl_slot
STW r7,r8,r2
bl_slot:
BOOL.0 r4,r5,r6
LD r15,r0,@bl_lr
RET
bl_lr:
.word 0
bl_exp:
.word 0
bl_demo:
.word 0
bl_a:
.word 0xCCCCCCCC
bl_b:
.word 0xAAAAAAAA
bl_na:
.word 0x33333333
s_ok:
.str "ok"
s_bad:
.str "BAD"
s_title:
.str " BOOLE 16: all two-input functions built and run live (a=CCCCCCCC b=AAAAAAAA)"
s_head:
.str "n   function        result     n*11111111 lane    mirror"
s_allok:
.str "ALL 16 ok: BOOL.n(a,b) = n per nibble, BOOL.rot2(n)(a,b) = BOOL.n(~a,b)"
s_allbad:
.str "FAILURES: see BAD above - the class nibble is not acting as the truth table"
s_w1:
.str "XOR word: class n="
s_w2:
.str "after BSWAPM: n="
s_foot:
.str " class nibble = truth table. BSWAPM swaps faces: n -> rot2(n).  [any key] back"
s_footer:
.str "UP/DOWN line  LEFT/RIGHT page  [1] live  ESC shell  line "
bl_names:
.word @n0
.word @n1
.word @n2
.word @n3
.word @n4
.word @n5
.word @n6
.word @n7
.word @n8
.word @n9
.word @n10
.word @n11
.word @n12
.word @n13
.word @n14
.word @n15
n0:
.str "FALSE"
n1:
.str "NOR"
n2:
.str "NOT a AND b"
n3:
.str "NOT a"
n4:
.str "a AND NOT b"
n5:
.str "NOT b"
n6:
.str "XOR"
n7:
.str "NAND"
n8:
.str "AND"
n9:
.str "XNOR"
n10:
.str "b"
n11:
.str "a IMPLIES b"
n12:
.str "a"
n13:
.str "b IMPLIES a"
n14:
.str "OR"
n15:
.str "TRUE"
'''


def esc(s):
    return s.replace('\\', '\\\\').replace('"', '\\"')


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, 'src', 'exhibits', 'boole_cart.nas')
    body = []
    body.append('; ---- plaque text: one .str per line, each starts on a guest word boundary ----')
    for i, line in enumerate(LINES):
        body.append('PL%03d:' % i)
        body.append('.str "%s"' % esc(line))
    body.append('; ---- 32-bit pointer table indexed by plaque line ----')
    body.append('bl_lines:')
    for i in range(len(LINES)):
        body.append('.word @PL%03d' % i)
    text = CODE + '\n'.join(body) + '\n'
    with open(out, 'w') as f:
        f.write(text)
    print('wrote %s: %d plaque lines, %d bytes' % (out, len(LINES), len(text)))


if __name__ == '__main__':
    main()
