; NaN16 head scratch bank: 255 logical heads, double-buffered 1KiB snapshots.
; All addressing, version selection, checksum and publish rules execute in the
; native guest. Host must reserve an NH_WORDS-word, nonoverlapping RAM extent
; and persist/restore that raw extent atomically if disk durability is needed.
; This is NOT canonical training, NANNET merge, or a cryptographic signature.
;
; 8 words global header
; head n = base + 8 + (n-1)*266
;   slot 0 = head + 0, slot 1 = head + 133
; each slot = [magic, head, generation, checksum, commit] + 128 raw NaN16 words
; A slot is visible only when commit is written last and the checksum verifies.
; Checksums include both payload (LD) and class nibble (LDN) for each word;
; outer storage transport MUST additionally use SHA-256 for adversarial bytes.
;
; ABI (r13=1, r0=0, non-reentrant):
;   nh_format: r1=base -> r5=0 success,1 bad base (destructive reset)
;   nh_open:   r1=base -> r5=0 valid,1 not formatted
;   nh_put:    r1=base,r2=head(1..255),r3=source of 128 NaN16 words
;              -> r4=new generation, r5=0 success,1 invalid,3 exhausted
;   nh_get:    r1=base,r2=head,r3=destination (128 NaN16 words)
;              -> r4=generation, r5=0 success,1 invalid,2 not committed
; No failed get copies ANY destination bytes; prior slot survives torn publish.
; Source/destination spans cannot alias bank storage. Generation is capped
; at 0x7fffffff so guest signed CMP preserves chronological ordering.
; No concurrent guest callers.
.equ NH_MAGIC 0x4E485331
.equ NH_SLOT_MAGIC 0x4E484431
.equ NH_COMMIT 0x434D5431
.equ NH_STRIDE 266
.equ NH_SLOT 133
.equ NH_DATA 128
.equ NH_WORDS 67838

nh_format:
  ST r15,r0,@nh_format_ret
  MOVI r5,4096
  CMP r1,r5
  JMP[LT] @nh_format_bad
  ; Caller supplies adequate memory; avoid 32-bit address overflow.
  LA r5,0x00300000
  CMP r1,r5
  JMP[GT] @nh_format_bad
  LA r5,#NH_MAGIC
  ST r5,r1,0
  MOVI r5,255
  ST r5,r1,1
  LA r5,#NH_STRIDE
  ST r5,r1,2
  LA r5,#NH_DATA
  ST r5,r1,3
  MOVI r5,1
  ST r5,r1,4
  MOVI r5,0
  ST r5,r1,5
  ST r5,r1,6
  ST r5,r1,7
  ADDI r6,r1,8
  MOVI r7,255
nh_format_loop:
  ST r0,r6,4
  ADDI r6,r6,133
  ST r0,r6,4
  ADDI r6,r6,133
  SUB r7,r7,r13
  CMP r7,r0
  JMP[NE] @nh_format_loop
  MOVI r5,0
  LD r15,r0,@nh_format_ret
  RET
nh_format_bad:
  MOVI r5,1
  LD r15,r0,@nh_format_ret
  RET
nh_format_ret:
  .word 0

; Validate a 128-word staging span against the reserved head bank.
; r1=base, r3=span pointer -> r5=0 safe or 1 invalid.
nh_buffer_safe:
  MOVI r6,4096
  CMP r3,r6
  JMP[LT] @nh_buffer_bad
  LA r6,#NH_WORDS
  ADD r7,r1,r6
  CMP r3,r1
  JMP[LT] @nh_buffer_before
  CMP r3,r7
  JMP[LT] @nh_buffer_bad
  ; Destination follows the bank; stay within canonical VM guest memory.
  ADDI r8,r3,128
  LA r9,0x00400000
  CMP r8,r9
  JMP[GT] @nh_buffer_bad
  JMP @nh_buffer_ok
nh_buffer_before:
  ADDI r8,r3,128
  CMP r8,r1
  JMP[GT] @nh_buffer_bad
nh_buffer_ok:
  MOVI r5,0
  RET
nh_buffer_bad:
  MOVI r5,1
  RET

nh_open:
  LA r4,#NH_MAGIC
  LD r5,r1,0
  CMP r5,r4
  JMP[NE] @nh_open_bad
  LD r4,r1,1
  MOVI r5,255
  CMP r4,r5
  JMP[NE] @nh_open_bad
  LD r4,r1,2
  LA r5,#NH_STRIDE
  CMP r4,r5
  JMP[NE] @nh_open_bad
  LD r4,r1,3
  LA r5,#NH_DATA
  CMP r4,r5
  JMP[NE] @nh_open_bad
  LD r4,r1,4
  MOVI r5,1
  CMP r4,r5
  JMP[NE] @nh_open_bad
  MOVI r5,0
  RET
nh_open_bad:
  MOVI r5,1
  RET

; Fold class and payload from 128 source words. Noncryptographic 32-bit code.
; r1=source; returns r2=checksum; clobbers r1,r4,r6..r9.
nh_hash:
  LA r2,0x811C9DC5
  MOVI r4,128
nh_hash_loop:
  LD r6,r1,0
  LDN r7,r1,0
  BOOL.6 r6,r6,r7
  BOOL.6 r2,r2,r6
  SHL r8,r2,5
  SHR r9,r2,27
  BOOL.14 r2,r8,r9
  ADD r2,r2,r6
  ADD r1,r1,r13
  SUB r4,r4,r13
  CMP r4,r0
  JMP[NE] @nh_hash_loop
  RET

; Validate a particular slot and its raw 128 word payload.
; r1=slot, r2=head; -> r3=1 valid / 0 invalid, r4=epoch / 0
nh_valid:
  ST r15,r0,@nh_valid_ret
  ST r1,r0,@nh_valid_ptr
  ST r2,r0,@nh_valid_head
  LA r6,#NH_SLOT_MAGIC
  LD r7,r1,0
  CMP r7,r6
  JMP[NE] @nh_valid_bad
  LD r7,r1,1
  CMP r7,r2
  JMP[NE] @nh_valid_bad
  LD r7,r1,2
  CMP r7,r0
  JMP[LE] @nh_valid_bad
  LA r6,#NH_COMMIT
  LD r7,r1,4
  CMP r7,r6
  JMP[NE] @nh_valid_bad
  ADDI r1,r1,5
  CALL @nh_hash
  LD r1,r0,@nh_valid_ptr
  LD r7,r1,3
  CMP r2,r7
  JMP[NE] @nh_valid_bad
  LD r4,r1,2
  MOVI r3,1
  LD r15,r0,@nh_valid_ret
  RET
nh_valid_bad:
  MOVI r3,0
  MOVI r4,0
  LD r15,r0,@nh_valid_ret
  RET
nh_valid_ret:
  .word 0
nh_valid_ptr:
  .word 0
nh_valid_head:
  .word 0

; Select highest valid generation without altering either slot.
; r1=base, r2=head -> r3=best slot ptr (0 if empty),r4=epoch,r5=status
nh_choose:
  ST r15,r0,@nh_choose_ret
  ST r1,r0,@nh_base
  ST r2,r0,@nh_head
  CALL @nh_open
  CMP r5,r0
  JMP[NE] @nh_choose_bad
  MOVI r6,1
  CMP r2,r6
  JMP[LT] @nh_choose_bad
  MOVI r6,255
  CMP r2,r6
  JMP[GT] @nh_choose_bad
  SUB r6,r2,r13
  LA r7,#NH_STRIDE
  MUL r6,r6,r7
  ADD r6,r6,r1
  ADDI r6,r6,8
  ST r6,r0,@nh_slot0
  ADDI r7,r6,133
  ST r7,r0,@nh_slot1
  MOVI r7,0
  ST r7,r0,@nh_best
  ST r7,r0,@nh_epoch
  LD r1,r0,@nh_slot0
  LD r2,r0,@nh_head
  CALL @nh_valid
  CMP r3,r0
  JMP[EQ] @nh_choose_second
  LD r7,r0,@nh_slot0
  ST r7,r0,@nh_best
  ST r4,r0,@nh_epoch
nh_choose_second:
  LD r1,r0,@nh_slot1
  LD r2,r0,@nh_head
  CALL @nh_valid
  CMP r3,r0
  JMP[EQ] @nh_choose_done
  LD r7,r0,@nh_epoch
  CMP r4,r7
  JMP[LE] @nh_choose_done
  LD r7,r0,@nh_slot1
  ST r7,r0,@nh_best
  ST r4,r0,@nh_epoch
nh_choose_done:
  LD r3,r0,@nh_best
  LD r4,r0,@nh_epoch
  MOVI r5,0
  LD r15,r0,@nh_choose_ret
  RET
nh_choose_bad:
  MOVI r3,0
  MOVI r4,0
  MOVI r5,1
  LD r15,r0,@nh_choose_ret
  RET
nh_choose_ret:
  .word 0
nh_base:
  .word 0
nh_head:
  .word 0
nh_slot0:
  .word 0
nh_slot1:
  .word 0
nh_best:
  .word 0
nh_epoch:
  .word 0

; Publish entire raw 1KiB head into inactive generation (copy on write).
nh_put:
  ST r15,r0,@nh_put_ret
  ST r3,r0,@nh_put_source
  CALL @nh_buffer_safe
  CMP r5,r0
  JMP[NE] @nh_put_bad
  CALL @nh_choose
  CMP r5,r0
  JMP[NE] @nh_put_bad
  MOVI r6,0
  CMP r3,r6
  JMP[EQ] @nh_put_first
  ; Reject exhausted version counter; never reuse generation zero.
  LA r6,0x7FFFFFFF
  CMP r4,r6
  JMP[EQ] @nh_put_exhausted
  LD r6,r0,@nh_slot0
  CMP r3,r6
  JMP[EQ] @nh_put_second
  LD r6,r0,@nh_slot0
  JMP @nh_put_selected
nh_put_second:
  LD r6,r0,@nh_slot1
  JMP @nh_put_selected
nh_put_first:
  LD r6,r0,@nh_slot0
nh_put_selected:
  ST r6,r0,@nh_put_target
  ADD r4,r4,r13
  ST r4,r0,@nh_put_epoch
  ; Invalidate target before writing payload, preserve other slot.
  ST r0,r6,4
  ADDI r1,r6,5
  LD r2,r0,@nh_put_source
  MOVI r3,128
  BCOPY r1,r2,r3
  LD r1,r0,@nh_put_target
  ADDI r1,r1,5
  CALL @nh_hash
  LD r1,r0,@nh_put_target
  ST r2,r1,3
  LA r6,#NH_SLOT_MAGIC
  ST r6,r1,0
  LD r6,r0,@nh_head
  ST r6,r1,1
  LD r4,r0,@nh_put_epoch
  ST r4,r1,2
  LA r6,#NH_COMMIT
  ST r6,r1,4
  MOVI r5,0
  LD r15,r0,@nh_put_ret
  RET
nh_put_exhausted:
  MOVI r4,0
  MOVI r5,3
  LD r15,r0,@nh_put_ret
  RET
nh_put_bad:
  MOVI r4,0
  MOVI r5,1
  LD r15,r0,@nh_put_ret
  RET
nh_put_ret:
  .word 0
nh_put_source:
  .word 0
nh_put_target:
  .word 0
nh_put_epoch:
  .word 0

; Read only from a fully validated immutable generation.
nh_get:
  ST r15,r0,@nh_get_ret
  ST r3,r0,@nh_get_target
  CALL @nh_buffer_safe
  CMP r5,r0
  JMP[NE] @nh_get_bad
  CALL @nh_choose
  CMP r5,r0
  JMP[NE] @nh_get_bad
  CMP r3,r0
  JMP[EQ] @nh_get_empty
  ST r4,r0,@nh_get_epoch
  ADDI r2,r3,5
  LD r1,r0,@nh_get_target
  MOVI r3,128
  BCOPY r1,r2,r3
  LD r4,r0,@nh_get_epoch
  MOVI r5,0
  LD r15,r0,@nh_get_ret
  RET
nh_get_empty:
  MOVI r4,0
  MOVI r5,2
  LD r15,r0,@nh_get_ret
  RET
nh_get_bad:
  MOVI r4,0
  MOVI r5,1
  LD r15,r0,@nh_get_ret
  RET
nh_get_ret:
  .word 0
nh_get_target:
  .word 0
nh_get_epoch:
  .word 0
