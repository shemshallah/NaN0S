; b64.nas - 0x0E02 BASE64URL (RFC 4648 section 5, alphabet "AB..Za..z0..9-_",
; no pad). Pure byte codec: 3 bytes <-> 4 chars, tails 2 chars (1 byte) and
; 3 chars (2 bytes).
;
; ABI (defs.nas): r1 in, r2 inlen, r3 out, r4 outcap -> r5 ret word.
; Decoding accepts full 4-char groups and 3/2-char tails; len mod 4 == 1 is
; malformed (EPROTO); any out-of-alphabet char is malformed (EPROTO);
; non-canonical trailing bits are rejected (strict, EPROTO).
; Helpers are leaves touching r4(in),r5,r6 only; r7/r8 preserved.
; SHL/SHR take literal immediates only.
; Labels: b4_* helpers, be_* encode, bd_* decode.

; r4 = 0..63 -> r5 = base64url char
b4_char:
  MOVI r5,26
  CMP r4,r5
  MOVI r6,65               ; 'A'
  ADD[LT] r6,r6,r4         ; val<26: 'A'+val
  JMP[LT] @b4_c_done
  MOVI r5,52
  CMP r4,r5
  MOVI r6,71               ; 'a'-26
  ADD[LT] r6,r6,r4         ; 26..51: 'a'+(val-26)
  JMP[LT] @b4_c_done
  MOVI r5,62
  CMP r4,r5
  MOVI r6,4                ; '0'-52
  ADD[LT] r6,r6,r4         ; 52..61: '0'+(val-52)
  JMP[LT] @b4_c_done
  MOVI[EQ] r6,45           ; '-'
  MOVI[NE] r6,95           ; '_'
b4_c_done:
  ADD r5,r6,r0
  RET

; r4 = char -> r5 = 0..63 or 255 invalid (never touches r7/r8)
b4_val:
  MOVI r6,65
  CMP r4,r6
  JMP[LT] @b4v_low
  MOVI r6,91
  CMP r4,r6
  JMP[GE] @b4v_low
  ADDI r5,r4,-65           ; 0..25
  JMP @b4v_ret
b4v_low:
  MOVI r6,97
  CMP r4,r6
  JMP[LT] @b4v_dig
  MOVI r6,123
  CMP r4,r6
  JMP[GE] @b4v_dig
  ADDI r5,r4,-71           ; 26..51
  JMP @b4v_ret
b4v_dig:
  MOVI r6,48
  CMP r4,r6
  JMP[LT] @b4v_dash
  MOVI r6,58
  CMP r4,r6
  JMP[GE] @b4v_dash
  ADDI r5,r4,4             ; 52..61
  JMP @b4v_ret
b4v_dash:
  MOVI r6,45
  CMP r4,r6
  JMP[NE] @b4v_us
  MOVI r5,62
  JMP @b4v_ret
b4v_us:
  MOVI r6,95
  CMP r4,r6
  JMP[NE] @b4v_bad
  MOVI r5,63
  JMP @b4v_ret
b4v_bad:
  MOVI r5,255
b4v_ret:
  RET

; base64url encode
be_enc:                    ; r1 in, r2 len, r3 out, r4 cap -> r5
  ST r15,r0,@be_ret
  ST r4,r0,@be_cap         ; park cap (r4 becomes literal holder below)
  MOVI r4,2
  ADD r6,r2,r4             ; len+2
  MOVI r4,3
  DIVU r6,r6,r4            ; q = ceil(len/3)
  MOVI r4,3
  MODU r7,r2,r4            ; rem = len%3
  SHL r6,r6,2              ; 4*q
  MOVI r8,0                ; pad delta (stays 0 when rem==0)
  CMP r7,r0
  JMP[EQ] @be_pd
  MOVI r4,2
  CMP r7,r4
  MOVI[LT] r8,2            ; rem==1 -> 2
  MOVI[GE] r8,1            ; rem==2 -> 1
be_pd:
  SUB r6,r6,r8             ; need = 4*q - delta
  ST r6,r0,@be_need
  LD r4,r0,@be_cap
  CMP r4,r6
  JMP[LT] @be_nospc
be_g:
  MOVI r4,3
  CMP r2,r4
  JMP[LT] @be_tail
  LDB r7,r1,0              ; b0
  SHL r8,r7,16             ; v = b0<<16
  ADDI r1,r1,1
  LDB r7,r1,0              ; b1
  SHL r7,r7,8
  BOOL.14 r8,r8,r7         ; v |= b1<<8
  ADDI r1,r1,1
  LDB r7,r1,0              ; b2
  BOOL.14 r8,r8,r7         ; v |= b2
  ADDI r1,r1,1
  SHR r7,r8,18             ; c0 = v>>18 (6 bits)
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,0
  SHR r7,r8,12
  MOVI r4,63
  BOOL.8 r7,r7,r4          ; c1 = (v>>12)&63
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,1
  SHR r7,r8,6
  MOVI r4,63
  BOOL.8 r7,r7,r4          ; c2
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,2
  MOVI r4,63
  BOOL.8 r7,r8,r4          ; c3 = v&63
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,3
  ADDI r3,r3,4
  ADDI r2,r2,-3
  JMP @be_g
be_tail:
  CMP r2,r0
  JMP[EQ] @be_done
  MOVI r4,2
  CMP r2,r4
  JMP[EQ] @be_t2           ; r2==2 -> t2, else (r2==1) falls to t1
be_t1:                     ; one byte -> 2 chars
  LDB r7,r1,0
  SHR r8,r7,2              ; c0 = b>>2 (6 bits)
  ADD r4,r8,r0
  CALL @b4_char
  STB r5,r3,0
  MOVI r4,3
  BOOL.8 r8,r7,r4          ; b&3
  SHL r8,r8,4              ; c1 = (b&3)<<4
  ADD r4,r8,r0
  CALL @b4_char
  STB r5,r3,1
  ADDI r3,r3,2
  JMP @be_done
be_t2:                     ; two bytes -> 3 chars
  LDB r7,r1,0
  SHL r8,r7,8              ; v = b0<<8
  ADDI r1,r1,1
  LDB r7,r1,0
  BOOL.14 r8,r8,r7         ; v |= b1
  SHR r7,r8,10             ; c0 = v>>10 (6 bits)
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,0
  SHR r7,r8,4
  MOVI r4,63
  BOOL.8 r7,r7,r4          ; c1 = (v>>4)&63
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,1
  MOVI r4,15
  BOOL.8 r7,r8,r4          ; v&0xF
  SHL r7,r7,2              ; c2 = (v&15)<<2
  ADD r4,r7,r0
  CALL @b4_char
  STB r5,r3,2
  ADDI r3,r3,3
be_done:
  LD r5,r0,@be_need
  LD r15,r0,@be_ret
  RET
be_nospc:
  MOVI r8,0xFFFF
  BOOL.8 r8,r6,r8          ; need & 0xFFFF (need in r6)
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@be_ret
  RET
be_ret:
.word 0
be_need:
.word 0
be_cap:
.word 0

; base64url decode
be_dec:                    ; r1 in, r2 len, r3 out, r4 cap -> r5
  ST r15,r0,@bd_ret
  ST r4,r0,@bd_cap
  MOVI r4,4
  MODU r6,r2,r4            ; rem = len%4
  MOVI r4,1
  CMP r6,r4
  JMP[EQ] @bd_proto        ; len%4==1 malformed
  MOVI r4,4
  DIVU r7,r2,r4            ; groups = len/4
  SHL r7,r7,2              ; 3*groups
  MOVI r8,0
  CMP r6,r0
  ADDI[NE] r8,r6,-1        ; rem 2 -> +1, rem 3 -> +2
  ADD r7,r7,r8             ; need
  ST r7,r0,@bd_need
  LD r4,r0,@bd_cap
  CMP r4,r7
  JMP[LT] @bd_nospc
bd_g:
  MOVI r4,4
  CMP r2,r4
  JMP[LT] @bd_tail
  ADDI r2,r2,-4
  LDB r8,r1,0              ; c0
  ADD r4,r8,r0
  CALL @b4_val             ; r5 = val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  SHL r7,r5,18             ; v = c0<<18
  ADDI r1,r1,1
  LDB r8,r1,0              ; c1
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  SHL r8,r5,12
  BOOL.14 r7,r7,r8         ; v |= c1<<12
  ADDI r1,r1,1
  LDB r8,r1,0              ; c2
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  SHL r8,r5,6
  BOOL.14 r7,r7,r8         ; v |= c2<<6
  ADDI r1,r1,1
  LDB r8,r1,0              ; c3
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  BOOL.14 r7,r7,r5         ; v |= c3
  ADDI r1,r1,1
  SHR r8,r7,16             ; b0 = v>>16
  STB r8,r3,0
  SHR r8,r7,8              ; b1 = (v>>8)&0xFF
  STB r8,r3,1
  STB r7,r3,2              ; b2 = v&0xFF
  ADDI r3,r3,3
  JMP @bd_g
bd_tail:
  CMP r2,r0
  JMP[EQ] @bd_done
  MOVI r4,3
  CMP r2,r4
  JMP[EQ] @bd_t3           ; r2==3 -> t3, else (r2==2) falls to t2
bd_t2:                     ; 2 chars -> 1 byte
  LDB r8,r1,0              ; c0
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  SHL r7,r5,6              ; v = c0<<6 (park in r7)
  ADDI r1,r1,1
  LDB r8,r1,0              ; c1
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  MOVI r4,3
  BOOL.8 r8,r5,r4          ; c1&3 (r8 scratch; v kept in r7)
  CMP r8,r0
  JMP[NE] @bd_proto        ; non-canonical trailing bits
  BOOL.14 r7,r7,r5         ; v |= c1
  SHR r7,r7,2              ; b0 = v>>2
  STB r7,r3,0
  ADDI r3,r3,1
  JMP @bd_done
bd_t3:                     ; 3 chars -> 2 bytes
  LDB r8,r1,0              ; c0
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  SHL r7,r5,12             ; v = c0<<12
  ADDI r1,r1,1
  LDB r8,r1,0              ; c1
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  SHL r8,r5,6
  BOOL.14 r7,r7,r8         ; v |= c1<<6
  ADDI r1,r1,1
  LDB r8,r1,0              ; c2
  ADD r4,r8,r0
  CALL @b4_val
  MOVI r6,255
  CMP r5,r6
  JMP[EQ] @bd_proto
  MOVI r4,3
  BOOL.8 r8,r5,r4          ; c2&3 (r8 scratch; v kept in r7)
  CMP r8,r0
  JMP[NE] @bd_proto        ; non-canonical trailing bits
  BOOL.14 r7,r7,r5         ; v |= c2
  SHR r8,r7,4              ; b0 = v>>4
  STB r8,r3,0
  MOVI r4,255
  BOOL.8 r8,r7,r4          ; b1 = v&0xFF
  STB r8,r3,1
  ADDI r3,r3,2
bd_done:
  LD r5,r0,@bd_need
  LD r15,r0,@bd_ret
  RET
bd_nospc:
  MOVI r8,0xFFFF
  BOOL.8 r8,r7,r8          ; need & 0xFFFF (need in r7)
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@bd_ret
  RET
bd_proto:
  MOVI r5,0
  MOVHI r5,#NET_EPROTO
  LD r15,r0,@bd_ret
  RET
bd_ret:
.word 0
bd_need:
.word 0
bd_cap:
.word 0
