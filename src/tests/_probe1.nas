; THROWAWAY probe (r29): call b64/xor codecs directly, print r5 (8 hex digits) + produced bytes.
; REMOVE AFTER DEBUGGING. Gate: runbig --isa1.
JMP @m
.include "../net/defs.nas"
.include "../net/b64.nas"
.include "../net/xor.nas"
m:
  MOVI r13,1
  MOVI r4,65             ; 'A' marker
  PUTC r4
  MOVI r4,10
  PUTC r4
  ; ---- b64 encode "hello" (len 5)
  MOVI r1,@v_h
  SHL r1,r1,2
  MOVI r2,5
  MOVI r3,@bo
  SHL r3,r3,2
  MOVI r4,32
  CALL @be_enc
  CALL @m_show           ; print r5 then bo[0..7]
  ; ---- b64 decode "aGVsbG8" (len 7)
  MOVI r4,66             ; 'B'
  PUTC r4
  MOVI r4,10
  PUTC r4
  MOVI r1,@v_b6
  SHL r1,r1,2
  MOVI r2,7
  MOVI r3,@bo
  SHL r3,r3,2
  MOVI r4,32
  CALL @be_dec
  CALL @m_show
  ; ---- b64 encode "a" (len 1)
  MOVI r4,67             ; 'C'
  PUTC r4
  MOVI r4,10
  PUTC r4
  MOVI r1,@v_a
  SHL r1,r1,2
  MOVI r2,1
  MOVI r3,@bo
  SHL r3,r3,2
  MOVI r4,32
  CALL @be_enc
  CALL @m_show
  ; ---- xor "AB" key "K3" klen 2
  MOVI r4,68             ; 'D'
  PUTC r4
  MOVI r4,10
  PUTC r4
  MOVI r1,@v_x
  SHL r1,r1,2
  MOVI r2,2
  MOVI r3,@bo
  SHL r3,r3,2
  MOVI r4,32
  MOVI r5,@v_k
  MOVI r6,2
  CALL @xor_ec
  CALL @m_show
  HALT
; print r5 as 8 lowercase hex digits, newline, then the 8 bytes at word bo as
; printable chars ('.' for <32), newline. Clobbers r4..r9.
m_show:
  MOVI r8,0
  ADD r8,r5,r0           ; r8 = value
  MOVI r6,0              ; digits
ms_l:
  MOVI r4,15
  BOOL.8 r9,r8,r4        ; nib
  MOVI r4,10
  CMP r9,r4
  MOVI r4,48
  ADD[LT] r4,r4,r9       ; '0'+nib
  JMP[LT] @ms_put
  MOVI r4,87
  ADD r4,r4,r9           ; 'a'+nib-10
ms_put:
  PUTC r4
  SHR r8,r8,4
  ADDI r6,r6,1
  MOVI r4,8
  CMP r6,r4
  JMP[LT] @ms_l
  MOVI r4,10
  PUTC r4
  MOVI r9,@bo
  SHL r9,r9,2
  MOVI r6,0
ms_b:
  MOVI r4,8
  CMP r6,r4
  JMP[GE] @ms_x
  LDB r7,r9,0
  MOVI r4,31
  CMP r7,r4
  JMP[LT] @ms_dot
  PUTC r7
  JMP @ms_adv
ms_dot:
  MOVI r4,46
  PUTC r4
ms_adv:
  ADDI r9,r9,1
  ADDI r6,r6,1
  JMP @ms_b
ms_x:
  MOVI r4,10
  PUTC r4
  RET
v_h:
  .str "hello"
v_b6:
  .str "aGVsbG8"
v_a:
  .str "a"
v_x:
  .str "AB"
v_k:
  .str "K3"
bo:
  .word 0,0,0,0
