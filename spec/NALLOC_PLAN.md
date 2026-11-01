# nalloc: heap allocator in NaN16 (design round 11; WRITTEN AND TESTED round 12: src/prog/nalloc.nas, src/prog/nalloc_test.nas)
Next-fit (rover) over an implicit list of blocks with boundary tags, coalescing on free. Same family as Quake's Z_Malloc, so the Quake zone/hunk can sit on it. Uses only NaN16 v0.1 ops, so it also fits NaNVM0.
Block: head word at b, foot word at b+size-1, both payload = size<<1 | used. size counts head+foot, min 3. Pointer returned = b+1 (never 0 when base>0).
Vars (word addresses below 64K): NV_BASE, NV_END (exclusive), NV_ROVER. Heap may sit anywhere in 32-bit word space (base/size are registers).
API: nal_init r1=base r2=words | nal_alloc r1=words -> r1=ptr or 0 | nal_free r1=ptr -> r1=0 ok, 1 bad/double free | nal_check -> r1=err (0 ok, 1 head!=foot, 2 size<3, 3 overrun, 4 adjacent free blocks), r2=free words, r3=used words, r4=blocks, r5=largest free.
Alloc pseudocode: need=max(n+2,3); cur=rover; loop: if free and size>=need { if size-need>=3 split else take all; rover=next block (wrap to base); return cur+1 } cur+=size, wrap at end; stop when back at start -> 0.
Free pseudocode: b=ptr-1; reject if outside heap or not used; size=head>>1; if next block free: size+=its size; if previous block (from the foot at b-1) free: b-=its size, size+=its size; write head+foot free; if rover in [b,b+size) rover=b.
Planned test (nalloc_test.nas): heap at word 0x30000 (>64K), LCG workload 800 ops over 64 slots with pattern fill and verify, nal_check every 32 ops, drain, then expect one block of full size; whole-heap alloc then alloc fails; double free returns 1; free b,a,c coalesces to one block. Then nasm0 must assemble both files identically (mkproof --big).

## Round 12 status
nalloc.nas = nal_init/nal_alloc/nal_free/nal_check/nal_chkrover (the draft with one structural change: nal_chkrover added). nalloc_test.nas: 0xC54 = 3156 passed checks, 7 phases (init, 800-op random workload over 64 slots with pattern verify and nal_check every 32 ops, drain, whole-heap/too-big/take-all/split edges, double free and bad pointers incl. alloc(0), coalesce in three orders plus next-fit, exhaustion with 1-word blocks, rover wrap past the end, refill in rover order, drain). Heap at word 0x30000, 2048 words. logs/nalloc_test.txt.
Mutation test (tools/mutate_nalloc.py, logs/nalloc_mutations.txt): 9 planted single-edit bugs, all 9 stop the test at FAIL. One was missed at first (minimum block size 2 never exercised); alloc(0) test added for it.
nasm0 inside the guest assembles nalloc_test.nas (944 words) identical to the scaffold: logs/nasm0_proof_nalloc_test_flat1M.txt.
Known limit (documented in nalloc.nas): free trusts the word before the pointer; a pointer into the middle of a block is only caught if that word looks free.
