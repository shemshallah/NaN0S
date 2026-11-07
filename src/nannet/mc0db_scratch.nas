; MC0DB / BS0DB scratch quota manager — NaN16 guest.
; Accounting unit: 4 KiB pages. Never eagerly allocates the 10 GiB ceiling.
; Combined ceiling: 2,621,440 pages (10 GiB).
; BS0DB ceiling: 262,144 pages (1 GiB).
; MC0DB ceiling: 1,835,008 pages (7 GiB).
; Remaining 524,288 pages (2 GiB) are reserved headroom.
;
; ABI:
;   mc_scratch_reserve r1=pool(1 BS0, 2 MC0), r2=pages
;       -> r1=allocation_id, r2=granted_pages, r3=status
;   mc_scratch_release r1=allocation_id -> r3=status
;   mc_scratch_stats -> r1=BS0_used,r2=MC0_used,r3=total_used,r4=status
; Status: 0 success, 1 invalid, 3 quota/table full, 5 unknown allocation.
; Fixed metadata table is an in-memory bootstrap journal only. Durable
; MC0DB/BS0DB file persistence is deliberately a separate storage ABI.
;
; Allocation records: id,pool,pages,active. 64 records, first-fit.
mc_scratch_reserve:
ST r15,r0,@mc_reserve_ret
ST r1,r0,@mc_tmp_pool
ST r2,r0,@mc_tmp_pages
CMP r1,r0
JMP[EQ] @mc_reserve_bad
MOVI r4,2
CMP r1,r4
JMP[GT] @mc_reserve_bad
CMP r2,r0
JMP[EQ] @mc_reserve_bad
; Select current usage and quota.
CMP r1,r0
JMP[NE] @mc_reserve_mc
LD r5,r0,@mc_bs_used
LA r6,262144
JMP @mc_reserve_check
mc_reserve_mc:
LD r5,r0,@mc_mc_used
LA r6,1835008
mc_reserve_check:
LD r7,r0,@mc_tmp_pages
ADD r8,r5,r7
CMP r8,r6
JMP[GT] @mc_reserve_full
LD r9,r0,@mc_total_used
ADD r10,r9,r7
LA r11,2097152
CMP r10,r11
JMP[GT] @mc_reserve_full
; Find free metadata slot.
MOVI r4,@mc_scratch_table
MOVI r5,64
MOVI r6,0
mc_reserve_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @mc_reserve_slot
ADDI r4,r4,4
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @mc_reserve_scan
JMP @mc_reserve_full
mc_reserve_slot:
LD r7,r0,@mc_next_id
CMP r7,r0
JMP[EQ] @mc_reserve_full
ST r7,r0,@mc_tmp_id
ST r7,r4,0
LD r8,r0,@mc_tmp_pool
ST r8,r4,1
LD r8,r0,@mc_tmp_pages
ST r8,r4,2
MOVI r8,1
ST r8,r4,3
ADDI r7,r7,1
ST r7,r0,@mc_next_id
LD r8,r0,@mc_tmp_pool
CMP r8,r0
JMP[NE] @mc_reserve_add_mc
LD r8,r0,@mc_bs_used
LD r9,r0,@mc_tmp_pages
ADD r8,r8,r9
ST r8,r0,@mc_bs_used
JMP @mc_reserve_add_total
mc_reserve_add_mc:
LD r8,r0,@mc_mc_used
LD r9,r0,@mc_tmp_pages
ADD r8,r8,r9
ST r8,r0,@mc_mc_used
mc_reserve_add_total:
LD r8,r0,@mc_total_used
LD r9,r0,@mc_tmp_pages
ADD r8,r8,r9
ST r8,r0,@mc_total_used
LD r1,r0,@mc_tmp_id
LD r2,r0,@mc_tmp_pages
MOVI r3,0
LD r15,r0,@mc_reserve_ret
RET
mc_reserve_bad:
MOVI r1,0
MOVI r2,0
MOVI r3,1
LD r15,r0,@mc_reserve_ret
RET
mc_reserve_full:
MOVI r1,0
MOVI r2,0
MOVI r3,3
LD r15,r0,@mc_reserve_ret
RET
mc_reserve_ret:
.word 0

mc_scratch_release:
ST r15,r0,@mc_release_ret
ST r1,r0,@mc_tmp_id
MOVI r4,@mc_scratch_table
MOVI r5,64
MOVI r6,0
mc_release_scan:
LD r7,r4,0
CMP r7,r0
JMP[EQ] @mc_release_next
LD r8,r0,@mc_tmp_id
CMP r7,r8
JMP[EQ] @mc_release_found
mc_release_next:
ADDI r4,r4,4
ADDI r6,r6,1
CMP r6,r5
JMP[LT] @mc_release_scan
MOVI r3,5
LD r15,r0,@mc_release_ret
RET
mc_release_found:
LD r8,r4,3
CMP r8,r0
JMP[EQ] @mc_release_missing
LD r8,r4,1
CMP r8,r0
JMP[NE] @mc_release_mc
LD r9,r0,@mc_bs_used
LD r10,r4,2
SUB r9,r9,r10
ST r9,r0,@mc_bs_used
JMP @mc_release_total
mc_release_mc:
LD r9,r0,@mc_mc_used
LD r10,r4,2
SUB r9,r9,r10
ST r9,r0,@mc_mc_used
mc_release_total:
LD r9,r0,@mc_total_used
LD r10,r4,2
SUB r9,r9,r10
ST r9,r0,@mc_total_used
ST r0,r4,3
MOVI r3,0
LD r15,r0,@mc_release_ret
RET
mc_release_missing:
MOVI r3,5
LD r15,r0,@mc_release_ret
RET
mc_release_ret:
.word 0

mc_scratch_stats:
LD r1,r0,@mc_bs_used
LD r2,r0,@mc_mc_used
LD r3,r0,@mc_total_used
MOVI r4,0
RET

mc_tmp_pool:
.word 0
mc_tmp_pages:
.word 0
mc_tmp_id:
.word 0
mc_bs_used:
.word 0
mc_mc_used:
.word 0
mc_total_used:
.word 0
mc_next_id:
.word 1
.org 24000
mc_scratch_table:
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
.word 0,0,0,0
