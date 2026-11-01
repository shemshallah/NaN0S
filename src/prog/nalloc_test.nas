; nalloc_test - self-checking test of nalloc.nas, written in NaN16. Prints PASS or the first failing tag with values, then halts.
; Heap lives at word 0x30000 (above 64K), so run it in the flat big-memory model. NaN16 v0.1 ops only.
; Layout (word addresses): vars 0x1F00.., scratch 0x1F40.., slot tables 0x2000.., block table 0x3000.., stack 0x7000, heap 0x30000+2048.
.equ NV_BASE 0x1F00
.equ NV_END 0x1F01
.equ NV_ROVER 0x1F02
.equ V_RNG 0x1F10
.equ V_CHK 0x1F11
.equ V_SLOT 0x1F12
.equ V_LEN 0x1F13
.equ V_I 0x1F14
.equ V_AFAIL 0x1F15
.equ V_PAT 0x1F16
.equ V_A 0x1F17
.equ V_B 0x1F18
.equ V_C 0x1F19
.equ V_D 0x1F1A
.equ V_T1 0x1F1B
.equ V_T2 0x1F1C
.equ V_X 0x1F1D
.equ V_CNT 0x1F1E
.equ SCR 0x1F40
.equ TBL_PTR 0x2000
.equ TBL_LEN 0x2040
.equ TBL_PAT 0x2080
.equ BIG 0x3000
.equ STACK 0x7000
.equ HEAP_HI 3
.equ HEAP_SIZE 2048
.equ NOPS 800
.equ EXH 682
main:
MOVI r13,1
MOVI r14,#STACK
MOVI r1,@s_banner
CALL @puts
MOVI r1,0x1234
MOVHI r1,0x9ABC
ST r1,r0,#V_RNG
; ---- phase 1: init
MOVI r1,@s_p1
CALL @puts
MOVI r1,0
MOVHI r1,#HEAP_HI
MOVI r2,#HEAP_SIZE
CALL @nal_init
MOVI r6,#HEAP_SIZE
MOVI r7,0
MOVI r8,1
MOVI r9,#HEAP_SIZE
MOVI r10,0x101
CALL @chkexp
MOVI r1,@s_ok
CALL @puts
; ---- phase 2: random workload, 64 slots, pattern fill and verify, nal_check every 32 ops
MOVI r1,@s_p2
CALL @puts
ST r0,r0,#V_I
w_loop:
LD r1,r0,#V_I
MOVI r2,#NOPS
CMP r1,r2
JMP[GE] @w_done
ADD r1,r1,r13
ST r1,r0,#V_I
CALL @rnd
MOVI r2,63
BOOL.8 r6,r1,r2
ST r6,r0,#V_SLOT
LD r7,r6,#TBL_PTR
CMP r7,r0
JMP[NE] @w_free
SHR r3,r1,6
MOVI r2,31
BOOL.8 r3,r3,r2
ADD r3,r3,r13
SHR r4,r1,12
MOVI r2,3
BOOL.8 r4,r4,r2
CMP r4,r0
JMP[NE] @w_len
MOVI r5,100
ADD r3,r3,r5
w_len:
ST r3,r0,#V_LEN
BOOL.12 r1,r3,r3
CALL @nal_alloc
CMP r1,r0
JMP[NE] @w_got
LD r2,r0,#V_AFAIL
ADD r2,r2,r13
ST r2,r0,#V_AFAIL
JMP @w_next
w_got:
LD r6,r0,#V_SLOT
ST r1,r6,#TBL_PTR
ST r1,r0,#V_A
LD r3,r0,#V_LEN
ST r3,r6,#TBL_LEN
LD r2,r0,#NV_BASE
CMP r1,r2
MOVI r4,0
MOVI[GT] r4,1
BOOL.12 r1,r4,r4
MOVI r2,1
MOVI r10,0x201
CALL @ex
LD r1,r0,#V_A
LD r3,r0,#V_LEN
ADD r1,r1,r3
ADD r1,r1,r13
LD r2,r0,#NV_END
CMP r1,r2
MOVI r4,0
MOVI[LE] r4,1
BOOL.12 r1,r4,r4
MOVI r2,1
MOVI r10,0x202
CALL @ex
CALL @rnd
ST r1,r0,#V_PAT
LD r6,r0,#V_SLOT
ST r1,r6,#TBL_PAT
LD r1,r0,#V_A
LD r2,r0,#V_LEN
LD r3,r0,#V_PAT
CALL @fillpat
JMP @w_next
w_free:
CALL @slotfree
w_next:
LD r1,r0,#V_I
MOVI r2,31
BOOL.8 r1,r1,r2
CMP r1,r0
JMP[NE] @w_loop
CALL @chkbasic
JMP @w_loop
w_done:
CALL @chkbasic
MOVI r1,@s_ok
CALL @puts
; ---- phase 2b: drain every slot, expect one free block
MOVI r1,@s_p2b
CALL @puts
ST r0,r0,#V_I
d_loop:
LD r6,r0,#V_I
MOVI r2,64
CMP r6,r2
JMP[GE] @d_done
LD r7,r6,#TBL_PTR
CMP r7,r0
JMP[EQ] @d_next
CALL @slotfree
d_next:
LD r6,r0,#V_I
ADD r6,r6,r13
ST r6,r0,#V_I
JMP @d_loop
d_done:
MOVI r6,#HEAP_SIZE
MOVI r7,0
MOVI r8,1
MOVI r9,#HEAP_SIZE
MOVI r10,0x220
CALL @chkexp
MOVI r1,@s_ok
CALL @puts
; ---- phase 3: whole-heap, too-big, take-all (remainder 1), split (remainder 3)
MOVI r1,@s_p3
CALL @puts
MOVI r1,#HEAP_SIZE-2
LD r2,r0,#NV_BASE
ADD r2,r2,r13
MOVI r10,0x301
CALL @alloc_exp
ST r1,r0,#V_A
MOVI r1,1
MOVI r2,0
MOVI r10,0x302
CALL @alloc_exp
MOVI r6,0
MOVI r7,#HEAP_SIZE
MOVI r8,1
MOVI r9,0
MOVI r10,0x303
CALL @chkexp
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x304
CALL @free_exp
CALL @chkfull
MOVI r1,#HEAP_SIZE-1
MOVI r2,0
MOVI r10,0x306
CALL @alloc_exp
CALL @chkfull
MOVI r1,#HEAP_SIZE-3
LD r2,r0,#NV_BASE
ADD r2,r2,r13
MOVI r10,0x308
CALL @alloc_exp
ST r1,r0,#V_A
MOVI r6,0
MOVI r7,#HEAP_SIZE
MOVI r8,1
MOVI r9,0
MOVI r10,0x309
CALL @chkexp
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x30A
CALL @free_exp
CALL @chkfull
MOVI r1,#HEAP_SIZE-5
LD r2,r0,#NV_BASE
ADD r2,r2,r13
MOVI r10,0x30B
CALL @alloc_exp
ST r1,r0,#V_A
MOVI r6,3
MOVI r7,#HEAP_SIZE-3
MOVI r8,2
MOVI r9,3
MOVI r10,0x30C
CALL @chkexp
MOVI r1,1
LD r2,r0,#NV_BASE
MOVI r3,#HEAP_SIZE-2
ADD r2,r2,r3
MOVI r10,0x30D
CALL @alloc_exp
ST r1,r0,#V_B
MOVI r6,0
MOVI r7,#HEAP_SIZE
MOVI r8,2
MOVI r9,0
MOVI r10,0x30E
CALL @chkexp
LD r1,r0,#V_B
MOVI r2,0
MOVI r10,0x30F
CALL @free_exp
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x310
CALL @free_exp
CALL @chkfull
MOVI r1,@s_ok
CALL @puts
; ---- phase 4: double free and bad pointers
MOVI r1,@s_p4
CALL @puts
MOVI r1,10
LD r2,r0,#NV_BASE
ADD r2,r2,r13
MOVI r10,0x401
CALL @alloc_exp
ST r1,r0,#V_A
MOVI r2,0
MOVI r10,0x402
CALL @free_exp
LD r1,r0,#V_A
MOVI r2,1
MOVI r10,0x403
CALL @free_exp
MOVI r1,0
MOVI r2,1
MOVI r10,0x404
CALL @free_exp
LD r1,r0,#NV_BASE
MOVI r2,1
MOVI r10,0x405
CALL @free_exp
LD r1,r0,#NV_END
MOVI r3,4
ADD r1,r1,r3
MOVI r2,1
MOVI r10,0x406
CALL @free_exp
LD r1,r0,#NV_END
MOVI r2,1
MOVI r10,0x407
CALL @free_exp
LD r1,r0,#NV_BASE
ADD r1,r1,r13
MOVI r2,1
MOVI r10,0x408
CALL @free_exp
CALL @chkfull
MOVI r1,0
LD r2,r0,#NV_BASE
ADD r2,r2,r13
MOVI r10,0x409
CALL @alloc_exp
ST r1,r0,#V_A
MOVI r6,#HEAP_SIZE-3
MOVI r7,3
MOVI r8,2
MOVI r9,#HEAP_SIZE-3
MOVI r10,0x40A
CALL @chkexp
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x40B
CALL @free_exp
CALL @chkfull
MOVI r1,@s_ok
CALL @puts
; ---- phase 5: coalescing in three orders, and next-fit (a freed hole behind the rover is not reused first)
MOVI r1,@s_p5
CALL @puts
CALL @alloc3
MOVI r6,#HEAP_SIZE-36
MOVI r7,36
MOVI r8,4
MOVI r9,#HEAP_SIZE-36
MOVI r10,0x504
CALL @chkexp
LD r1,r0,#V_B
MOVI r2,0
MOVI r10,0x505
CALL @free_exp
MOVI r6,#HEAP_SIZE-24
MOVI r7,24
MOVI r8,4
MOVI r9,#HEAP_SIZE-36
MOVI r10,0x506
CALL @chkexp
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x507
CALL @free_exp
MOVI r6,#HEAP_SIZE-12
MOVI r7,12
MOVI r8,3
MOVI r9,#HEAP_SIZE-36
MOVI r10,0x508
CALL @chkexp
LD r1,r0,#V_C
MOVI r2,0
MOVI r10,0x509
CALL @free_exp
CALL @chkfull
CALL @alloc3
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x514
CALL @free_exp
MOVI r6,#HEAP_SIZE-24
MOVI r7,24
MOVI r8,4
MOVI r9,#HEAP_SIZE-36
MOVI r10,0x515
CALL @chkexp
LD r1,r0,#V_C
MOVI r2,0
MOVI r10,0x516
CALL @free_exp
MOVI r6,#HEAP_SIZE-12
MOVI r7,12
MOVI r8,3
MOVI r9,#HEAP_SIZE-24
MOVI r10,0x517
CALL @chkexp
LD r1,r0,#V_B
MOVI r2,0
MOVI r10,0x518
CALL @free_exp
CALL @chkfull
CALL @alloc3
LD r1,r0,#V_A
MOVI r2,0
MOVI r10,0x524
CALL @free_exp
MOVI r1,10
LD r2,r0,#V_C
MOVI r3,12
ADD r2,r2,r3
MOVI r10,0x525
CALL @alloc_exp
ST r1,r0,#V_D
MOVI r6,#HEAP_SIZE-36
MOVI r7,36
MOVI r8,5
MOVI r9,#HEAP_SIZE-48
MOVI r10,0x526
CALL @chkexp
LD r1,r0,#V_D
MOVI r2,0
MOVI r10,0x527
CALL @free_exp
LD r1,r0,#V_C
MOVI r2,0
MOVI r10,0x528
CALL @free_exp
LD r1,r0,#V_B
MOVI r2,0
MOVI r10,0x529
CALL @free_exp
CALL @chkfull
MOVI r1,@s_ok
CALL @puts
; ---- phase 6: exhaustion with 1-word blocks, rover wrap past the end, refill every other hole in rover order, drain
MOVI r1,@s_p6
CALL @puts
ST r0,r0,#V_CNT
x_loop:
MOVI r1,1
CALL @nal_alloc
CMP r1,r0
JMP[EQ] @x_end
LD r2,r0,#V_CNT
ST r1,r2,#BIG
ADD r2,r2,r13
ST r2,r0,#V_CNT
MOVI r3,1000
CMP r2,r3
JMP[LT] @x_loop
MOVI r10,0x600
MOVI r11,0
CALL @fail
x_end:
LD r1,r0,#V_CNT
MOVI r2,#EXH
MOVI r10,0x601
CALL @ex
MOVI r1,1
MOVI r2,0
MOVI r10,0x602
CALL @alloc_exp
MOVI r6,0
MOVI r7,#HEAP_SIZE
MOVI r8,#EXH
MOVI r9,0
MOVI r10,0x603
CALL @chkexp
MOVI r6,0
MOVI r7,0
dl_loop:
MOVI r2,#EXH-1
CMP r6,r2
JMP[GE] @dl_done
LD r3,r6,#BIG
LD r4,r6,#BIG+1
SUB r4,r4,r3
MOVI r5,3
CMP r4,r5
JMP[EQ] @dl_ok
ADD r7,r7,r13
dl_ok:
ADD r6,r6,r13
JMP @dl_loop
dl_done:
BOOL.12 r1,r7,r7
MOVI r2,0
MOVI r10,0x604
CALL @ex
LD r1,r0,#BIG+600
MOVI r2,0
MOVI r10,0x610
CALL @free_exp
MOVI r1,1
LD r2,r0,#BIG+600
MOVI r10,0x611
CALL @alloc_exp
LD r1,r0,#BIG+100
MOVI r2,0
MOVI r10,0x612
CALL @free_exp
MOVI r1,1
LD r2,r0,#BIG+100
MOVI r10,0x613
CALL @alloc_exp
ST r0,r0,#V_I
fe_loop:
LD r6,r0,#V_I
MOVI r2,#EXH-1
CMP r6,r2
JMP[GE] @fe_done
LD r1,r6,#BIG
MOVI r2,0
MOVI r10,0x620
CALL @free_exp
LD r6,r0,#V_I
ADD r6,r6,r13
ADD r6,r6,r13
ST r6,r0,#V_I
JMP @fe_loop
fe_done:
MOVI r6,1023
MOVI r7,#HEAP_SIZE-1023
MOVI r8,#EXH
MOVI r9,3
MOVI r10,0x621
CALL @chkexp
MOVI r1,102
ST r1,r0,#V_T2
ST r0,r0,#V_I
rf_loop:
LD r6,r0,#V_I
MOVI r2,341
CMP r6,r2
JMP[GE] @rf_done
MOVI r1,1
LD r2,r0,#V_T2
LD r2,r2,#BIG
MOVI r10,0x630
CALL @alloc_exp
LD r6,r0,#V_I
ADD r6,r6,r13
ST r6,r0,#V_I
LD r2,r0,#V_T2
ADD r2,r2,r13
ADD r2,r2,r13
MOVI r3,#EXH
CMP r2,r3
JMP[LT] @rf_ok
SUB r2,r2,r3
rf_ok:
ST r2,r0,#V_T2
JMP @rf_loop
rf_done:
MOVI r1,1
MOVI r2,0
MOVI r10,0x631
CALL @alloc_exp
MOVI r6,0
MOVI r7,#HEAP_SIZE
MOVI r8,#EXH
MOVI r9,0
MOVI r10,0x632
CALL @chkexp
ST r0,r0,#V_I
dr_loop:
LD r6,r0,#V_I
MOVI r2,#EXH
CMP r6,r2
JMP[GE] @dr_done
LD r1,r6,#BIG
MOVI r2,0
MOVI r10,0x640
CALL @free_exp
LD r6,r0,#V_I
ADD r6,r6,r13
ST r6,r0,#V_I
JMP @dr_loop
dr_done:
CALL @chkfull
MOVI r1,@s_ok
CALL @puts
; ---- verdict
MOVI r1,@s_tail1
CALL @puts
LD r1,r0,#V_CHK
CALL @puthex
MOVI r1,@s_tail2
CALL @puts
LD r1,r0,#V_AFAIL
CALL @puthex
MOVI r1,@s_pass
CALL @puts
HALT
; ---- helpers. All keep r13=1 and r14 (software stack, grows up).
; rnd: xorshift32 in V_RNG -> r1 (clobbers r2)
rnd:
LD r1,r0,#V_RNG
SHL r2,r1,13
BOOL.6 r1,r1,r2
SHR r2,r1,17
BOOL.6 r1,r1,r2
SHL r2,r1,5
BOOL.6 r1,r1,r2
ST r1,r0,#V_RNG
RET
; fillpat / verpat: r1=ptr r2=len r3=pattern base, word i holds pattern+i. verpat -> r1=0 ok else index+1 of the first bad word
fillpat:
MOVI r4,0
fp1:
CMP r4,r2
JMP[GE] @fp2
ADD r5,r3,r4
ADD r6,r1,r4
ST r5,r6,0
ADD r4,r4,r13
JMP @fp1
fp2:
RET
verpat:
MOVI r4,0
vp1:
CMP r4,r2
JMP[GE] @vp_ok
ADD r6,r1,r4
LD r5,r6,0
ADD r7,r3,r4
CMP r5,r7
JMP[NE] @vp_bad
ADD r4,r4,r13
JMP @vp1
vp_ok:
MOVI r1,0
RET
vp_bad:
ADD r1,r4,r13
RET
; ex: r1=got r2=want r10=tag. Equal: count the check. Different: print tag, got, want and halt.
ex:
CMP r1,r2
JMP[NE] @ex_bad
LD r3,r0,#V_CHK
ADD r3,r3,r13
ST r3,r0,#V_CHK
RET
ex_bad:
ST r1,r0,#SCR
ST r2,r0,#SCR+1
MOVI r11,2
CALL @fail
; fail: r10=tag r11=count of SCR words to print. Never returns.
fail:
MOVI r1,@s_fail
CALL @puts
BOOL.12 r1,r10,r10
CALL @puthex
MOVI r9,0
fl1:
CMP r9,r11
JMP[GE] @fl2
MOVI r1,32
PUTC r1
LD r1,r9,#SCR
CALL @puthex
ADD r9,r9,r13
JMP @fl1
fl2:
MOVI r1,13
PUTC r1
MOVI r1,10
PUTC r1
HALT
; alloc_exp: r1=words r2=expected ptr (0 = must fail) r10=tag -> r1=ptr
alloc_exp:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,#V_X
CALL @nal_alloc
LD r2,r0,#V_X
CALL @ex
SUB r14,r14,r13
LD r15,r14,0
RET
; free_exp: r1=ptr r2=expected result r10=tag
free_exp:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,#V_X
CALL @nal_free
LD r2,r0,#V_X
CALL @ex
SUB r14,r14,r13
LD r15,r14,0
RET
; alloc3: allocate a,b,c of 10 words each from a fully free heap, expect consecutive 12-word blocks from base+1 -> V_A V_B V_C
alloc3:
ST r15,r14,0
ADD r14,r14,r13
MOVI r1,10
LD r2,r0,#NV_BASE
ADD r2,r2,r13
MOVI r10,0x5A1
CALL @alloc_exp
ST r1,r0,#V_A
MOVI r1,10
LD r2,r0,#V_A
MOVI r3,12
ADD r2,r2,r3
MOVI r10,0x5A2
CALL @alloc_exp
ST r1,r0,#V_B
MOVI r1,10
LD r2,r0,#V_B
MOVI r3,12
ADD r2,r2,r3
MOVI r10,0x5A3
CALL @alloc_exp
ST r1,r0,#V_C
SUB r14,r14,r13
LD r15,r14,0
RET
; slotfree: r6=slot. verify its pattern, free it (must return 0), clear the slot.
slotfree:
ST r15,r14,0
ADD r14,r14,r13
ST r6,r0,#V_SLOT
LD r1,r6,#TBL_PTR
LD r2,r6,#TBL_LEN
LD r3,r6,#TBL_PAT
CALL @verpat
MOVI r2,0
MOVI r10,0x203
CALL @ex
LD r6,r0,#V_SLOT
LD r1,r6,#TBL_PTR
CALL @nal_free
MOVI r2,0
MOVI r10,0x204
CALL @ex
LD r6,r0,#V_SLOT
ST r0,r6,#TBL_PTR
SUB r14,r14,r13
LD r15,r14,0
RET
; chkbasic: structure walk is clean, rover on a boundary, free+used = heap size
chkbasic:
ST r15,r14,0
ADD r14,r14,r13
CALL @nal_chkrover
MOVI r2,0
MOVI r10,0x210
CALL @ex
CALL @nal_check
ST r2,r0,#V_T1
ST r3,r0,#V_T2
MOVI r2,0
MOVI r10,0x211
CALL @ex
LD r1,r0,#V_T1
LD r2,r0,#V_T2
ADD r1,r1,r2
MOVI r2,#HEAP_SIZE
MOVI r10,0x212
CALL @ex
SUB r14,r14,r13
LD r15,r14,0
RET
; chkfull: heap is one free block
chkfull:
ST r15,r14,0
ADD r14,r14,r13
MOVI r6,#HEAP_SIZE
MOVI r7,0
MOVI r8,1
MOVI r9,#HEAP_SIZE
MOVI r10,0x2F0
CALL @chkexp
SUB r14,r14,r13
LD r15,r14,0
RET
; chkexp: r6=free r7=used r8=blocks r9=largest r10=tag. nal_chkrover and nal_check must agree with them.
chkexp:
ST r15,r14,0
ADD r14,r14,r13
ST r6,r0,#SCR+8
ST r7,r0,#SCR+9
ST r8,r0,#SCR+10
ST r9,r0,#SCR+11
ST r10,r0,#SCR+12
CALL @nal_chkrover
ST r1,r0,#SCR+13
CALL @nal_check
ST r1,r0,#SCR
ST r2,r0,#SCR+1
ST r3,r0,#SCR+2
ST r4,r0,#SCR+3
ST r5,r0,#SCR+4
LD r6,r0,#SCR+8
BOOL.6 r6,r6,r2
LD r7,r0,#SCR+9
BOOL.6 r7,r7,r3
BOOL.14 r6,r6,r7
LD r7,r0,#SCR+10
BOOL.6 r7,r7,r4
BOOL.14 r6,r6,r7
LD r7,r0,#SCR+11
BOOL.6 r7,r7,r5
BOOL.14 r6,r6,r7
BOOL.14 r6,r6,r1
LD r7,r0,#SCR+13
BOOL.14 r6,r6,r7
CMP r6,r0
JMP[NE] @ce_bad
LD r3,r0,#V_CHK
ADD r3,r3,r13
ST r3,r0,#V_CHK
SUB r14,r14,r13
LD r15,r14,0
RET
ce_bad:
LD r10,r0,#SCR+12
MOVI r11,14
CALL @fail
puts:
MOVI r4,255
pw:
LD r2,r1,0
MOVI r3,4
pt1:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @pt1
ADD r1,r1,r13
JMP @pw
puthex:
MOVI r3,8
MOVI r4,10
MOVI r7,7
ph1:
SHR r2,r1,28
SHL r1,r1,4
MOVI r6,48
ADD r6,r6,r2
CMP r2,r4
ADD[GE] r6,r6,r7
PUTC r6
SUB r3,r3,r13
JMP[NE] @ph1
RET
s_banner:
.str "nalloc test: heap at word 0x30000, 2048 words\r\n"
s_p1:
.str "init     "
s_p2:
.str "workload "
s_p2b:
.str "drain    "
s_p3:
.str "edges    "
s_p4:
.str "badfree  "
s_p5:
.str "coalesce "
s_p6:
.str "exhaust  "
s_ok:
.str "ok\r\n"
s_fail:
.str "FAIL tag="
s_tail1:
.str "checks="
s_tail2:
.str " allocfail="
s_pass:
.str " PASS\r\n"
.include "nalloc.nas"
