; base32.nas - 0x0E01 BASE32 (RFC 4648 section 6, alphabet A-Z2-7, '=' pad).
;
; ABI (defs.nas): r1 in, r2 inlen, r3 out, r4 outcap -> r5 ret word.
; Encode: 5 bytes -> 8 chars; final partial block zero-fills then pads '='
; to the 8-char block (produced length is 8*ceil(len/5), 0 when len==0).
; Decode: lenient on padding (accepts the all-at-end padded final block and
; unpadded tails), strict otherwise: any out-of-alphabet char, data after
; pads, pad runs not at input end, data-char counts per block outside
; {2,4,5,7} (or 8) and non-canonical trailing bits are EPROTO. Writes a
; chunk only when it fits, but scans and counts every chunk, so the
; -ENOSPC return still carries the FULL required length (spec 4).
; Helpers are leaves touching r4(in),r5,r6 only; r7/r8 preserved.
; SHL/SHR take literal immediates only.
; Labels: b32_* helpers, e32_* encode, d32_* decode.

; r4 = 0..31 -> r5 = base32 char (touches r5 only beyond its input)
b32_char:
  MOVI r5,26
  CMP r4,r5
  MOVI r5,65               ; 'A'
  MOVI[GE] r5,24           ; '2'-26
  ADD r5,r5,r4
  RET

; r4 = char -> r5 = 0..31 or 255 invalid (never touches r7/r8)
b32_val:
  MOVI r6,65
  CMP r4,r6
  JMP[LT] @b32v_dig
  MOVI r6,91
  CMP r4,r6
  JMP[GE] @b32v_dig
  ADDI r5,r4,-65           ; 0..25
  RET
b32v_dig:
  MOVI r6,50
  CMP r4,r6
  JMP[LT] @b32v_bad
  MOVI r6,56
  CMP r4,r6
  JMP[GE] @b32v_bad
  ADDI r5,r4,-24           ; 26..31
  RET
b32v_bad:
  MOVI r5,255
  RET

; base32 encode
e32:                       ; r1 in, r2 len, r3 out, r4 cap -> r5
  ST r15,r0,@e32_ret
  ST r4,r0,@e32_cap
  MOVI r4,4
  ADD r6,r2,r4             ; len+4
  MOVI r4,5
  DIVU r6,r6,r4            ; q = ceil(len/5)  (0 when len==0)
  SHL r6,r6,3              ; need = 8*q
  ST r6,r0,@e32_need
  LD r4,r0,@e32_cap
  CMP r4,r6
  JMP[LT] @e32_nospc
e32_g:                     ; full 5-byte blocks
  MOVI r4,5
  CMP r2,r4
  JMP[LT] @e32_tail
  LDB r7,r1,0              ; b0
  SHL r8,r7,24
  ADDI r1,r1,1
  LDB r7,r1,0              ; b1
  SHL r7,r7,16
  BOOL.14 r8,r8,r7
  ADDI r1,r1,1
  LDB r7,r1,0              ; b2
  SHL r7,r7,8
  BOOL.14 r8,r8,r7
  ADDI r1,r1,1
  LDB r7,r1,0              ; b3
  ADDI r1,r1,1
  LDB r6,r1,0              ; b4 (r6; b32_char preserves it)
  ADDI r1,r1,1
  SHR r4,r8,27             ; c0 = v>>27
  CALL @b32_char
  STB r5,r3,0
  SHR r4,r8,22
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c1
  CALL @b32_char
  STB r5,r3,1
  SHR r4,r8,17
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c2
  CALL @b32_char
  STB r5,r3,2
  SHR r4,r8,12
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c3
  CALL @b32_char
  STB r5,r3,3
  SHR r4,r8,7
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c4
  CALL @b32_char
  STB r5,r3,4
  SHR r4,r8,2
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c5
  CALL @b32_char
  STB r5,r3,5
  MOVI r5,3
  BOOL.8 r4,r8,r5          ; v&3
  SHL r4,r4,3
  SHR r5,r6,5              ; b4>>5
  BOOL.14 r4,r4,r5         ; c6 = ((v&3)<<3)|(b4>>5)
  CALL @b32_char
  STB r5,r3,6
  MOVI r5,31
  BOOL.8 r4,r6,r5          ; c7 = b4&31
  CALL @b32_char
  STB r5,r3,7
  ADDI r3,r3,8
  ADDI r2,r2,-5
  JMP @e32_g
e32_tail:                  ; r2 = remaining bytes 0..4
  CMP r2,r0
  JMP[EQ] @e32_done
  MOVI r4,2
  CMP r2,r4
  JMP[EQ] @e32_t2
  MOVI r4,3
  CMP r2,r4
  JMP[EQ] @e32_t3
  MOVI r4,4
  CMP r2,r4
  JMP[EQ] @e32_t4
  ; r2 == 1
  LDB r8,r1,0              ; b
  SHR r4,r8,3              ; c0 (5 bits)
  CALL @b32_char
  STB r5,r3,0
  MOVI r5,7
  BOOL.8 r4,r8,r5          ; b&7
  SHL r4,r4,2              ; c1
  CALL @b32_char
  STB r5,r3,1
  MOVI r6,6                ; pads
  ADDI r3,r3,2
  JMP @e32_pad
e32_t2:                    ; 2 bytes -> 4 chars + 4 pads
  LDB r7,r1,0
  SHL r8,r7,8
  ADDI r1,r1,1
  LDB r7,r1,0
  BOOL.14 r8,r8,r7         ; v (16 bits)
  SHR r4,r8,11             ; c0
  CALL @b32_char
  STB r5,r3,0
  SHR r4,r8,6
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c1
  CALL @b32_char
  STB r5,r3,1
  SHR r4,r8,1
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c2
  CALL @b32_char
  STB r5,r3,2
  MOVI r5,1
  BOOL.8 r4,r8,r5          ; v&1
  SHL r4,r4,4              ; c3
  CALL @b32_char
  STB r5,r3,3
  MOVI r6,4
  ADDI r3,r3,4
  JMP @e32_pad
e32_t3:                    ; 3 bytes -> 5 chars + 3 pads
  LDB r7,r1,0
  SHL r8,r7,16
  ADDI r1,r1,1
  LDB r7,r1,0
  SHL r7,r7,8
  BOOL.14 r8,r8,r7
  ADDI r1,r1,1
  LDB r7,r1,0
  BOOL.14 r8,r8,r7         ; v (24 bits)
  SHR r4,r8,19             ; c0
  CALL @b32_char
  STB r5,r3,0
  SHR r4,r8,14
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c1
  CALL @b32_char
  STB r5,r3,1
  SHR r4,r8,9
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c2
  CALL @b32_char
  STB r5,r3,2
  SHR r4,r8,4
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c3
  CALL @b32_char
  STB r5,r3,3
  MOVI r5,15
  BOOL.8 r4,r8,r5          ; v&0xF
  SHL r4,r4,1              ; c4
  CALL @b32_char
  STB r5,r3,4
  MOVI r6,3
  ADDI r3,r3,5
  JMP @e32_pad
e32_t4:                    ; 4 bytes -> 7 chars + 1 pad
  LDB r7,r1,0
  SHL r8,r7,24
  ADDI r1,r1,1
  LDB r7,r1,0
  SHL r7,r7,16
  BOOL.14 r8,r8,r7
  ADDI r1,r1,1
  LDB r7,r1,0
  SHL r7,r7,8
  BOOL.14 r8,r8,r7
  ADDI r1,r1,1
  LDB r7,r1,0
  BOOL.14 r8,r8,r7         ; v (32 bits)
  SHR r4,r8,30             ; c0 (2 bits)
  CALL @b32_char
  STB r5,r3,0
  SHR r4,r8,25
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c1
  CALL @b32_char
  STB r5,r3,1
  SHR r4,r8,20
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c2
  CALL @b32_char
  STB r5,r3,2
  SHR r4,r8,15
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c3
  CALL @b32_char
  STB r5,r3,3
  SHR r4,r8,10
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c4
  CALL @b32_char
  STB r5,r3,4
  SHR r4,r8,5
  MOVI r5,31
  BOOL.8 r4,r4,r5          ; c5
  CALL @b32_char
  STB r5,r3,5
  MOVI r5,31
  BOOL.8 r4,r8,r5          ; c6 = v&31
  CALL @b32_char
  STB r5,r3,6
  MOVI r6,1
  ADDI r3,r3,7
e32_pad:
  CMP r6,r0
  JMP[EQ] @e32_done
  MOVI r5,61               ; '='
  STB r5,r3,0
  ADDI r3,r3,1
  SUB r6,r6,r13
  JMP @e32_pad
e32_done:
  LD r5,r0,@e32_need
  LD r15,r0,@e32_ret
  RET
e32_nospc:
  MOVI r8,0xFFFF
  BOOL.8 r8,r6,r8          ; need & 0xFFFF (need in r6)
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@e32_ret
  RET
e32_ret:
.word 0
e32_need:
.word 0
e32_cap:
.word 0

; base32 decode (single pass: validate + count + write what fits)
d32:                       ; r1 in, r2 len, r3 out, r4 cap -> r5
  ST r15,r0,@d32_ret
  ST r4,r0,@d32_cap
  ST r0,r0,@d32_tot
d32_chunk:
  MOVI r8,@d32c0           ; slot walk ptr
  MOVI r7,0                ; dc (data chars this chunk)
d32_cs:
  MOVI r4,8
  CMP r7,r4
  JMP[GE] @d32_c8          ; 8 data chars -> full block
  CMP r2,r0
  JMP[EQ] @d32_short       ; input ended mid-chunk (unpadded tail)
  LDB r5,r1,0              ; next char
  ADDI r1,r1,1
  SUB r2,r2,r13
  MOVI r6,61
  CMP r5,r6
  JMP[EQ] @d32_padsaw      ; '=' starts the pad run of the final block
  ADD r4,r5,r0
  CALL @b32_val            ; r5 = val or 255
  MOVI r4,255
  CMP r5,r4
  JMP[EQ] @d32_proto
  ST r5,r8,0
  ADDI r8,r8,1
  ADDI r7,r7,1
  JMP @d32_cs
d32_padsaw:                ; pad run; all remaining chars must be '='
  CMP r2,r0
  JMP[EQ] @d32_paddone
  LDB r5,r1,0
  ADDI r1,r1,1
  SUB r2,r2,r13
  MOVI r6,61
  CMP r5,r6
  JMP[NE] @d32_proto
  JMP @d32_padsaw
d32_paddone:               ; r7 = data-char count of padded final block
  MOVI r4,2
  CMP r7,r4
  JMP[EQ] @d32_write2
  MOVI r4,4
  CMP r7,r4
  JMP[EQ] @d32_write4
  MOVI r4,5
  CMP r7,r4
  JMP[EQ] @d32_write5
  MOVI r4,7
  CMP r7,r4
  JMP[EQ] @d32_write7
  JMP @d32_proto
d32_short:                 ; unpadded tail; r7 = dc
  MOVI r4,2
  CMP r7,r4
  JMP[EQ] @d32_write2
  MOVI r4,4
  CMP r7,r4
  JMP[EQ] @d32_write4
  MOVI r4,5
  CMP r7,r4
  JMP[EQ] @d32_write5
  MOVI r4,7
  CMP r7,r4
  JMP[EQ] @d32_write7
  JMP @d32_proto
d32_c8:                    ; full data chunk: 5 bytes; may or may not be final
  ; write decision
  LD r4,r0,@d32_tot
  MOVI r6,5
  ADD r4,r4,r6
  LD r6,r0,@d32_cap
  CMP r6,r4
  JMP[LT] @d32_skip8
  LD r5,r0,@d32c0
  SHL r7,r5,3              ; r7 was dc counter; reuse after branch
  LD r5,r0,@d32c1
  SHR r8,r5,2
  BOOL.14 r7,r7,r8         ; b0 = (c0<<3)|(c1>>2)
  STB r7,r3,0
  LD r5,r0,@d32c1
  MOVI r6,3
  BOOL.8 r8,r5,r6          ; c1&3
  SHL r8,r8,6
  LD r5,r0,@d32c2
  SHL r5,r5,1              ; c2<<1 (bits 5..1)
  BOOL.14 r8,r8,r5
  LD r5,r0,@d32c3
  SHR r5,r5,4              ; c3>>4 (bit 0)
  BOOL.14 r8,r8,r5         ; b1
  STB r8,r3,1
  LD r5,r0,@d32c3
  MOVI r6,15
  BOOL.8 r7,r5,r6          ; c3&0xF
  SHL r7,r7,4
  LD r5,r0,@d32c4
  SHR r5,r5,1
  MOVI r6,15
  BOOL.8 r5,r5,r6          ; (c4>>1)&0xF
  BOOL.14 r7,r7,r5         ; b2
  STB r7,r3,2
  LD r5,r0,@d32c4
  MOVI r6,1
  BOOL.8 r8,r5,r6          ; c4&1
  SHL r8,r8,7
  LD r5,r0,@d32c5
  SHL r5,r5,2              ; c5<<2 (bits 6..2)
  BOOL.14 r8,r8,r5
  LD r5,r0,@d32c6
  SHR r5,r5,3
  MOVI r6,3
  BOOL.8 r5,r5,r6          ; (c6>>3)&3
  BOOL.14 r8,r8,r5         ; b3
  STB r8,r3,3
  LD r5,r0,@d32c6
  MOVI r6,7
  BOOL.8 r7,r5,r6          ; c6&7
  SHL r7,r7,5
  LD r5,r0,@d32c7
  BOOL.14 r7,r7,r5         ; b4
  STB r7,r3,4
  ADDI r3,r3,5
d32_skip8:
  LD r6,r0,@d32_tot
  MOVI r7,5
  ADD r6,r6,r7
  ST r6,r0,@d32_tot
  CMP r2,r0
  JMP[NE] @d32_chunk
  JMP @d32_fin
; shared write-decision preamble per dc: if tot+len <= cap: emit else skip
d32_write2:
  LD r5,r0,@d32c0
  SHL r7,r5,5              ; v = c0<<5|c1 (10 bits)
  LD r5,r0,@d32c1
  BOOL.14 r7,r7,r5
  MOVI r6,3
  BOOL.8 r8,r5,r6          ; canon: c1&3 == 0 (checked regardless of cap)
  CMP r8,r0
  JMP[NE] @d32_proto
  LD r4,r0,@d32_tot
  MOVI r6,1
  ADD r4,r4,r6
  LD r6,r0,@d32_cap
  CMP r6,r4
  JMP[LT] @d32_skip2
  SHR r7,r7,2              ; b0 = v>>2
  STB r7,r3,0
  ADDI r3,r3,1
d32_skip2:
  LD r6,r0,@d32_tot
  MOVI r7,1
  ADD r6,r6,r7
  ST r6,r0,@d32_tot
  CMP r2,r0
  JMP[NE] @d32_chunkator
  JMP @d32_fin
d32_write4:
  LD r5,r0,@d32c0
  SHL r7,r5,15             ; v (20 bits)
  LD r5,r0,@d32c1
  SHL r5,r5,10
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c2
  SHL r5,r5,5
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c3
  BOOL.14 r7,r7,r5
  MOVI r6,15
  BOOL.8 r8,r5,r6          ; canon: c3&15 == 0 (checked regardless of cap)
  CMP r8,r0
  JMP[NE] @d32_proto
  LD r4,r0,@d32_tot
  MOVI r6,2
  ADD r4,r4,r6
  LD r6,r0,@d32_cap
  CMP r6,r4
  JMP[LT] @d32_skip4
  SHR r8,r7,12             ; b0
  STB r8,r3,0
  SHR r8,r7,4              ; b1
  STB r8,r3,1
  ADDI r3,r3,2
d32_skip4:
  LD r6,r0,@d32_tot
  MOVI r7,2
  ADD r6,r6,r7
  ST r6,r0,@d32_tot
  CMP r2,r0
  JMP[NE] @d32_chunkator
  JMP @d32_fin
d32_write5:
  LD r5,r0,@d32c0
  SHL r7,r5,20             ; v (25 bits)
  LD r5,r0,@d32c1
  SHL r5,r5,15
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c2
  SHL r5,r5,10
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c3
  SHL r5,r5,5
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c4
  BOOL.14 r7,r7,r5
  MOVI r6,1
  BOOL.8 r8,r5,r6          ; canon: c4&1 == 0 (checked regardless of cap)
  CMP r8,r0
  JMP[NE] @d32_proto
  LD r4,r0,@d32_tot
  MOVI r6,3
  ADD r4,r4,r6
  LD r6,r0,@d32_cap
  CMP r6,r4
  JMP[LT] @d32_skip5
  SHR r8,r7,17             ; b0
  STB r8,r3,0
  SHR r8,r7,9              ; b1
  STB r8,r3,1
  SHR r8,r7,1              ; b2
  STB r8,r3,2
  ADDI r3,r3,3
d32_skip5:
  LD r6,r0,@d32_tot
  MOVI r7,3
  ADD r6,r6,r7
  ST r6,r0,@d32_tot
  CMP r2,r0
  JMP[NE] @d32_chunkator
  JMP @d32_fin
d32_write7:
  LD r5,r0,@d32c0
  MOVI r6,3
  CMP r5,r6
  JMP[GT] @d32_proto       ; canon: c0 <= 3 (top 3 pad bits zero), always checked
  LD r4,r0,@d32_tot
  MOVI r6,4
  ADD r4,r4,r6
  LD r6,r0,@d32_cap
  CMP r6,r4
  JMP[LT] @d32_skip7
  SHL r7,r5,6              ; b0 = ((c0&3)<<6)|(c1<<1)|(c2>>4)
  LD r5,r0,@d32c1
  SHL r5,r5,1
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c2
  SHR r5,r5,4
  BOOL.14 r7,r7,r5
  STB r7,r3,0
  LD r5,r0,@d32c2
  MOVI r6,15
  BOOL.8 r8,r5,r6          ; b1 = ((c2&0xF)<<4)|((c3>>1)&0xF)
  SHL r8,r8,4
  LD r5,r0,@d32c3
  SHR r5,r5,1
  MOVI r6,15
  BOOL.8 r5,r5,r6
  BOOL.14 r8,r8,r5
  STB r8,r3,1
  LD r5,r0,@d32c3
  MOVI r6,1
  BOOL.8 r7,r5,r6          ; b2 = ((c3&1)<<7)|(c4<<2)|((c5>>3)&3)
  SHL r7,r7,7
  LD r5,r0,@d32c4
  SHL r5,r5,2
  BOOL.14 r7,r7,r5
  LD r5,r0,@d32c5
  SHR r5,r5,3
  MOVI r6,3
  BOOL.8 r5,r5,r6
  BOOL.14 r7,r7,r5
  STB r7,r3,2
  LD r5,r0,@d32c5
  MOVI r6,7
  BOOL.8 r8,r5,r6          ; b3 = ((c5&7)<<5)|c6
  SHL r8,r8,5
  LD r5,r0,@d32c6
  BOOL.14 r8,r8,r5
  STB r8,r3,3
  ADDI r3,r3,4
d32_skip7:
  LD r6,r0,@d32_tot
  MOVI r7,4
  ADD r6,r6,r7
  ST r6,r0,@d32_tot
  CMP r2,r0
  JMP[NE] @d32_chunkator
  JMP @d32_fin
d32_chunkator:             ; mid-input: next chunk (slots reused)
  JMP @d32_chunk
d32_fin:
  LD r6,r0,@d32_tot        ; total = required length
  LD r7,r0,@d32_cap
  CMP r7,r6
  JMP[LT] @d32_nospc
  ADD r5,r6,r0             ; produced = total
  LD r15,r0,@d32_ret
  RET
d32_nospc:
  MOVI r8,0xFFFF
  BOOL.8 r8,r6,r8          ; required & 0xFFFF
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@d32_ret
  RET
d32_proto:
  MOVI r5,0
  MOVHI r5,#NET_EPROTO
  LD r15,r0,@d32_ret
  RET
d32_ret:
.word 0
d32_tot:
.word 0
d32_cap:
.word 0
d32c0:
.word 0
d32c1:
.word 0
d32c2:
.word 0
d32c3:
.word 0
d32c4:
.word 0
d32c5:
.word 0
d32c6:
.word 0
d32c7:
.word 0
