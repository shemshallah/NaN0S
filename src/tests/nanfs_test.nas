; nanfs_test.nas - RAM format/alloc/write/read round-trip.
.org 0
JMP @main
.include "../lib/nanfs.nas"
main:
MOVI r13,1
; fill source buffer 4096..4159
MOVI r1,0
MOVI r3,4096
MOVI r4,0x5A5A
fill:
ADD r5,r4,r1
ST r5,r3,0
ADD r3,r3,r13
ADD r1,r1,r13
MOVI r5,64
CMP r1,r5
JMP[LT] @fill
; format 64 blocks at 16384
MOVI r1,16384
MOVI r2,64
CALL @nanfs_format
; allocate
MOVI r1,16384
MOVI r2,64
CALL @nanfs_alloc
ST r1,r0,@blk
; write block
MOVI r1,16384
LD r2,r0,@blk
MOVI r3,4096
CALL @nanfs_write
; clear source
MOVI r1,0
MOVI r3,4096
clear:
ST r0,r3,0
ADD r3,r3,r13
ADD r1,r1,r13
MOVI r5,64
CMP r1,r5
JMP[LT] @clear
; read back
MOVI r1,16384
LD r2,r0,@blk
MOVI r3,4096
CALL @nanfs_read
; verify
LD r1,r0,4096
MOVI r2,0x5A5A
CMP r1,r2
JMP[NE] @fail
LD r1,r0,4159
MOVI r2,0x5A99
CMP r1,r2
JMP[NE] @fail
MOVI r1,@s_pass
CALL @puts
HALT
fail:
MOVI r1,@s_fail
CALL @puts
HALT
puts:
MOVI r4,255
p1:
LD r2,r1,0
MOVI r3,4
p2:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @p2
ADD r1,r1,r13
JMP @p1
blk:
.word 0
s_pass:
.str "NANFS PASS\n"
s_fail:
.str "NANFS FAIL\n"
