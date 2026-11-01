; bytes.nas - NaNnet byte-lane primitives (wave 0).
;
; One NaN16 word carries 4 payload bytes (LDB/STB byte order inside the
; word is little-endian: byte 0 = payload bits [7:0]).  Wire fields are
; built or parsed byte by byte; the ENDIANNESS of every field is chosen
; here (spec section 3 markers [BE]/[LE]/[NE] -> these word routines):
;   rdbe16/wrbe16/rdbe24/wrbe24/rdbe32/wrbe32   MSB first (RFC fields)
;   rdle16/wrle16                               LSB first (image flag fields)
; All routines are leaves: pointer registers PRESERVED, no CALL, no slots.
; Only r1..r8 touched; r2 carries the assembled value.
; SHL/SHR take literal immediates only (nasm0 rule).

; rdbe16 r1 = buf -> r2 = u16
rdbe16:
  ADD r2,r1,r0
  LDB r3,r2,0
  SHL r3,r3,8
  ADDI r2,r2,1
  LDB r2,r2,0
  BOOL.14 r2,r2,r3       ; r2 = (b0<<8) | b1
  RET

; rdle16 r1 = buf -> r2
rdle16:
  LDB r2,r1,0
  ADDI r5,r1,1
  LDB r3,r5,0
  SHL r3,r3,8
  BOOL.14 r2,r2,r3
  RET

; wrbe16 r1 = buf, r2 = val (r1 preserved)
wrbe16:
  SHR r6,r2,8
  STB r6,r1,0
  STB r2,r1,1
  RET

; wrle16 r1 = buf, r2 = val
wrle16:
  STB r2,r1,0
  SHR r6,r2,8
  STB r6,r1,1
  RET

; rdbe24 r1 = buf -> r2 (low 24 bits)
rdbe24:
  LDB r2,r1,0
  SHL r2,r2,16
  ADDI r5,r1,1
  LDB r3,r5,0
  SHL r3,r3,8
  BOOL.14 r2,r2,r3
  ADDI r5,r1,2
  LDB r3,r5,0
  BOOL.14 r2,r2,r3
  RET

; wrbe24 r1 = buf, r2 = val (3 bytes BE, r1 preserved)
wrbe24:
  SHR r5,r2,16
  STB r5,r1,0
  SHR r5,r2,8
  STB r5,r1,1
  STB r2,r1,2
  RET

; rdbe32 r1 = buf -> r2
rdbe32:
  LDB r2,r1,0
  SHL r2,r2,8
  ADDI r5,r1,1
  LDB r3,r5,0
  SHL r2,r2,8
  BOOL.14 r2,r2,r3
  ADDI r5,r1,2
  LDB r3,r5,0
  SHL r2,r2,8
  BOOL.14 r2,r2,r3
  ADDI r5,r1,3
  LDB r3,r5,0
  SHL r2,r2,8
  BOOL.14 r2,r2,r3
  RET

; wrbe32 r1 = buf, r2 = val (4 bytes BE, r1 preserved)
wrbe32:
  SHR r6,r2,24
  STB r6,r1,0
  SHR r6,r2,16
  STB r6,r1,1
  SHR r6,r2,8
  STB r6,r1,2
  STB r2,r1,3
  RET
