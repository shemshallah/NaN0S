# TOOL01 - replace nanchk.py / nan16sim.py / runbig.py with raw NaN16 (r29)

Owner rule: no new Python/C/JS; the outer scaffold is only the test bench. Everything below is
existing raw-NaN16 source under src/, assembled with the proven guest toolchain itself.

## What exists already (do NOT rebuild)
- src/tools/n16i.nas  (526 lines): NaN16 interpreter IN NaN16. All 68 ops + HALT, both-face gate
  (!G), bad-op trap (!O), predication via r11=2Z+L, BOOL runs unpredicated with n as truth table;
  guest regs live at @ni_regs; I/O passes through to the host. Entry: r1=guest pc, r2=GB
  (host addr of guest word 0), r3=guest mask; CALL @n16i_run -> r1 = guest steps.
- src/prog/nasm1.nas  (2604 lines): byte assembler in NaN16 (status-Y/bytes protocol) already
  proven: kan16_a64.xa64 core byte-identical to tools/a64.awk (r28c). Not the word assembler.
- src/prog/nasm0.nas  (+src/prog/nasm0_tables.nas): NaN16 WORD assembler in NaN16, previously
  proven vs nanchk on several files (mkproof, diff=0).

## Mandate mapping and VERIFIED status (r29, in-model)
| scaffold      | replacement | status |
|---------------|-------------|--------|
| nan16sim.py   | src/tools/n16i.nas                    | VERIFIED: ngate_n16i.sh (was n16i_check.py) 3/3 MATCH + nest depth 0/1/2 identical + ngate_fuzz.sh 60 seeds 0 mismatches (r29i; the python n16i_fuzz.py oracle is retired and deleted) |
| nanchk.py     | src/prog/nasm0.nas (P2 proof)         | VERIFIED: mkproof PASS diff=0 on key_test AND net_test (1965 words, 224 labels); showed nanchk vs nasm0 label-policy divergence only on duplicate labels (see below) |
| runbig.py     | src/tests/nrun_test.nas               | VERIFIED: guest assembles mini source with nasm0 then runs the OUT words under n16i_run; HI RUN PASS, steps 15279. Gate: `python3 tools/runbig.py src/tests/nrun_test.nas --isa1` |
| nanchk.py (fixpoint) | src/tests/nfix_test.nas + tools/ngate_nfix.sh | VERIFIED r29h: source on a NaNFS disk (ATA) -> guest nasm0 -> == own words (gen1==gen0, class nibble too) -> gen1 under n16i assembles again (gen2==gen1) -> FIX PASS. Seed only: nmk.awk, nflat.awk, nmkfs.sh |

NaNFS disk format (r29h): volume of 32-bit words, each stored as two LE u16 (what ATA INW returns); 128 words per sector = 2 blocks of 64 words. Block 0 superblock [magic 0x4E465331, nblocks, free, first data block, file words]; bitmap from block 1 spans ceil(nblocks/64) blocks (1 word per block, 1=used); data from sb[3] (2 when nblocks<=64). File text = 4 chars/word LE, NUL-terminated.

## Key lesson: duplicate labels make assemblers "disagree" silently
`src/net/crc32.nas` had `cmk_r:` as BOTH the rounds-loop re-entry and the .word counter slot.
nanchk keeps the LAST definition; guest nasm0 keeps the FIRST. Both resolved the same file
differently (nanchk: 5 refs -> .word data word -> the W0 crc32 crc32_update crawl/hang; nasm0:
diff=5 at 0x147). Fix = never reuse a label name: the counter slot is now `cmk_cnt`. Sweeping
for other duplicates in src/ recommended before the next big gate.

## Remaining work, in order
1. Land the net_test runbig rerun after the cmk fix (logs/net_test_v29c.txt): expect the boot to
   run mktab (256*8 rounds) and the vec suite; fix whatever the next real defect is, or get NET PASS.
2. Sweep src/net/*.nas for duplicate label names (cmk-style foot-guns); re-emit + re-proof.
3. Port the P2 proof + runner gates under the QEMU kan16 kernel (persistence), then drop
   nanchk/mkproof/runbig from the BUILD path (outer box remains for diagnostics only).
4. Then resume per r24/r27 plans (nbuild manifest P1, RISC-V, Python retirement).

## Semantics reference (keep aligned)
- nan16.c (aarch64/android/core) is now the line-of-truth for op behavior (flags fl(z,l)=2z+l; ST/STB set class 10/word; STW class = regs[b]&15; ADDI sext; CA LDR semantics r15 CALL/CALLR; JMPF/CALLF 24-bit; BOOL nibble = bit-index truth table: 6 = XOR, 8 = AND, 14 = OR).
- n16i.nas mirrors it; divergences get caught by tools/ngate_n16i.sh / ngate_fuzz.sh first.
- nasm0 build: V_* slot addresses 6272..6297 are fixed by nasm0.nas .equ block; the SRC/OUT/LAB/STACK areas may be re-based anywhere (runtime pointers V_SRCB/V_OUTB/V_LABB only).
