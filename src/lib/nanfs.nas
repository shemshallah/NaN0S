; nanfs.nas - NaNFS RAM slice. 64-word blocks (512 bytes), block 0 superblock,
; block 1 bitmap (one word per block), data from block 2.
.equ NF_BLOCK 64
.equ NF_MAGIC 0x4E465331

; format: r1=base, r2=blocks (>=3)
nanfs_format:
  ST r15,r0,@nf_f_ret
  ST r1,r0,@nf_base
  ST r2,r0,@nf_blocks
  LA r3,#NF_MAGIC
  ST r3,r1,0
  ST r2,r1,1
  MOVI r4,2
  SUB r5,r2,r4
  ST r5,r1,2
  ST r4,r1,3
  MOVI r6,64
  ADD r6,r6,r1
  MOVI r9,0
nff_l:
  ST r0,r6,0
  ADD r6,r6,r13
  ADD r9,r9,r13
  CMP r9,r2
  JMP[LT] @nff_l
  LD r15,r0,@nf_f_ret
  RET
nf_f_ret:
.word 0

; alloc: r1=base, r2=blocks -> r1=block index (>=2) or 0
nanfs_alloc:
  ST r15,r0,@nf_a_ret
  MOVI r3,2
nfa_l:
  CMP r3,r2
  JMP[GE] @nfa_fail
  MOVI r4,64
  ADD r4,r4,r1
  ADD r4,r4,r3
  LD r5,r4,0
  CMP r5,r0
  JMP[NE] @nfa_next
  MOVI r5,1
  ST r5,r4,0
  LD r4,r0,@nf_base
  LD r5,r4,2
  SUB r5,r5,r13
  ST r5,r4,2
  ADD r1,r3,r0
  LD r15,r0,@nf_a_ret
  RET
nfa_next:
  ADD r3,r3,r13
  JMP @nfa_l
nfa_fail:
  MOVI r1,0
  LD r15,r0,@nf_a_ret
  RET
nf_a_ret:
.word 0
nf_base:
.word 0
nf_blocks:
.word 0

; write: r1=base, r2=block, r3=source buffer
nanfs_write:
  MOVI r4,#NF_BLOCK
  MUL r4,r2,r4
  ADD r4,r4,r1
  ADD r1,r4,r0
  ADD r2,r3,r0
  MOVI r3,#NF_BLOCK
  BCOPY r1,r2,r3
  RET

; read: r1=base, r2=block, r3=destination buffer
nanfs_read:
  MOVI r4,#NF_BLOCK
  MUL r4,r2,r4
  ADD r4,r4,r1
  ADD r2,r4,r0
  ADD r1,r3,r0
  MOVI r3,#NF_BLOCK
  BCOPY r1,r2,r3
  RET
