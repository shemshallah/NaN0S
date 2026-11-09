; Native NaN16 head-bank runtime attachment and bounded observation learning.
; This library is a single-guest, non-reentrant, scratch-only interface.
; It never executes an MTH transformation or promotes a mathematical rule.
; Native nh_* validates each COW generation and NaN class/payload checksum.
; Attach refuses an unformatted bank: no implicit destructive recovery.
; ABI (r0=0, r13=1, all pointers in guest words):
;   nhr_attach:  r1=bank_base -> r5=0 attached,1 denied (old binding preserved)
;   nhr_detach:  -> r5=0
;   nhr_read:    r1=head(1..255),r2=128-word destination -> r5 status,r6=generation
;   nhr_observe: r1=head,r2=feature(0..127),r3=increment(1..255),
;                r4=128-word staging -> r5 status,r6=generation.
; Status 0 ok, 1 invalid/unattached, 3 generation or counter exhausted.
; A failed read copies no bytes. Head 0 is NANNET0 and never learnable.
; Stage must not overlap the head bank, and caller must serialize access.
; The 128 counters are ONLY an empirical scoreboard, not mathematical truth.

nhr_attach:
  ST r15,r0,@nhr_attach_ret
  ST r1,r0,@nhr_req_base
  CALL @nh_open
  CMP r5,r0
  JMP[NE] @nhr_attach_exit
  LD r6,r0,@nhr_req_base
  ST r6,r0,@nhr_attached_base
nhr_attach_exit:
  LD r15,r0,@nhr_attach_ret
  RET
nhr_attach_ret:
  .word 0
nhr_req_base:
  .word 0

nhr_detach:
  ST r0,r0,@nhr_attached_base
  MOVI r5,0
  RET

nhr_read:
  ST r15,r0,@nhr_read_ret
  ST r1,r0,@nhr_head
  ST r2,r0,@nhr_stage
  LD r1,r0,@nhr_attached_base
  CMP r1,r0
  JMP[EQ] @nhr_read_bad
  LD r2,r0,@nhr_head
  LD r3,r0,@nhr_stage
  CALL @nh_get
  ADD r6,r4,r0
  LD r15,r0,@nhr_read_ret
  RET
nhr_read_bad:
  MOVI r5,1
  MOVI r6,0
  LD r15,r0,@nhr_read_ret
  RET
nhr_read_ret:
  .word 0

nhr_observe:
  ST r15,r0,@nhr_obs_ret
  ST r1,r0,@nhr_head
  ST r2,r0,@nhr_feature
  ST r3,r0,@nhr_increment
  ST r4,r0,@nhr_stage
  LD r1,r0,@nhr_attached_base
  CMP r1,r0
  JMP[EQ] @nhr_obs_bad
  LD r6,r0,@nhr_head
  MOVI r7,1
  CMP r6,r7
  JMP[LT] @nhr_obs_bad
  MOVI r7,255
  CMP r6,r7
  JMP[GT] @nhr_obs_bad
  LD r6,r0,@nhr_feature
  CMP r6,r0
  JMP[LT] @nhr_obs_bad
  MOVI r7,127
  CMP r6,r7
  JMP[GT] @nhr_obs_bad
  LD r6,r0,@nhr_increment
  MOVI r7,1
  CMP r6,r7
  JMP[LT] @nhr_obs_bad
  MOVI r7,255
  CMP r6,r7
  JMP[GT] @nhr_obs_bad
  LD r3,r0,@nhr_stage
  CALL @nh_buffer_safe
  CMP r5,r0
  JMP[NE] @nhr_obs_bad
  LD r1,r0,@nhr_attached_base
  LD r2,r0,@nhr_head
  LD r3,r0,@nhr_stage
  CALL @nh_get
  CMP r5,r0
  JMP[EQ] @nhr_obs_loaded
  MOVI r7,2
  CMP r5,r7
  JMP[NE] @nhr_obs_bad
  ; A virgin head gets deterministic +q class words with zero counters.
  LD r8,r0,@nhr_stage
  MOVI r9,128
  MOVI r11,6
nhr_obs_zero:
  STW r0,r8,r11
  ADD r8,r8,r13
  SUB r9,r9,r13
  CMP r9,r0
  JMP[NE] @nhr_obs_zero
nhr_obs_loaded:
  LD r8,r0,@nhr_stage
  LD r9,r0,@nhr_feature
  ADD r8,r8,r9
  LD r9,r8,0
  CMP r9,r0
  JMP[LT] @nhr_obs_bad
  LA r10,0x7FFFFFFF
  LD r7,r0,@nhr_increment
  SUB r10,r10,r7
  CMP r9,r10
  JMP[GT] @nhr_obs_exhausted
  ; Preserve the input word's four-class NaN face during counter updates.
  LDN r11,r8,0
  ADD r9,r9,r7
  STW r9,r8,r11
  LD r1,r0,@nhr_attached_base
  LD r2,r0,@nhr_head
  LD r3,r0,@nhr_stage
  CALL @nh_put
  ADD r6,r4,r0
  LD r15,r0,@nhr_obs_ret
  RET
nhr_obs_exhausted:
  MOVI r5,3
  MOVI r6,0
  LD r15,r0,@nhr_obs_ret
  RET
nhr_obs_bad:
  MOVI r5,1
  MOVI r6,0
  LD r15,r0,@nhr_obs_ret
  RET
nhr_obs_ret:
  .word 0
nhr_attached_base:
  .word 0
nhr_head:
  .word 0
nhr_feature:
  .word 0
nhr_increment:
  .word 0
nhr_stage:
  .word 0
