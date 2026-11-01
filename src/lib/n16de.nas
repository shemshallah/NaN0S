; n16de.nas - NaN16 double-ended qNaN carrier, pair-voting codec.
; This is a data carrier, not a cryptographic primitive. It is safe to include
; in the museum.
;
; Word layout used here (NaN16, not IEEE bytes):
;   class nibble 10 (both faces +q) for DATA / DELIM / RESYNC
;   payload bits 31..16 = tag, bits 15..0 = 16-bit chunk
;   tag 0x0000 = big-endian member, tag 0x0001 = byte-swapped member
;   tag 0x0002 = DELIM, tag 0x0003 = RESYNC, tag 0x0004 = CTRL (class 11)
; A chunk is written twice. The decoder byte-swaps the tag-1 member and votes.
; Disagreement is a loud failure: return 0 and let the caller resync.
.equ N16_CLASS 10
.equ N16_CTRL 11
.equ N16_TAG_BE 0
.equ N16_TAG_LE 1
.equ N16_TAG_DELIM 2
.equ N16_TAG_RESYNC 3
.equ N16_TAG_CTRL 4

; bswap16: r1 -> r1, r2/r3/r4 clobbered
n16_bswap16:
  MOVI r5,255
  BOOL.8 r2,r1,r5
  SHL r2,r2,8
  SHR r3,r1,8
  BOOL.8 r3,r3,r5
  BOOL.14 r1,r2,r3
  RET

; encode: r1=chunk, r2=dest word address. Writes two qNaN words.
; preserves r10..r14, clobbers r1..r9,r15.
n16_encode:
  ST r15,r0,@n16e_ret
  ST r1,r0,@n16e_chunk
  ST r2,r0,@n16e_dst
  MOVI r4,#N16_CLASS
  STW r1,r2,r4
  LD r1,r0,@n16e_chunk
  CALL @n16_bswap16
  MOVI r4,1
  SHL r4,r4,16
  BOOL.14 r1,r1,r4
  LD r2,r0,@n16e_dst
  ADD r2,r2,r13
  MOVI r4,#N16_CLASS
  STW r1,r2,r4
  LD r15,r0,@n16e_ret
  RET
n16e_ret:
.word 0
n16e_chunk:
.word 0
n16e_dst:
.word 0

; decode one pair: r1=ptr -> r1=chunk, r2=1 ok / 0 bad
; clobbers r1..r9,r15.
n16_decode:
  ST r15,r0,@n16d_ret
  LDN r3,r1,0
  MOVI r4,#N16_CLASS
  CMP r3,r4
  JMP[NE] @n16_bad
  LDN r3,r1,1
  CMP r3,r4
  JMP[NE] @n16_bad
  LD r4,r1,0
  LD r5,r1,1
  SHR r6,r4,16
  CMP r6,r0
  JMP[NE] @n16_bad
  SHR r6,r5,16
  MOVI r7,#N16_TAG_LE
  CMP r6,r7
  JMP[NE] @n16_bad
  MOVI r6,0xFFFF
  BOOL.8 r4,r4,r6
  BOOL.8 r5,r5,r6
  ADD r1,r5,r0
  CALL @n16_bswap16
  CMP r1,r4
  JMP[NE] @n16_bad
  ADD r1,r4,r0
  MOVI r2,1
  LD r15,r0,@n16d_ret
  RET
n16_bad:
  MOVI r1,0
  MOVI r2,0
  LD r15,r0,@n16d_ret
  RET
n16d_ret:
.word 0

; emit a delimiter word: r1=dest
n16_delim:
  MOVI r2,#N16_TAG_DELIM
  SHL r2,r2,16
  MOVI r3,#N16_CLASS
  STW r2,r1,r3
  RET

; emit a resync word: r1=dest
n16_resync:
  MOVI r2,#N16_TAG_RESYNC
  SHL r2,r2,16
  MOVI r3,#N16_CLASS
  STW r2,r1,r3
  RET
