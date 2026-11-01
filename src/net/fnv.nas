; fnv.nas - FNV-1a 32-bit digest. Spec section 6 uses it for the frame
; SEAL word; also the cheap content check for packet caches (wave N7).
; h = 0x811C9DC5; per byte: h ^= byte; h *= 0x01000193 (mod 2^32) via MUL.
;
; ABI: r1 = buf byte addr, r2 = len -> r3 = digest. Leaf-style loop,
; r15 saved via slot (no nested CALLs in the loop).
; MUL is a VM1 op: runbig needs --isa1; the A64/RV64/X86 cores implement
; it natively (universal op list, TODO r28d).
; Labels: fnv_*.

fnv32:                      ; r1 buf, r2 len -> r3 hash
  ST r15,r0,@fnv_ret
  MOVI r3,0x9DC5
  MOVHI r3,0x811C          ; h = 0x811C9DC5
  MOVI r4,0x0193
  MOVHI r4,0x0100          ; prime = 0x01000193
fnv_l:
  CMP r2,r0
  JMP[EQ] @fnv_done
  LDB r5,r1,0
  BOOL.6 r3,r3,r5          ; h ^= byte
  MUL r3,r3,r4             ; h *= prime
  ADDI r1,r1,1
  SUB r2,r2,r13
  JMP @fnv_l
fnv_done:
  LD r15,r0,@fnv_ret
  RET
fnv_ret:
.word 0
