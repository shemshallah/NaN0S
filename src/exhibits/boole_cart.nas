; EXHIBIT CARTRIDGE: Boole - The Laws of Thought (1854), "16 functions, live".
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
; ---- plaque text: one .str per line, each starts on a guest word boundary ----
PL000:
.str " NaN/0S  BOOLE - THE LAWS OF THOUGHT - 1854"
PL001:
.str " A NAN/0S MUSEUM EXHIBIT IN THE SPIRIT OF GEORGE BOOLE"
PL002:
.str ""
PL003:
.str " THE MAN"
PL004:
.str " George Boole was born 2 November 1815 in Lincoln, Lincolnshire,"
PL005:
.str " England, the son of a shoemaker and amateur optical instrument maker."
PL006:
.str " He left school at 16, taught, and taught himself mathematics from"
PL007:
.str " books he borrowed. He never took a university degree as a student."
PL008:
.str " In 1849 he became the first professor of mathematics at Queen's"
PL009:
.str " College, Cork, in Ireland, now University College Cork. He married"
PL010:
.str " Mary Everest in 1855. He died on 8 December 1864 in Ballintemple,"
PL011:
.str " Cork, aged 49, after a feverish illness. Status: DEAD."
PL012:
.str ""
PL013:
.str " THE BOOKS"
PL014:
.str " 1847: The Mathematical Analysis of Logic."
PL015:
.str " 1854: An Investigation of the Laws of Thought, on Which are Founded"
PL016:
.str " the Mathematical Theories of Logic and Probabilities."
PL017:
.str " Boole wrote logic as algebra over the values 0 and 1. If x means"
PL018:
.str " the class of things with property x, then x*y means both, 1-x means"
PL019:
.str " not x, and x+y means either, when the classes do not overlap. He"
PL020:
.str " turned reasoning into calculation. He did not use the truth-table"
PL021:
.str " picture we use today, and his algebra was not yet a circuit diagram."
PL022:
.str ""
PL023:
.str " THE TABLE"
PL024:
.str " Two inputs a and b have four possible rows: 00, 01, 10, 11."
PL025:
.str " A two-input Boolean function must choose an output for each row, so"
PL026:
.str " there are exactly 2^4 = 16 functions. Give each output pattern the"
PL027:
.str " nibble n whose bit k is f(a,b) for k = 2*a+b. Then n itself is the"
PL028:
.str " function. n=8 is AND, n=14 is OR, n=6 is XOR, n=7 is NAND, n=1 is"
PL029:
.str " NOR, n=15 is TRUE, n=0 is FALSE. Every digital gate is one of these."
PL030:
.str " NAND and NOR alone can build any of the other 14, so either one is"
PL031:
.str " universal. That is the table that made logic design mechanical."
PL032:
.str " IEEE header order needs PERM 0,1,2,3,8,9,10,11,4,5,6,7,12..15."
PL033:
.str " In NaN16 the class nibble is already n, so PERM is the identity."
PL034:
.str ""
PL035:
.str " WHY IT MATTERED"
PL036:
.str " Claude Shannon (1916-2001, DEAD) showed in his 1937 master's thesis,"
PL037:
.str " published in 1938, that Boolean algebra describes relay switching"
PL038:
.str " circuits. A closed contact can be 1 and an open contact 0, series is"
PL039:
.str " AND, parallel is OR, and a relay contact can invert. From there came"
PL040:
.str " logic gates, adders, instruction decoders, bitwise ALU operations,"
PL041:
.str " memory address decoding, and essentially every CPU. Boole died long"
PL042:
.str " before electronics. His two-value algebra became the language of it."
PL043:
.str ""
PL044:
.str " THE NAN MAPPING"
PL045:
.str " Every NaN16 instruction is one 64-bit word: near head, 32-bit payload,"
PL046:
.str " far head. The near head is read little-endian from bytes 6 and 7. The"
PL047:
.str " far head is read big-endian from bytes 0 and 1. Payload bytes 2..5 are"
PL048:
.str " the opcode. The 4-bit class nibble n = (near class << 2) | far class."
PL049:
.str " For the BOOL op, n IS the truth table. BOOL.n d,a,b computes bit k of"
PL050:
.str " the result from bit k of a and bit k of b through function n. It does"
PL051:
.str " this independently in all 32 bit lanes. There is no lookup table and"
PL052:
.str " no branch: the opcode nibble is the function. In this exhibit we write"
PL053:
.str " BOOL.n into a code slot at run time, run it on a=CCCCCCCC and"
PL054:
.str " b=AAAAAAAA, and every lane must return n, because n*0x11111111 is n"
PL055:
.str " repeated in all eight nibbles. The result is not a coincidence: it is"
PL056:
.str " the truth table executing itself."
PL057:
.str ""
PL058:
.str " DOUBLE ENDIANNESS"
PL059:
.str " A NaN16 word has two heads, one at each end, read in opposite byte"
PL060:
.str " orders. The same 8 bytes therefore carry a near face and a far face."
PL061:
.str " BSWAPM reverses all 8 bytes, so it swaps the faces. For a BOOL word"
PL062:
.str " with class n, the far face becomes rot2(n) = ((n & 3) << 2) | (n >> 2)."
PL063:
.str " That is exactly f(~a,b): complement a and swap the input rows. The"
PL064:
.str " mirror law BOOL.rot2(n)(a,b) = BOOL.n(~a,b) must hold. The seal checks"
PL065:
.str " both faces, both payload hashes, and a class channel, so a word that"
PL066:
.str " is legal on one face but lies on the other is refused. Endianness is"
PL067:
.str " not a convention here. It is a second, independent view of every word."
PL068:
.str ""
PL069:
.str " LIVING WORD LAB"
PL070:
.str " The XOR word below has class n=6. Before BSWAPM the near face reads"
PL071:
.str " n=6 and payload 00310002. After BSWAPM the near face reads n=9 and"
PL072:
.str " payload 02003100. n=9 is XNOR, the complement-row twin of XOR. Both"
PL073:
.str " faces are real. Both are checked. Both are part of the exhibit."
PL074:
.str ""
PL075:
.str " WHAT THIS EXHIBIT DOES"
PL076:
.str " [1] runs all 16 functions live and checks every lane and the mirror"
PL077:
.str " law. [UP] and [DOWN] scroll this plaque one line. [LEFT] and [RIGHT]"
PL078:
.str " move ten lines. [ESC] returns to the museum shell. The plaque, the"
PL079:
.str " live table, and the word lab are all NaN16 code, assembled from"
PL080:
.str " mnemonics by the NaN toolchain and sealed into cartridge 2."
PL081:
.str ""
PL082:
.str " PEOPLE"
PL083:
.str " George Boole 1815-1864 DEAD. Mary Everest Boole 1832-1916 DEAD,"
PL084:
.str " mathematician and educational writer, his wife. Alicia Boole Stott"
PL085:
.str " 1860-1940 DEAD, his daughter, known for four-dimensional polytopes."
PL086:
.str " Claude Shannon 1916-2001 DEAD. Augustus De Morgan 1806-1871 DEAD,"
PL087:
.str " logician and Boole's correspondent. William Stanley Jevons 1835-1882"
PL088:
.str " DEAD, built one of the first logic machines. Charles Sanders Peirce"
PL089:
.str " 1839-1914 DEAD, extended Boolean algebra and truth-table ideas."
PL090:
.str ""
PL091:
.str " SOURCES"
PL092:
.str " Boole, The Mathematical Analysis of Logic (1847)."
PL093:
.str " Boole, An Investigation of the Laws of Thought (1854)."
PL094:
.str " Shannon, A Symbolic Analysis of Relay and Switching Circuits (1937"
PL095:
.str " thesis, 1938 Trans. AIEE). Spec: NAN16_SPEC.md, NANVM1_SPEC.md."
PL096:
.str " This plaque is a modern reading. Badge: INSPIRED, not a copy of"
PL097:
.str " Boole's notation and not a reconstruction of a historical machine."
PL098:
.str ""
PL099:
.str " [1] live table   [UP/DOWN] scroll   [LEFT/RIGHT] page   [ESC] shell"
; ---- 32-bit pointer table indexed by plaque line ----
bl_lines:
.word @PL000
.word @PL001
.word @PL002
.word @PL003
.word @PL004
.word @PL005
.word @PL006
.word @PL007
.word @PL008
.word @PL009
.word @PL010
.word @PL011
.word @PL012
.word @PL013
.word @PL014
.word @PL015
.word @PL016
.word @PL017
.word @PL018
.word @PL019
.word @PL020
.word @PL021
.word @PL022
.word @PL023
.word @PL024
.word @PL025
.word @PL026
.word @PL027
.word @PL028
.word @PL029
.word @PL030
.word @PL031
.word @PL032
.word @PL033
.word @PL034
.word @PL035
.word @PL036
.word @PL037
.word @PL038
.word @PL039
.word @PL040
.word @PL041
.word @PL042
.word @PL043
.word @PL044
.word @PL045
.word @PL046
.word @PL047
.word @PL048
.word @PL049
.word @PL050
.word @PL051
.word @PL052
.word @PL053
.word @PL054
.word @PL055
.word @PL056
.word @PL057
.word @PL058
.word @PL059
.word @PL060
.word @PL061
.word @PL062
.word @PL063
.word @PL064
.word @PL065
.word @PL066
.word @PL067
.word @PL068
.word @PL069
.word @PL070
.word @PL071
.word @PL072
.word @PL073
.word @PL074
.word @PL075
.word @PL076
.word @PL077
.word @PL078
.word @PL079
.word @PL080
.word @PL081
.word @PL082
.word @PL083
.word @PL084
.word @PL085
.word @PL086
.word @PL087
.word @PL088
.word @PL089
.word @PL090
.word @PL091
.word @PL092
.word @PL093
.word @PL094
.word @PL095
.word @PL096
.word @PL097
.word @PL098
.word @PL099
