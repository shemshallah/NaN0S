; NaNFS validated native guest regression — all storage decisions in NaN16.
.org 0
JMP @main
.include "../lib/nanfs.nas"

main:
  MOVI r13,1
  MOVI r9,0
  MOVI r7,4096
  MOVI r8,0x5A5A
fill_source:
  ADD r6,r8,r9
  ST r6,r7,0
  ADD r7,r7,r13
  ADD r9,r9,r13
  MOVI r6,64
  CMP r9,r6
  JMP[LT] @fill_source

  ; 130 blocks => three bitmap blocks, four reserved blocks, 126 data.
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_format
  CMP r3,r0
  JMP[NE] @fail
  LD r6,r0,16387
  MOVI r7,4
  CMP r6,r7
  JMP[NE] @fail
  LD r6,r0,16386
  MOVI r7,126
  CMP r6,r7
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_check
  CMP r3,r0
  JMP[NE] @fail

  ; First fit starts AFTER reserved bitmap blocks, and stays unique.
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_alloc
  CMP r3,r0
  JMP[NE] @fail
  MOVI r6,4
  CMP r1,r6
  JMP[NE] @fail
  ST r1,r0,@first
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_alloc
  CMP r3,r0
  JMP[NE] @fail
  MOVI r6,5
  CMP r1,r6
  JMP[NE] @fail
  ST r1,r0,@second

  ; Native 64-word write/read after clearing the receiving buffer.
  MOVI r1,16384
  LD r2,r0,@first
  MOVI r3,4096
  CALL @nanfs_write
  CMP r4,r0
  JMP[NE] @fail
  MOVI r9,0
  MOVI r7,8192
clear_destination:
  ST r0,r7,0
  ADD r7,r7,r13
  ADD r9,r9,r13
  MOVI r6,64
  CMP r9,r6
  JMP[LT] @clear_destination
  MOVI r1,16384
  LD r2,r0,@first
  MOVI r3,8192
  CALL @nanfs_read
  CMP r4,r0
  JMP[NE] @fail
  LD r6,r0,8192
  MOVI r7,0x5A5A
  CMP r6,r7
  JMP[NE] @fail
  LD r6,r0,8255
  MOVI r7,0x5A99
  CMP r6,r7
  JMP[NE] @fail

  ; Access to an unallocated payload is rejected without buffer mutation.
  MOVI r6,0x1234
  ST r6,r0,8192
  MOVI r1,16384
  MOVI r2,6
  MOVI r3,8192
  CALL @nanfs_read
  MOVI r7,2
  CMP r4,r7
  JMP[NE] @fail
  LD r6,r0,8192
  MOVI r7,0x1234
  CMP r6,r7
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,6
  MOVI r3,4096
  CALL @nanfs_write
  MOVI r7,2
  CMP r4,r7
  JMP[NE] @fail

  ; Reserved blocks cannot be freed or written.
  MOVI r1,16384
  MOVI r2,2
  CALL @nanfs_free
  MOVI r7,1
  CMP r3,r7
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,2
  MOVI r3,4096
  CALL @nanfs_write
  MOVI r7,1
  CMP r4,r7
  JMP[NE] @fail

  ; Reject double-free; then reuse the same index with zeroized payload.
  MOVI r1,16384
  LD r2,r0,@first
  CALL @nanfs_free
  CMP r3,r0
  JMP[NE] @fail
  MOVI r1,16384
  LD r2,r0,@first
  CALL @nanfs_free
  MOVI r7,2
  CMP r3,r7
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_alloc
  CMP r3,r0
  JMP[NE] @fail
  MOVI r7,4
  CMP r1,r7
  JMP[NE] @fail
  LD r6,r0,16640
  CMP r6,r0
  JMP[NE] @fail
  LD r6,r0,16703
  CMP r6,r0
  JMP[NE] @fail

  ; Re-open/check after formatting a DIFFERENT base: no stale global base.
  MOVI r1,50000
  MOVI r2,3
  CALL @nanfs_format
  CMP r3,r0
  JMP[NE] @fail
  MOVI r1,50000
  MOVI r2,3
  CALL @nanfs_alloc
  CMP r3,r0
  JMP[NE] @fail
  MOVI r7,2
  CMP r1,r7
  JMP[NE] @fail
  MOVI r1,50000
  MOVI r2,3
  CALL @nanfs_alloc
  MOVI r7,3
  CMP r3,r7
  JMP[NE] @fail
  CMP r1,r0
  JMP[NE] @fail
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_check
  CMP r3,r0
  JMP[NE] @fail
  MOVI r1,50000
  MOVI r2,3
  CALL @nanfs_check
  CMP r3,r0
  JMP[NE] @fail

  ; Format with impossible count must not alter the supplied base.
  MOVI r6,0x55AA
  ST r6,r0,60000
  MOVI r1,60000
  MOVI r2,2
  CALL @nanfs_format
  MOVI r7,1
  CMP r3,r7
  JMP[NE] @fail
  LD r6,r0,60000
  MOVI r7,0x55AA
  CMP r6,r7
  JMP[NE] @fail

  ; Full bitmap scan catches corruption even if the cheap header is valid.
  ST r0,r0,16448
  MOVI r1,16384
  MOVI r2,130
  CALL @nanfs_check
  MOVI r7,1
  CMP r3,r7
  JMP[NE] @fail

  MOVI r1,@pass
  CALL @puts
  HALT
fail:
  MOVI r1,@failed
  CALL @puts
  HALT

puts:
  MOVI r4,255
puts_word:
  LD r2,r1,0
  MOVI r3,4
puts_byte:
  BOOL.8 r5,r2,r4
  CMP r5,r0
  RET[EQ]
  PUTC r5
  SHR r2,r2,8
  SUB r3,r3,r13
  JMP[NE] @puts_byte
  ADD r1,r1,r13
  JMP @puts_word

first:
  .word 0
second:
  .word 0
pass:
  .str "NANFS STORAGE PASS\n"
failed:
  .str "NANFS STORAGE FAIL\n"
