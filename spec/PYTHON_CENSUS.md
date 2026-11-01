# Python census (r24) - EXECUTED r26j: zero Python left in the tree; RE-EXECUTED r29i after the
# regression (uncommitted working tree had restored 16 tools/*.py plus the legacy shells and the
# tools/harness/*.mjs node boxes).

r29i re-execution (1 Nov 2026): the r26j zero-Python state had regressed in the uncommitted
tree. This round re-deleted everything for good and closed the last two functional gaps:

- `tools/ngate_fuzz.sh` + `src/tests/n16fuzz.nas` - the in-guest fuzz cart that replaced
  `n16i_fuzz.py` (engine vs engine on 60 seeds; mode 1 one-image under n16i, mode 0 one
  nan_cli per seed; PASS 60/60). One real semantics fact came out of debugging it: BOOL's
  nibble truth table is 0b0110 = XOR and 0b1110 = OR (`BOOL.14` used as "=A^B" was OR and
  degenerated the stream; all 6 sites fixed to `BOOL.6`).
- `tools/build.sh` / `x86/tools/build.sh` call `sh tools/mkbase.sh` now (base.img
  byte-identical python-vs-sh; only the emitted nanvm0.nan header comment names the proper
  tools/scaffold path).
- Deleted: `mkproof.py proofnat.py nanchk.py nan16sim.py mkbase.py mkimg1.py mkboot.py
  nasm1run.py nasm1check.py nasm1_tests.py test_nanvm1.py difftest.py fuzz.py traptest.py
  sweep_seal.py`, shells `nasm1check.sh native_check.sh x86/tools/native_check.sh
  build_round01.sh capture_r21.sh x86/tools/capture_r21.sh`, and `tools/harness/`
  `x86/harness/` (node_modules + .mjs; boot/capture gates are `qgate.sh`, sh + qemu only).
- Re-proven post-delete (no Python anywhere): `build.sh` end-to-end, `ngate_n16i.sh`
  RESULT PASS, `ngate_fuzz.sh` PASS 60/60, `ngate_nfix.sh` PASS, `mkproof.sh` on
  src/tests/key_test.nas PROOF PASS, `qgate.sh` PASS. Outer stack: POSIX sh + gawk/awk +
  xxd/od + qemu-system-i386 only; guest remains raw NaN16 (adapters: nan_cli C core, qemu).

r26j resolution: the whole census below is DONE. Every `tools/*.py` file (22),
`tools/harness/` (node_modules, bios, *.mjs, package.json, package-lock.json,
qrun.sh), `tools/scaffold/` and the legacy shells were deleted. The tree now
has 0 `.py`, 0 `.mjs`, no C. The outer dev stack is POSIX sh + gawk + xxd +
qemu-system-i386 only; the guest remains NaN16-only.

Replacements shipped in r26j (outer stack, byte-exact ports of the retired
scaffolds; evidence in `logs/nmk_parity_r26j.txt` and `logs/qgate_com1.txt`):

- `tools/nmk.awk` - emit (all 10 sources) + check; replaced `nanchk.py`.
- `tools/mkimg.awk` - image layout, TOC, seals A/B/C; replaced `mkimg1.py`.
- `tools/mkall.sh` - sh glue; builds `build/nan0s.img` (byte-identical to the
  r26i reference image sha256 79cc73edf90915c27d619cb9008979edd4a36b164b440975
  e626785ba6ac5200 before the r26j shell banner was added).
- `tools/qgate.sh` - bare-metal boot gate on `qemu-system-i386`; replaced the
  v86/JS harness checks. PASS prints `NaN/0S R26J READY MENU=S` from the guest.

Historical r24 census (what still stood between NaN/0S and zero Python then):

Goal: no Python anywhere in the build, the runtime, or the tests. Today the
*runtime* has none: the image boots on x86 and runs only NaN16 words. What
remains is the host build and test bench. Every file below says `SCAFFOLD` in
its header. This table is the removal plan, in dependency order.

## A. Build path (the real blockers)

| file | does | NaN replacement | status |
|---|---|---|---|
| `nanchk.py` | `.nas` -> `.nan` words (assembler, `.include`, `.str`, `.org`) | `src/prog/nasm0.nas` (in-guest, proven fixed point, 63 mnemonics) | nasm0 lacks `.include`/`.org`; add both, then flip `mkall` to use it |
| `mkimg1.py` | pack boot + kernel + guest, seal carts (FNV A/B + class C), patch TOC | `src/prog/nbuild.nas` (RAM slice: assemble, seal, store, verify) | needs ATA write (blocked on PIO write handshake) or a host-side "dump guest RAM" hook |
| `nasm1run.py` | run nasm1 (x86 emitter in NaN16) to produce boot and kernel bytes | `src/prog/nasm1.nas` itself | needs a NaN-VM host that is not Python: v86 harness (`tools/harness`, JS) can run it |
| `nan16sim.py` | byte-accurate model of the VM | the native kernel in v86 / hardware; `src/tools/n16i.nas` inside the guest | keep as oracle until n16i fuzz is clean |
| `mkall.sh` etc. | glue | a manifest read by nbuild | after the three rows above |

## B. Oracles and tests (can be deleted last)

`test_nanvm1.py`, `nasm1_tests.py`, `nasm1check.py`, `n16i_check.py`,
`n16i_fuzz.py`, `fuzz.py`, `difftest.py`, `traptest.py`, `test_far.py`,
`mkproof.py`, `proofnat.py`, `sweep_seal.py`, `mutate_nalloc.py`, `babyref.py`.
Replacement: self-validating NaN16 programs that print PASS/FAIL, run on the
real kernel in v86. First two exist: `src/tests/gui_test.nas` (r24, 20 checks)
and `src/tests/n16i_test.nas` (r23).

## C. Generators of museum text and tables

`gen_about_carts.py`, `gen_boole_cart.py`, `gen_patriot_cart.py`,
`gen_trust_cart.py`, `gen_sierpinski_*.py`, `gen_fb_lib.py`, `gen_nasm1_tables.py`,
`gen_n16i_*.py`, `gen_nbuild_selfhost.py`, `mktables.py`, `mkalloc.py`,
`mkbabydata.py`, `mkboot.py`, `mkbase.py`.
Replacement: the generated `.nas` files are already checked in and are the
source of truth. `mktables` is already ported (`src/tools/mktables.nas`).
Delete a generator once its output has a hand-maintained `.nas` and a golden
log. The r24 GUI (`wm.nas`, `gui_cart.nas`) was written directly in `.nas`, no
generator.

## D. Screenshots

`fbshot.py`, `shot.py`, `textshot.py`, `t.py`, `guitest.py`. Replacement: a JS
capture in `tools/harness` that writes PNG directly (no Python). Cheap.

## Order of attack

1. nasm0: `.include` and `.org` (unblocks in-guest assembly of every cart).
2. JS capture writes PNG (drops D).
3. nbuild reads a manifest and emits the image through a host RAM dump or ATA
   write (drops mkimg1, mkall).
4. Run nasm1 under v86 to emit boot + kernel (drops nasm1run, nan16sim in build).
5. Convert each oracle to a NaN self-test; delete the Python file when the
   NaN test and a log exist.


## r26h update
Retired: 13 generators (output byte-identical to the checked-in .nas; 3 more were stale), fbshot/shot/textshot/t/bootcmp/runbig/guitest, and the JS cap/capfb/capx drivers (replaced by tools/harness/shot.mjs, the single outer box, which can also dump guest RAM).
Remaining Python (22): nanchk mkimg1 mkbase mkboot nasm1run nan16sim gen_nbuild_selfhost mkalloc mkproof proofnat nasm1check nasm1_tests test_nanvm1 test_far difftest fuzz traptest n16i_check n16i_fuzz babyref sweep_seal mutate_nalloc + native gas files. Order of attack: see TODO r26h NEXT.
