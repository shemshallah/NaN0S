; nan0s_fs_check.nas - boot header check for a sparse NSPV volume.
; Reads ATA primary-master sector 0, validates magic/geometry, and prints
; capacity, used sectors, suite and the lazy flag. It does not decrypt data.
.org 0
JMP @main
.include "../../src/lib/ata.nas"
main:
MOVI r13,1
MOVI r1,0
MOVI r2,4096
CALL @ata_read28
; magic word0 = cells 0/1
LD r1,r0,4096
MOVI r2,0x5631
CMP r1,r2
JMP[NE] @bad
LD r1,r0,4097
MOVI r2,0x5350
CMP r1,r2
JMP[NE] @bad
; word1 cell4 = suite (low16), cell5 = version (high16)
LD r1,r0,4100
ST r1,r0,@suite
LD r1,r0,4101
MOVI r2,1
CMP r1,r2
JMP[NE] @bad
; word4 cells 16/17 = data capacity (low 32)
LD r1,r0,4112
LD r2,r0,4113
SHL r2,r2,16
BOOL.14 r1,r1,r2
ST r1,r0,@cap
; word11 cells 44/45 = used (low 32)
LD r1,r0,4140
LD r2,r0,4141
SHL r2,r2,16
BOOL.14 r1,r1,r2
ST r1,r0,@used
; word12 cells 48/49 = flags (low 32)
LD r1,r0,4144
LD r2,r0,4145
SHL r2,r2,16
BOOL.14 r1,r1,r2
MOVI r2,1
BOOL.8 r1,r1,r2
ST r1,r0,@lazy
; full volumes have no used word: use capacity
LD r1,r0,@lazy
CMP r1,r0
JMP[NE] @lazy_used
LD r1,r0,@cap
ST r1,r0,@used
lazy_used:
; used <= cap
LD r1,r0,@used
LD r2,r0,@cap
CMP r1,r2
JMP[GT] @bad
MOVI r1,@s_ok
CALL @puts
MOVI r1,@s_cap
CALL @puts
LD r5,r0,@cap
CALL @puthex8
MOVI r1,@s_used
CALL @puts
LD r5,r0,@used
CALL @puthex8
MOVI r1,@s_suite
CALL @puts
LD r5,r0,@suite
CALL @puthex8
MOVI r1,@s_lazy
CALL @puts
LD r5,r0,@lazy
CALL @puthex8
MOVI r1,@s_nl
CALL @puts
HALT
bad:
MOVI r1,@s_no
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
; print r5 as eight hex digits
puthex8:
MOVI r6,8
ph8:
MOVI r2,4
SHR r1,r5,28
MOVI r3,15
BOOL.8 r1,r1,r3
MOVI r2,10
CMP r1,r2
JMP[LT] @phd
ADDI r1,r1,55
JMP @pho
phd:
ADDI r1,r1,48
pho:
PUTC r1
SHL r5,r5,4
SUB r6,r6,r13
JMP[NE] @ph8
RET
cap:
.word 0
used:
.word 0
suite:
.word 0
lazy:
.word 0
s_ok:
.str "NAN0S_FS OK"
s_cap:
.str " cap="
s_used:
.str " used="
s_suite:
.str " suite="
s_lazy:
.str " lazy="
s_nl:
.str "\n"
s_no:
.str "NAN0S_FS NO\n"
