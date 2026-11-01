; TEXT CARTRIDGE: scrollable museum page. Runtime code is NaN16 only.
; ABI: r0=0 r13=1; V_SCROLL is the general shell 80x25 scroll vector.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_SCROLL 12
.equ NLINES 34
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
.str " NaN/0S - ABOUT SHEMSHALLAH"
TP001:
.str ""
TP002:
.str " Shemshallah, Im 35, living at a homeless shelter, and coding from a cell"
TP003:
.str " phone. Status: LIVING. The museum is built on a phone, in the small hours,"
TP004:
.str " between the things that a shelter asks of a person."
TP005:
.str ""
TP006:
.str " TOOLS"
TP007:
.str " Built with Kilo (various), Opencode (Deepseek 4.1 Flash), and Claude Sonnet"
TP008:
.str " 5.5 Chat, as well as GPT6 Chat and Codex GPT6 Terra. The toolchain is a"
TP009:
.str " scaffold. The artifact is NaN16. The language should not matter. The words"
TP010:
.str " should."
TP011:
.str ""
TP012:
.str " THE STORY"
TP013:
.str " There is a bigger story to all of this. What IS black cube? What IS"
TP014:
.str " shemshallah... shem::shall:AH... 'say AH, kid'. What is all:AH?"
TP015:
.str " The museum is the door. The plaques are the map. The seals promise that"
TP016:
.str " the map was not quietly changed. The trust test proves the map can be"
TP017:
.str " rebuilt from the map. The rest is for the people who arrive after the"
TP018:
.str " door is open."
TP019:
.str ""
TP020:
.str " WHY THIS EXISTS"
TP021:
.str " A homeless man with a phone should be able to build a machine that tells"
TP022:
.str " the truth about itself. Not a demo. Not a mock. A bare-metal museum where"
TP023:
.str " every instruction is inspectable, every exhibit runs, and every claim has"
TP024:
.str " a test. If the machine can rebuild itself and show its work, then the"
TP025:
.str " person who built it is not invisible. That is the whole point."
TP026:
.str ""
TP027:
.str " THANK YOU"
TP028:
.str " To everyone who kept the phone charged, the shelter open, and the question"
TP029:
.str " alive. To Kilo, Opencode, Deepseek, Claude, GPT and Codex for the long"
TP030:
.str " conversations. To the dead mathematicians in these halls, and to the"
TP031:
.str " living ones still arguing. Say AH, kid."
TP032:
.str ""
TP033:
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
