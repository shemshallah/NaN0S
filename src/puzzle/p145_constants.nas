; Puzzle 145 constants. Public challenge only. No arbitrary-target input.
; Pubkey: 03 af dd a4 97 36 9e 21 9a 2c 1c 36 99 54 a9 30
;         e4 d3 74 09 68 e5 e4 35 24 75 bc ff ce 31 40 da e5
; Address: 19GpszRNUej5yYqxXoLnbZWKew3KdVLkXg
; Range: 2^144 .. 2^145-1
.equ P145_BITS 145
p145_pubkey:
.word 3
.word 0xAFDDA497
.word 0x369E219A
.word 0x2C1C3699
.word 0x54A930E4
.word 0xD3740968
.word 0xE5E43524
.word 0x75BCFFCE
.word 0x3140DAE5
p145_lo:
.word 0,0,0,0,0x00010000,0,0,0
p145_hi:
.word 0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0x0001FFFF,0,0,0
p145_address:
.str "19GpszRNUej5yYqxXoLnbZWKew3KdVLkXg"
