; Exhaustive mirror-pair map over 256 palindromic points.
; Enumerates each unordered pair of distinct points exactly once:
; 256 choose 2 = 32,640 pairs. Point 0 is reserved for the
; NaNNet interface in each universe; it remains part of the 256-point
; topology but is not a runner-owned hardware register.
; Each record is a 32-bit packed key: high16=left point, low16=right point.
; This is a logical topology fixture; it makes no hardware-availability claim.
main:
MOVI r13,1
MOVI r4,0
MOVI r6,0
MOVI r7,0
MOVI r8,0
MOVI r9,@pair_map
outer:
MOVI r12,256
CMP r4,r12
JMP[GE] @verify
BOOL.14 r5,r4,r0
ADDI r5,r5,1
inner:
MOVI r12,256
CMP r5,r12
JMP[GE] @next_outer
; key = (left << 16) | right
SHL r10,r4,16
BOOL.14 r10,r10,r5
ST r10,r9,0
ADDI r9,r9,1
ADDI r6,r6,1
ADDI r7,r7,1
ADDI r5,r5,1
JMP @inner
next_outer:
ADDI r4,r4,1
JMP @outer
verify:
MOVI r12,32640
CMP r6,r12
JMP[NE] @fail
CMP r7,r12
JMP[NE] @fail
MOVI r12,0
CMP r8,r12
JMP[NE] @fail
; First and final packed keys are (0,1) and (254,255).
MOVI r9,@pair_map
LD r10,r9,0
MOVI r12,1
CMP r10,r12
JMP[NE] @fail
MOVI r12,32639
ADD r9,r9,r12
LD r10,r9,0
MOVI r12,255
MOVHI r12,254
CMP r10,r12
JMP[NE] @fail
; MIRROR PAIRS PASS
MOVI r1,77
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,79
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,10
PUTC r1
HALT
fail:
MOVI r1,77
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,79
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,10
PUTC r1
HALT
.org 16384
pair_map:
.word 0
