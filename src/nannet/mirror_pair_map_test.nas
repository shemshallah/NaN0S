; Exhaustive 255-head mirror-pair map bootstrap fixture.
; Enumerates i<=j: 32,385 distinct cross-head pairs + 255 self-pairs.
; Each record is a 32-bit packed key: high16=left head, low16=right head.
; The map is a scratch fixture only; it does not assert hardware availability.
; Expected totals: 32,640 all pairs, 32,385 cross pairs, 255 self pairs.
main:
MOVI r13,1
MOVI r4,1
MOVI r6,0
MOVI r7,0
MOVI r8,0
MOVI r9,@pair_map
outer:
MOVI r12,256
CMP r4,r12
JMP[GE] @verify
BOOL.14 r5,r4,r0
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
CMP r4,r5
JMP[EQ] @self_pair
ADDI r7,r7,1
JMP @next_pair
self_pair:
ADDI r8,r8,1
next_pair:
ADDI r5,r5,1
JMP @inner
next_outer:
ADDI r4,r4,1
JMP @outer
verify:
MOVI r12,32640
CMP r6,r12
JMP[NE] @fail
MOVI r12,32385
CMP r7,r12
JMP[NE] @fail
MOVI r12,255
CMP r8,r12
JMP[NE] @fail
; Verify first and final packed keys: (1,1) and (255,255).
MOVI r9,@pair_map
LD r10,r9,0
MOVI r12,1
MOVHI r12,1
CMP r10,r12
JMP[NE] @fail
MOVI r12,32639
ADD r9,r9,r12
LD r10,r9,0
MOVI r12,255
MOVHI r12,255
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
