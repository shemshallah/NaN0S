; Default guest image for a standalone S1 AArch64 build (layer-1 demo).
; The gate replaces this with a generated image from a real .nas source.
.quad 0xFFF801100050F8FF   ; MOVI r1,80
.quad 0xFFF801200003F8FF   ; MOVI r2,3
.quad 0xFFF803310002F8FF   ; ADD r3,r1,r2
.quad 0xFFF815300000F8FF   ; PUTC r3        -> 'S'
.quad 0xFFF801100031F8FF   ; MOVI r1,49
.quad 0xFFF815100000F8FF   ; PUTC r1        -> '1'
.quad 0xFFF801100056F8FF   ; MOVI r1,86
.quad 0xFFF815100000F8FF   ; PUTC r1        -> 'V'
.quad 0xFFF80110004DF8FF   ; MOVI r1,77
.quad 0xFFF815100000F8FF   ; PUTC r1        -> 'M'
.quad 0xFFF801100020F8FF   ; MOVI r1,32
.quad 0xFFF815100000F8FF   ; PUTC r1        -> ' '
.quad 0xFFF80110004FF8FF   ; MOVI r1,79
.quad 0xFFF815100000F8FF   ; PUTC r1        -> 'O'
.quad 0xFFF80110004BF8FF   ; MOVI r1,75
.quad 0xFFF815100000F8FF   ; PUTC r1        -> 'K'
.quad 0xFFF80110000AF8FF   ; MOVI r1,10
.quad 0xFFF815100000F8FF   ; PUTC r1        -> '\n'
.quad 0xFFF8FF000000F8FF   ; HALT
