; Native NaN16 255-head 1 KiB COW scratch guest regression.
.org 0
JMP @main
.include "n16_head_store.nas"
main:
  MOVI r13,1
  MOVI r11,6
  MOVI r7,4096
  MOVI r9,0
  LA r8,0xA000
fill:
  ADD r6,r8,r9
  STW r6,r7,r11
  ADD r7,r7,r13
  ADD r9,r9,r13
  MOVI r6,128
  CMP r9,r6
  JMP[LT] @fill

  MOVI r1,16384
  CALL @nh_format
  CMP r5,r0
  JMP[NE] @fail
  MOVI r1,16384
  CALL @nh_open
  CMP r5,r0
  JMP[NE] @fail

  ; Empty head must not copy to destination.
  LA r6,0xBEEF
  ST r6,r0,8192
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,8192
  CALL @nh_get
  MOVI r6,2
  CMP r5,r6
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0xBEEF
  CMP r6,r7
  JMP[NE] @fail

  ; Head 1 first committed snapshot.
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,4096
  CALL @nh_put
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,1
  CMP r4,r6
  JMP[NE] @fail

  MOVI r1,16384
  MOVI r2,1
  MOVI r3,8192
  CALL @nh_get
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,1
  CMP r4,r6
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0xA000
  CMP r6,r7
  JMP[NE] @fail
  LDN r6,r0,8192
  MOVI r7,6
  CMP r6,r7
  JMP[NE] @fail
  LD r6,r0,8319
  LA r7,0xA07F
  CMP r6,r7
  JMP[NE] @fail

  ; Head 255 must be independent, including upper index boundary.
  LA r6,0xFEED
  MOVI r7,4096
  STW r6,r7,r11
  MOVI r1,16384
  MOVI r2,255
  MOVI r3,4096
  CALL @nh_put
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,1
  CMP r4,r6
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,255
  MOVI r3,8192
  CALL @nh_get
  CMP r5,r0
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0xFEED
  CMP r6,r7
  JMP[NE] @fail

  ; Head 1 second generation, without changing head 255.
  LA r6,0xDEAD
  STW r6,r0,4096
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,4096
  CALL @nh_put
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,2
  CMP r4,r6
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,8192
  CALL @nh_get
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,2
  CMP r4,r6
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0xDEAD
  CMP r6,r7
  JMP[NE] @fail

  ; Corrupt generation 2 raw payload: guest checksum must fall back to gen1.
  LA r6,0xBAD
  MOVI r7,16530
  STW r6,r7,r11
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,8192
  CALL @nh_get
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,1
  CMP r4,r6
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0xA000
  CMP r6,r7
  JMP[NE] @fail

  ; Repair by republishing inactive slot (gen2 again).
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,4096
  CALL @nh_put
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,2
  CMP r4,r6
  JMP[NE] @fail
  ; Clear newest commit marker (power failure); still read gen1.
  ST r0,r0,16529
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,8192
  CALL @nh_get
  CMP r5,r0
  JMP[NE] @fail
  MOVI r6,1
  CMP r4,r6
  JMP[NE] @fail

  ; Invalid head requests are rejected and do not change destination.
  LA r6,0x1234
  ST r6,r0,8192
  MOVI r1,16384
  MOVI r2,0
  MOVI r3,8192
  CALL @nh_get
  MOVI r6,1
  CMP r5,r6
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,256
  MOVI r3,4096
  CALL @nh_put
  MOVI r6,1
  CMP r5,r6
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0x1234
  CMP r6,r7
  JMP[NE] @fail

  ; Both snapshots unreadable: reject and preserve output.
  ST r0,r0,16396  ; slot0 commit=base+8+4
  MOVI r1,16384
  MOVI r2,1
  MOVI r3,8192
  CALL @nh_get
  MOVI r6,2
  CMP r5,r6
  JMP[NE] @fail
  LD r6,r0,8192
  LA r7,0x1234
  CMP r6,r7
  JMP[NE] @fail

  ; Wrong superblock never authorizes access.
  ST r0,r0,16384
  MOVI r1,16384
  CALL @nh_open
  MOVI r6,1
  CMP r5,r6
  JMP[NE] @fail

  MOVI r1,@passed
  CALL @puts
  HALT
fail:
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
  .str "N16 HEAD STORE PASS\n"
failed:
  .str "N16 HEAD STORE FAIL\n"
