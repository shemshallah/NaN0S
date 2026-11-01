; audio.nas - NaN16 PC speaker driver. No native sound op.
; PIT channel 2, gate via port 0x61. All timing is TICK-based.
.equ PIT_CH2 0x42
.equ PIT_CMD 0x43
.equ SPEAKER 0x61
.equ PIT_HZ 0x001234DE

; audio_beep: r1=frequency Hz, r2=duration ms. r1/r2 are preserved.
audio_beep:
  ST r15,r0,@ab_ret
  ST r1,r0,@ab_freq
  ST r2,r0,@ab_ms
  LD r3,r0,#PIT_HZ
  LD r1,r0,@ab_freq
  DIVU r3,r3,r1
  MOVI r4,#PIT_CMD
  MOVI r5,0xB6
  OUTB r5,r4
  MOVI r4,#PIT_CH2
  MOVI r5,255
  BOOL.8 r6,r3,r5
  OUTB r6,r4
  SHR r6,r3,8
  BOOL.8 r6,r6,r5
  OUTB r6,r4
  MOVI r4,#SPEAKER
  INB r5,r4
  MOVI r6,3
  BOOL.14 r5,r5,r6
  OUTB r5,r4
  TICK r5
ab_wait:
  TICK r6
  SUB r7,r6,r5
  LD r8,r0,@ab_ms
  CMP r7,r8
  JMP[LT] @ab_wait
  MOVI r4,#SPEAKER
  INB r5,r4
  MOVI r6,0xFC
  BOOL.8 r5,r5,r6
  OUTB r5,r4
  LD r15,r0,@ab_ret
  RET
ab_ret:
.word 0
ab_freq:
.word 0
ab_ms:
.word 0

; audio_off: gate the speaker off immediately.
audio_off:
  MOVI r4,#SPEAKER
  INB r5,r4
  MOVI r6,0xFC
  BOOL.8 r5,r5,r6
  OUTB r5,r4
  RET
