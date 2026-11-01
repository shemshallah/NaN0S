; common.nas - shared NaN16 translator IR and byte emitters.
; Byte addresses are little-endian payload bytes: word*4 + byte.
common_emit8:
  STB r1,r2,0
  RET
common_emit16:
  STB r1,r2,0
  SHR r3,r1,8
  STB r3,r2,1
  RET
common_emit32:
  STB r1,r2,0
  SHR r3,r1,8
  STB r3,r2,1
  SHR r3,r1,16
  STB r3,r2,2
  SHR r3,r1,24
  STB r3,r2,3
  RET
