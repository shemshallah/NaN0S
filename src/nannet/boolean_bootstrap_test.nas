; BS0 Boolean bootstrap: exhaust all 16 two-input truth tables.
; BOOL.n encodes truth-table output bits for inputs (a,b) = 00,01,10,11.
; Every function is checked over all four combinations: 64 executable assertions.
main:
MOVI r13,1
; truth table 0, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.0 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 0, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.0 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 0, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.0 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 0, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.0 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 1, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.1 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 1, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.1 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 1, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.1 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 1, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.1 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 2, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.2 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 2, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.2 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 2, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.2 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 2, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.2 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 3, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.3 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 3, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.3 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 3, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.3 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 3, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.3 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 4, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.4 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 4, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.4 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 4, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.4 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 4, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.4 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 5, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.5 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 5, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.5 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 5, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.5 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 5, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.5 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 6, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.6 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 6, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.6 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 6, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.6 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 6, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.6 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 7, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.7 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 7, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.7 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 7, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.7 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 7, inputs 11, expected 0
MOVI r1,1
MOVI r2,1
BOOL.7 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 8, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.8 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 8, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.8 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 8, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.8 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 8, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.8 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 9, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.9 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 9, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.9 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 9, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.9 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 9, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.9 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 10, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.10 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 10, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.10 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 10, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.10 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 10, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.10 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 11, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.11 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 11, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.11 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 11, inputs 10, expected 0
MOVI r1,1
MOVI r2,0
BOOL.11 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 11, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.11 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 12, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.12 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 12, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.12 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 12, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.12 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 12, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.12 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 13, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.13 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 13, inputs 01, expected 0
MOVI r1,0
MOVI r2,1
BOOL.13 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 13, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.13 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 13, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.13 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 14, inputs 00, expected 0
MOVI r1,0
MOVI r2,0
BOOL.14 r3,r1,r2
MOVI r4,0
CMP r3,r4
JMP[NE] @fail
; truth table 14, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.14 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 14, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.14 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 14, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.14 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 15, inputs 00, expected 1
MOVI r1,0
MOVI r2,0
BOOL.15 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 15, inputs 01, expected 1
MOVI r1,0
MOVI r2,1
BOOL.15 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 15, inputs 10, expected 1
MOVI r1,1
MOVI r2,0
BOOL.15 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
; truth table 15, inputs 11, expected 1
MOVI r1,1
MOVI r2,1
BOOL.15 r3,r1,r2
MOVI r4,1
CMP r3,r4
JMP[NE] @fail
MOVI r1,66
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,48
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,66
PUTC r1
MOVI r1,79
PUTC r1
MOVI r1,79
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,10
PUTC r1
HALT
fail:
MOVI r1,66
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,48
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,66
PUTC r1
MOVI r1,79
PUTC r1
MOVI r1,79
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,10
PUTC r1
HALT
