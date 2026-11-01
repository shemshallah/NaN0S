# NaN/0S v42 / r26

A bare-metal museum of computing where every instruction is a 64-bit
double-ended NaN-like word, every exhibit is NaN16 code, and the machine can
show its work.

Contact: shemshallah@gmail.com. Started 26 October 2026.

## r26j: outer-tool census DONE - sh + gawk + xxd + qemu only

Every Python scaffold (`tools/*.py`), the v86/node/JS harness (`x86/harness/`),
`x86/scaffold/`, the retired x86 sources (`x86/native/nan16.s`, `boot.s`,
`r22_verified/`) and the legacy shells are gone from the tree. 0 .py, 0 .mjs,
0 c. The outer dev stack is POSIX sh + gawk + xxd + qemu-system-i386:

```
sh x86/tools/mkall.sh      # guest text -> x86/build/nan0s.img byte-exact (mkimg.awk)
sh x86/tools/qgate.sh      # boot gate: greps the COM1 banner from bare Metal boot
gawk -f tools/nmk.awk -v CMD=emit src/museum/museum.nas   # .nas -> .nan (byte-exact port of the retired tool)
```

Developer tools kept in `tools/`: `mkall.sh`, `mkimg.awk`, `nmk.awk`, `qgate.sh`,
`carts.txt`. The guest nasm0 remains the NaN-native assembler; nkm is the
host-side dev-loop equivalent. Census details + evidence: `spec/PYTHON_CENSUS.md`,

## r26e: see TODO.md (PAE 16 GB bank window designed, draft in src/draft/kan16_pae_wip.xa, not shipped)

## What runs now

- **Framebuffer.** VGA mode 13h, 320x200x8, linear A0000. The mode-set
  register sequence is NaN16 (`src/lib/fb.nas`); the native kernel only
  provides `OUTB/INB`, `VPOKE/VPEEK`, `FBINFO`, `VSYNC`, `FBCOPY`, `FBFILL`.
- **Homebrew 5x7 font.** Complete printable ASCII, 14 Unicode glyphs, 1px
  horizontal and 2px vertical gaps, UTF-8 decoder (`fb_char5` / `fb_text5`).
  The Sierpinski panel is 53 columns and eight lines of sharper text.
  `NaN/0S` is in the exhibit headers. No copied font.
- **Sierpinski.** Real 320x128 white-on-black pixel rule-90 lattice, live
  scroll; the lower 72 pixels are a scrollable 3x5-font label. The exact dev
  note is in the panel.
- **Boole 16.** 98-line scrollable plaque, all 16 two-input functions built and
  run at runtime, the lane identity, the mirror law, and a dual-face word lab.
  `V_SCROLL` is a general shell vector.
- **About NaN/0S** and **About Shemshallah**, both scrollable.
- **The Trust exhibit.** A preface on Ken Thompson and the question, then the
  full paper "Trusting Trust in a Double-Endian NaN Machine", 376 wrapped
  lines, scrollable. Paper: `spec/TRUST_PAPER.md`.
- **Curator Console.** Secret key `~` (Shift+backtick). Raw guest memory, four
  payloads per row, scroll and page. Read-only.
- **Self-hosted builder + in-guest fixed point.** `src/prog/nbuild.nas`
  assembles a cartridge, seals it A/B/C, copies it to the RAM store, writes a
  TOC entry, and verifies store + seal (`NBUILD words=5 err=0`,
  `STORE PASS`, `SEAL PASS`).
  `src/prog/nbuild_selfhost.nas` assembles the running nasm0 source and
  matches all 661 words of itself: `SELFHOST PASS` (`logs/selfhost_r21.txt`).
- **NaNFS RAM slice.** `src/lib/nanfs.nas`: 64-word blocks, superblock,
  bitmap allocator, block write/read; `NANFS PASS` (`logs/nanfs_r21.txt`).
- **ATA read + write.** `ATA RW PASS` on the primary master (r21 v86-era evidence; the same boot now runs under qemu). The 16-bit
  PIO path needed the `0x66` operand-size prefix; `OUTL` completes the sector.
- **Nine TOC entries.** Baby, Boole, Sierpinski, About NaN/0S, About
  Shemshallah, Trust, Patriot Missile Failure, Paradox Engine, and the
  NaN/0S GUI desktop.

## r24: the desktop (GUI in NaN16)

Menu entry 9 opens a windowed desktop. **No native GUI code**: the window
manager, console, apps and the self-test are NaN16 (`src/lib/wm.nas`,
`src/exhibits/gui_cart.nas`, `src/tests/gui_test.nas`).

- 320x200 desktop, `NaN/0S` top bar with live tick counter, MOVE indicator.
- Window manager: 8 windows, z-order, focus = top, raise, Tab cycles, ESC closes,
  overlap and occlusion test (`wm_covered`), 11 px title bars that start with
  `NaN/0S`, close box, focus colours. Every window owns a 512-word private buffer.
- App kinds dispatch through a table (init, draw, key, tick), so a new program is
  four routines and a table row.
- **Terminal**: virtual console (cells, cursor, scroll by BCOPY, backspace). Commands
  by first letter: `h c v w l m x t q`; `l m x t` open more windows.
- **Sierpinski**: stateless rule-90 pixel window. Each pixel is computed from
  (t, x), scrolled with FBCOPY, skipped while covered. t wraps mod 128, so the triangle regrows.
- **Monitor**: double-endian timer. FWD = T, REV = FFFFFFFF - T, 16 lamps each.
- **Hex**: live guest memory, arrows and pages.
- **Move mode**: backtick, arrows move the window by 8 px, Enter leaves.
- Verified on the real kernel (v86-era r24 logs: `logs/gui_v86_r24.txt`, `screencaps/gui.png`,
  `screencaps/gui_esc_close.png`). `src/tests/gui_test.nas` is a NaN16 self-test
  (open, close, z-order, raise, cycle, covered, slot reuse, overflow, pixel readback):
  `GUI PASS` in the model (`logs/gui_test_r24.txt`).
- Found and fixed a retired-model bug: FBFILL/FBCOPY indexed registers by value
  (the native kernel was right). `fb_scroll` had never run in the model.
- Menu footer moved to row 22 to make room for entry 9.
- Python census: `spec/PYTHON_CENSUS.md` (executed r26j: outer stack sh+gawk+xxd+qemu).

## r23: Stage 3, a NaN16 interpreter written in NaN16

- `src/tools/n16i.nas` (512 words): fetch, both-face gate, predication by guest flags, decode and dispatch
  table for all 68 ops (0x00-0x43) plus HALT. Guest registers are 16 words in memory. Traps `!Gpppp` / `!Opppp`
  match the model. Guest I/O, floats and port ops pass through to the host. Entry: `r1=pc r2=GB r3=mask`, `CALL @n16i_run`.
- `src/tests/n16i_test.nas`: one image, two entries. The same guest (all 16 BOOL.n, flags and all 8 predicates,
  memory/class ops, CALL/RET/JMPR, MUL/DIV/SAR/ADDI/LDB/STB/BCOPY/BFILL/CALLF/JMPF, and the disassembler
  disassembling itself) runs natively and under n16i.
- `src/tests/n16i_nest.nas`: n16i running a relabelled copy of n16i running a guest (`logs/n16i_r23.txt`).
- Results (pre-qemu model only, r23): native vs interpreted output byte-identical for the
  suite, the gate trap and the bad-op trap. Guest step counts match exactly (73973). Nested output identical at
  depth 0, 1 and 2. Slowdown is about 45x per level. `nasm0` assembles n16i.nas in-guest: 512 words, err=0, diff=0
  (`logs/n16i_nasm0_r23.txt`).
- Fuzz (retired r26j scaffold; 400 random straight-line guests, all 16 classes): 399 match. Seed 0 differs in one
  register (r5) and is not yet root-caused (`logs/n16i_fuzz_r23.txt`).
- Scaffolds, not shipped path: `tools/gen_n16i_test.py`, `gen_n16i_nest.py`, `n16i_check.py`, `n16i_fuzz.py`.
- Known limits: guest addresses must alias through the mask (tests assemble guests at `.org 8192`); `nasm0` has no `.org`,
  so the test images are assembled by the host scaffolds (retired); floats and hardware ops are passed through, not re-implemented.

## Trust test (r21 transcript)

```
# r21 scaffold (retired r26j); in-guest nasm0 remains the live path
```

Result in `logs/r21_trust_test.txt`:

```
harness+nasm0 = 798 words (limit 6272) | source 2485 words | expected 798 words
gen0 steps 1402242 | gen1 (guest-built code) steps 1402242 |
words=0000031E labels=0000007A err=00000000 mirror=00000000 diff=00000000 PASS |
gen1 output == gen0 output: True
```

The independent scaffold and the in-guest assembler agree. The seal checks
both faces. The honest limits are in the paper: the native kernel is trusted,
the seal is not a signature, and DDC does not defeat two compromised builders.

## Build and run

```
sh x86/tools/mkall.sh
```

The image rule: `build/` holds at most two images: `nan0s.img` (the system)
and `base.img` (scaffold input for nasm0 proofs). Test images go to `$TMPDIR`.

The guest image is 524,288 bytes / 65,536 words. The boot loader reads 1040
sectors (16 kernel + 1024 guest) and the kernel copies 512 KB. One cart <= 57,344 words (r26b).
still small. The two-stage allocation image plan is in
`spec/IMAGE_SCALE_PLAN.md`: ship a small loader plus `work.img`; create a sparse
`store.nan` on first boot, write the work image into it, boot it. Never upload a
multi-GB image. Prototype (retired r26j scaffold): an apparent
apparent 64 GiB sparse image with about 1.5 MiB allocated (`logs/mkalloc_r21.txt`).

bare-metal boot under qemu (v86 harness retired r26j):

```
sh x86/tools/qgate.sh                              # automated gate: COM1 banner check
qemu-system-i386 -m 32 -drive format=raw,if=floppy,file=x86/build/nan0s.img   # interactive VGA view
```

## Gates

Historical r21-era evidence below came from scaffolds retired r26j; the live
gates are `sh x86/tools/mkall.sh` then `sh x86/tools/qgate.sh` (qemu bare metal).

- `python3 tools/nasm1check.py`: 83/83, boot 512 identical, kernel 5,784
  identical, v86 selftest match.
- `sh tools/nasm1check.sh`: the full gate, including six-cart museum, Baby,
  Boole, Trust, Curator, and pixel Sierpinski.
- `python3 tools/test_nanvm1.py`: 5,810 checks, 0 FAIL.
- `python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2`: fixed point PASS.
- `logs/nasm1_check_r21.txt`, `logs/nanvm1_ops_test_r21.txt`,
  `logs/r21_trust_test.txt`.

Not yet green: seal mutation sweep, mirror-law refusal on the multi-entry
layout, real-hardware PS/2/USB, ATA PIO write (read is green), and the GUI.
The self-hosting/disk plan is `spec/SELF_HOSTING.md`; the GUI plan is
`spec/GUI_PLAN.md`; the three-file translator plan is `spec/TRANSLATOR.md`;
the Sierpinski/16-operand reference mapping is `spec/REFERENCE_HTML.md`.

## Museum plan

Nine cartridges live. The recursive plan for everything else is in `TODO.md`.
Highlights:

- **Hall 7 failure exhibits**: Patriot Missile (1991) and Ariane 5 (1996),
  specs in `spec/FAILURE_EXHIBITS_PLAN.md`.
- **Hall 1 Apollo AGC**: 15-bit words, DSKY, 1202 alarm demo, lunar descent
  toy, spec in `spec/APOLLO_AGC_PLAN.md`.
- **Alien Mechanics**: double-endian timer, causal loops, Paradox Engine,
  Halting Oracle, Asimov Loop, EPR twin pair, the Orrery / NaN Singularity,
  spec in `spec/ALIEN_MECHANICS.md`.
- **Curator Console**: spec in `spec/CURATOR_CONSOLE.md`.
- **Two-stage allocation image**: `spec/IMAGE_SCALE_PLAN.md`.

Every exhibit carries a badge (EXACT / RE-CREATION / INSPIRED), a date, people
with alive/dead status, a history lesson, a code tutorial, sources, and a
golden log. ROMs and assets are homebrew unless public domain is verified.

## Layout

```
src/boot       boot sector (kboot0.xa)
src/native     kan16.xa (NaN-written x86 emitter source), nan16.s (host model),
               r22_verified/ (fallback)
src/prog       nasm0, nasm1, nalloc, selftest, sierpinski, spanbench
src/museum     shell, lib, plaques
src/exhibits   Baby, Boole, Sierpinski, About, Trust
src/lib        libvec.nas (vectors), fb.nas (framebuffer + 3x5 font)
src/tests      keyboard, ring, tick, far, framebuffer
spec           all plans, NAN16/NANVM1 specs, TRUST_PAPER.md
logs           evidence, including r21 transcripts
screencaps     milestone screenshots
tools          scaffold (Python), harness (v86), generators
```

## Screenshots

`screencaps/main.png`, `boole_plaque.png`, `boole_scrolled.png`,
`boole_live.png`, `sierpinski_pixels.png`, `sierpinski_details.png`,
`about_nan0s.png`, `about_dev.png`, `trust_preface.png`, `trust_paper.png`,
`curator.png`, `patriot.png`, `paradox.png`, `gui.png`, `gui_move.png`.

## Old headers

The v39 and earlier status headers are in `spec/README_v23_archive.md` and the
logs. The v22/v23 TODOs are kept in `spec/`.

## r25 WIP note (31 Oct 2026)
1024x768 mode, NaNGlyph font, raw-scancode keyboard driver (`src/lib/kbd.nas`) and the reference Sierpinski colours are in and verified. The new window manager is a draft (`src/draft/wm_r25_wip.nas`); the shipped GUI is still the 320x200 one. See the top of TODO.md for the exact remaining tasks.


## r26h: Python retirement begun
Generators are gone (the `.nas` files are the source). `x86/harness/shot.mjs` is the one outer box (screenshots, key plans, guest RAM dump). Kernel enables SSE at boot. See TODO r26h and spec/PYTHON_CENSUS.md.

## r26k: AArch64 + RISC-V adapter workline opened (WIP)

Target: the guest word stream becomes bootable UNMODIFIED on three ISAs
(the museum's 24,904 words are ISA-neutral; only boot shim + native core
are per-arch). Contract and entry-state table: `spec/ARCH_ADAPTERS.md`.
Boot-path smoke blobs sit in `src/draft/` (first boot attempt serial-empty;
debug open). No A64/RV64 gold yet; x86 gold and the image layout are
unchanged. Per-arch gates (`tools/qgate_a64.sh`, `tools/qgate_rv64.sh`)
land after the smoke test passes. Outer stack stays sh + gawk + xxd + qemu.
