; nalloc - heap allocator in NaN16 (round 12). Next-fit over an implicit list of blocks with boundary tags, coalescing on free.
; NaN16 v0.1 ops only (fits NaNVM0 and the flat big-memory layout). Heap base/size are 32-bit register values, so the heap may sit anywhere.
; The including program must define (as .equ, word addresses below 65536): NV_BASE NV_END NV_ROVER (three variable words).
; Block: head word at b, foot word at b+size-1, both payload = size<<1 | used. size counts head+foot, min 3. Pointer = b+1.
; Conventions: r0=0 r13=1 r15=link. nal_init/nal_alloc/nal_free clobber r1..r9. nal_check and nal_chkrover clobber r1..r12. r13,r14 never touched.
; nal_init     r1=base r2=words              -> heap is one free block (words >= 3)
; nal_alloc    r1=words                      -> r1=ptr or 0 (heap full / fragmented)
; nal_free     r1=ptr                        -> r1=0 ok, 1 bad pointer or double free
; nal_check    -> r1=err 0 ok | 1 head!=foot | 2 size<3 | 3 overrun | 4 adjacent free blocks; r2=free words r3=used words r4=blocks r5=largest free
; nal_chkrover -> r1=0 if the rover sits on a block boundary, 1 if not
; Known limit: free trusts the word before the pointer. A pointer into the middle of a block whose previous word looks used is not detected.
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
; nal_check: walk every block. r6=cur r7=end r8=previous-was-free r9=head r10=size r11=used bit r12=next
nal_check:
LD r6,r0,#NV_BASE
LD r7,r0,#NV_END
MOVI r2,0
MOVI r3,0
MOVI r4,0
MOVI r5,0
MOVI r8,0
nc_loop:
CMP r6,r7
JMP[GE] @nc_done
LD r9,r6,0
SHR r10,r9,1
BOOL.8 r11,r9,r13
MOVI r12,3
CMP r10,r12
JMP[LT] @nc_e2
ADD r12,r6,r10
CMP r12,r7
JMP[GT] @nc_e3
SUB r1,r12,r13
LD r1,r1,0
CMP r1,r9
JMP[NE] @nc_e1
ADD r4,r4,r13
CMP r11,r0
JMP[EQ] @nc_free
ADD r3,r3,r10
MOVI r8,0
JMP @nc_adv
nc_free:
CMP r8,r0
JMP[NE] @nc_e4
ADD r2,r2,r10
CMP r10,r5
JMP[LE] @nc_nl
BOOL.12 r5,r10,r10
nc_nl:
MOVI r8,1
nc_adv:
BOOL.12 r6,r12,r12
JMP @nc_loop
nc_done:
MOVI r1,0
RET
nc_e1:
MOVI r1,1
RET
nc_e2:
MOVI r1,2
RET
nc_e3:
MOVI r1,3
RET
nc_e4:
MOVI r1,4
RET
nal_chkrover:
LD r2,r0,#NV_ROVER
LD r3,r0,#NV_BASE
LD r4,r0,#NV_END
cr_loop:
CMP r3,r4
JMP[GE] @cr_bad
CMP r3,r2
JMP[EQ] @cr_ok
LD r5,r3,0
SHR r5,r5,1
MOVI r6,3
CMP r5,r6
JMP[LT] @cr_bad
ADD r3,r3,r5
JMP @cr_loop
cr_ok:
MOVI r1,0
RET
cr_bad:
MOVI r1,1
RET
