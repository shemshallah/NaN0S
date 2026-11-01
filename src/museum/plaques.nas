; MENU + PLAQUES. Attribute words: 0x0F00 white 0x0E00 yellow 0x0B00 cyan 0x0A00 green 0x0700 grey 0x7000 inverse.
menu:
CALL @vcls
MOVI r1,@m_banner
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL @vputs
MOVI r1,@m_list
MOVI r2,324
MOVI r3,0x0F00
MOVI r5,4
MOVI r6,4
CALL @vputs
MOVI r1,@m_foot
MOVI r2,1840
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL @vputs
mkey:
KEY r1
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,49
CMP r1,r4
JMP[EQ] @plaque_baby
JMP @mkey
; ---- Baby plaque ----
plaque_baby:
CALL @vcls
MOVI r1,@p_baby
MOVI r2,0
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL @vputs
pbk:
KEY r1
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @menu
MOVI r4,49
CMP r1,r4
MOVI r3,@baby18
ST[EQ] r3,r0,@bs_sel
JMP[EQ] @baby_start
MOVI r4,50
CMP r1,r4
MOVI r3,@baby12
ST[EQ] r3,r0,@bs_sel
JMP[EQ] @baby_start
JMP @pbk
m_banner:
.str " NaN/0S  MUSEUM OF COMPUTING   (every exhibit is NaN words on bare metal)       "
m_list:
.str "[1]  1948  Manchester Baby (SSEM) - the first stored program\n\n\n     more exhibits are being installed - see TODO.md\n"
m_foot:
.str "ring 0, no host OS. press a number key. NaN/0S round 05"
p_baby:
.str " MANCHESTER SMALL-SCALE EXPERIMENTAL MACHINE - THE BABY - 21 JUNE 1948\n University of Manchester, England\n\n The first electronic stored-program computer. Program and data shared one\n electronic memory (Williams-Kilburn tube: 32 words x 32 bits) and a new\n program needed no rewiring. 7 instructions: JMP JRP LDN STO SUB CMP STP.\n\n THE PEOPLE\n   Freddie Williams  1911-1977  died   tube inventor, project lead\n   Tom Kilburn       1921-2001  died   wrote the first program\n   Geoff Tootill     1922-2017  died   built it, kept the notebook\n\n THE FIRST PROGRAM: highest proper factor of 2^18, trying 262143 downwards.\n Answer 131072 after about 52 minutes (~3.5 million store accesses).\n\n THIS EXHIBIT: exact machine (32x32-bit store, CI incremented before fetch).\n The program is a 20-instruction re-creation, not Kilburn's 17-instruction\n listing (TODO: transcribe it from Tootill's notebook for exact parity).\n\n [1] authentic run N=2^18 (3.4M Baby steps)   [2] quick run N=2^12   [ESC] back\n"
