JMP @main
.equ W_W 3
.equ W_H 4
.equ W_X 1
.equ W_Y 2
fb_w:
.word 64
fb_h:
.word 48
cnt:
.word 0
rec:
.word 1,3,2,44,36,0,1,0
wm_wbase:
MOVI r1,@rec
RET
wm_covered:
MOVI r1,0
RET
main:
MOVI r13,1
MOVI r14,4000
MOVI r1,0
CALL @lat_sync
MOVI r1,70
ST r1,r0,@cnt
mloop:
LD r1,r0,@cnt
CMP r1,r0
JMP[EQ] @mdone
SUB r1,r1,r13
ST r1,r0,@cnt
MOVI r1,0
CALL @lat_tick
JMP @mloop
mdone:
MOVI r1,0
CALL @lat_draw
HALT
; ====================== SIERPINSKI (exact rule 90, cyclic edges, VRAM row cache) ======================
; State is global (one lattice window at a time). Cells are class-6 (XOR) NaN16 words, payload 1 = fire. Row n+1 = BOOL.6(left,right) with wrap-around edges.
; Both end cells of every new row are read back with LDN; a class other than 6 (a bad head) reseeds the lattice. Rows live in offscreen VRAM (ring of LSRD rows, stride fb_w) and are blitted with FBCOPY.
; Time flows UP: the seed row sits at the top, new rows enter at the bottom, once the body is full everything scrolls up by one pixel row per step.
.equ LSLIM 2000000
.equ LSRD 768
; lat_sync r1=id : load body geometry, reseed when the cell width changed
lat_sync:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ls_id
CALL @wm_wbase
ST r1,r0,@ls_wb
LD r2,r1,#W_W
MOVI r3,4
SUB r2,r2,r3
ST r2,r0,@ls_bw
LD r3,r1,#W_H
MOVI r4,20
SUB r3,r3,r4
ST r3,r0,@ls_bh
LD r6,r1,#W_X
ADD r6,r6,r13
ADD r6,r6,r13
LD r7,r1,#W_Y
MOVI r8,18
ADD r7,r7,r8
LD r9,r0,@fb_w
MUL r7,r7,r9
ADD r7,r7,r6
ST r7,r0,@ls_a
LD r4,r0,@ls_w
CMP r4,r2
JMP[EQ] @lsy_ok
ADD r1,r2,r0
CALL @lat_reset
lsy_ok:
SUB r14,r14,r13
LD r15,r14,0
RET
; lat_reset r1=cells : clear both row arrays, seed the centre cell, paint row 0, n=1
lat_reset:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@ls_w
ST r0,r0,@ls_n
LD r2,r0,@fb_w
LD r3,r0,@fb_h
MUL r2,r2,r3
ST r2,r0,@ls_oc
MOVI r4,#LSLIM
MOVI r5,0
CMP r2,r4
JMP[GE] @lrs_rd
SUB r5,r4,r2
LD r6,r0,@fb_w
DIVU r5,r5,r6
MOVI r6,#LSRD
CMP r5,r6
JMP[LE] @lrs_rd
ADD r5,r6,r0
lrs_rd:
ST r5,r0,@ls_rd
MOVI r2,0
MOVHI r2,16
ST r2,r0,@ls_pa
MOVI r3,4096
ADD r3,r2,r3
ST r3,r0,@ls_pb
MOVI r6,6
MOVI r4,0
lrs_c:
CMP r4,r1
JMP[GE] @lrs_cd
ADD r5,r2,r4
STW r0,r5,r6
ADD r5,r3,r4
STW r0,r5,r6
ADD r4,r4,r13
JMP @lrs_c
lrs_cd:
SHR r4,r1,1
ADD r5,r2,r4
STW r13,r5,r6
CALL @lat_paint
MOVI r1,1
ST r1,r0,@ls_n
SUB r14,r14,r13
LD r15,r14,0
RET
; lat_paint : paint the cell row ls_pa into cache row (ls_n mod ls_rd) as idle fill + fire runs (leaf)
lat_paint:
LD r2,r0,@ls_rd
CMP r2,r0
RET[EQ]
LD r1,r0,@ls_n
MODU r1,r1,r2
LD r3,r0,@fb_w
MUL r1,r1,r3
LD r4,r0,@ls_oc
ADD r1,r1,r4
LD r5,r0,@ls_w
MOVI r6,17
FBFILL r5,r1,r6
LD r7,r0,@ls_pa
MOVI r8,0
MOVI r6,16
lp_x:
CMP r8,r5
RET[GE]
ADD r9,r7,r8
LD r10,r9,0
CMP r10,r0
JMP[NE] @lp_run
ADD r8,r8,r13
JMP @lp_x
lp_run:
ADD r11,r8,r0
lp_e:
ADD r8,r8,r13
CMP r8,r5
JMP[GE] @lp_f
ADD r9,r7,r8
LD r10,r9,0
CMP r10,r0
JMP[NE] @lp_e
lp_f:
SUB r12,r8,r11
ADD r2,r1,r11
FBFILL r12,r2,r6
JMP @lp_x
; lat_step : next = rule 90 of cur (cyclic), swap, verify class, paint, n+1
lat_step:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@ls_pa
LD r2,r0,@ls_pb
LD r3,r0,@ls_w
MOVI r12,6
MOVI r4,0
lst_x:
CMP r4,r3
JMP[GE] @lst_d
SUB r5,r4,r13
CMP r4,r0
SUB[EQ] r5,r3,r13
ADD r6,r4,r13
CMP r6,r3
MOVI[EQ] r6,0
ADD r5,r1,r5
LD r7,r5,0
ADD r6,r1,r6
LD r9,r6,0
BOOL.6 r7,r7,r9
ADD r8,r2,r4
STW r7,r8,r12
ADD r4,r4,r13
JMP @lst_x
lst_d:
ST r2,r0,@ls_pa
ST r1,r0,@ls_pb
MOVI r6,6
LDN r5,r2,0
CMP r5,r6
JMP[NE] @lst_bad
LD r3,r0,@ls_w
ADD r3,r3,r2
SUB r3,r3,r13
LDN r5,r3,0
CMP r5,r6
JMP[NE] @lst_bad
CALL @lat_paint
LD r1,r0,@ls_n
ADD r1,r1,r13
ST r1,r0,@ls_n
JMP @lst_ret
lst_bad:
LD r1,r0,@ls_w
CALL @lat_reset
lst_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; lat_put r1=generated row, r2=screen row of the body : blit one cached row (leaf; idle fill when the row left the ring)
lat_put:
LD r3,r0,@ls_n
SUB r3,r3,r1
LD r4,r0,@ls_rd
CMP r3,r4
JMP[GT] @lpu_idle
CMP r4,r0
JMP[EQ] @lpu_idle
MODU r3,r1,r4
LD r4,r0,@fb_w
MUL r3,r3,r4
LD r5,r0,@ls_oc
ADD r3,r3,r5
MUL r6,r2,r4
LD r7,r0,@ls_a
ADD r6,r6,r7
LD r8,r0,@ls_bw
FBCOPY r8,r6,r3
RET
lpu_idle:
LD r4,r0,@fb_w
MUL r6,r2,r4
LD r7,r0,@ls_a
ADD r6,r6,r7
LD r8,r0,@ls_bw
MOVI r9,17
FBFILL r8,r6,r9
RET
lat_draw:
ST r15,r14,0
ADD r14,r14,r13
CALL @lat_sync
LD r1,r0,@ls_n
LD r2,r0,@ls_bh
CMP r1,r2
JMP[GT] @ld_full
MOVI r3,0
JMP @ld_go
ld_full:
SUB r3,r1,r2
ld_go:
ST r3,r0,@ld_f
ST r0,r0,@ld_r
ld_loop:
LD r2,r0,@ld_r
LD r3,r0,@ls_bh
CMP r2,r3
JMP[GE] @ld_done
LD r1,r0,@ld_f
ADD r1,r1,r2
LD r4,r0,@ls_n
CMP r1,r4
JMP[LT] @ld_have
LD r5,r0,@fb_w
MUL r6,r2,r5
LD r7,r0,@ls_a
ADD r6,r6,r7
LD r8,r0,@ls_bw
MOVI r9,17
FBFILL r8,r6,r9
JMP @ld_next
ld_have:
CALL @lat_put
ld_next:
LD r2,r0,@ld_r
ADD r2,r2,r13
ST r2,r0,@ld_r
JMP @ld_loop
ld_done:
SUB r14,r14,r13
LD r15,r14,0
RET
ld_f:
.word 0
ld_r:
.word 0
; lat_tick r1=id : advance one row (always, so history stays exact); touch the screen only when the window is not covered
lat_tick:
ST r15,r14,0
ADD r14,r14,r13
CALL @lat_sync
LD r1,r0,@ls_n
ST r1,r0,@lt_n0
CALL @lat_step
LD r1,r0,@ls_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @lt_done
LD r1,r0,@lt_n0
LD r2,r0,@ls_bh
CMP r1,r2
JMP[GE] @lt_scroll
ADD r2,r1,r0
CALL @lat_put
JMP @lt_done
lt_scroll:
LD r10,r0,@ls_a
LD r9,r0,@fb_w
LD r12,r0,@ls_bw
MOVI r11,1
lt_sl:
LD r2,r0,@ls_bh
CMP r11,r2
JMP[GE] @lt_sd
MUL r8,r11,r9
ADD r8,r10,r8
SUB r7,r11,r13
MUL r7,r7,r9
ADD r7,r10,r7
FBCOPY r12,r7,r8
ADD r11,r11,r13
JMP @lt_sl
lt_sd:
LD r1,r0,@lt_n0
LD r2,r0,@ls_bh
SUB r2,r2,r13
CALL @lat_put
lt_done:
SUB r14,r14,r13
LD r15,r14,0
RET
lt_n0:
.word 0
ls_id:
.word 0
ls_wb:
.word 0
ls_w:
.word 0
ls_n:
.word 0
ls_rd:
.word 0
ls_oc:
.word 0
ls_pa:
.word 0
ls_pb:
.word 0
ls_bw:
.word 0
ls_bh:
.word 0
ls_a:
.word 0
