; xor.nas - 0x0E0B XOR_CHAIN byte codec. Self-inverse stream cipher:
;   c[i] = p[i] ^ key[i mod klen] ^ c[i-1]   (c[-1] = 0)
; The chained output is its own key on the way back (decode == encode).
;
; ABI (defs.nas): r1 in, r2 inlen, r3 out, r4 outcap,
;   r5 = key WORD index (vec ABI: raw cfg arg; this codec shifts it),
;   r6 = klen (1..anything nonzero) -> r5 ret word.
; need = inlen; klen == 0 is EINVAL (bad configuration).
; Chain state and key cursor live in local slots (r9..r12 are reserved);
; wave N7 moves them to registers when the realtime frame core lands.
; SHL/SHR take literal immediates only.
; Labels: xoc_*.

xor_ec:                     ; -> r5 = (err<<16)|value
  ST r15,r0,@xoc_ret
  SHL r5,r5,2              ; cfg1 word idx -> byte addr
  CMP r6,r0
  JMP[EQ] @xoc_ival        ; klen == 0: EBADCFG
  ST r2,r0,@xoc_need       ; needed = produced = inlen
  CMP r4,r2
  JMP[LT] @xoc_nospc
  ST r0,r0,@xoc_chain      ; chain = 0
  ST r6,r0,@xoc_kl         ; park klen (r6 reused below)
  MOVI r8,0                ; key cursor
xoc_l:
  CMP r2,r0
  JMP[EQ] @xoc_done
  LDB r7,r1,0              ; p
  ADD r6,r5,r8             ; key byte addr = key + cursor
  LDB r6,r6,0              ; k
  BOOL.6 r7,r7,r6          ; p ^= k
  LD r6,r0,@xoc_chain
  BOOL.6 r7,r7,r6          ; p ^= chain
  ST r7,r0,@xoc_chain      ; chain = c
  STB r7,r3,0
  ADDI r1,r1,1
  ADDI r3,r3,1
  ADDI r8,r8,1             ; cursor++
  LD r6,r0,@xoc_kl
  CMP r8,r6
  JMP[LT] @xoc_l           ; cursor < klen: keep
  MOVI r8,0                ; wrapped
  JMP @xoc_l
xoc_done:
  LD r5,r0,@xoc_need
  LD r15,r0,@xoc_ret
  RET
xoc_nospc:
  LD r6,r0,@xoc_need
  MOVI r8,0xFFFF
  BOOL.8 r8,r6,r8          ; needed & 0xFFFF
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@xoc_ret
  RET
xoc_ival:
  MOVI r5,0
  MOVHI r5,#NET_EINVAL
  LD r15,r0,@xoc_ret
  RET
xoc_ret:
.word 0
xoc_need:
.word 0
xoc_chain:
.word 0
xoc_kl:
.word 0
