; hex.nas - 0x0E04 HEX_ASCII codec. Lowercase, 2 chars/byte, pairs are
; (hi nibble, lo nibble), MSB first on the wire per spec.
;
; ABI (src/net/defs.nas): r1 in, r2 inlen, r3 out, r4 cap -> r5 ret word.
; Internal contract: only r1..r8 touched, r9..r12 preserved; produced
; length through a local slot because helpers own r5.
; Helpers hx_nib/hx_val are leaves touching r4(in),r5,r6,r7 only.
; SHL/SHR take literal immediates only.
;
; Vectors consumed by src/tests/net_test.nas (per spec 7):
;   enc "hello"      -> "68656c6c6f"      10
;   enc ""           -> ""                0
;   enc "hello" cap9 -> (ENOSPC<<16)|10
;   dec "303132"     -> "012"             3
;   dec "30313"      -> (EPROTO<<16)|0    (odd length)
;   dec len6 cap2    -> (ENOSPC<<16)|3

; nib -> char: r4 = 0..15 -> r5; '0'+n for 0..9, 'a'+(n-10) = 87+n else. Leaf.
hx_nib:
  MOVI r5,87               ; 'a' - 10
  MOVI r6,9
  CMP r4,r6
  MOVI[LE] r5,48           ; '0'
  ADD r5,r5,r4
  RET

; char -> nib: r4 = char -> r6 = 0..15 or 0xFF invalid. Leaf.
hx_val:
  MOVI r6,48
  CMP r4,r6
  JMP[LT] @hx_v_bad        ; below '0'
  SUB r6,r4,r6             ; d = c - 48
  MOVI r7,10
  CMP r6,r7
  JMP[LT] @hx_v_ok         ; 0..9
  ADDI r6,r6,-39           ; d = c - 87
  MOVI r7,16
  CMP r6,r7
  JMP[LT] @hx_v_ok         ; 10..15 ('a'..'f')
hx_v_bad:
  MOVI r6,255
hx_v_ok:
  RET

; hex encode
he_enc:                    ; r1 in, r2 len, r3 out, r4 cap -> r5
  ST r15,r0,@he_ret
  MOVI r7,1
  SHL r7,r2,1              ; need = 2*len
  CMP r4,r7
  JMP[LT] @he_nospc
  ST r7,r0,@he_len         ; produced = need
he_l:
  CMP r2,r0
  JMP[EQ] @he_done
  LDB r8,r1,0              ; byte
  SHR r6,r8,4              ; hi nibble
  ADD r4,r6,r0
  CALL @hx_nib             ; r5 = char
  STB r5,r3,0
  MOVI r4,15
  BOOL.8 r4,r8,r4          ; r4 = low nibble
  CALL @hx_nib
  STB r5,r3,1
  ADDI r3,r3,2
  ADDI r1,r1,1
  SUB r2,r2,r13
  JMP @he_l
he_done:
  LD r5,r0,@he_len
  LD r15,r0,@he_ret
  RET
he_nospc:
  MOVI r8,0xFFFF
  BOOL.8 r8,r7,r8          ; need & 0xFFFF (need in r7)
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@he_ret
  RET
he_ret:
.word 0
he_len:
.word 0

; hex decode
he_dec:                    ; r1 in, r2 len, r3 out, r4 cap -> r5
  ST r15,r0,@hd_ret
  MOVI r7,1
  BOOL.8 r6,r2,r7          ; len & 1
  CMP r6,r0
  JMP[NE] @hd_proto        ; odd length malformed
  SHR r7,r2,1              ; need = len >> 1
  CMP r4,r7
  JMP[LT] @hd_nospc
  ST r7,r0,@hd_len
hd_l:
  CMP r2,r0
  JMP[EQ] @hd_done
  LDB r8,r1,0              ; hi char
  ADD r4,r8,r0
  CALL @hx_val             ; r6 = nib or 0xFF
  MOVI r7,255
  CMP r6,r7
  JMP[EQ] @hd_proto
  SHL r8,r6,4              ; hi << 4 parked in r8
  ADDI r1,r1,1
  LDB r6,r1,0              ; lo char
  ADD r4,r6,r0
  CALL @hx_val             ; r6 = nib or 0xFF
  ADDI r1,r1,1
  MOVI r7,255
  CMP r6,r7
  JMP[EQ] @hd_proto
  BOOL.14 r8,r8,r6         ; byte = (hi<<4) | lo
  STB r8,r3,0
  ADDI r3,r3,1
  ADDI r2,r2,-2            ; consumed 2 chars
  JMP @hd_l
hd_done:
  LD r5,r0,@hd_len
  LD r15,r0,@hd_ret
  RET
hd_nospc:
  MOVI r8,0xFFFF
  BOOL.8 r8,r7,r8
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@hd_ret
  RET
hd_proto:
  MOVI r5,0
  MOVHI r5,#NET_EPROTO
  LD r15,r0,@hd_ret
  RET
hd_ret:
.word 0
hd_len:
.word 0
