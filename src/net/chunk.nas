; chunk.nas - 0x0E09 CHUNK_SPLIT transport codec. Emits ceil(len/N) pieces,
; each a 1-byte piece length (N, or the short final piece) followed by that
; many raw bytes; the receiver re-chunks identically (self-describing flow
; per spec section 0x0E09).
;
; ABI (defs.nas): r1 in, r2 inlen, r3 out, r4 outcap,
;   r5 = N (piece size, 1..255) -> r5 ret word.
; need = inlen + ceil(inlen/N); N == 0 or N > 255 is EINVAL.
; Only r1..r8 touched; r6/r7/r8 scratch, r5 = N stays live in-loop.
; SHL/SHR take literal immediates only.
; Labels: cs_*.

chunk:                      ; -> r5 = (err<<16)|value
  ST r15,r0,@cs_ret
  CMP r5,r0
  JMP[EQ] @cs_ival
  MOVI r8,256
  CMP r5,r8
  JMP[GE] @cs_ival
  MOVI r8,1
  SUB r8,r5,r8             ; N-1
  ADD r8,r8,r2             ; len + N - 1
  DIVU r8,r8,r5            ; pieces = ceil(len/N)
  ADD r8,r8,r2             ; need
  ST r8,r0,@cs_need
  CMP r4,r8
  JMP[LT] @cs_nospc        ; cap vs need (r4 untouched so far)
cs_l:
  CMP r2,r0
  JMP[EQ] @cs_done
  CMP r2,r5                ; remaining vs N
  JMP[LT] @cs_last
  ADD r8,r5,r0             ; piece = N
  JMP @cs_have
cs_last:
  ADD r8,r2,r0             ; piece = remaining
cs_have:
  STB r8,r3,0              ; piece length byte
  ADDI r3,r3,1
  ADD r7,r8,r0             ; copy counter
cs_c:
  CMP r7,r0
  JMP[EQ] @cs_cend
  LDB r6,r1,0
  STB r6,r3,0
  ADDI r1,r1,1
  ADDI r3,r3,1
  SUB r7,r7,r13
  JMP @cs_c
cs_cend:
  SUB r2,r2,r8             ; remaining -= piece
  JMP @cs_l
cs_done:
  LD r5,r0,@cs_need
  LD r15,r0,@cs_ret
  RET
cs_nospc:
  LD r6,r0,@cs_need
  MOVI r8,0xFFFF
  BOOL.8 r8,r6,r8
  MOVHI r8,#NET_ENOSPC
  ADD r5,r8,r0
  LD r15,r0,@cs_ret
  RET
cs_ival:
  MOVI r5,0
  MOVHI r5,#NET_EINVAL
  LD r15,r0,@cs_ret
  RET
cs_ret:
.word 0
cs_need:
.word 0
