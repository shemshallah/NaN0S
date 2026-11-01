; memtest.nas - r26f guest test of the PAE bank window (kernel src/draft/kan16_pae_wip.xa -> shipped as kan16.xa).
; Queries CPUID leaf 0x4E4D00FF (mask, words, flags b0=PAE b1=E820, bank switches), raises the mask to the maximum,
; writes class-6 words at word index (bank<<27)|0x123456 in every bank the machine has, reads them all back
; with LDN/LD (aliasing between banks would show), then BCOPYs 8 words from bank 0 into bank 1.
; Output: lines 'M..' 'W..' 'F..' 'S..' 'K..' then one P/F per bank, then BCOPY P/F, then PASS or FAIL.
main:
MOVI r13,1
MOVI r11,6
LA r1,0x4E4D001F
CPUID r3,r1,r0
ST r3,r0,@mk
ADDI r8,r3,1
SHR r8,r8,27
ST r8,r0,@nb
MOVI r4,75
CALL @ph
LA r1,0x4E4D00FF
MOVI r2,0
CPUID r3,r1,r2
MOVI r4,77
CALL @ph
MOVI r2,1
CPUID r3,r1,r2
ST r3,r0,@nwd
MOVI r4,87
CALL @ph
MOVI r2,2
CPUID r3,r1,r2
ST r3,r0,@flg
MOVI r4,70
CALL @ph
MOVI r2,3
CPUID r3,r1,r2
MOVI r4,83
CALL @ph
MOVI r10,0
w1:
CALL @idx
LD r8,r0,@nwd
CMP r4,r8
JMP[GE] @w2
LA r7,0x01010101
MUL r6,r10,r7
ADDI r6,r6,4660
STW r6,r4,r11
w2:
ADD r10,r10,r13
LD r9,r0,@nb
CMP r10,r9
JMP[LT] @w1
MOVI r10,0
MOVI r12,0
r1l:
CALL @idx
LD r8,r0,@nwd
CMP r4,r8
JMP[GE] @rn
LA r7,0x01010101
MUL r6,r10,r7
ADDI r6,r6,4660
LDN r8,r4,0
CMP r8,r11
JMP[NE] @rf
LD r8,r4,0
CMP r8,r6
JMP[NE] @rf
MOVI r5,80
PUTC r5
ADD r12,r12,r13
JMP @rn
rf:
MOVI r5,70
PUTC r5
ST r13,r0,@bad
rn:
ADD r10,r10,r13
LD r9,r0,@nb
CMP r10,r9
JMP[LT] @r1l
MOVI r5,10
PUTC r5
; BCOPY bank0 -> bank1
MOVI r1,0
LA r2,0x200000
MOVI r3,0
bs:
ADD r4,r2,r3
LA r7,0xABC00
ADD r6,r7,r3
STW r6,r4,r11
ADD r3,r3,r13
MOVI r9,8
CMP r3,r9
JMP[LT] @bs
LA r5,0x8300000
LA r1,0x200000
MOVI r4,8
BCOPY r5,r1,r4
MOVI r3,0
LD r8,r0,@nb
MOVI r9,2
CMP r8,r9
JMP[LT] @bnb
bv:
ADD r4,r5,r3
LDN r8,r4,0
CMP r8,r11
JMP[NE] @bf
LD r8,r4,0
LA r7,0xABC00
ADD r6,r7,r3
CMP r8,r6
JMP[NE] @bf
ADD r3,r3,r13
MOVI r9,8
CMP r3,r9
JMP[LT] @bv
MOVI r5,80
PUTC r5
JMP @fin
bf:
MOVI r5,70
PUTC r5
ST r13,r0,@bad
JMP @fin
bnb:
MOVI r5,45
PUTC r5
fin:
MOVI r5,10
PUTC r5
LD r8,r0,@bad
CMP r8,r0
JMP[NE] @failp
MOVI r5,80
PUTC r5
MOVI r5,65
PUTC r5
MOVI r5,83
PUTC r5
MOVI r5,83
PUTC r5
MOVI r5,10
PUTC r5
HALT
failp:
MOVI r5,70
PUTC r5
MOVI r5,65
PUTC r5
MOVI r5,73
PUTC r5
MOVI r5,76
PUTC r5
MOVI r5,10
PUTC r5
HALT
; r4 = (r10<<27) | 0x123456
idx:
SHL r4,r10,27
LA r7,0x123456
BOOL.14 r4,r4,r7
RET
; print r4 as a char, then r3 as 8 hex digits and newline (clobbers r5,r6,r7,r9,r14)
ph:
PUTC r4
MOVI r9,8
ph1:
SHR r5,r3,28
SHL r3,r3,4
MOVI r6,10
CMP r5,r6
MOVI r7,48
MOVI[GE] r7,55
ADD r7,r7,r5
PUTC r7
SUB r9,r9,r13
CMP r9,r0
JMP[NE] @ph1
MOVI r7,10
PUTC r7
RET
nwd:
.word 0
mk:
.word 0
nb:
.word 0
flg:
.word 0
bad:
.word 0
