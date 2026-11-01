; DRAFT - NOT ASSEMBLED, NOT TESTED, NOT IN THE BUILD (round 11). Written from spec/NALLOC_PLAN.md. NaN16 v0.1 ops only. r13=1 r15=link.
; .equ NV_BASE/NV_END/NV_ROVER are word addresses < 65536 supplied by the including program.
nal_init:
ST r1,r0,#NV_BASE
ADD r3,r1,r2
ST r3,r0,#NV_END
ST r1,r0,#NV_ROVER
SHL r4,r2,1
ST r4,r1,0
SUB r5,r3,r13
ST r4,r5,0
RET
nal_alloc:
ADD r1,r1,r13
ADD r1,r1,r13
MOVI r2,3
CMP r1,r2
MOVI[LT] r1,3
LD r2,r0,#NV_ROVER
LD r3,r0,#NV_END
LD r4,r0,#NV_BASE
BOOL.12 r5,r2,r2
na_loop:
LD r6,r2,0
SHR r7,r6,1
BOOL.8 r8,r6,r13
CMP r8,r0
JMP[NE] @na_next
CMP r7,r1
JMP[LT] @na_next
SUB r8,r7,r1
MOVI r9,3
CMP r8,r9
JMP[LT] @na_all
SHL r9,r1,1
ADD r9,r9,r13
ST r9,r2,0
ADD r6,r2,r1
SUB r7,r6,r13
ST r9,r7,0
SHL r9,r8,1
ST r9,r6,0
ADD r7,r6,r8
SUB r7,r7,r13
ST r9,r7,0
ST r6,r0,#NV_ROVER
ADD r1,r2,r13
RET
na_all:
SHL r9,r7,1
ADD r9,r9,r13
ST r9,r2,0
ADD r6,r2,r7
SUB r8,r6,r13
ST r9,r8,0
CMP r6,r3
JMP[LT] @na_ro
BOOL.12 r6,r4,r4
na_ro:
ST r6,r0,#NV_ROVER
ADD r1,r2,r13
RET
na_next:
ADD r2,r2,r7
CMP r2,r3
JMP[LT] @na_nw
BOOL.12 r2,r4,r4
na_nw:
CMP r2,r5
JMP[NE] @na_loop
MOVI r1,0
RET
nal_free:
SUB r2,r1,r13
LD r3,r0,#NV_BASE
CMP r2,r3
JMP[LT] @nf_bad
LD r4,r0,#NV_END
CMP r2,r4
JMP[GE] @nf_bad
LD r5,r2,0
BOOL.8 r6,r5,r13
CMP r6,r0
JMP[EQ] @nf_bad
SHR r5,r5,1
ADD r6,r2,r5
CMP r6,r4
JMP[GE] @nf_prev
LD r7,r6,0
BOOL.8 r8,r7,r13
CMP r8,r0
JMP[NE] @nf_prev
SHR r7,r7,1
ADD r5,r5,r7
nf_prev:
CMP r2,r3
JMP[LE] @nf_wr
SUB r6,r2,r13
LD r7,r6,0
BOOL.8 r8,r7,r13
CMP r8,r0
JMP[NE] @nf_wr
SHR r7,r7,1
SUB r2,r2,r7
ADD r5,r5,r7
nf_wr:
SHL r6,r5,1
ST r6,r2,0
ADD r7,r2,r5
SUB r7,r7,r13
ST r6,r7,0
LD r8,r0,#NV_ROVER
CMP r8,r2
JMP[LT] @nf_done
ADD r7,r2,r5
CMP r8,r7
JMP[GE] @nf_done
ST r2,r0,#NV_ROVER
nf_done:
MOVI r1,0
RET
nf_bad:
MOVI r1,1
RET
; nal_check (walk, verify head==foot, no adjacent free, sums) is specified in spec/NALLOC_PLAN.md and not drafted yet.
