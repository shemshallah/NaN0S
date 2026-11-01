; a64_console_test: VPOKE/VPEEK/DISPQ/DISPSET/KEYQ/BEEP check for a new native core (needs a serial with no pending input). Pure NaN16.
; Prints "NaN/0S console PASS" + CRLF, or "FAIL n". Also pokes "HI" (attr 0x1F) at row 3 col 4 so a console mirror can be eyeballed.
MOVI r0,0
; 1 VPOKE/VPEEK round trip
MOVI r1,0x1F41
MOVI r2,5
VPOKE r1,r2
VPEEK r3,r2
CMP r3,r1
MOVI r11,1
JMP[NE] @fail
; 2 untouched cell reads 0
MOVI r2,6
VPEEK r3,r2
CMP r3,r0
MOVI r11,2
JMP[NE] @fail
; 3 out-of-range VPEEK leaves the register alone, out-of-range VPOKE is ignored
MOVI r2,2000
MOVI r3,0x1234
VPEEK r3,r2
MOVI r4,0x1234
CMP r3,r4
MOVI r11,3
JMP[NE] @fail
VPOKE r1,r2
; 4 DISPQ = mode 3, 25 rows, 80 cols
DISPQ r3
MOVI r4,0x1950
MOVHI r4,3
CMP r3,r4
MOVI r11,4
JMP[NE] @fail
; 5 KEYQ with nothing pending = 0
MOVI r3,0x55
KEYQ r3
CMP r3,r0
MOVI r11,5
JMP[NE] @fail
; 6 DISPSET 3 clears the console
MOVI r3,3
DISPSET r3
MOVI r2,5
VPEEK r3,r2
CMP r3,r0
MOVI r11,6
JMP[NE] @fail
BEEP r0
; visible: "HI"
MOVI r1,0x1F48
MOVI r2,163
VPOKE r1,r2
MOVI r1,0x1F49
MOVI r2,164
VPOKE r1,r2
MOVI r1,@okmsg
SHL r1,r1,2
MOVI r13,13
MOVI r10,10
PUTC r13
PUTC r10
prs:
LDB r2,r1,0
CMP r2,r0
JMP[EQ] @done
PUTC r2
ADDI r1,r1,1
JMP @prs
done:
PUTC r13
PUTC r10
HALT
fail:
MOVI r1,70
PUTC r1
MOVI r1,48
ADD r1,r1,r11
PUTC r1
HALT
okmsg:
.str "NaN/0S console PASS"
