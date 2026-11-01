; TEXT CARTRIDGE: scrollable museum page. Runtime code is NaN16 only.
; ABI: r0=0 r13=1; V_SCROLL is the general shell 80x25 scroll vector.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_SCROLL 12
.equ NLINES 72
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
.str " NaN/0S - THE PATRIOT MISSILE FAILURE"
TP001:
.str " DHAHRAN, SAUDI ARABIA - 25 FEBRUARY 1991"
TP002:
.str ""
TP003:
.str " WHAT HAPPENED"
TP004:
.str " A Patriot air-defence battery failed to intercept a Scud missile."
TP005:
.str " The missile struck a barracks in Dhahran. Twenty-eight soldiers died."
TP006:
.str " Ninety-eight were injured. The failure was not a lack of processing"
TP007:
.str " power. It was a lack of bits in the representation of time."
TP008:
.str ""
TP009:
.str " THE CLOCK"
TP010:
.str " The Patriot software kept time in a 24-bit fixed-point counter. The"
TP011:
.str " counter was incremented every 0.1 second. Converting that counter to a"
TP012:
.str " real number required a multiplication by 0.1. The multiplication was"
TP013:
.str " truncated. The truncation was tiny: about 0.000000095 second per 0.1"
TP014:
.str " second tick. The error accumulated. After about 100 hours of continuous"
TP015:
.str " operation the clock was off by about 0.34 second. A Scud at roughly"
TP016:
.str " 1.6 km/s moves about 550 metres in that time. The intercept window was"
TP017:
.str " tens of metres. The battery looked at the wrong point in the sky."
TP018:
.str ""
TP019:
.str " THE NUMBER THAT MATTERS"
TP020:
.str " 24 bits is about 16.7 million counts. At 0.1 s per count that is about"
TP021:
.str " 19.4 days of clock. The system had to be restarted before the error"
TP022:
.str " grew too large. The battery had been running for about 100 hours"
TP023:
.str " without a full restart. That was inside the allowed operating time."
TP024:
.str " The error was not supposed to matter yet. It did."
TP025:
.str ""
TP026:
.str " THE PEOPLE"
TP027:
.str " The 28 soldiers killed at Dhahran, 25 February 1991. Status: DEAD."
TP028:
.str " Theodore A. Postol, 1946-, MIT physicist who publicly analysed the"
TP029:
.str " failure and the software. Status: LIVING."
TP030:
.str " The U.S. Army Patriot Project Office and the Raytheon team. The"
TP031:
.str " software authors are not named in the public record. Status: not"
TP032:
.str " listed here, and not guessed."
TP033:
.str ""
TP034:
.str " WHY IT IS A MUSEUM PIECE"
TP035:
.str " This is a tragedy of representation. The system did not lack"
TP036:
.str " processing power. It lacked the bits to represent time accurately."
TP037:
.str " Here, in a NaN machine, we have many ways to represent 'undefined'."
TP038:
.str " The Patriot had none. A coordinate that could not be computed became"
TP039:
.str " a wrong number, not a refusal."
TP040:
.str ""
TP041:
.str " THE TUTORIAL"
TP042:
.str " The exhibit would render a tracking display. A clock ticks in 0.1 s"
TP043:
.str " units. A 24-bit counter is converted to seconds with truncation. The"
TP044:
.str " drift is accumulated and multiplied by the target speed. The predicted"
TP045:
.str " intercept point slides away from the true point. When the range error"
TP046:
.str " exceeds the intercept window, the coordinate is replaced by a NaN word"
TP047:
.str " and the display prints !G. The visitor sees the failure as a number,"
TP048:
.str " not as a story. The plaque is the source. The simulation is the lesson."
TP049:
.str ""
TP050:
.str " THE PLAQUE"
TP051:
.str " This exhibit is a tragedy of representation. The system didn't lack"
TP052:
.str " processing power, it lacked the bits to represent time accurately."
TP053:
.str " Here, in a NaN machine, we have infinite ways to represent 'undefined'"
TP054:
.str " but the Patriot had none."
TP055:
.str ""
TP056:
.str " SOURCES"
TP057:
.str " U.S. General Accounting Office, 'Patriot Missile Defense: Software"
TP058:
.str " Problem Led to System Failure at Dhahran, Saudi Arabia', 1992."
TP059:
.str " Theodore A. Postol, public analysis of the Patriot software failure."
TP060:
.str " The 24-bit fixed-point clock and the 0.1 s tick are described in the"
TP061:
.str " public record. The exact drift figure is approximate and is labelled"
TP062:
.str " as such. This exhibit is a RE-CREATION, not the classified software."
TP063:
.str ""
TP064:
.str " WHAT THIS EXHIBIT DOES NOT DO"
TP065:
.str " It does not run Patriot code. It does not use classified data. It"
TP066:
.str " does not name people who are not in the public record. It does not"
TP067:
.str " claim that a NaN machine would have saved the soldiers. It shows the"
TP068:
.str " shape of the failure: a small representation error, accumulated over"
TP069:
.str " time, becomes a large error in the world."
TP070:
.str ""
TP071:
.str " UP/DOWN scroll  ESC shell"
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
.word @TP039
.word @TP040
.word @TP041
.word @TP042
.word @TP043
.word @TP044
.word @TP045
.word @TP046
.word @TP047
.word @TP048
.word @TP049
.word @TP050
.word @TP051
.word @TP052
.word @TP053
.word @TP054
.word @TP055
.word @TP056
.word @TP057
.word @TP058
.word @TP059
.word @TP060
.word @TP061
.word @TP062
.word @TP063
.word @TP064
.word @TP065
.word @TP066
.word @TP067
.word @TP068
.word @TP069
.word @TP070
.word @TP071
