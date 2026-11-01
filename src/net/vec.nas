; vec.nas - NaNnet vector runner (spec section 7). Each table entry is a
; 10-word record consumed here without host help:
;   +0 fn        word idx of the codec entry point (RUNNER CALLRs it)
;   +1 name      word idx of a NUL-padded name string
;   +2 in        word idx of input data
;   +3 out       word idx of the output scratch
;   +4 inlen     byte count
;   +5 outcap    byte count
;   +6 expect    expected return word (err<<16)|value
;   +7 k1        codec cfg arg 1 (raw u32)
;   +8 k2        codec cfg arg 2 (raw u32)
;   +9 exp       word idx of expected output bytes, or 0 for error vectors
;
; The runner prints "<name> OK" / "<name> X" per vector via PUTC, walks
; with stride 10 until fn == 0, and returns r5 = pass count, r6 = fail
; count. Compare against r6 == 0 for the gate.
;
; Register reservation (codec ABI, defs.nas): vec_run lives in r10 (table
; cursor), r11 (pass), r12 (fail); codecs never touch r9..r12.
; CALL metadata: r13 must be 1 when vec_run is called (tree convention).
; Labels: vr_*.

vec_run:                    ; r1 = table word idx -> r5 pass, r6 fail
  ST r15,r0,@vr_ret
  ADD r10,r1,r0
  MOVI r11,0
  MOVI r12,0
vr_e:
  LD r9,r10,0              ; fn
  CMP r9,r0
  JMP[EQ] @vr_done
  LD r8,r10,1              ; name
  SHL r8,r8,2
  CALL @vr_pstr
  LD r1,r10,2              ; in
  SHL r1,r1,2
  LD r2,r10,4              ; inlen
  LD r3,r10,3              ; out
  SHL r3,r3,2
  LD r4,r10,5              ; outcap
  LD r5,r10,7              ; k1 (raw)
  LD r6,r10,8              ; k2 (raw)
  CALLR r9                 ; run codec -> r5 ret word
  LD r8,r10,6              ; expect
  CMP r5,r8
  JMP[NE] @vr_fail
  SHR r8,r8,16             ; high half set => error vector, whole-word match
  CMP r8,r0
  JMP[NE] @vr_passok
  ; success vector: compare produced bytes against exp
  LD r1,r10,3              ; out
  SHL r1,r1,2
  LD r2,r10,9              ; exp
  SHL r2,r2,2
  ADD r3,r5,r0             ; produced byte count
  CALL @vr_cmp             ; r4 = 1 when equal
  CMP r4,r0
  JMP[EQ] @vr_fail
vr_passok:
  ADDI r11,r11,1
  MOVI r8,32               ; ' '
  PUTC r8
  MOVI r8,79               ; 'O'
  PUTC r8
  MOVI r8,75               ; 'K'
  PUTC r8
  MOVI r8,10               ; '\n'
  PUTC r8
  JMP @vr_next
vr_fail:
  ADDI r12,r12,1
  MOVI r8,32
  PUTC r8
  MOVI r8,88               ; 'X'
  PUTC r8
  MOVI r8,10
  PUTC r8
vr_next:
  MOVI r9,10
  ADD r10,r10,r9
  JMP @vr_e
vr_done:
  ADD r5,r11,r0
  ADD r6,r12,r0
  LD r15,r0,@vr_ret
  RET

; print NUL-terminated string, one PUTC per byte (leaves r9..r12 intact)
vr_pstr:                    ; r8 = byte addr
  LDB r7,r8,0
  CMP r7,r0
  JMP[EQ] @vr_pdone
  PUTC r7
  ADDI r8,r8,1
  JMP @vr_pstr
vr_pdone:
  RET

; byte compare: r1 A, r2 B, r3 len -> r4 = 1 equal / 0 differ (leaf)
vr_cmp:
  MOVI r4,1
vr_cmp_l:
  CMP r3,r0
  JMP[EQ] @vr_cmp_e
  LDB r6,r1,0
  LDB r7,r2,0
  CMP r6,r7
  JMP[NE] @vr_cmp_d
  ADDI r1,r1,1
  ADDI r2,r2,1
  SUB r3,r3,r13
  JMP @vr_cmp_l
vr_cmp_d:
  MOVI r4,0
vr_cmp_e:
  RET
vr_ret:
.word 0
