; nanfs.nas — validated NaN16 RAM block store (NFS1 compatible).
; The guest alone owns allocation, bitmap, bounds and block copying.
; One block = 64 NaN16 words (512 bytes). Caller supplies a valid RAM slice.
;   block 0: [magic, block_count, free_data_blocks, first_data_block]
;   blocks 1..ceil(count/64): one 32-bit allocation marker per block index
;   remaining blocks: payload; allocated blocks are zeroed before reuse.
; Format is destructive; all other functions work after process-local reload
; with no global mount pointer. This is a RAM store, NOT a disk flush driver.
; Single guest execution only; no concurrent/interleaved calls.
;
; ABI (r13 must hold 1, r0 is the zero register):
;   format r1=base, r2=blocks -> r3=0 success/1 invalid
;   verify r1=base -> r3=0 header valid/1 invalid
;   check  r1=base, r2=expected blocks -> r3=0 valid/1 corruption
;   alloc  r1=base, r2=expected blocks -> r1=index or 0, r3=0/1/3
;   free   r1=base, r2=block -> r3=0/1 bad/2 not allocated
;   write  r1=base, r2=block, r3=source -> r4=0/1 bad/2 not allocated
;   read   r1=base, r2=block, r3=destination -> r4=0/1 bad/2 not allocated
; Status 3 = full. Failed read/write never touches caller buffer.
; Returns clobber r3..r12 except for the explicitly described outputs.
; Each routine is non-reentrant and uses a private NaN16 return cell.
.equ NF_BLOCK 64
.equ NF_MAGIC 0x4E465331
.equ NF_MAX_BLOCKS 16384

; Require at least 3 blocks, cap the block count and reject destructive
; formatting over guest code at low addresses.
nanfs_format:
  ST r15,r0,@nf_f_ret
  MOVI r3,4096
  CMP r1,r3
  JMP[LT] @nf_f_bad
  MOVI r3,3
  CMP r2,r3
  JMP[LT] @nf_f_bad
  LA r3,#NF_MAX_BLOCKS
  CMP r2,r3
  JMP[GT] @nf_f_bad
  MOVI r4,63
  ADD r4,r2,r4
  SHR r4,r4,6
  ADD r4,r4,r13
  CMP r4,r2
  JMP[GE] @nf_f_bad
  ; Commit header only after preflight; metadata markers follow.
  LA r5,#NF_MAGIC
  ST r5,r1,0
  ST r2,r1,1
  SUB r5,r2,r4
  ST r5,r1,2
  ST r4,r1,3
  MOVI r6,64
  ADD r6,r6,r1
  MOVI r9,0
nf_f_loop:
  ; A reserved block is never available to the allocator.
  CMP r9,r4
  JMP[LT] @nf_f_reserved
  ST r0,r6,0
  JMP @nf_f_next
nf_f_reserved:
  ST r13,r6,0
nf_f_next:
  ADD r6,r6,r13
  ADD r9,r9,r13
  CMP r9,r2
  JMP[LT] @nf_f_loop
  MOVI r3,0
  LD r15,r0,@nf_f_ret
  RET
nf_f_bad:
  MOVI r3,1
  LD r15,r0,@nf_f_ret
  RET
nf_f_ret:
  .word 0

; Fast structural header validation (not a full bitmap integrity scan).
; r1 remains the base; r2 is not changed.
nanfs_verify:
  LA r4,#NF_MAGIC
  LD r5,r1,0
  CMP r5,r4
  JMP[NE] @nf_v_bad
  LD r5,r1,1
  MOVI r6,3
  CMP r5,r6
  JMP[LT] @nf_v_bad
  LA r6,#NF_MAX_BLOCKS
  CMP r5,r6
  JMP[GT] @nf_v_bad
  MOVI r6,63
  ADD r6,r5,r6
  SHR r6,r6,6
  ADD r6,r6,r13
  LD r7,r1,3
  CMP r6,r7
  JMP[NE] @nf_v_bad
  SUB r8,r5,r6
  LD r7,r1,2
  CMP r7,r8
  JMP[GT] @nf_v_bad
  MOVI r3,0
  RET
nf_v_bad:
  MOVI r3,1
  RET

; Full on-mount bitmap check. Detects free-count drift, non-binary
; markers, and any metadata block marked free. No mutation on failure.
nanfs_check:
  ST r15,r0,@nf_c_ret
  CALL @nanfs_verify
  CMP r3,r0
  JMP[NE] @nf_c_bad
  LD r4,r1,1
  CMP r2,r4
  JMP[NE] @nf_c_bad
  LD r5,r1,3
  MOVI r6,64
  ADD r6,r6,r1
  MOVI r7,0
  MOVI r8,0
nf_c_loop:
  LD r9,r6,0
  CMP r7,r5
  JMP[LT] @nf_c_reserved
  CMP r9,r0
  JMP[EQ] @nf_c_free
  CMP r9,r13
  JMP[NE] @nf_c_bad
  JMP @nf_c_next
nf_c_free:
  ADD r8,r8,r13
  JMP @nf_c_next
nf_c_reserved:
  CMP r9,r13
  JMP[NE] @nf_c_bad
nf_c_next:
  ADD r6,r6,r13
  ADD r7,r7,r13
  CMP r7,r4
  JMP[LT] @nf_c_loop
  LD r9,r1,2
  CMP r9,r8
  JMP[NE] @nf_c_bad
  MOVI r3,0
  LD r15,r0,@nf_c_ret
  RET
nf_c_bad:
  MOVI r3,1
  LD r15,r0,@nf_c_ret
  RET
nf_c_ret:
  .word 0

; First-fit allocation with a zero-filled new payload. This intentionally
; does not cache the base from format: a reloaded/mounted store can allocate.
nanfs_alloc:
  ST r15,r0,@nf_a_ret
  CALL @nanfs_verify
  CMP r3,r0
  JMP[NE] @nf_a_bad
  LD r4,r1,1
  CMP r2,r4
  JMP[NE] @nf_a_bad
  LD r5,r1,2
  CMP r5,r0
  JMP[EQ] @nf_a_full
  LD r6,r1,3
nf_a_loop:
  CMP r6,r4
  JMP[GE] @nf_a_full
  MOVI r7,64
  ADD r7,r7,r1
  ADD r7,r7,r6
  LD r8,r7,0
  CMP r8,r0
  JMP[EQ] @nf_a_found
  CMP r8,r13
  JMP[NE] @nf_a_bad
  ADD r6,r6,r13
  JMP @nf_a_loop
nf_a_found:
  ; Clear payload *before* publishing the new allocation marker.
  MOVI r9,64
  MUL r10,r6,r9
  ADD r10,r10,r1
  MOVI r11,0
nf_a_zero:
  ST r0,r10,0
  ADD r10,r10,r13
  ADD r11,r11,r13
  CMP r11,r9
  JMP[LT] @nf_a_zero
  ST r13,r7,0
  LD r8,r1,2
  SUB r8,r8,r13
  ST r8,r1,2
  ADD r1,r6,r0
  MOVI r3,0
  LD r15,r0,@nf_a_ret
  RET
nf_a_bad:
  MOVI r1,0
  MOVI r3,1
  LD r15,r0,@nf_a_ret
  RET
nf_a_full:
  MOVI r1,0
  MOVI r3,3
  LD r15,r0,@nf_a_ret
  RET
nf_a_ret:
  .word 0

; A block can only be released once; metadata blocks cannot be freed.
nanfs_free:
  ST r15,r0,@nf_free_ret
  CALL @nanfs_verify
  CMP r3,r0
  JMP[NE] @nf_free_bad
  LD r4,r1,3
  CMP r2,r4
  JMP[LT] @nf_free_bad
  LD r4,r1,1
  CMP r2,r4
  JMP[GE] @nf_free_bad
  MOVI r5,64
  ADD r5,r5,r1
  ADD r5,r5,r2
  LD r6,r5,0
  CMP r6,r0
  JMP[EQ] @nf_free_absent
  CMP r6,r13
  JMP[NE] @nf_free_bad
  ST r0,r5,0
  LD r6,r1,2
  ADD r6,r6,r13
  ST r6,r1,2
  MOVI r3,0
  LD r15,r0,@nf_free_ret
  RET
nf_free_absent:
  MOVI r3,2
  LD r15,r0,@nf_free_ret
  RET
nf_free_bad:
  MOVI r3,1
  LD r15,r0,@nf_free_ret
  RET
nf_free_ret:
  .word 0

; Guarded 64-word copies. Read and write copy exactly one allocated block.
nanfs_write:
  ST r15,r0,@nf_w_ret
  ST r3,r0,@nf_w_source
  CALL @nanfs_verify
  CMP r3,r0
  JMP[NE] @nf_w_bad
  LD r5,r1,3
  CMP r2,r5
  JMP[LT] @nf_w_bad
  LD r5,r1,1
  CMP r2,r5
  JMP[GE] @nf_w_bad
  MOVI r5,64
  ADD r6,r1,r5
  ADD r6,r6,r2
  LD r7,r6,0
  CMP r7,r0
  JMP[EQ] @nf_w_absent
  CMP r7,r13
  JMP[NE] @nf_w_bad
  MUL r8,r2,r5
  ADD r1,r8,r1
  LD r2,r0,@nf_w_source
  MOVI r3,64
  BCOPY r1,r2,r3
  MOVI r4,0
  LD r15,r0,@nf_w_ret
  RET
nf_w_absent:
  MOVI r4,2
  LD r15,r0,@nf_w_ret
  RET
nf_w_bad:
  MOVI r4,1
  LD r15,r0,@nf_w_ret
  RET
nf_w_ret:
  .word 0
nf_w_source:
  .word 0

nanfs_read:
  ST r15,r0,@nf_r_ret
  ST r3,r0,@nf_r_destination
  CALL @nanfs_verify
  CMP r3,r0
  JMP[NE] @nf_r_bad
  LD r5,r1,3
  CMP r2,r5
  JMP[LT] @nf_r_bad
  LD r5,r1,1
  CMP r2,r5
  JMP[GE] @nf_r_bad
  MOVI r5,64
  ADD r6,r1,r5
  ADD r6,r6,r2
  LD r7,r6,0
  CMP r7,r0
  JMP[EQ] @nf_r_absent
  CMP r7,r13
  JMP[NE] @nf_r_bad
  MUL r8,r2,r5
  ADD r2,r8,r1
  LD r1,r0,@nf_r_destination
  MOVI r3,64
  BCOPY r1,r2,r3
  MOVI r4,0
  LD r15,r0,@nf_r_ret
  RET
nf_r_absent:
  MOVI r4,2
  LD r15,r0,@nf_r_ret
  RET
nf_r_bad:
  MOVI r4,1
  LD r15,r0,@nf_r_ret
  RET
nf_r_ret:
  .word 0
nf_r_destination:
  .word 0
