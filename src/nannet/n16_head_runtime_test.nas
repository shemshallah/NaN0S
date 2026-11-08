; End-to-end native NaN16 runtime -> attached scratch -> learning -> recovery.
.org 0
JMP @main
.include "n16_head_store.nas"
.include "n16_head_runtime.nas"
main:
  MOVI r13,1
  MOVI r10,65
  ST r10,r0,@diag
  ; Unformatted banks may never be attached.
  MOVI r1,16384
  CALL @nhr_attach
  MOVI r7,1
  CMP r5,r7
  JMP[NE] @fail
  MOVI r10,66
  ST r10,r0,@diag
  MOVI r1,16384
  CALL @nh_format
  CMP r5,r0
  JMP[NE] @fail
  MOVI r1,16384
  CALL @nhr_attach
  CMP r5,r0
  JMP[NE] @fail

  MOVI r10,67
  ST r10,r0,@diag
  ; Virgin head 1, feature 12 -> 3; no host-side score calculation.
  MOVI r1,1
  MOVI r2,12
  MOVI r3,3
  MOVI r4,4096
  CALL @nhr_observe
  CMP r5,r0
  JMP[NE] @fail
  MOVI r7,1
  CMP r6,r7
  JMP[NE] @fail

  MOVI r10,68
  ST r10,r0,@diag
  ; Second generation -> 5; distinct feature remains zero.
  MOVI r1,1
  MOVI r2,12
  MOVI r3,2
  MOVI r4,4096
  CALL @nhr_observe
  CMP r5,r0
  JMP[NE] @fail
  MOVI r7,2
  CMP r6,r7
  JMP[NE] @fail
  MOVI r10,69
  ST r10,r0,@diag
  MOVI r1,1
  MOVI r2,8192
  CALL @nhr_read
  CMP r5,r0
  JMP[NE] @fail
  MOVI r7,2
  CMP r6,r7
  JMP[NE] @fail
  LD r7,r0,8204
  MOVI r8,5
  CMP r7,r8
  JMP[NE] @fail
  LDN r7,r0,8204
  MOVI r8,6
  CMP r7,r8
  JMP[NE] @fail
  LD r7,r0,8205
  CMP r7,r0
  JMP[NE] @fail

  MOVI r10,70
  ST r10,r0,@diag
  ; Head 255 is independent of head 1.
  MOVI r1,255
  MOVI r2,12
  MOVI r3,7
  MOVI r4,4096
  CALL @nhr_observe
  CMP r5,r0
  JMP[NE] @fail
  MOVI r1,255
  MOVI r2,8192
  CALL @nhr_read
  CMP r5,r0
  JMP[NE] @fail
  LD r7,r0,8204
  MOVI r8,7
  CMP r7,r8
  JMP[NE] @fail

  MOVI r10,71
  ST r10,r0,@diag
  ; Native stale-slot recovery: corrupt head 1's newest commit marker.
  ST r0,r0,16529
  MOVI r1,1
  MOVI r2,8192
  CALL @nhr_read
  CMP r5,r0
  JMP[NE] @fail
  MOVI r7,1
  CMP r6,r7
  JMP[NE] @fail
  LD r7,r0,8204
  MOVI r8,3
  CMP r7,r8
  JMP[NE] @fail

  MOVI r10,72
  ST r10,r0,@diag
  ; Recovery resumes from generation 1, then republishes generation 2.
  MOVI r1,1
  MOVI r2,12
  MOVI r3,4
  MOVI r4,4096
  CALL @nhr_observe
  CMP r5,r0
  JMP[NE] @fail
  MOVI r7,2
  CMP r6,r7
  JMP[NE] @fail
  MOVI r1,1
  MOVI r2,8192
  CALL @nhr_read
  CMP r5,r0
  JMP[NE] @fail
  LD r7,r0,8204
  MOVI r8,7
  CMP r7,r8
  JMP[NE] @fail

  MOVI r10,73
  ST r10,r0,@diag
  ; A reserved point, invalid feature and bank alias cannot mutate a head.
  MOVI r1,0
  MOVI r2,12
  MOVI r3,1
  MOVI r4,4096
  CALL @nhr_observe
  MOVI r7,1
  CMP r5,r7
  JMP[NE] @fail
  MOVI r1,1
  MOVI r2,128
  MOVI r3,1
  MOVI r4,4096
  CALL @nhr_observe
  MOVI r7,1
  CMP r5,r7
  JMP[NE] @fail
  MOVI r1,1
  MOVI r2,12
  MOVI r3,1
  MOVI r4,16397
  CALL @nhr_observe
  MOVI r7,1
  CMP r5,r7
  JMP[NE] @fail

  MOVI r10,74
  ST r10,r0,@diag
  CALL @nhr_detach
  MOVI r1,1
  MOVI r2,8192
  CALL @nhr_read
  MOVI r7,1
  CMP r5,r7
  JMP[NE] @fail
  MOVI r10,75
  ST r10,r0,@diag
  ; Reattachment is non-destructive.
  MOVI r1,16384
  CALL @nhr_attach
  CMP r5,r0
  JMP[NE] @fail
  MOVI r1,1
  MOVI r2,8192
  CALL @nhr_read
  CMP r5,r0
  JMP[NE] @fail
  LD r7,r0,8204
  MOVI r8,7
  CMP r7,r8
  JMP[NE] @fail

  MOVI r1,@passed
  CALL @puts
  HALT
fail:
  LD r1,r0,@diag
  PUTC r1
  MOVI r1,10
  PUTC r1
  MOVI r1,@failed
  CALL @puts
  HALT
puts:
  MOVI r4,255
word:
  LD r2,r1,0
  MOVI r3,4
byte:
  BOOL.8 r5,r2,r4
  CMP r5,r0
  RET[EQ]
  PUTC r5
  SHR r2,r2,8
  SUB r3,r3,r13
  JMP[NE] @byte
  ADD r1,r1,r13
  JMP @word
passed:
  .str "N16 HEAD RUNTIME PASS\n"
failed:
  .str "N16 HEAD RUNTIME FAIL\n"

diag:
  .word 0
