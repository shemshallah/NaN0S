# >>> FIRST: ANDROID DEVICE TEST FIXES (1 Nov 2026, first APK run on a phone; screenshots Screenshot_20261101_0812..0817_NaN0S.jpg) <<<
Status: APK builds green and boots. Exhibits 1, 7, 8, 9 run. Fix in this order (A = blocks use, B = wrong, C = design).
- [ ] A0. PYTHON RETIREMENT (r29i, 1 Nov 2026, IN PROGRESS). r29i DELTA: tree starts EMPTY of .py (git-checked and re-raked). (1) NEW tools/ngate_fuzz.sh + src/tests/n16fuzz.nas, the raw-NaN fuzz cart that replaces n16i_fuzz.py (random-program differential was the last Python oracle): the window (60 words at PROGB[12..71]) is built IN-GUEST by a seeded xorshift32 chain (fz_xs: SHL r3,r4,13 / XOR r4,r4,r3 ... count in the imm, BOOL.6 = A^B, NOT BOOL.14 = OR per the nibble-is-truth-table encoding of NAN16_SPEC 'BOOL_n(0xCC..,0xAA..) == n*0x1111..'); generated program uses only pure ALU/FP ops with d,a<8 and b mapped to {0..9,14} so BOTH engines preload every operand; 12 INIT words at window[800..811] (nibble 10), preload stub BCOPY'd to window[0..11], reg-dump stub at 72.. (one digit mask in r10 can clobber: stub HALTs after). Gate mode 1 = one image runs 60 seeds under n16i (patch V_COUNT=60 via .org 6302), mode 0 = per-seed nan_cli (V_FMODE=0, V_SEEDC=s, s=0..59); per-seed segments split on ^M[0-9A-F]{4}$ must be byte-identical and every run rc=3. RESULT PASS 60/60 (seed 41 first matched inter vs native step-for-step, 4667 native steps).
- (2) REAL semantics bug found by the cart and FIXED IN THE CART (engine is right): BOOL.14's nibble truth table 0b1110 = OR, not XOR, so the stream degenerated to all-FF (all engines printed exactly the wrong FFFF values, which is why both engines never diverged - they agreed on the wrong data). C-probe (TMPDIR, throwaway) on the C core with nan_reg/nan_word traced Gadream inputs 0xA40560 ^ 0x05202B at acceptance: got 0xA5256B = OR. All 6 BOOL.14 sites -> BOOL.6; commentary fixed.
- (3) tools/build.sh and x86/tools/build.sh re-wired from python3 tools/mkbase.py to sh tools/mkbase.sh; the port proof ran byte-compare across python vs sh: x86/build/base.img IDENTICAL, src/vm/nanvm0.nan differs only in the emitted header's scaffold path (sh writes tools/scaffold/nanvm0.s which is where the .s actually lives now; not a data byte).
- (4) DELETED the final 16 .py mkall/tree-wide: mkproof.py proofnat.py (gate = tools/mkproof.sh, PROOF PASS on src/tests/key_test.nas), nanchk.py nan16sim.py (run + parity anchors live in tools/nrun.sh + ngate_n16i.sh), mkbase.py, mkimg1.py, mkboot.py, nasm1run.py nasm1check.py nasm1_tests.py test_nanvm1.py (all had no live callers), difftest.py fuzz.py traptest.py (their callers tools/native_check.sh x2 are DELETED SHELLS), sweep_seal.py (was supervised by seal gate and dead since its shell was deleted), and the dead legacy shells tools/nasm1check.sh tools/native_check.sh x86/tools/native_check.sh tools/build_round01.sh tools/capture_r21.sh x86/tools/capture_r21.sh plus the node.js JS outer boxes tools/harness/ x86/harness/ (node_modules, *.mjs, qrun.sh; screenshot boot capture now lives only in tools/qgate.sh, sh + qemu). tree count now: .py 0, .mjs 0; outer stack = sh + awk (POSIX) + xxd/od + qemu-system-i386 only.
- (5) Re-proven post-delete, all no-Python: tools/build.sh END-TO-END rc=0 (base.img, build/nan0s.img boot 512 kernel 5808 guest 58666 words, 2 images), tools/ngate_n16i.sh RESULT PASS (suite + both trap flavors + nest depth 0/1/2), tools/ngate_fuzz.sh PASS 60/60, tools/ngate_nfix.sh PASS words=003C9189, tools/mkproof.sh src/tests/key_test.nas PROOF PASS (27,923 steps), tools/qgate.sh PASS (COM1 boot banner). Census doc r29i re-executed note added. Older r29h text follows.
- r29h DELTA: (1) NEW tools/ngate_nfix.sh = nasm0 FIXPOINT gate, all in the guest, source read from a NaNFS disk over ATA PIO: gen0 (src/tests/nfix_test.nas built by nmk.awk) pristine-copies its own words, loads its own flattened source via ata_read28 + nanfs_read, assembles it with nasm0 (2 passes) and requires OUT == own words (payload AND class nibble): F1 PASS words=0x6D9 (gen1==gen0). Stage 2 copies the GUEST-EMITTED words into a window and runs them under raw-NaN n16i (mode 1, source pre-placed): that gen1 assembles the same source and checks itself: F2 PASS (gen2==gen1), then FIX PASS (3,964,xxx guest steps; ~181M native steps total, ~15 s). No Python, no awk oracle at run time. Negative test done: one corrupted source byte on the disk -> 'F1 FAIL first=00000106'. (2) Host seed only, one-time: tools/nflat.awk (flatten .include + strip comments) -> tools/nmkfs.awk/.sh (NaNFS disk image; shell printf %b with \\0ddd octal; dash printf misreads \\ddd with a leading 0 so do NOT use plain printf). (3) nanfs.nas EXTENDED, compatible: it only worked for <=64 blocks (bitmap = 1 word/block in block 1 overran data at 64+; a latent bug in nanfs_format with >64 blocks). Now the bitmap spans ceil(blocks/64) blocks from block 1, sb[3]=first data block (2 when blocks<=64, so old volumes/nanfs_test unchanged), nanfs_alloc starts at sb[3]. nanfs_test NANFS PASS, make test 866/0, ngate_n16i PASS re-run. NEXT for A0: port the proof gates (mkproof/proofnat) -> run nfix on every src/*.nas target by putting each source on the disk (gate now proves the loader+assembler on the biggest guest, 6.9K words incl. n16i); then n16i_fuzz via an LCG generator cart under n16i; then delete nanchk/nan16sim. The nmk.awk seed stays only until a guest 'nmkfs' (raw NaN) writes the disk. NOT run this round: gawk path, make seals. r29g DELTA: (1) tools/nmk.awk is now POSIX awk (the 4 gawk-only constructs, 3-arg match x2 and strtonum x2, replaced by hexv()/RSTART parsing): runs under mawk, no gawk needed; parity vs nanchk.py re-proven on all 72 standalone sources (71 byte-identical + src/net/defs.nas, a 0-word .equ file, empty on both). check and -v LABELS work. tools/nrun.sh now calls plain `awk`. (2) NEW tools/ngate_n16i.sh = the differential gate on nan_cli, no Python: suite native 73982 steps vs under raw-NaN n16i 3343783 steps MATCH (2640 B out), gate trap '!G2141' and bad-op '!O2140' MATCH, nest depth 0/1/2 identical, RESULT PASS. DELETED tools/n16i_check.py (17 .py files left in tools/; the r29f note below said 20, the tree count was 18 before this deletion). NOT ported: n16i_fuzz.py (300 random programs; needs a program generator, plan: raw-NaN LCG generator cart under n16i). Nothing else was re-run this round (no make test/seals). Older r29f text follows: DONE THIS ROUND: (a) host tools proven: gawk is installable here (apt), so tools/nmk.awk now runs; it was byte-identical to nanchk.py on 72/72 standalone sources AFTER fixing a real bug (ev() dropped the '-' sign: `#HEAP_SIZE-2` assembled as +2; hit src/prog/nalloc_test.nas) and removing leftover stderr debug; `-v LABELS=file` dumps the label table. (b) aarch64/android/nan_cli (the C core, `make test` 866 checks) is STEP-IDENTICAL with nan16sim.py (same serial bytes, same step count) on selftest, nalloc_test (630085 steps), disasm_test, retro, nanfs, n16de, translate, nrun_test (15279), net_test, tick; far_test prints FKMN. New tools/nrun.sh = assemble + run on nan_cli (replaces runbig.py). (c) DELETED (replacement proven or output checked in): runbig, test_far, 22 generators/screenshot/reference tools (gen_* x12, textshot, fbshot, shot, t, guitest, bootcmp, babyref, mkbabydata, mkalloc, mktables -> src/tools/mktables.nas). (d) CORRECTION: the Android CI/Makefile never called nanchk.py (only make test/seals/asan, pure C); the earlier A0 claim was wrong. STILL PYTHON (20 files, all need nanchk/nan16sim): nanchk nan16sim mkimg1 mkbase mkboot mkproof proofnat n16i_check n16i_fuzz nasm1run nasm1check nasm1_tests sweep_seal mutate_nalloc test_nanvm1 difftest fuzz traptest, plus inline python in aarch64/android/tools/gdiff.sh, tools/nasm1check.sh, x86/tools/native_check.sh and perl in tools/hex2bin.sh, build_round01.sh, x86/tools/build.sh. PORT PLAN (each = sh+gawk+nan_cli, then delete the .py): mkproof/proofnat -> a gawk script emitting a `.nan` with `.org` sections (nan_cli loads .org, 4M words) for harness+minified source+EXP, run on nan_cli, expect PASS; n16i_check/fuzz -> same with patched mode words via -v LABELS; nasm1run -> source at word 0x20000 via .org, serial = 'Y\n'+bytes, nasm1check compares to x86/native/nan16_x86.nan; sweep_seal -> flip image bytes with xxd then nan_cli key 1; mutate_nalloc -> sed + nrun.sh; test_nanvm1/difftest/fuzz/traptest -> covered by test_core.c + aarch64/android/tools/fuzz.sh (C core vs real kan16.xa kernel on qemu-system-i386, now installable); then delete nanchk/nan16sim/mkimg1/mkbase/mkboot last. IMAGES: a fresh gawk rebuild (mkimg.awk from .nas via nmk) differs from the checked-in nan0s.img ONLY in TOC entry 8 and the gui payload (expected: A2 edit; the checked-in image was patched, not rebuilt). x86/tools/mkall.sh should emit src/nan/*.nan from .nas first (src/nan/gui_cart.nan, nanfs_test, nbuild, nbuild_selfhost are STALE vs their .nas). Not yet rebuilt/shipped: do it with `make seals` as gate.
- [x] A1. DONE (1 Nov 2026). ROOT CAUSE was not stale seals: the cartridge store (words 6400..25066) overlapped the run SLOT (word 8192..~15300). Running ANY exhibit copied it over SLOT and wiped the carts stored under it, so the next load of 2-6 failed its seal (repro: keys `1,ESC,2`). FIX: store moved to word 40000.. (tools/carts.txt first line, mkimg.awk/mkimg1.py default top); both nan0s.img copies (x86/build, android assets) relocated with seals/class bits unchanged; fresh-boot screens of all 9 exhibits are byte/pixel identical to before. GATE: `make seals` (64 ordered pairs of exhibits 1-8, no SEAL MISMATCH) runs in CI core-tests. LEFT: the shell's 'Store: 3,072..14,516 words' plaque text in src/museum/shell.nas is stale (needs a museum.nan rebuild with gawk, not available in this sandbox); rebuild x86 image from carts.txt with gawk on a PC/Termux (`pkg install gawk`) to confirm mkimg.awk gives the same layout.
- [x] A2. DONE (1 Nov 2026). cart_entry's boot block in src/exhibits/gui_cart.nas replaced four `gui_open_at` calls (monitor, lattice, hex, terminal) with a single `MOVI r1,0 / CALL @gui_open_new`, so the desktop boots with ONE terminal window. Everything else was already reachable from the terminal's single-letter commands (l=lattice, m=monitor, x=hex, s=settings, n=nannet, u=utils, w=window count, t=new term; s_help lists them) - no new launcher code was needed for this item (that's A4). VERIFIED (not just assembled): src/tests/a2_boot_test.nas hosts the real gui_cart.nas as GUEST code under src/tools/n16i.nas (GB=0, mask=0x7FFFF to cover WT/ZO/STK at 0x58000-0x59000 and PCIT at 0x50300) - this is the raw-NaN interpreter actually executing the interpretation, nan16sim.py is only the outer box running n16i.nas's own words (see A0). Result: wm_zn=1 (exactly one window), that window's W_KIND=0 (terminal), W_ALIVE=1. Guest executed 1650 real instructions (n16i itself took 145552 steps, 0.58s) - this check stays before the first full-window paint so it does not hit the known-slow per-pixel wm_rect fill. gui_cart.nas payload now 15261 words (was 15350 before A2's edit removed the 3 extra gui_open_at call sites plus the earlier NaNNet NIC-detector addition included separately). r29j UPDATE: a2_boot_test.nas now SELF-JUDGES (after the window-state stores it checks wm_zn==1, W_KIND==0, W_ALIVE==1 IN-GUEST and prints `A2 PASS`/`A2 FAIL` on serial; `sh tools/nrun.sh src/tests/a2_boot_test.nas` -> A2 PASS, 146730 steps) and runs in CI's sh+awk gates. Still not visually re-checked on the phone (needs a device run); the APK asset image is byte-identical to build/nan0s.img.
- [x] A4b. DONE (r29j). STORAGE / nmkfs WIRED (Android FS + x86 virtual storage). (1) HOST: tools/nmkfs.sh + nmkfs.awk (the r29h NaNFS seed) now runs as part of tools/build.sh and x86/tools/build.sh - every build emits build/disk.nanfs (96 sectors, seed content src/tests/nfix_test.nas) and copies it into aarch64/android/app/src/main/assets/disk.nanfs and x86/build/disk.nanfs; aarch64/android Makefile has a `volume` target too. The format is a raw ATA PIO LBA28 volume (32-bit words as two LE u16, block 0 superblock) - exactly what ata_read28/ata_write28 in the guest and nan_attach_disk_fd/nan_attach_disk_mem in the C core already speak. (2) ANDROID: the APK ships assets/disk.nanfs; MainActivity seeds filesDir/disk.nanfs once, opens it RDWR and attaches the borrowed fd (nan_attach_disk_fd) so guest writes persist in app storage. The SAF "Disk" button still opens ANY volume from Android storage (that is the AndroidFS interface), Reset re-seeds a pristine volume from assets, and PFD lifetime is now Java-owned (the C core never closes fds; the old detachFd() path leaked one per attach). (3) X86: tools/qgate.sh and x86/tools/qgate.sh accept an optional DISK=<volume> and attach it as a virtual IDE drive (qemu -drive if=ide); boot gates still PASS with the volume attached. (4) HDD/SSD READINESS: the volume is already the real-hardware layout; `dd` it onto the primary master and the guest reads it with the same ATA PIO driver. LEFT: booting FROM a real HDD/SSD still needs an extended-read (int13h AH=42 / LBA) boot sector - boot0.s currently loads by floppy CHS (BIOS geometry), so HDD boot is a follow-up, data access is ready. PROVEN: the SHIPPED asset volume through the guest path (nan_cli --img nfix --disk assets/disk.nanfs -> F1 PASS / F2 PASS / FIX PASS, 180.8M steps) and qgate PASS both roots with DISK attached.
- [x] A5. DONE (r29m, 1 Nov 2026). GUI IS THE BOOT TARGET, MENU REORDERED, ABOUT-DEV REWRITTEN, SIERPINSKI UNIFIED. (1) Boot: the shell now cold-boots straight into the GUI - the museum TOC gained a HIDDEN 9th entry (index 8, id 0 = list terminator, title @sh_str9) and shell_entry jumps to sh_run on it before ever drawing the menu; the GUI cart's A2 entry opens ONE terminal window (verified on the real image via nan_cli --peek: wm_zn=1, W_ALIVE=1, W_KIND=0). ESC/q in the GUI closes the terminal -> g_exit -> museum menu. NEW tools/ngate_boot.sh gates this on build/nan0s.img (nan_cli new option: comma-separated ADDR[:LEN] word dumps); added to CI. IMPORTANT: the APK asset had been STALE - tools/build.sh did not copy nan0s.img into assets, so the multi-window GUI and old TOC were still shipping; build.sh now refreshes assets/nan0s.img (all three image copies share sha256 60954e9a...). gui_cart.nan was stale vs its .nas (the A2 edit never re-emitted) - regenerated. (2) Menu: GUI removed as exhibit #9; order is now 1 Baby, 2 Boole, 3 Sierpinski, 4 Trust, 5 Patriot, 6 Paradox, 7 About NaN/0S (second to last), 8 About Shemshallah (last); shell TOC ids/years/halls/titles/badges and tools/carts.txt reordered in lockstep (builder patches entry k from carts line k; GUI cart stays the last carts line). Footer 9->8 exhibits. make seals updated: 5x ESC wake prefix (image boots to GUI; keys are slice-spaced) then a/ESC/b -> 64 pairs OK. (3) About Shemshallah: page text replaced with the owner's exact text ONLY (bigger-story paragraph, About me, Contact me; nothing added), wrapped to the cart's line grid, NLINES 34->16; rendered from the image verbatim. (4) Sierpinski consolidated with the HTML reference (Download/NaN Lattice): museum cart now uses the same palette (bright #42F08B / field #10311C = palette 16/17), cyclic rule 90, time-flows-up history and dynamic geometry (fb_w/fb_h; stage height = h - 72; buffers moved to words 200000/210000 so width is not capped at 320); panel says I LOVE TRIANGLES! and the old white-on-black text is gone. PPM proof from the running image: 40641 field px, 319 bright px (160 rule-90 rows), black panel. The GUI window lattice (lat_*) already used this palette/pattern; both now match the HTML. (5) B3/B4 perf: NanView caches the content bitmap and rebuilds only when the guest drew (dirty changed), mode/view size changed or integerScale flipped; DURING a pinch the cached bitmap is transform-only (no text rasterisation, no VM snapshot) -> pinch zoom no longer stutters. (6) Python re-check: 0 .py files in the tree; only historical "retired python" comments remain.
- [x] A6. DONE (r29n, 1 Nov 2026). PERMANENT GUI BOOT + BUILDER-OWNED SLOTS (replaces the r29m hidden-TOC path). (1) tools/carts.txt is now the ONLY file needed to change slot numbers, list order or titles: lines are `SLOT:FILE:YEAR:HALL:BADGE:TITLE` (SLOT = menu key 1..9, unique; title may contain ':' and is the line tail) and a separate `boot:FILE` line declares the SYSTEM cart started on cold boot. tools/mkimg.awk builds the whole museum TOC from this file (entry k: slot/year/hall/title_ptr/badge/start/len/seals), writes each title into guest RAM at word 6000+16*k (4 chars/word LE, NUL padded), writes the id-0 terminator, and patches a dedicated 16-word BOOT record at word 4768 - so the GUI is NOT an exhibit slot and slot 9 is FREE for TempleOS. A bare museum.nan (no builder) now boots to an empty menu instead of stale entries; the cold path checks boot_rec[0] and falls through to the menu when absent. (2) shell.nas keeps only menu chrome + badge strings; the eight hardcoded TOC entries and title strings are gone. Switchability PROVEN: moving the two About lines (keeping their 7/8 keys) produced `[8] About Shemshallah` then `[7] About NaN/0S`, and moving them back restored 7/8 - keys travel with content, list order follows file order, no assembly edits. (3) Rebuilt image: menu 1..8 identical wording; boot record start=51386 len=7069 seals DC52F918/843469E0/2FB41998; ngate_boot PASS; seals 64 pairs OK. Sub-categorization later = the hall field (already in the TOC) plus carts.txt grouping.
- [ ] A7. NAN C TOOLCHAIN (ncc) - STARTED r29o, M0 DONE. Goal: a C implementation written ENTIRELY in raw NaN16 (assembled by the in-guest nasm0 once self-hosted; host nmk.awk remains only a seed), operable from the guest CLI, faithful to C semantics, eventually complete enough to build real programs / the slot-9 TempleOS project. Architecture (staged so every milestone is real and testable): (a) INPUT: C sources live on the NaNFS ATA volume (4 chars/word, NUL terminated; nanfs_read already proven); the compiler reads the disk directly. (b) LEXER: token stream on packed text. (c) PARSER: recursive descent, C precedence/associativity, emitting a compact STACK-MACHINE IR with a symbol table and a real call-frame layout. (d) EXECUTION: M1-M4 interpret the IR (the user explicitly allows an interpreter); M5 adds a NaN16 native backend through nasm0 so `cc file.c` can emit bootable carts. Same frontend feeds both - no forked semantics. (e) RUNTIME: tiny libc (putc/puts/print_int, later malloc in guest words) as .nas; diagnostics (line:col) on serial and screen. (f) CLI: the GUI terminal grows a real line editor + command dispatch (`cc FILE`, `as FILE`, `run FILE`, `ls`). MEMORY: buffers above the store (words >= 1,000,000). MILESTONES, each gated: M0 lexer; M1 expressions + variables + assignment + print builtins; M2 control flow + functions/params/recursion; M3 pointers, arrays, char/string literals, sizeof, casts, enums/typedefs; M4 diagnostics + #define/#include-lite + multi-file; M5 native codegen via nasm0 + CLI plumbing; M6 self-host. M0 DONE (r29o): src/tests/ncc_lex_test.nas is a self-contained raw-NaN16 C lexer (org 0) that streams an embedded C translation unit and prints "K VVVVVVVV LL @LLLL" per token; K = 01 EOF, 02 INT, 03 IDENT, 04 STRING, 05 CHAR, 06 PUNCT, 07 ERR, 08 KEYWORD; V = INT value / FNV-1a/32 of token bytes / keyword id; exact rules: // and /* */ comments, decimal/octal/hex, identifier charset, C89 keyword table by hash (32 ids documented in the .nas), escapes kept raw, LONGEST-MATCH punctuators (<<= >>= << >> <= >= == != && || ++ -- -> += -= *= /= %= &= |= ^= + single set), tracked corners documented (bad octal 0[89], newline-in-literal -> ERR). Golden: src/tests/ncc_lex.expected (98 tokens) from an independent reference model; gate tools/ncc_lex.sh = PASS exact, in CI. Real bugs found+fixed en route: NaN16 CALL clobbers r15 so any function that CALLs must save/restore the link (puthexn had RET re-enter its own loop); hex/octal marker peek offset after consuming the leading 0; puthex2/4 must shift the value so digits start at bit 31; nmk cmtless is now quote-aware so .str bodies may contain ';' (C source) - existing emits re-verified byte-identical. NEXT: M1 expression parser/evaluator (C precedence), variables, assignment, builtins putc/print_int, gated by its own exact-output test; then M2.
- [ ] A3. TWO different Sierpinskis (museum #3 'Rule 90' text plaque + live fractal, and the Sierpinski window inside the GUI; also tools/gen_sierpinski_cart.py vs gen_sierpinski_pixel_cart.py). Keep ONE implementation. The desired look is the user's HTML file (user said 'like this html file'; the file was NOT attached in this chat, ask for it again before changing the visuals). Both the museum entry and the GUI window must run the same cart. r29m UPDATE: the HTML reference was found (Download/NaN Lattice) and the MUSEUM cart now uses its exact palette/pattern (green #42F08B on #10311C, cyclic rule 90, time-flows-up, I LOVE TRIANGLES! panel); the GUI window's lat_* engine already matched. They are still two code paths (museum: full-screen 1px/cell low-RAM buffers; GUI: VRAM ring + window geometry) - full code-sharing remains open, visuals now agree.
- [ ] A4. CARTRIDGES must be loadable from the GUI, intuitively. Add a launcher (terminal command `run <n>` / `ls`, plus a clickable cartridge list or menu) that loads any TOC entry through the same seal check, in a window. The text-mode museum menu can stay as the boot screen of the plain museum image, but the GUI is the primary way to open carts.
- [ ] B1. Baby wall time is wrong: the screen says 38 s for 3,407,871 steps, the real run takes a few seconds. The Android loop sets TICK as ms since the thread started (NanLoop.kt: System.nanoTime()-t0), the guest subtracts a start value. Check in src/exhibits/baby.nas: (a) start TICK is read once at run start and not at boot, (b) the end-minus-start is divided to seconds correctly (ms/1000), (c) TICK is not frozen while the VM naps (WAIT_KEY nap 250 ms, VSYNC nap 16 ms, TIME_WAIT nap 1 ms add real time the guest sees). Note the per-step redraw of the Williams tube may be slow on the phone: if the true run really takes 38 s, speed up (draw every N steps) and say so. Verify with `nan_cli` that the printed seconds are the real elapsed time within +-1 s.
- [x] B2. DONE (r29j, 1 Nov 2026). PORTRAIT TEXT FIXED. NanView no longer stretches the 80x25 grid per axis (`cw = width/80`, `ch = height/25`): the text now renders into an aspect-locked content bitmap with VGA 8:16 cells (CELL_ASPECT 0.5, uniform stage = min(width/(80*0.5), height/25)) and is centered with black letterboxing. consequence: letters keep the same width/height ratio in portrait, landscape and with the IME open; the old `textScaleX` squeeze hack now only nudges glyphs inside correctly-proportioned cells. Same path is the base for pinch zoom (B4).
- [x] B3. DONE (r29j). GUI scaling: both render paths (text and VBE graphics) now compute their fit stage every frame from the CURRENT view size - min-scale over both axes, pixel aspect preserved, integer snap only when the "Scale" toggle is on (fractional smooth fit otherwise), centered via black letterboxes. Rotation and soft-keyboard resize need no callbacks: the next onDraw sees the new dimensions.
- [x] B4. DONE (r29j). PINCH ZOOM + PAN in NanView for all modes: ScaleGestureDetector zooms 1x..8x focal-anchored (the point between the fingers stays put), one-finger drag pans when zoomed with the content clamped to the view, double-tap or the new "Fit" button resets to whole-screen. "Change the resolution on the fly" = zoom over the current fit; the "Scale" button still toggles integer-pixel snapping. Text and graphics share one bitmap+transform pipeline, so zoom quality is uniform. LEFT (out of this round): taps cannot yet reach the guest as pointer events - the C core has NO mouse device/API (keyboard-only guest GUI); a click-to-guest protocol would need a guest-port feature (A4 territory), so touch today only focuses the view and drives zoom/pan.
- [ ] C1. Docs: update README.md / aarch64/android/docs when the fixes land; keep the single TODO (no new guide files).
- [x] C2. DONE (r29k, 1 Nov 2026). V86 LIVE DEMO ON GITHUB PAGES. `docs/` is now the Pages site (classic serve-from-branch: Settings -> Pages -> Deploy from a branch: main / docs; docs/.nojekyll keeps files verbatim): docs/index.html is a self-hosted v86 page that fetches the real guest floppy `docs/nan0s.img` (byte-identical copy of build/nan0s.img, refreshed by tools/build.sh; the page also falls back to ../build/nan0s.img when serving the repo root locally) and boots it in WebAssembly. v86 is pinned to npm 0.5.473 via jsDelivr (libv86.js + v86.wasm, CORS verified *) and the seabios/vgabios images come from copy/v86 on jsDelivr gh (the npm package ships no BIOS). The page has the 80x25 text layer + canvas graphics, COM1 serial panel (serial0-output-byte), Restart, full screen, and a load/error status line; page JS syntax-checked with node --check (v26) and the UMD global window.V86 confirmed in the pinned bundle. README's "sighting" section: iframe of the live page FIRST, then the clickable screenshot fallback with the caption "Click the screenshot to boot LIVE in your browser!" (GitHub strips iframes from READMEs, so github.com shows the still; renderers that allow frames run the machine inline). r29k3: BOOT PROVEN HEADLESSLY with the exact pinned artifacts (v86 0.5.473 libv86.js + v86.wasm, copy/v86 seabios/vgabios, build/nan0s.img): node harness stubs a DOM and wasm_fn; emulator-ready 169-191 ms and guest serial = "NaN/0S R26J READY MENU=S\r\n" (26 bytes, same banner qgate greps) = HEADLESS BOOT PASS. So the page's boot path is real, not just plausible; the earlier live failure was the V86-name shadowing only. Links carry ?live=1 to dodge the Pages HTML cache after the fix. r29k2 FIXES after the first live click: (a) the page's own `var V86` CDN constant SHADOWED the global V86 class inside the IIFE, so `new V86(...)` threw "V86 is not a constructor" - renamed to V86_CDN/BIOS_CDN and split the error paths (image fetch vs emulator start) so you only get the "serve the repo root" hint for 404 image paths; (b) README/TODO URLs pointed at /nan0s/ but Pages serves /NaN0S/ (404) - corrected. LEFT: enabling Pages is a one-time repo setting (cannot be set from the tree), and the page needs one real-browser run after the first deploy (no browser in this sandbox; the headless run covers boot + serial, not canvas rendering). A screenshot png remains in assets/ as the README fallback poster. r29k4 (touch input): the page now has an on-screen keypad (Esc, 0-9, Tab, Backspace, Enter, Space, E0-prefixed arrows) sending make+break PS/2 scancodes via keyboard_send_scancodes, and a text bar that raises the phone IME and forwards typed text via keyboard_send_text while the emulator's own document-level capture is disabled on focus (Backspace/Enter/Esc/Tab forwarded as scancodes; no double input). Controls enable at emulator-ready. Headless harness re-run: boot banner + 'key api: OK' (scancodes, text, capture toggle all callable). README: the owner rewrote it (commit 0b90d35) - clickable screenshot + caption; not touched by this round.
Order of work: A1 (gate first) -> A2 -> A3 -> A4 -> B2 -> B3 -> B4 -> B1.
After each fix: `make test` in aarch64/android, `sh tools/...` gates, push, check the green APK run on the Actions tab, then test on the phone.

# >>> r29 NOTE v2 (31 Oct 2026): ALL THREE SCAFFOLD LEGS NOW PROVEN IN-MODEL: n16i (sim) + nasm0 (proofs) + nrun_test (runner); W0 crc32 hang root-caused: DUPLICATE LABEL cmk_r; fixed, nasm0 proof net = PASS diff=0, runbig-net rerun in flight <<<
- W0 ROOT CAUSE (closed): src/net/crc32.nas had `cmk_r:` TWICE: line ~48 = rounds-loop re-entry, line ~71 = the .word 0 counter slot. nanchk keeps LAST definition (mktab's JMP @cmk_r -> the .word data word at 347 -> crawled into crc32_update bytes -> the pc-352/356/360 hang); guest nasm0 keeps FIRST (the diff=5 at 0x147 was this too). FIXED by renaming the counter slot to `cmk_cnt` (refs in mktab updated; loop label cmk_r kept, single definition). Emitted code now: counter ST/LD -> 347, loop JMP -> 328, consistent for both assemblers.
- VERIFIED THIS ROUND (in-model, nan16sim as outer box only):
  1. `python3 tools/n16i_check.py` -> suite 3/3 MATCH (native 73982 vs interp steps identical out; gate trap '!G2141'; bad-op '!O2140') + n16i_nest depth 0/1/2 identical + `tools/n16i_fuzz.py` 300 programs 0 mismatches. NOTE: /tmp is read-only here; fuzz was run from /data/data/com.termux/files/usr/tmp/opencode (patched copy).
  2. Fixed stale pre-LA immediates in src/tests/n16i_test.nas (MOVI>0xFFFF): r1 0x12345678 via LA, r3 0xDEADBEEF via LA, MUL vectors 100000/70000 via LA - same two-word footprint/semantics.
  3. `tools/mkproof.py src/tests/key_test.nas --run` -> PASS diff=0 (guest nasm0 == nanchk words).
  4. `tools/mkproof.py src/tests/net_test.nas --run --steps 4e9 --big` -> AFTER the cmk fix: words=1965 labels=0xE0 err=0 mirror=0 diff=0 PASS (logs/proof_net_v29d.txt). BEFORE the fix it was diff=5 first=0x147 (logs/proof_net_w0_v29.txt) - both assemblers "disagreeing" was the ambig label.
  5. NEW LEG: src/tests/nrun_test.nas (1373 words) = the raw-NaN "runbig": driver includes n16i.nas + nasm0.nas; copies a .str-packed mini source to the SRC area, runs guest nasm0 BOTH passes, then CALLs @n16i_run over the emitted words at OUTBS (GB=OUTBS, mask 65535); guest prints HI; driver asserts steps>=8 AND guest marker word 0x1234 from OUTBS+32 (n16i clobbers r2 per ABI - reload GB before reading!), prints RUN PASS. Gate: `python3 tools/runbig.py src/tests/nrun_test.nas --isa1` -> "HI / RUN PASS", steps 15279, no trap (logs/nrun_test_r29.txt). V_* slots 6272-6297 must stay where nasm0.nas .equ's them; pick SRC/OUT/LAB/STACK bases freely (runtime driven via V_SRCB/V_OUTB/V_LABB only).
- PENDING: runbig net_test rerun after the cmk fix (logs/net_test_v29c.txt, in flight - the old file hung at boot; new one runs the full mktab + suite). nrun_test marker uses guest pc-relative ST - key_test-style marker set BUT no negative-mark traps (a !O in the guest would still be caught by missing marker).
- LEG SCOREBOARD (scaffold -> raw NaN): nan16sim.py -> src/tools/n16i.nas VERIFIED. nanchk.py -> src/prog/nasm0.nas VERIFIED on key_test + net_test (diff=0 both). runbig.py -> guest driver CALLing @n16i_run VERIFIED (nrun_test PASS; n16i_nest pattern for .org'd guests proven earlier). Hypervisors/QEMU/v86 not yet in scope this round.
- NET W0 next: after the rerun lands green, wire the NET PASS gate into the nbuild/selfhost chain; the net files are the first things to be ASSEMBLED-AND-RUN ENTIRELY IN-GUEST (nasm0->n16i->modules), which IS what proved the toolchain itself.
- R29 mandate (user): replace nanchk.py + nan16sim.py + runbig.py with raw NaN16 code. Plan + scoreboard: spec/TOOL01_PLAN.md.

# >>> USER NETWORK SPEC (r29) - VERBATIM from /storage/emulated/0/Download/network_plan.txt (491 lines; user file name was "network_specs.txt", this is the matching file on disk) <<<
NaN/0S Modern networking and historical networking museum implementations. Everything is to be done in custom 4 type x4 16 boolean double endian NaN 0x raw code and everythjng is to be built from scratch. all of this needs to be UNIVERSAL so aarch64/x86/riscv can all run it. Be meticulously thorough and add this entire todo INTO the TODO in the zip. Get as much done as you can and adjust whatever necessary to adjust to get the code working with the system.

## 1. WORD

uint64_t. Tagged iff (w >> 48) >= 0xFFF8. Else binary64.
Canonical NaN 0xFFF8000000000000; every arithmetic NaN rewrites to it.

 0xFFFA T_INT   48-bit two's complement
 0xFFFB T_PTR   48-bit, 8-aligned
 0xFFFC T_RAW   48-bit; [47:40]=len 0..6, [39:0]=bytes
 0xFFFD T_SYM   48-bit interned id
 0xFFF8 T_NIL   payload 0
 0xFFF9 T_BOOL  0 or 1
 0xFFFE T_FRAME
 0xFFFF T_ESC   [47:40]=subtype

## 2. OPCODES

Cells are u16. `[op:8][arity:8]` then arity u16. Arity mismatch is
-EPROTO. Jumps are i16 relative to next cell.

 00 NOP 0      01 PUSH_K 1   02 PUSH_I 1   03 PUSH_R 1
 04 DUP 0      05 DROP 0     06 SWAP 0     07 OVER 0    08 ROT 0
 10 ADD 0      11 SUB 0      12 MUL 0      13 DIV 0     14 MOD 0
 15 NEG 0      16 AND 0      17 OR 0       18 XOR 0     19 NOT 0
 1A SHL 0      1B SHR 0      1C ROL 0      1D ROR 0
 1E BSWAP 1    20 CMP 0      21 TEST 0     22 COERCE 1  23 BOX 1
 24 UNBOX 1    30 LDL 1      31 STL 1      32 LDG 1     33 STG 1
 34 LDP 1      35 STP 1      40 JMP 1      41 JZ 1      42 JNZ 1
 43 CALL 1     44 RET 0      45 CALLH 1    46 ENTER 1   47 LEAVE 0
 50 ARG 1      51 RETV 0     52 SWITCH 1   60 SYS 1     61 PANIC 1
 62 TRAP 1     63 BRK 0      70 VARARG 1   7F HALT 0

## 3. ENDIAN AND HEX

Three markers on every field: [BE] [LE] [NE] neutral. [BE]/[LE] are
fixed by the RFC and win over host order. Only [HOST] fields mirror
the image flag. Byte-swapping a value word swaps the whole u64, never
field-wise.

Hex: lowercase, 2 digits/byte, one 0x per run, wrap 32 bytes, offset
comment `/* +0x%04X */`. Doubles as 0x bit pattern with decimal in a
comment. Width suffix on every literal.

## 4. DRIVER ABI

```c
struct dev_caps { uint16_t max_frame, overhead, mtu, rel, egress, rsv; };
struct dev_ops {
  uint16_t did, flags;
  int32_t (*open)(struct dev*, const void*, uint16_t);
  int32_t (*close)(struct dev*);
  int32_t (*read)(struct dev*, void*, uint16_t);
  int32_t (*write)(struct dev*, const void*, uint16_t);
  int32_t (*ioctl)(struct dev*, uint16_t, void*, uint16_t);
  int32_t (*poll)(struct dev*, uint16_t, uint16_t);
  const struct dev_caps *caps;
};
```
One `dev_<mn>` and one `caps_<mn>` per file. Flat 0x00-terminated
registry. Config structs in-file, never strings.

```c
struct car_ops {
  uint16_t cid, flags, slot_bytes;
  int32_t (*encode)(struct car*, const void*, uint16_t, void*, uint16_t);
  int32_t (*decode)(struct car*, const void*, uint16_t, void*, uint16_t);
};
```
Encoders are total. `-ENOSPC` when the destination is short, with the
required length in the low half of the return.

## 5. ERRORS

0 OK, -1 EAGAIN, -2 EIO, -3 EINVAL, -4 ENOTSUP, -5 ETIMEDOUT,
-6 ECLOSED, -7 EFAULT, -8 ENOSPC, -9 EPERM, -10 EPROTO,
-11 EBADENDIAN, -12 EBADTAG, -13 EOVERFLOW, -14 EEMPTY, -15 ECRC.

---

# FIELD INVENTORY

Format per row:
`DID MNEMONIC  off/width [order]  preserve/mutate note`
then `enc:` `dec:` `vec:`

## 0x01 — L2

0x0101 ETH_PAD  trailer 0..46 bytes [NE]
  preserve: switches pad short frames; NIC strips. mutate: some bridges.
  enc: eth_pad_enc(uint8_t*,uint16_t,const uint8_t*,uint16_t) -> i32
  dec: eth_pad_dec(...)  vec: 0, 46, 47(ENOSPC)

0x0102 MAC_SRC  octets 6..11, low 46 bits [NE]
  requires locally-administered bit 0x02 set in octet 6.
  enc: mac_src_enc(...)  dec: mac_src_dec(...)  vec: 46-bit max, all-zero, all-ones

0x0103 VLAN_TCI  offset 14, u16 [BE], PCP [15:13] DEI [12] VID [11:0]
  cap 16 bits. preserve: 802.1Q path. mutate: VID may be rewritten by
  some switch ASICs on tagged uplinks.
  enc: vlan_enc(...)  dec: vlan_dec(...)  vec: PCP-only, VID-only, both

0x0104 QINQ_OUTER  outer TCI, TPID 0x88A8
  same layout as VLAN_TCI, outer wins when both present.
  vec: single tag, double tag, triple tag

0x0105 ARP_PAD  frame trailer after 28-byte ARP body, 0..18
  enc: arp_pad_enc(...)  dec: arp_pad_dec(...)  vec: 0, 18, 19

0x0106 LLDP_ORG  TLV type 127, len u8, OUI 3B, subtype u8, data
  [NE]  cap 507-len. OUI 0x00A0C9 subtype 0 reserved.
  enc: lldp_org_enc(...)  dec: lldp_org_dec(...)  vec: min, 507, truncated TLV

0x0107 STP_BPDU  bridge-id priority 2B + timer bytes
  enc: stp_enc(...)  dec: stp_dec(...)  vec: config BPDU, TCN, RSTP

0x0108 EAPOL_ID  EAP-Response/Identity, len u8 prefix
  enc: eapol_id_enc(...)  dec: eapol_id_dec(...)  vec: 1, 253, 254

0x0109 MPLS_LBL  4B per hop: label [31:12] TC [11:9] S [8] TTL [7:0]
  [BE]  cap 20 bits per hop, stack depth 3 default.
  enc: mpls_enc(...)  dec: mpls_dec(...)  vec: 1 hop, 3 hops, S=0 tail

## 0x02 — L3/L4

0x0201 IP4_TTL  offset 8, u8, cap 8. Encoder subtracts expected hops.
0x0202 IP4_ID  offset 4, u16 [BE], cap 16. DF clear.
0x0203 IP4_TOS  offset 1, u8, DSCP [7:2] cap 6, ECN [1:0]
0x0204 IP4_OPT  offset 20, len = (IHL*4)-20, 0..40, TLV type/len
0x0205 IP4_FRAG  offset 6, u16 [BE], offset [12:3] MF [13] DF [14]
0x0206 IP6_FLOW  offset 1, 20 bits, mask 0x000FFFFF after version
0x0207 IP6_EXT  next-header chain, hop-by-hop 0 / dest-opt 60
0x0208 IP6_IID  address octets 8..15, 64 bits
0x0209 ICMP_ECHO  after 8-byte header, 0..(MTU-28)
0x020A ICMP_QUOTE  quoted datagram tail after 8-byte ICMP header
0x020B TCP_ISN  seq field offset 4, u32, one shot per flow
0x020C TCP_OPT  options area, max 40, kind 1 NOP / 0 EOL padding
0x020D TCP_TS  kind 8 len 10, TSval u32 [BE], TSecr u32 [BE]
0x020E TCP_URG  urgent ptr u16 [BE] + URG flag 0x20
0x020F TCP_WIN  offset 14, u16 [BE], scaled by wscale
0x0210 TCP_PORT  sport/dport pair, u16 [BE] each
0x0211 UDP_PAD  bytes past the length field, 0..(MTU-8-len)
0x0213 GRE_KEY  offset 4, u32 [BE], requires K flag 0x2000
0x0214 IPIP_PROTO  IP protocol byte 9, selector alphabet
0x0215 WG_RESERVED  handshake type 1/2, reserved 3 bytes zero-on-send
0x0216 VXLAN_VNI  octets 4..6, 24 bits, VNI [23:0]
0x0217 GENEVE_OPT  opt TLV: class u16 [BE], type u8, len u8, value
0x0218 SRH_TLV  SRH optional TLV area, type u8 len u8
0x0219 GTP_TEID  u32 [BE], plus extension header chain

All 0x02 rows: enc/dec pair, vectors min/MTU/malformed.

## 0x03 — NAMING

0x0301 DNS_A  RDATA rdlength=4 [BE], 4 bytes. AAAA: 16 bytes.
0x0302 DNS_TXT  cap 255/string, 65535/RR
  slot: RR RDATA. rdlength u16 [BE], then N character-strings:
  `{ len:u8, data:len }`, len 1..255, N>=1, N*257<=rdlength.
  preserve: recursive resolvers relay RDATA verbatim.
  mutate: DNSSEC on/off changes nothing in RDATA.
  enc: dns_txt_enc(buf,cap,in,n) chunks at 255, returns total
  dec: dns_txt_dec() concatenates, -EPROTO on len 0
  vec: 255 exact, 256 -> 2 strings, 65535 -> 257 strings

0x0303 DNS_NULL  RDATA arbitrary, rdlength u16 [BE], 0..65535
  vec: 0, 1, 65535

0x0304 DNS_CNAME  RDATA is a domain name, labels 63 max, total 255
  encode as label chain, terminator 0x00. vec: 63-label, 255 total, 256(ENOSPC)

0x0305 DNS_NS  delegation: NS RRset at the zone apex pointing at own
  authoritative server. RDATA is a name, same limits as CNAME.

0x0306 DNS_MX  preference u16 [BE] then exchange name
0x0307 DNS_SRV  priority u16, weight u16, port u16, target name
0x0308 DNS_SOA  serial/refresh/retry/expire u32 [BE], minimum u32
0x0309 DNS_LOC  version u8, size/hprec/vprec u8, lat/lon/alt u32
0x030A DNS_CAA  flags u8, tag len u8, tag, value
0x030B DNS_SVCB  priority u16, target, then params { key:u16, len:u16, val }
0x030C DNS_EDNS  OPT RR, option { code:u16 [BE], len:u16 [BE], data }
  option 12 is padding. cap 65535 per option.
0x030D DNS_COOKIE  option 10, client 8B / server 8..32B
0x030E DNS_QTYPE  query QTYPE field, u16 [BE], alphabet of rare types
0x030F DNS_TTL  RR TTL u32 [BE], cap 32
0x0310 DNS_CASE  0x20: uppercase bit of each QNAME letter, 1 bit/char
  enc sets case from bit, dec reads case. vec: all-lower, all-upper, alternating
0x0311 DNS_LABEL  label-length alphabet, 1..63 per label
0x0312 DNS_AXFR  zone transfer stream, TCP 53, full RR dump
0x0313 DNS_DOH  RFC 8484: POST `application/dns-message`, or GET
  `?dns=` base64url. Body is a raw DNS message.
0x0314 DNS_DOT  RFC 7858: TCP 853, u16 [BE] length prefix per message
0x0315 DNS_DOQ  RFC 9250: QUIC stream, same u16 prefix
0x0316 MDNS  UDP 5353, DNS wire format, TXT slot
0x0317 LLMNR  UDP 5355, DNS wire format
0x0318 NBNS  UDP 137, name field, 16-byte encoded name
0x0319 SSDP  `M-SEARCH * HTTP/1.1` header block, `MAN: "ssdp:discover"`
0x031A WSD  SOAP envelope over UDP 3702
0x031B SLP  UDP 427, URL entry, attr list
0x031C DHCP_OPT43  option code 43, len u8, 0..255, sub-options
0x031D DHCP_OPT60  option 60, len u8, class-id string
0x031E DHCP_OPT77  option 77, user-class, len u8
0x031F DHCP_82  option 82, sub-options 1..9, circuit-id 1 / remote-id 2

## 0x04 — REMOTE ACCESS

0x0401 SSH_BANNER  `SSH-2.0-<sw>\r\n`, 255 max, no `-` in sw, sent
  before KEX. enc/dec trims CRLF.
0x0402 SSH_IGNORE  msg 2, `uint32 len, bytes`. Accepted at any point.
0x0403 SSH_DEBUG  msg 4, `boolean, uint32 len, bytes`
0x0404 SSH_CHAN  channel data on an idle channel, `uint32 len, bytes`
0x0405 SSH_DIRECT  `direct-tcpip` global request, 4 length-prefixed strings
0x0406 SMB_PIPE  `\pipe\<name>` UTF-16LE, WRITE/READ on the handle
0x0407 SMB_DIALECT  negotiate reserved field, u16 [LE]
0x0408 RDP_VCHAN  DVC `Create`/`Data` PDUs, channel name 8 chars ASCII
0x0409 RDP_DRDYNVC  DRDYNVC header, Cmd u8, Sp u8, ChanId u16 [LE]
0x040A VNC_CLIP  `ServerCutText`/`ClientCutText`, u32 [BE] len + text
0x040B VNC_NAME  ServerInit desktop name, u32 [BE] len + bytes
0x040C TELNET_OPT  IAC 0xFF, opt, SB..SE subnegotiation
0x040D NFS_HANDLE  file handle padding past fh_length
0x040E RPC_FRAG  record marking, u32 [BE], last-frag bit 0x80000000
0x040F LDAP_ATTR  OCTET STRING value, BER len
0x0410 LDAP_FILTER  filter assertion string, `(attr=value)`
0x0411 KRB_PADATA  PA-DATA type u16 [BE], padata-value OCTET STRING
0x0412 KRB_PRIV  KRB-PRIV enc-part, etype u16, cipher
0x0413 SNMP_OID  BER subidentifiers, arc 0..2^32-1, cap 128
0x0414 SNMP_SET  varbind value, INTEGER/OCTET STRING, in a SET PDU
0x0415 SNMP_CTX  v3 msgAuthoritativeEngineID / contextName
0x0416 SYSLOG_SD  `[id name="val"]`, escape `"` `\` `]` as `\"` `\\` `\]`
0x0417 RADIUS_AVP  type u8, len u8, value, 253 max. Type 24 State, 33 Proxy-State
0x0418 IPMI  RMCP+ session payload, 16 bytes per packet, seq u32
0x0419 REDFISH  HTTPS POST body, JSON resource
0x041A TR069  SOAP `SetParameterValues` value
0x041B NETCONF  `<edit-config>` XML
0x041C GNMI  `SetRequest` JSON
0x041D OPENFLOW  `packet-out` data field
0x041E ONVIF  SOAP body, `GetSnapshotUri`
0x041F RTSP  interleaved frame `$` 0x24, channel u8, len u16 [BE]

## 0x05 — WEB

0x0501 HTTP_HDR  `Name: value\r\n`, name from cfg, value 0..8192
  RFC 9110 §5. Field names with `X-` are non-standard and preserved.
0x0502 HTTP_COOKIE  `Cookie: n=v; n2=v2`, value 0..4096, RFC 6265
0x0503 HTTP_PATH  path segment between `/`, unreserved + pct-encoded
0x0504 HTTP_QUERY  query value after `=`, `&` separated, RFC 3986
0x0505 HTTP_FRAG  after `#`, never leaves the client
0x0506 HTTP_METHOD  token, alphabet of 9 standard + extension tokens
0x0507 HTTP_STATUS  3-digit code, `xyz` per-digit alphabet
0x0508 HTTP_CHUNKX  chunk-size `;ext=val` extension, RFC 9112 §7.1.1
0x0509 HTTP_TRAILER  trailer field after the last chunk
0x050A HTTP_ETAG  `ETag: "opaque"`, W/ prefix weak form
0x050B HTTP_RANGE  `Range: bytes=a-b`, a/b as digit alphabet
0x050C HTTP_103  `103 Early Hints` header block, pre-final
0x050D HTTP_ALTSVC  `Alt-Svc: h3=":443"`, RFC 7838
0x050E HTTP_CSPREP  `report-uri` POST body, JSON
0x050F HTTP_NEL  `NEL` report body, JSON, RFC 9458
0x0510 H2_SETTINGS  SETTINGS frame payload, 6-byte params
0x0511 H2_HPACK  dynamic table index selection, RFC 7541 §2.3
0x0512 H2_PING  8 opaque bytes, SETTINGS ACK not required
0x0513 H2_PAD   Pad Length byte + trailing zeros on any frame
0x0514 H3_CID  DCID/SCID, 0..20 bytes, RFC 9000 §5.1
0x0515 H3_TPARAM  transport param { id:varint, len:varint, val }, RFC 9000 §18
0x0516 H3_SPIN  short-header byte bit 0x20, 1 bit
0x0517 H3_DGRAM  DATAGRAM frame 0x30/0x31, len varint, data, RFC 9221
0x0518 WS_FRAME  payload after the 2..14 byte header, RFC 6455 §5.2
0x0519 WS_CLOSE  opcode 0x8, status u16 [BE], reason UTF-8
0x051A WS_PROTO  `Sec-WebSocket-Protocol: token`
0x051B SSE  `data: <utf8>\n\n`, RFC 8895
0x051C LONGPOLl  held GET, response body
0x051D SENDBEACON  POST body, fire-and-forget
0x051E SW_PUSH  Push API payload, AES128GCM, RFC 8291
0x051F GRAPHQL  field alias `alias:field`, `@directive(arg:1)`
0x0520 GRPC_META  `key: value\r\n` in the HEADERS frame, `-bin` suffix = base64
0x0521 GRPC_TRAILER  trailers-only response, `grpc-status-details-bin`
0x0522 JSON_FIELD  key order, duplicate key, unknown key, whitespace
0x0523 XML_NODE  `<!-- -->`, `<?pi?>`, namespace prefix, CDATA
0x0524 FORM_POST  `boundary=`, part header block, RFC 7578

## 0x06 — MAIL

0x0601 SMTP_HDR  `X-Name: value\r\n`, line 998 max, fold CRLF+WSP, RFC 5322 §2.2.3
0x0602 SMTP_RCVD  `Received: from a by b;` hop, appended at each MTA
0x0603 SMTP_MSGID  `<local@domain>` local part, dot-atom
0x0604 SMTP_REFS  `References:` / `In-Reply-To:` msg-id list
0x0605 SMTP_R2047  `=?utf-8?B?<b64>?=`, RFC 2047 §2
0x0606 SMTP_MIME  part body, base64, 76-col, CRLF
0x0607 IMAP_MAILBOX  modified UTF-7 name, literal `{n}` form, RFC 3501 §5.1.3
0x0608 IMAP_FLAG  custom keyword `\`-less atom, PERMANENTFLAGS
0x0609 IMAP_IDLE  `IDLE` + `+` continuation, no payload limit
0x060A IMAP_APPEND  `APPEND mbox {n}` literal, n bytes follow
0x060B POP3  `RETR` body, dot-stuffed `.` prefix
0x060C EWS_ITEM  `CreateItem` SOAP, extended property `distinguishedPropertySetId`
0x060D JMAP  `Email/set` body, RFC 8621
0x060E NNTP_GROUP  `news.group.name`, dot hierarchy
0x060F NNTP_HDR  `X-Name: value`, `Xref` chain
0x0610 FAX_T38  IFP packet: `type u8, data`, UDPTL redundancy
0x0611 DTMF  `INFO` body `Signal=`, RFC 4733 event codes 0..15

## 0x07 — CHAT

0x0701 IRC_CTCP  `\x01NAME args\x01`, RFC 2812
0x0702 IRC_TOPIC  `TOPIC #chan :text`, 390 max
0x0703 IRC_NICK  nick atom, `[a-zA-Z\[\]\\`_^{|}][-a-zA-Z0-9...]{0,8}`
0x0704 IRC_PART  `PART #chan :reason`
0x0705 XMPP_PRES  `<presence><status>text</status>`, XEP-0085
0x0706 XMPP_PUBSUB  `<publish node=><item id=><payload/>`, XEP-0060
0x0707 MATRIX_EVT  custom `m.` type, `content` object
0x0708 ACTIVITYPUB  custom activity type, `object` field
0x0709 ATPROTO_REC  custom lexicon `$type` record
0x070A NOSTR_EVT  `kind` u16, `tags` array, `content`
0x070B SLACK_EMOJI  custom emoji `:name:` alias
0x070C SLACK_HOOK  incoming webhook JSON `text` + `blocks`
0x070D DISCORD_HOOK  `content` + `embeds[].fields`
0x070E TEAMS_HOOK  MessageCard `sections[].facts`
0x070F TELEGRAM_BOT  `sendMessage.text`, markdown entities
0x0710 EMOJI_ENC  emoji codepoint alphabet, 0x1F300..0x1FAFF

## 0x08 — FILE

0x0801 FTP_LISTING  `LIST` output lines, name field, RFC 959 §4
0x0802 FTP_PORT  `PORT h1,h2,h3,h4,p1,p2`, `227 (h1,h2,h3,h4,p1,p2)`
0x0803 FTP_MDTM  `213 YYYYMMDDHHMMSS`
0x0804 TFTP_NAME  `filename\0mode\0`, 512 max
0x0805 TFTP_OPT  `blksize\0<n>\0`, 8..65464
0x0806 BTDHT  `put`/`get` on the mainline DHT, bencoded, BEP 5
0x0807 BTMAGNET  infohash 20 bytes, `xt=urn:btih:`
0x0808 BT_PEX  compact peer list, 6 bytes/peer, BEP 11
0x0809 IPFS_BLOCK  CIDv1 multibase + raw block, `/api/v0/block/put`
0x080A IPFS_PUBSUB  `/api/v0/pubsub/pub`, topic string
0x080B GIT_OBJECT  loose object zlib body, header `<type> <len>\0`
0x080C GIT_REF  `refs/heads/<name>`, `/` hierarchy
0x080D GIST  gist API `files` map, key = filename
0x080E S3_KEY  object key, `/`-delimited, 1024 max
0x080F S3_META  `x-amz-meta-<name>: value`, 2KB total
0x0810 S3_ERR  `<Error><Code>` body on 4xx
0x0811 PKG_MANIFEST  `package.json` field / `PKG-INFO` / `Cargo.toml` key
0x0812 OCI_LAYER  tar layer, `tar` PAX extended header
0x0813 OCI_LABEL  `org.opencontainers.image.*` label

## 0x09 — MEDIA

0x0901 SIP_HDR  `Via:` branch `z9hG4bK`, `Call-ID:`, `Contact:`
0x0902 SIP_SDP  `a=<name>:<value>`, RFC 4566
0x0903 SIP_MESSAGE  `MESSAGE` body, `Content-Type: text/plain`
0x0904 RTP_PAD  P bit 0x20 + trailing pad count byte
0x0905 RTP_EXT  profile 0xBEDE, 4-byte elements id[7:4]/len[3:0]
0x0906 RTCP_APP  subtype u8, name 4B ASCII, app data
0x0907 STUN_ATTR  type u16 [BE], len u16 [BE], value, pad to 4, RFC 8489
0x0908 TURN_CHAN  channel data `0x40|ch` u16, len u16, value
0x0909 ICE_CAND  `candidate:` line, ufrag, tcptype
0x090A WEBRTC_DC  SCTP DATA chunk, PPID 53/51
0x090B G711_LSB  low bit of each 8-bit PCM sample
0x090C SILENCE_MOD  comfort-noise gating pattern, RFC 3389
0x090D HLS_PLAYLIST  `#EXT-X-` tag line
0x090E DASH_MPD  MPD attribute, `EventStream`
0x090F WEBVTT  cue text, `<v Name>` tag
0x0910 SCTE35  splice_info_section base64 in `#EXT-X-SCTE35`
0x0911 MIDI_SYSEX  0xF0 body 0xF7, manufacturer ID first byte
0x0912 OSC_MSG  address pattern `/a/b`, type tag string
0x0913 ARTNET  `ArtDmx` universe u16 [LE], 512 channel values

## 0x0A — INDUSTRIAL

0x0A01 MQTT_TOPIC  UTF-8, u16 [BE] len prefix, `/` levels, `+` `#` wildcards, RFC 9594 §4.7
0x0A02 MQTT_RETAIN  PUBLISH retain bit 0x01, broker stores one per topic
0x0A03 MQTT_WILL  CONNECT will-payload, delivered on abnormal disconnect
0x0A04 MQTT5_PROP  property 0x26, u16 key len, u16 val len
0x0A05 COAP_OPT  delta/len nibble byte, ext delta 13/14, value, RFC 7252 §3.1
0x0A06 COAP_BLOCK  option 23, NUM/SZX/M
0x0A07 AMQP_PROP  `application-properties` map entry
0x0A08 MODBUS_REG  function 0x03 read / 0x10 write, u16 [BE], 125/123 limit
0x0A09 DNP3_OBJ  object header group/variation u8, qualifier u8
0x0A0A S7COMM  `Read Var`/`Write Var`, item spec 0x12
0x0A0B OPCUA_NODE  NodeId `ns=;s=` / `i=`, `MonitoredItem`
0x0A0C BACNET  `WriteProperty` value, object-instance u32
0x0A0D KNX  group address 2B [BE], APDU value
0x0A0E CAN_FRAME  ID 11 or 29 bits, DLC 0..8, payload 8
0x0A0F UDS_PID  service 0x22 DID, u16 [BE]
0x0A10 SOMEIP  service u16, method u16, [BE], message type 0x02

## 0x0B — RF

0x0B01 WIFI_SSID  IE 0, len u8, 0..32, hidden = len 0
0x0B02 WIFI_VSIE  IE 221, len u8, OUI 3B, data
0x0B03 WIFI_PROBE  PNL element, IE 0 in a probe request
0x0B04 WIFI_QOS  QoS control u16 [LE], TID [3:0]
0x0B05 WIFI_SEQ  sequence control 12 bits
0x0B06 BLE_ADV  AD struct len u8, type 0xFF, company u16 [LE], 0..27 data
0x0B07 BLE_GATT  characteristic value, ATT handle
0x0B08 BLE_UUID  128-bit UUID byte order per RFC 8100
0x0B09 ZIGBEE_ATTR  cluster attr id u16 [LE], ZCL data type u8
0x0B0A ZWAVE_CC  command class u8, encapsulated CC for S0/S2
0x0B0B LORA_PAYLOAD  PHYPayload, MHDR u8 + MACPayload
0x0B0C LORA_PORT  FPort u8, 1..223 app range
0x0B0D LORA_MAC  CID u8, MAC command block
0x0B0E NFC_NDEF  NDEF record, TNF u8, type len u8, payload len u32 [BE]
0x0B0F IR_CONSUMER  header + 16-bit pulse-distance pairs, NEC protocol
0x0B10 ADSB  Mode S ME field 56 bits, DF 17
0x0B11 AIS  NMEA `!AIVDM` payload, 6-bit ASCII armor

## 0x0C — LOCAL

0x0C01 UNIX_SOCK  `AF_UNIX` `SOCK_STREAM`, path cfg
0x0C02 NETLINK  `NETLINK_USERSOCK` 2, nlmsghdr + payload
0x0C03 TUN_TAP  `IFF_TUN|IFF_NO_PI`, raw IP in/out
0x0C04 BPF_SOCK  `SO_ATTACH_BPF`, classic filter return
0x0C05 PTY  master/slave pair, termios raw
0x0C06 SERIAL  baud/parity/stop in cfg, UART frame
0x0C07 HID_REPORT  report body, descriptor report count
0x0C08 USBIP  `USBIP_CMD_SUBMIT`, urb buffer
0x0C09 CLIPBOARD  host clipboard text/bytes
0x0C0A I2C_SPI  `i2c-dev` `I2C_RDWR`, `spidev` `SPI_IOC_MESSAGE`

## 0x0D — STORAGE

0x0D01 PCAP_FILE  `0xA1B2C3D4` header + records
0x0D02 PCAP_PAD  per-frame trailer past caplen
0x0D03 IPFIX_FIELD  template field specifier, enterprise bit
0x0D04 JSON_LOG  extra top-level key
0x0D05 ZIP_COMMENT  end-of-central-directory comment, 65535 max
0x0D06 PNG_CHUNK  `tEXt` chunk, keyword + 0x00 + text
0x0D07 EXIF_TAG  TIFF IFD entry, tag u16 [BE], type, count, value
0x0D08 PDF_META  XMP `dc:` property in the metadata stream
0x0D09 ADS_STREAM  `file:stream` NTFS alternate stream
0x0D0A XATTR  `user.*` namespace, `setxattr`

## 0x0E — CODECS

0x0E01 BASE32  RFC 4648 §6, alphabet A-Z2-7, `=` pad
0x0E02 BASE64URL  RFC 4648 §5, `-_`, no pad
0x0E03 BASE85  RFC 1924 alphabet, 4 bytes -> 5 chars
0x0E04 HEX_ASCII  lowercase hex, 2 chars/byte
0x0E05 QP  RFC 2045 §6.7, `=XX`, soft break `=\r\n`
0x0E06 ZLIB_STREAM  RFC 1950, deflate level cfg
0x0E07 LZ4_BLOCK  `LZ4_compress_default`, u32 [LE] length prefix
0x0E08 CRC32_FRAME  CRC-32/ISO-HDLC trailing, 4 bytes [BE]
0x0E09 CHUNK_SPLIT  split at N bytes with a len u8 prefix per piece
0x0E0A BIT_PACK  MSB-first bit writer, caller supplies width
0x0E0B XOR_CHAIN  key cfg, CBC-style chaining
0x0E0C ROT_N  N in cfg, modulo alphabet size
0x0E0D SYMBOL_MAP  caller-supplied 256-entry byte->symbol table
0x0E0E TIMING_PAD  inter-packet delay alphabet, N ms buckets in cfg
0x0E0F SIZE_PAD  packet-size bucket alphabet, pad to bucket
0x0E10 ORDER_PAD  permutation of K consecutive packets, K in cfg

## 0x0F — HOST

0x0F01 FD_BRIDGE  raw fd, `read`/`write` passthrough
0x0F02 FILE_BRIDGE  `open`/`pread`/`pwrite`
0x0F03 STDIO_BRIDGE  0/1
0x0F04 NULL_DEV  discard
0x0F05 LOOP_DEV  echo back
0x0F06 REPLAY_DEV  source from pcap, real-time or as-fast-as-possible
0x0F07 RECORD_DEV  sink to pcap

---

## 6. IMAGE

```
0x00 magic 0x4E42564D [NE]   0x04 ver u16 [LE] = 0x0001
0x06 flags u16: bit0 endian, bit1 cells16, bit2 debug
0x08 nsec u16   0x0A crc32 u32 (field zeroed during compute)
0x0E sectab: nsec * { u16 type, u16 off, u16 len }
```
Sections: 1 CODE 2 CONST 3 STRTAB 4 SYMTAB 5 RELOC 6 DRVREQ 7 DEBUG
8 SEAL. Loader order: magic, ver, crc, section bounds, reloc targets,
endian. Never partially loads.

## 7. VECTORS

Three per codec in `tst/vec_<mn>.c`:
`{name, in, inlen, out, outlen, expect}` — canonical, boundary
(0 / max / max+1), endian (both flags, identical logical value).
Runner prints per-vector pass/fail, returns nonzero on any failure.

## 8. AUDIT

Print `OK <item>` or fix:
  [] every row has a file, every opcode a case, every error reachable
  [] no decimal float literal, no banned word, no TODO, no ellipsis
  [] -Werror clean under `-Wconversion -Wsign-conversion -Wcast-align`
  [] image round-trips under both endian flags
  [] tag survives u64 byte swap
  [] canonical NaN at every arithmetic return
  [] 3 vectors per codec

#
```

-- 

- R29 mandate (user): replace nanchk.py + nan16sim.py + runbig.py with raw NaN16 code. Plan: spec/TOOL01_PLAN.md.


BASE: r28c tree + r28d changes merged (a64asm.nas, a64asm_forms files and a64_core_ref.hex included). `python3 tools/nasm1run.py src/native/kan16_a64.xa64 OUT.bin --nasm1 src/prog/a64asm.nas` assembles the extended 2,412-byte core byte-identical to tools/a64.awk (cmp 0 diff). a64_run.sh still uses a64.awk; switching it is next.
DONE (real qemu-system-aarch64 8.2.2, gawk 5.2.1):
- `sh tools/a64_run.sh /tmp/a64_test.nan` -> `NaN/0S core PASS` (r28 claim confirmed). Emit with `gawk -f tools/nmk.awk -v CMD=emit X.nas 2>/dev/null` (nmk.awk prints POSTASSIGN debug to stderr; harmless, remove that line).
- kan16_a64.xa64 now 2,412 bytes: VPOKE/VPEEK = 80x25 u16 cell shadow at 0x43E00000 (x27); changed cells mirrored to the PL011 as ANSI (ESC[r;cH ESC[0[;1];3f;4bm char, VGA->ANSI colour swap, non-printables -> space/'#'). DISPQ = 0x00031950. DISPSET (r&255, not 0x13, <0x10000) clears + ESC[2J. KEY blocking / KEYQ non-blocking read PL011 RX (0x7F -> 8). BEEP = NOP (as x86). Cell index >= 2000 ignored (as x86).
- NEW src/tests/a64_console_test.nas -> `NaN/0S console PASS`; also draws "HI" at row 3 col 4 (seen in the UART stream).
- tools/a64_run.sh: `KEYS="1"` feeds bytes to the guest UART after 1 s; `CARTS=tools/carts.txt` embeds the sealed exhibit cartridges (without it: SEAL MISMATCH).
- Museum: menu renders fully (9 exhibits); `KEYS=1 CARTS=tools/carts.txt` loads Baby exhibit 1 through the seal check and renders it.
NOT DONE / NOT VERIFIED:
- Exhibits 2-9 and ESC-back NOT run (sweep interrupted). Expect traps in the GUI cart (needs FBINFO/FBFILL/FBCOPY/VSYNC) and anything using float ops.
- Terminal arrow/ESC sequences pass as raw bytes (x86 maps arrows to 0x80+). CP437 box chars show as '#'.
- No sim-vs-QEMU differential fuzz. a64asm.nas switch and a64.awk deletion pending (r28c).
NEXT, in order:
1. Sweep exhibits 1-9 (+ESC) with KEYS, note each first trap (separate TMPDIR per parallel run).
2. Signed DIV/MOD; float ops 0x30-0x37; then FBINFO/FBFILL/FBCOPY/VSYNC via ramfb for the GUI cart.
3. Switch a64_run.sh to a64asm.nas (r28c); delete a64.awk after one QEMU run.
4. Per-arch gold + image flag in mkimg.awk, qgate_a64.sh, RISC-V, Python retirement P1-P5, fix spec/ARCH_ADAPTERS.md (0x40080000).

# >>> r28c NOTE (31 Oct 2026): a64asm.nas (A64 assembler IN NaN16) DONE FOR THE CORE - 460/460 WORDS MATCH <<<
- `src/prog/a64asm.nas` (1837 words) = the old drafts + all handlers (movz/movk/mov, add/sub/cmp/neg, logic/tst/mvn, shifts, ubfx/sbfx/ubfm/sbfm, mul family, madd/msub, rev/rev16, ldr/str b/h/w/x offset+register+post-index, b/bl/b.cc/br/blr/cbz/cbnz/adr, csel/csinc/cset, mrs cntvct/cntfrq, ret/nop/wfi/isb) + directives .byte .word .quad .ascii .asciz .space .align .org .equ. Drafts a64asm_*_wip.nas and f567_wip.nas deleted (F5-F7 are already in gui_cart since r26a).
- PROOF (Python sim runner only as outer box): `python3 tools/nasm1run.py src/native/kan16_a64.xa64 /tmp/core.bin --nasm1 src/prog/a64asm.nas` -> status Y, 1840 bytes, 1.5M steps; every word equals `src/tests/a64_core_ref.hex` (the a64.awk output) = 0 mismatches. Second test: `src/tests/a64asm_forms.xa64` -> `a64asm_forms_ref.hex` (139 bytes; cmp/tst/mvn/br/blr/csinc/cset/sbfx/madd/msub/rev*/strh/ldrb reg/post-index/mrs/lsl/asr/add imm/sub shifted/neg + cbnz/b.lt/adr/.align/.ascii/.quad); the 23 words I knew from the ARM manual match (the one bug found, BLR bit 21, is fixed); the rest were checked by hand. Unknown mnemonic -> status N.
- LIMITS: 32-bit registers, so `.quad` writes the low dword then 0; no logical immediates (and/orr/eor need registers, same as a64.awk); no pre-index `[x,#i]!`; branch/adr ranges are masked, not checked. NOT run on QEMU (no qemu in this sandbox) - the output equals the awk output that already booted there.
- NEXT: tools/a64_run.sh should call nasm1run + a64asm.nas instead of gawk (delete tools/a64.awk after one QEMU run on a host with qemu); then the rest of the r28 list (KEY/KEYQ/VPOKE console ops in kan16_a64.xa64, per-arch gold + image flag, RISC-V, Python retirement P1-P5).

# >>> r28b NOTE (31 Oct 2026): a64asm.nas (A64 assembler IN NaN16) STARTED, NOT FINISHED, NOT ASSEMBLED, NOT RUN <<<
Owner rules restated this round: NO new Python/C/JS; source in NaN; bare minimum outer code; this sandbox had no qemu/gawk/xxd/v86 (no network), so NOTHING A64 was run. I wrote and deleted a throwaway Python A64 emulator in /tmp (not in the tree) - do not repeat.
GOAL: replace tools/a64.awk with `src/prog/a64asm.nas`, a two-pass A64 assembler written in raw NaN16, same stdout protocol as nasm1 (Y/N, newline, bytes). Run it with the EXISTING runner: `python3 tools/nasm1run.py src/native/kan16_a64.xa64 /tmp/core.bin --nasm1 src/prog/a64asm.nas` (the runner minifies only `;` comments, so a64asm also skips `//`).
FILES (drafts, in src/draft/, never assembled yet):
- a64asm_wip.nas = part1 (driver, getc/nextc/skipline, rdmn1 hash incl '.', label table, expr/tnum, emitb/w/d; `//` comment handling) + part2 (parseop operand records [type,A,B,C,D] at 0x4100+8n, rdid, clsreg x/w/sp/xzr, memparse incl [rn,rm,lsl #s] and [rn,#imm], tgt, condv).
- a64asm_tables_wip.nas = djb2 (upper-folded) hash tables: mnem (stride 3: hash,@handler,aux), conds, dirs, plus hashes for LSL / CNTVCT_EL0 / CNTFRQ_EL0 (need `hv_lsl`, `hv_cntvct`, `hv_cntfrq` .word labels). ret/nop/wfi/isb use h_fix with the 32-bit encoding as aux. Generated with a transient mawk script (not kept); no hash collisions.
- src/tests/a64_core_ref.hex = REFERENCE: 460 words (little-endian hex, one per line) of the shipped kan16_a64.xa64 as encoded by a64.awk. Made by running a64.awk under mawk after a perl pass that turned 0x literals into decimal and a hexn() shim for strtonum (mawk ignores 0x in source). Target: a64asm output must equal this byte for byte.
STILL TO WRITE (handlers; encodings are exactly the formulas in tools/a64.awk, already objdump-verified): h_movw (movz/movk), h_mov (reg->orr alias, imm->movz), h_arith (add/adds/sub/subs/cmp/neg, imm12 + lsl#12, shifted reg), h_logic (and/orr/eor/ands/bic/orn/tst/mvn), h_shift (lsl/lsr/asr reg+imm via ubfm), h_bfx (ubfx/sbfx/ubfm/sbfm), h_mul (mul/udiv/sdiv/umulh/smulh table), h_madd, h_rev, h_ldst (ldr/str/ldrb/strb/ldrh/strh: offset, register, post-index), h_b/h_bcc/h_br/h_cbz/h_adr (SAR r,r,2; mask 26/19/21 bits), h_csel/h_cset (cond via conds table; cset inverts cond), h_mrs, h_fix; directives d_byte d_word(32-bit) d_quad d_str d_strz d_space d_align(2^n) d_org d_equ; then assemble the file + tables together and diff against a64_core_ref.hex. Plan notes: CMP is unsigned, CMPS signed; SAR d,a,imm; compose 32-bit constants as (hi16)<<16 + lo; MOVI zero-extends imm16.
THEN (unchanged, in order): add KEY/KEYQ (PL011 RX), VPOKE/VPEEK/DISPQ/DISPSET/BEEP (shadow 80x25 text, flush as ANSI to the UART) to kan16_a64.xa64 so the museum menu works (the !O006C stop; museum uses KEY low 8 bits = ASCII, DISPSET 3 = clear); run tools/a64_run.sh on a host with qemu; per-arch gold + image flag in mkimg.awk; RISC-V; Python retirement P1-P5; fix spec/ARCH_ADAPTERS.md (0x40080000).
NOTE (r25d carry-over, other tree): the Sierpinski rule-90 work and F5/F6/F7 plan live in the r25d zip, not in this r28 tree.

# >>> r28 NOTE (31 Oct 2026): AARCH64 CORE RUNS ON QEMU - SELF-TEST PASS, MUSEUM BOOTS TO ITS PROMPT, FIRST !O TRAP AT OP FOR KEY/VPOKE <<<
## Owner rules (unchanged)
- All new code = raw NaN16 `.nas` -> nasm0 -> `.nan`. Only per-arch host files: `src/boot/kboot0_<arch>.xa` + `src/native/kan16_<arch>.xa*`. No new Python/C. Outer tools: sh + gawk + xxd + qemu + node (shot.mjs). Android/aarch64 first, RISC-V last.
## DONE this round (evidence: `sh tools/a64_run.sh /tmp/a64_test.nan` prints `NaN/0S core PASS`; `sh tools/a64_run.sh src/nan/museum.nan` prints `NaN/0S R26J READY MENU=S` then `!O006C`)
- SMOKE BLOBS FIXED (both were wrong encodings, not boot-path problems): a64_smoke.hex had stray bit 23 (stores decoded as LDRSW), `movz` built 0x90000000 instead of 0x09000000, loop branch went to itself; rv64_smoke.hex had `lui t0,0x10` (needs 0x10000), `ld` instead of `lbu`, forward branch instead of back, `wfi` falling into data. Both now print on QEMU 8.2.2 (`NaN/0S A64 READY`, `NaN/0S RV64 READY`). Hex files rewritten in src/draft/.
- FINDING: for a raw `-kernel` blob QEMU 8.2 loads aarch64 at 0x40080000 (not 0x40000000, which is only QEMU's rom stub that jumps there); RV64 `-bios none` enters at 0x80000000. spec/ARCH_ADAPTERS.md table ("entered at base") must be corrected.
- NEW tools/a64.awk: gawk A64 assembler (movz/movk, add/sub/logic, shifts, ubfx/sbfx, mul/div/msub, rev, ldr/str incl. register + post-index, b/bl/b.cc/cbz, adr, csel/cset, mrs cntvct). Output checked instruction-by-instruction against aarch64-linux-gnu-objdump (all forms matched).
- NEW src/native/kan16_a64.xa64 (1,840 bytes core + shim): copies the guest image (blob+0x2200, 65,536 words) to 0x44000000, regs at 0x43F00000, PL011 at 0x09000000 (init + TXFF poll), gate check of both heads (!G<pc>), predication by k=2Z+L, 70-entry op table. IMPLEMENTED: BOOL, MOVI, MOVHI, ADD, SUB, SHL, SHR, CMP, LD, ST, JMP, CALL, RET, JMPR, NOP, TICK (ms from CNTVCT/CNTFRQ), BSWAPM, PUTC, STW, LDN, MUL, MULH, MULHU, DIVU, MODU, SAR, CMPS, ADDI, LDB, STB, CALLR, BCOPY, BFILL, JMPF, HALT. Everything else traps `!O<pc>` (same text as the reference sim).
- NEW src/tests/a64_test.nas: portable 18-check core self-test (pure NaN16, also passes on tools/nan16sim.py = the oracle; prints `NaN/0S core PASS` or `FAIL nn`). Use it for every new core (a64 / rv64 / x86).
- NEW tools/a64_run.sh GUEST.nan [SECS]: assemble core, pack blob (core padded to 0x2200 + guest words from tools/mkimg.awk), run QEMU, print UART.
## NOT DONE / NOT VERIFIED
- Museum stops at `!O006C`: the first unimplemented op is a display/keyboard op (VPOKE/VPEEK/KEY/KEYQ/DISPQ/DISPSET/BEEP, 0x10-0x1B) used by the menu. Next: (a) KEY/KEYQ from PL011 RX (FR bit 4 RXFE, DR 0x00) so `-nographic` keys work; (b) VPOKE/VPEEK/DISPSET/DISPQ as a text console mirror to the UART (VMODE 0) so the museum text menu is visible; (c) signed DIV/MOD; (d) then FBINFO/FBFILL/FBCOPY/VSYNC via a ramfb or virtio-gpu framebuffer for the GUI cart; (e) float ops 0x30-0x37 (FADD..CVTFI) with A64 FP (fadd s0..), JMPF done.
- Not run on real hardware or Android. Android path stays: QEMU in Termux (works with this blob) or a UEFI/bare-metal payload (not started).
- Not compared word-for-word against the x86 core on random programs (only the 18-check test + museum prefix). TODO: run tools/difftest/fuzz equivalent vs nan16sim for the implemented ops.
- No kboot0_a64.xa / nan16_a64.nan gold yet: tools/mkimg.awk is still x86-only (needs a per-arch layout flag). The a64 blob is currently assembled by tools/a64_run.sh.
## NEXT, in order
1. Finish the op set above until the museum menu is usable on `qemu-system-aarch64 -M virt -nographic`; then GUI cart via ramfb (`-device ramfb`), keyboard via virtio-input or UART.
2. Per-arch gold + image: src/native/nan16_a64.nan (hex of the blob), `tools/mkimg.awk -v ARCH=a64`, a `qgate_a64.sh` that runs a64_test + museum prefix.
3. RISC-V (rv64): same shape; a rv64 assembler (tools/rv64.awk) + kan16_rv64.xa64-style core, smoke already fixed.
4. Remaining from before: Python scaffold retirement P1-P5 (still Python: nanchk/mkimg1/proofs), disk utility (ATA/virtio-blk), 5x7 museum font, Settings countdown test, drag-while-animating check, `tools/qgate.sh` regressions, README.
5. Fix spec/ARCH_ADAPTERS.md load-address note (0x40080000) and the "kan16_a64.xa" naming (source is `.xa64`, assembled by tools/a64.awk).

---
>>> r26i NOTE (31 Oct 2026) - HISTORICAL (state before the r26j census executed; see the r26j section at the bottom): nasm0 .org DONE; GOLD REFRESHED; SELFHOST REGENERATED <<<
- Added `.org expr` to `src/prog/nasm0.nas` and `nasm0_tables.nas` (hash 193501741 = "org"). It pads to an absolute word index in both passes. Proof: `.org 100` test PASS, diff=0 (`logs/nasm0_org_r26i.txt`).
- nasm0 grew 661 -> 752 words. `tools/gen_nbuild_selfhost.py` made dynamic (BASE0/BASE1) and regenerated `src/prog/nbuild_selfhost.nas` (source 2300 words). NOT re-run in v86: this Termux tree has no `tools/harness/node_modules`; run on a host with v86 before claiming SELFHOST PASS for the 752-word assembler.
- Refreshed `src/native/nan16_x86.nan` gold for the SSE kernel: boot 512 + kernel 5808. `sh tools/nasm1check.sh`: 83/83, boot/kernel IDENTICAL, build 24,901 guest words. Full v86 gate skipped because node_modules is absent.
- Still Python: nanchk/mkimg1/mkbase/mkboot/nasm1run/nan16sim/gen_nbuild_selfhost/mkalloc/proofs/oracles. Next P1: nbuild reads a manifest, assembles a flat cart with `.org 8192`, seals, stores, and dumps the 65,536-word guest image via `shot.mjs --mem`.

# >>> r26h NOTE (31 Oct 2026): PYTHON RETIREMENT STARTED (P3 + P4 done), SSE KERNEL FIX APPLIED <<<
DONE (evidence in this round's shell log; each deleted generator was first run in a scratch copy and its output diffed against the checked-in file):
- P3 generators RETIRED, 13 files. Output byte-identical to the checked-in .nas, so the .nas is now the only source: gen_about_carts, gen_boole_cart, gen_font, gen_n16i_nest, gen_n16i_test, gen_nasm1_tables, gen_patriot_cart, gen_sierpinski_pixel_cart, gen_trust_cart, mkbabydata. Stale (their output no longer matched; the hand-edited .nas wins): gen_fb_lib, gen_sierpinski_cart, mktables (also crashed on the LA table form; src/tools/mktables.nas replaces it). gen_trust_cart's input spec/TRUST_PAPER.md stays. Edit the .nas files directly from now on.
- P4 DONE: ONE outer box, tools/harness/shot.mjs: boots an image in v86, plays a key plan, writes PNG (graphics, any VBE size) or a .txt (text screen), and `--mem ADDR:LEN:FILE` dumps guest RAM (the RAM-dump hook P1 needs). No logic in it. Deleted fbshot.py shot.py textshot.py t.py bootcmp.py runbig.py guitest.py and harness cap.mjs capfb.mjs capx.mjs. capture_r21.sh, build.sh, nasm1check.sh no longer call them (sierpinski pixel check is now `tr | wc`). Tested: menu .txt, GUI 1024x768 .png (screencaps/r26h_gui_v86_1024x768.png).
- Python files in tools/: 47 -> 22 (all in the remaining list below). C source: none exists in this tree; the non-NaN leftovers are those .py files, tools/harness/*.mjs (9 -> 6 incl. shot.mjs), and the gas files src/native/nan16.s, src/native/boot.s, tools/scaffold/*.s (native test core + old boot).
- KERNEL FIX (src/native/kan16.xa): new `sse_init` called first in _start: CPUID.1, requires EDX bit24 (FXSR) and bit26 (SSE2), then CR0.EM=0, CR0.MP=1, CR4.OSFXSR|OSXMMEXCPT (0x600). Needed by BCOPY (MOVQ xmm0) AND the guest float ops (ADDSS/MOVD). Encoded with .byte for CPUID/CR moves. Assembles with nasm1 (kernel still 5808 bytes: code sits before the fixed data .org); `sh tools/mkall.sh` builds; v86 boots the museum and the 1024x768 GUI. NOT PROVEN: QEMU (the bug only shows there). QEMU is NOT installed in this sandbox: `apt-get update` first, the earlier install failed on a 404 (ovmf). The PAE draft src/draft/kan16_pae_wip.xa does NOT have this fix yet (copy sse_init + the CALL into it before promoting). nasm1 gold bytes (logs, native_check) for the kernel changed: refresh them.
STILL PYTHON (22): build path nanchk.py mkimg1.py mkbase.py mkboot.py nasm1run.py nan16sim.py gen_nbuild_selfhost.py (its output is STALE vs nasm0.nas after the LA change: regenerate or replace by P1) mkalloc.py; proofs mkproof.py proofnat.py nasm1check.py nasm1_tests.py; oracles test_nanvm1.py test_far.py difftest.py fuzz.py traptest.py n16i_check.py n16i_fuzz.py babyref.py sweep_seal.py mutate_nalloc.py. Native/gas: nan16.s boot.s scaffold/*.s.
NEXT, in order: (1) P1 with the RAM-dump hook: boot a builder image in v86, the guest runs nasm0 over the carts, seals, builds the 65,536-word guest image in RAM, shot.mjs --mem dumps it; the host only concatenates boot+kernel+dump (boot/kernel bytes come from nasm1 run in the guest the same way). First milestone: nasm0-in-v86 output for ONE .nas byte-equals nanchk (this is what mkproof does in the model; proofnat on gas). (2) delete nasm1run/nan16sim from the build once nasm1 runs on kan16 in v86. (3) port each oracle to a guest .nas PASS test, delete the .py. (4) retire nan16.s/boot.s/scaffold/*.s with difftest/fuzz/traptest. (5) P5 gate. (6) finish r26g items: memtest bank-count fix, SSE into the PAE draft, promote it. Open GUI items: the Sierpinski window renders empty after a while (stateless Pascal mod 2 at large t; should be the HTML's cyclic rule 90, time flowing up).
# >>> r26g NOTE (31 Oct 2026): QEMU FINDINGS ON THE PAE DRAFT (zip taken mid-debug) <<<
- PUTC goes to the SERIAL port, not the VGA text screen (museum draws with VPOKE). To read guest PUTC output in QEMU add `-serial file:/tmp/ser.txt` to tools/harness/qrun.sh args. Earlier "blank screen" memtest runs were this, not a hang.
- RESULT with the PAE kernel, QEMU -m 3500: E820 map parsed (7 entries at 0x600, count 7 at 0x5FC), frame table FT filled (FT[0..]=1,2,3..), memq works: CPUID leaf 0x4E4D001F gives mask 0x0FFFFFFF (power-of-two cap, MAXM), NWD=0x1B500000 words (1748 frames), flags=3 (PAE on, E820 ok). Bank 0 read/write PASS.
- BUG IN THE TEST (not the kernel): mask 0x0FFFFFFF = 2 banks, so banks 2 and 3 alias banks 0 and 1; memtest.nas must test only banks < (mask+1)>>27 (fix: store mask, nb=(mask+1)>>27, loop to nb, skip BCOPY if nb<2).
- REAL KERNEL BUG FOUND (also in the SHIPPED kan16.xa): the BCOPY fast path uses MOVQ xmm0 (F3 0F 7E / 66 0F D6). In QEMU this raises #UD (!X0006) because the kernel never enables SSE: CR0.EM must be 0, CR0.MP 1, CR4.OSFXSR (0x200) 1, gated on CPUID.1:EDX bit 24 (FXSR). v86 ignores this, real hardware and QEMU do not. FIX (not yet applied): in pae_init (and the shipped kernel's init) after the CPUID leaf-1 call: if EDX bit 24: MOV %CR0,%EAX; AND $0xFFFFFFFB,%EAX; OR $2,%EAX; MOV %EAX,%CR0; then MOV CR4 (.byte 0x0F,0x20,0xE0), OR $0x200, MOV CR4 (.byte 0x0F,0x22,0xE0). Keep EDX for the PAE test that follows. Alternatively replace MOVQ with two 32-bit MOVs (slower, no SSE dependency).
- STILL NOT DONE: apply both fixes, rerun memtest (-m 3500 gives banks 0,1 only; 16 banks needs a 17 GB machine), promote the draft to src/native/kan16.xa, rebuild build/nan0s.img, Python retirement (P1..P5).
# >>> r26f NOTE (31 Oct 2026): INTERIM - PAE DRAFT NOW ASSEMBLES AND BOOTS THE MUSEUM IN QEMU; 16 GB NOT YET PROVEN <<<
DONE: (1) nasm1 source area was 4096 words, so any .xa over 16 KB silently corrupted itself (output buffer overlapped the source): OUT moved 0x21000 -> 0x24000 in src/prog/nasm1.nas (V_OUTB setup + .equ). Shipped kan16.xa still assembles to the byte-identical 5808 bytes. (2) src/draft/kan16_pae_wip.xa assembles clean: 6834 bytes (limit 8192), status Y. It was already further along than the r26e note said (nrmA/B/C, bk_sw, bcslow, pae_init, memq are all present). (3) kboot0.xa: INT 15h E820 loop added (entries at 0x600, count word 0x5FC), still exactly 512 bytes. (4) QEMU 8.2.2 installed in the sandbox (apt-get update first). Museum image built with the PAE kernel + new boot sector boots in QEMU at -m 3500 and -m 3000: all 9 exhibits listed (screenshot checked). (5) src/tests/memtest.nas written (CPUID leaf 0x4E4D00FF query, mask raise, class-6 words at (bank<<27)|0x123456 in every bank, LDN/LD readback, cross-bank BCOPY); assembles (169 words).
NOT DONE / NOT PROVEN: memtest has not produced output yet (first QEMU run showed no text after 15 s, probably just load time; rerun with longer wait). The sandbox has ~4 GB, so -m 17000 cannot be run here: at most 3 banks. The PAE draft is NOT promoted to src/native/kan16.xa; build/nan0s.img is unchanged. Legacy v86 boot of the PAE kernel not tested (v86 may not report PAE: pae_init then leaves paging off by design).
PYTHON RETIREMENT: NOT STARTED beyond this. Order is unchanged: P1 nbuild (needs ATA write or a RAM-dump hook), P2 proofs as guest .nas, P3 generators, P4 one JS capture driver, P5 gate. The build path still needs Python for: nanchk (assembler), mkimg1 (image), nasm1run + nan16sim (running nasm1). First real cut: run nasm1.nas under n16i or the booted kernel instead of nan16sim, then write nbuild.

# >>> r26e NOTE (31 Oct 2026): 16 GB BANK WINDOW DESIGNED + HALF-PATCHED IN A DRAFT; SHIPPED KERNEL UNCHANGED <<<
NO NEW PYTHON/C WRITTEN THIS ROUND. Shipped src/native/kan16.xa and src/boot/kboot0.xa are byte-identical to r26d; `sh tools/mkall.sh` rebuilds build/nan0s.img IDENTICAL to the shipped one (checked with cmp).
VERIFIED: QEMU is installable here (apt, qemu-system-x86_64 8.2.2) and BOOTS the r26d image: museum with 9 exhibits (`sh tools/harness/qrun.sh IMG SECS OUT.ppm 512`). QEMU can enter PAE paging; v86 cannot (no long mode, PAE unproven), so the 16 GB path is verified in QEMU, legacy path in v86.
DESIGN CHANGE (replaces M2'): DO NOT use long/compat mode. The kernel takes IRQ0/IRQ1 through a 32-bit IDT; in IA-32e mode every interrupt needs a 64-bit gate and 64-bit handler, which breaks the "no REX" plan. Use 32-bit PAE paging instead: CR4.PAE (bit 5) + CR3=PDPT + CR0.PG. No EFER/WRMSR, no IDT change, 36-bit physical, 2 MB pages. Only new encodings: MOV CR4 (0F 20/22 E0) as `.byte`; MOV CR3 already in nasm1. nasm1 16-bit `66` prefixes, `AND [mem],%EAX`, `MOV %EAX,%CR3` checked with ndisasm: correct.
DESIGN (all in src/draft/kan16_pae_wip.xa, NOT assembled yet):
- boot: INT 15h E820 loop in kboot0 (ES=0, entries at 0x600, count word at 0x5FC, max 40). Needs ~50 bytes, boot sector has room.
- kernel after the image copy: build frame table FT (0x50000, dword = phys>>21) from type-1 ranges, 2 MB frames from phys 2 MB up, cap 8192 frames = 16 GB; require the first 16 frames contiguous at 0x200000 else legacy. No ADC/SBB in nasm1: do the 64-bit range math with CMP/JAE.
- tables: PDPT 0x40000, four PDs at 0x41000 (array index = 2 MB page from linear 0x40000000). PD0[0]=identity low 2 MB (flags 0x83); PD array[1..512]=bank 0 = linear 0x200000 (= G, so existing `[G+ECX*8]` is unchanged) via FT[0..511]; array[513..1024]=window W (linear 0x40200000, 1 GB) rewritten per bank from FT[bank*512+j]; PD3 = identity 3-4 GB UC (flags 0x9B) for the VBE LFB/BARs. 2 MB pages everywhere, so pdpe1gb is not needed.
- every guest access: `AND [MASKV],r / CMP $0x8000000,r / JB ok / CALL nrmA|B|C` (index>=2^27 words -> bank=idx>>27, idx'=2^27|low27, bk_sw rewrites 512 PDEs + reloads CR3 if CURB differs). MASKV defaults 0x3FFFFF, so shipped behaviour is unchanged until a guest raises it.
- BCOPY: fast path when mask<2^27 or both ranges inside bank 0; else 4096-word bounce buffer (0x60000), chunked, direction by the original overlap rule. BFILL keeps its raw index on the stack. OUTSW is bank 0 only. No zero fill above 32 MB (not committed).
- guest interface with NO new opcode (no edits to nanchk/nasm0 tables): `CPUID rd,rLeaf,b` with leaf 0x4E4D00nn: nn=0xFF query, nn=1..31 sets mask=min(2^nn-1,MAXM); reg0=mask, reg1=NW words, reg2=flags (b0 paging on, b1 E820 ok), reg3=bank-switch count.
STATE OF THE DRAFT: patched in the draft (not assembling because helpers are missing): constants, loop-top fetch, LD, ST, STW, LDN, BSWAPM, LDB, STB, BFILL, OUTSW, BCOPY entry + fast path. NOT written: nrmA/nrmB/nrmC, bk_sw, pae_init + E820 parse, bcslow, memq in h_cpuid, kboot0 E820 loop, `MOV %CR4` bytes. Kernel space: 5808 of 8192 bytes used and code must end before `.org 0x1400`, so append new code AFTER the data tables; if it exceeds 8192 raise the kernel to 24 sectors (loader count 1048, `MOV $0x12000,%ESI` -> 0x13000, mkimg1 assert). Unknown: whether v86's CPUID reports PAE; gate pae_init on E820 present AND PAE bit AND a v86 boot test.
NEXT, in order: (1) finish the draft, assemble it with nasm1, boot the museum in v86 (legacy) AND QEMU (-m 17000); (2) src/tests/memtest.nas in NaN16: set mask via CPUID leaf, write class words at banks 0,1,7,15 (idx k<<27|0x123456), read back with LDN, BCOPY across banks, print PASS; (3) then the Python-retirement items (P1..P5 below), starting with D (screenshots) and nbuild; (4) fused span ops, translator, RAWMAP/VRAM.
HONEST LIMITS: 16 GB untested on any machine; the 805 MB figure in r26c is still the only measured memory result. Window switches cost ~512 PDE writes + a TLB flush, so cross-bank random access will be slow; keep working sets inside one 1 GB bank.

# >>> r26d NOTE (31 Oct 2026): C1 DONE - `LA` 32-bit load pseudo-op in nasm0 AND the scaffold <<<
`LA[PRED] rD,expr` = MOVI rD,lo16 + MOVHI rD,hi16 (2 words, always 2 in both passes so labels stay stable). nasm0: table entry `.word 5862482,257,65` (op bit 8 = emit a second MOVHI word) + 14 instructions after `de:` in src/prog/nasm0.nas. nanchk.py expands it identically. PROVEN (nasm0 vs scaffold, diff=0 PASS): `LA r2,5`; `.equ` > 64K; label operand; `#BIG+0x1234`; `0xFFFFFFFF`; `LA[EQ]`. nanchk now REFUSES `MOVI` immediates > 0xFFFF (they used to wrap silently) and says use LA; the full image still builds. Carts can now keep data/code above word 65535: use LA for every address that may exceed 16 bits (nasm0 has no .org, so a cart larger than 57,344 words needs the overlay/far-code scheme in C4). NOT done: nasm0 label-hash collision check (0b); `LA` is not yet in src/tools/disasm.nas (it shows MOVI+MOVHI, which is exact). NOT VERIFIED: nasm0 proof of wm_test.nas and gui_cart.nas with the patched nasm0 (started, exceeded the sandbox time limit; run in background with a long timeout); nasm0 self-host fixed point with the new table entry.
NEXT: M2' compat-mode 1 GB bank window, then C2 ATA-streamed carts.

# >>> r26c NOTE (31 Oct 2026): MEASURED LIMITS (16 GB RAM, 32 GB VRAM, Doom/Quake/Wolf3D/newer) <<<
VERIFIED IN REAL v86 THIS ROUND: the r26b image (1040-sector loader, WT/ZO/STK at 0x58000) boots; museum lists 9 exhibits; [9] opens the 1024x768 GUI; F5 draws Settings (screencaps/r26b_f5_v86_1024x768.png). First v86 run of the GUI cart with F5.
MEASURED:
- M-a. Interpreter speed in v86: 18.0 M guest ops (3M x 6-op loop) in 1565 ms TICK = 11.5 M ops/s. Doom spans alone need 16.9 M ops/s (spec/PERF_ESTIMATE.md) => interpreter is too slow even for Doom in v86; real x86 maybe 5-10x (UNMEASURED, extrapolation). Quake (FPU, 3D, lighting) is far beyond. Needs: fused span ops + NaN16->native translator (src/translate/x86.nas, a64.nas exist as stubs, 10 and 73 lines).
- M-b. Guest memory probe (kernel MASK raised to 0xFFFFFFF, v86 memory_size 2200 MB, fill count 0x20000000): read/write OK at word index 0x00FFFFF0, 0x03FFFFF0, 0x05FFFFF0, 0x07FFFFF0, 0x0BFFFFF0 (= 1.5 GB of word space = 805 MB of payload); 0x0FFFFFF0 (2 GB) reads back 0xFFFFFFFF = v86 does not map it. Shipped kernel stays at MASK 0x3FFFFF (32 MB): a bigger default would crash real machines with less RAM. Recipe to enlarge: kan16.xa `.equ MASK` + the zero-fill count (MASK+1)*2 dwords + RAM size; the real fix is E820/MEMQ (spec/MEMORY_SCALE.md M1).
STRUCTURAL LIMITS (read from code/spec):
- L1. Word index is 32-bit (LD/ST base register + imm16): 2^32 words = 32 GB of word space. 16 GB RAM = 2^31 words FITS. 32 GB of VRAM as words does NOT (it alone is 2^32 words): VRAM must be a raw window (RAWMAP), never plain LD/ST.
- L2. 8 bytes per word, 4 bytes of payload: 16 GB RAM = 8 GB payload. Pack pixels/textures/WAD bytes 4 per word (LDB/STB exist); never one byte per word.
- L3. Kernel is 32-bit protected flat: physical <= 4 GB minus PCI hole (~3 GB usable) => ~384M words max. 16 GB RAM and any GPU BAR above 4 GB need long mode. Plan M2': keep the 32-bit interpreter unchanged by running it in x86-64 COMPATIBILITY mode (EFER.LME, PAE, identity page tables, CS.L=0) and map a 1 GB bank window through one PDPT entry (1 GB page); word index >> 27 picks the bank (16 banks = 16 GB), INVLPG on bank change, VRAM bank uses PAT write-combining pages. Needs nasm1 to emit WRMSR/RDMSR/MOV CR3,CR4/LJMP only (no REX): small.
- L4. Code addressing: MOVI #label and LD/ST offsets are 16-bit (cart <= 57,344 words); JMP/CALL 24-bit. Needs `LA` (MOVI+MOVHI) in nasm0 and nanchk (item C1 below).
- L5. Boot image: BIOS real-mode load < 0x9F000 => ~70k words; floppy 1.44 MB = 184k words. Bigger = NaN ATA loader (C2).
- L6. Display: 8 bpp indexed Bochs VBE only (Doom/Wolf3D/Quake software modes are 8 bpp = FITS). No 32 bpp, no 1080p, no GPU acceleration. VPOKE is per pixel; use FBCOPY/FBFILL rows.
- L7. GPU: PIO/BAR mapping gives raw VRAM access only. Compute/3D needs a vendor command-processor driver (AMD documented ISA, NVIDIA GSP firmware opaque, Intel documented). "Newer games" = software rendering until that exists; real 3D = virtio-gpu in VMs first, then one documented AMD/Intel GPU.
ORDER (push to the limit): C1 `LA` -> M2' compat-mode bank window (16 GB) -> C2 ATA streamed carts -> fused span ops (M-a) -> native translator -> RAWMAP + PCIe BAR (32 GB VRAM) -> virtio-gpu -> real GPU.

# >>> r26b NOTE (31 Oct 2026): CAPACITY x2 IMAGE, x5 PER CART (Doom/Quake-scale is the goal) <<<
DONE: (1) wm.nas WT/ZO/STK moved from 26624/26880/31400 to 0x58000/0x58100/0x59000 (32-bit: every use is MOVI rX,#WTL + MOVHI rX,#WTH; same for ZO/STK), so a cart may now run from 8192 up to 65535 = 57,344 payload words (old cap: 18400 counted from word 0 = ~10k payload words). (2) Image 32,768 -> 65,536 guest words: kboot0.xa loads 1040 sectors, kan16.xa copies 0x20000 dwords, mkimg1.py asserts/pads 512 KB. gui_cart (6918 payload words) + museum + all carts use 24,901 of 65,536. Verified: image builds; gui_cart in the sim (1<<20 words) runs to idle with windows at the new WT; ZO order ok. NOT verified: x86 boot in v86 (loader/kernel byte changes), native_check gold bytes (kernel changed), nasm0 proof.
LIMITS NOW: image <= ~70k words (BIOS real-mode load must end below 0x9F000); one cart <= 57,344 words because `MOVI #label` is 16-bit. Doom/Quake need MORE:
- C1. 32-bit label refs: nasm0/nanchk pseudo `LA rX,@label` = MOVI lo + MOVHI hi (labels > 65535); data tables > 64K addressed with base regs. JMP/CALL are already 24-bit, JMPF/CALLF exist (far_test.nas).
- C2. Streamed carts: NaN loader reads carts from disk (LBA > the BIOS-loaded part) straight into high guest memory (>= 0x100000) with ata.nas; needs a 4-INW->1-word pack path (or a kernel DISKLOAD op) and a per-sector dual-face seal; TOC entry gets LBA + length + load address. Disk image is no longer a floppy (use HDD image, 64 MB+).
- C3. Variable mask / MEMQ (spec/MEMORY_SCALE.md M1), then M2 long mode for > 32 MB.
- C4. Multi-segment carts (code overlays + 100k-word data lumps) for WAD-like data: lumps are class-6 words, sealed per lump.
Order: C1, C2 (biggest win), then C3.

# >>> r26a NOTE (31 Oct 2026): F5/F6/F7 SPLICED INTO gui_cart.nas <<<
DONE (src/exhibits/gui_cart.nas, 15092 words, limit 18400; src/nan/gui_cart.nan regenerated with nanchk emit; src/draft/f567_wip.nas deleted, it now lives in the cart):
- Text helpers tx_org/tx_s/tx_c/tx_h/tx_d/tx_end/tx_wh, gui_single (raise or open centred), kdef/kt rows for kinds 4 SETTINGS, 5 NaNNet, 6 SYSTEM (UTILITIES).
- g_onkey: F5/F6/F7 (0x105..0x107) open the single-instance windows; while st_pend is armed EVERY key goes to st_pendkey (ENTER keep, ESC revert). Terminal commands s / n / u added (help text updated, version r26).
- g_bar is fb_w-relative (MOVE flag at fb_w-144, clock at fb_w-98/-74); wm.nas picks the short hint (s_hint2) when fb_w < 900.
- Settings: modes 1024x768, 720x1600, RISC-V (disabled row), custom WxH (W snapped to x8, 320-1920 x 200-1600, W*H <= 2M); 10 s TICK countdown, st_refit clamps/un-enlarges windows, lattice reseeds. DOUBLE-ENDIAN: the revert mode is stored as a class-6 word + BSWAPM mirror (class 9, payload byte-reversed); st_load re-mirrors a scratch copy and checks class AND payload, falls back to 1024x768 if either face is damaged.
- NaNNet: adapter row from the PCI scan, CONNECT probe (1.5 s with dots) -> "adapter found, no driver (stub)" / "no adapter", ADDRESS DHCP/STATIC and DNS AUTO/MANUAL flipped by XOR (BOOL.6), HOST row. No NIC driver yet.
- Utilities: CPUID (leaf 0 EBX/EDX/ECX words ARE the vendor string, brand 0x80000002-4, family/model/stepping, EDX/ECX features), TSC hi/lo + MHz over >=500 ms TICK + the BE face of TSC low (class-6 word through BSWAPM), ATA IDENTIFY x4 slots (bounded waits, 0xFF/0/ATAPI = none, model string byte-swap fixed, size MB), PCI list bus 0 (bus:dev.fn ven:dev class sub). PCI entries are stored as class-6 words (STW) and verified with LDN (gate-style integrity).
VERIFIED: assembles (nanchk emit, no duplicate labels); in a /tmp copy of the Python sim with a 1024x768 fb and mocked CPUID/RDTSC/PCI/ATA the cart boots and F5 opens the Settings window and draws correctly (screenshot checked).
NOT VERIFIED YET: F6 / F7 draws, Settings apply + 10 s revert + Esc/Enter, 720x1600 refit, terminal s/n/u, nasm0 proof (label-hash collision check, item 0b), not booted in v86, gui_test.nas not updated, README not updated.
NEXT (owner order): finish the sim run of F6/F7/apply/revert, then P1 (nbuild in NaN16) .. P5 and the NaN16DE + bare-metal x86/aarch64/riscv universal adapter that replaces the Python scaffold.

# >>> r25e NOTE (31 Oct 2026): NO CODE CHANGE TO gui_cart.nas THIS ROUND <<<
Only addition: src/draft/f567_wip.nas = first part of F5-F7 (text helpers tx_*, gui_single, Settings F5 complete with 10 s revert, st_refit, NaNNet start, PCI/ATA/CPUID design in comments). It is UNASSEMBLED and UNTESTED, truncated mid-NaNNet, and is not included by any cart. gui_cart.nan is unchanged from r25d. Next: finish the draft, splice into gui_cart.nas (budget: cart must stay < 18400 words, 13102 now), assemble with nanchk emit, test in a /tmp sim with a 1024x768 fb.

# >>> r25c HANDOFF (31 Oct 2026): READ THIS FIRST <<<
DONE this round (src/exhibits/gui_cart.nas, Sierpinski section):
- Sierpinski is now EXACT rule 90 with cyclic edges (cells = class-6 XOR words, next = BOOL.6(left,right), wrap at both ends, single centre seed, time flows up, seed row at top until the body fills, then scroll by FBCOPY).
- Offscreen VRAM row cache: ring of ls_rd rows (<=768, limited so cache stays under 2,000,000 bytes of VRAM), stride fb_w, at fb_w*fb_h. lat_draw/lat_put redraw from the cache (drag/enlarge/uncover safe); lat_tick always steps so history is exact, touches the screen only when uncovered. Width change reseeds. Both end cells are read back with LDN each row; class != 6 reseeds (gate-style integrity).
- VERIFIED ONLY in the Python NaN16 sim (isa=1): `src/tests/lat_rule90_test.nas` (stubs + lattice block) vs an independent rule-90 reference: cache rows exact, scrolled screen body exact, lat_draw redraw exact (see tools below). NOT booted in v86 (v86 not installed in this sandbox, no network).
- src/nan/gui_cart.nan regenerated; image builds (13102+ words cart, below WT=26624 limit: keep cart < 18400 words).
NOT DONE (unchanged): Settings F5 / NaNNet F6 / Utilities F7 handlers; shell-launch + mode-restore screenshot; nasm0 proof of gui_cart.nas; nasm1check.sh; native_check.sh; seal sweep; gui_test.nas update; P1-P5 Python retirement; nasm0 label-hash fix (0b).
Design notes for F5-F7 (not written yet): single-instance windows (find alive kind, else open); kinds 4/5/6 with kdef/kt rows; Settings: modes 1024x768, 720x1600, RISC-V (disabled), custom WxH; apply via fb_init_mode, clamp windows, 10 s TICK countdown that reverts (Esc must be routed to the window while testing); g_bar uses fixed x=880/926/950 and s_hint is long: make them fb_w-relative before 720-wide mode. Utilities: CPUID(op 0x44: d,a=leaf,b=reg 0..3 = eax,ebx,ecx,edx), RDTSC(rd,r0 low / rd,r13 high) over a TICK(ms) interval, ATA IDENTIFY 0xEC with bounded waits (floating bus 0xFF/0 = no drive), PCI via OUTL 0xCF8 + INW 0xCFC/0xCFE.
Sim test note: /tmp scripts used Sim(nwords=1<<21,isa=1); a worker loop must keep its counter in memory (lat_tick clobbers r1-r12).

# >>> NEXT CLAUDE: START HERE (r25 WIP handoff, 31 Oct 2026) <<<

## TOP PRIORITY (owner, 31 Oct 2026): RETIRE THE PYTHON SCAFFOLD
Goal: the image is built, proven and shipped by NaN16 code only. Python/JS are allowed ONLY as the throwaway outer box (v86 host) until nasm0 can run on bare metal; nothing in the build logic may live in them.
- P1. Image builder in NaN16: replace `tools/mkimg1.py` + `mkboot.py` + `mkbase.py` + `mkall.sh` with a `.nas` "nbuild" that runs in the guest: reads carts (`.nan` text or words), runs nasm0 on each `.nas`, writes TOC + seals (dual-face FNV-1a/32) and the 528-sector image to disk through `src/lib/ata.nas`. Start from `tools/gen_nbuild_selfhost.py` output, then delete the generator.
- P2. Proof in NaN16: replace `mkproof.py`/`nanchk.py`/`nasm1check.py` with a guest `.nas` that assembles a file with nasm0 AND with the reference table words and prints PASS/diff=N. The host only boots the image and reads the screen/serial.
- P3. Generators (`gen_*.py`, `mkalloc.py`, `mkbabydata.py`): rewrite each as `.nas` (font7 and cart data become hand-written `.nas` or nasm0 data directives), then delete the .py.
- P4. Harness (`tools/harness/*.mjs`): keep one tiny capture/keystroke driver as the only non-NaN file; list it explicitly as "outer box" in README.
- P5. Gate: `tools/` contains no `.py`; `PYTHON_CENSUS.md` shows 0 build-path Python files. Track progress in `spec/PYTHON_CENSUS.md`.

## OPCODE DIRECTIVE (owner): NaN q/s/+/- : 16 boolean : DOUBLE ENDIANNESS
New code uses only the NaN16 word model: the four heads +s/-s/+q/-q, the 16 boolean functions (class nibble n = truth table), and the two faces of every word (near head LE / far head BE). Be creative with double endianness:
- Mirror = bswap: `BSWAPM` turns n into rot2(n) = f(~a,b); use it as a free logical NOT on one operand, a free "reverse direction" for scans/Sierpinski rows, and a 2-cycle self-check (word == bswap(bswap(word))).
- Neutral words (near==far: n=0,5,10,15) are endian-invariant: use them as sentinels/flags that read the same from both ends; non-neutral words are direction-tagged data.
- Store window records, key events and ring entries as class words so a bad head traps (`!G`) instead of silently corrupting: integrity from the encoding, not from extra code.
- Predication already is a 4-bit table lookup over (Z,L): keep branching as `[EQ]/[NE]/[LT]/[GE]` predicates, avoid x86-style flag tricks.

## Owner rules (non-negotiable)
- Every instruction and word of NEW code is raw NaN16: `.nas` source -> assembled by `nasm0` (the NaN assembler, in the guest) -> `.nan` raw NaN words (`7FF1_xxxxxxxx_F17F` style). NO new Python, C or other generators. The Python scaffold (`tools/mkimg1.py`, `nanchk.py`, `mkproof.py`, harness .mjs) is only the S6 test bench / imaging; do not extend it, and prove new `.nas` with nasm0: `python3 tools/mkproof.py FILE.nas /tmp/x.img --run` must print `PASS` (diff=0).
- x86 is the bare minimum (kernel `src/native/kan16.xa` only). Edit existing files in place; do not create new files unless needed.
- Terse, high-density output. Less planning, more code. Quantum-foam experiments are separate research; never relate them to QTCL.
- nasm0 has no `.org` / `.include` (the bench flattens includes). Guest code is assembled at `.org 8192`.

## State at this checkpoint (all in `logs/r25_status.txt`)
DONE + VERIFIED in v86:
- 1024x768x8 mode works (`DISPSET w<<16|h`, Bochs VBE, PCI BAR scan). Pixels are correct; the earlier "stripes" was a bad capture. `src/tests/vbe_test.nas` shows NaNGlyph text on screen. Capture: `cd tools/harness && node capx.mjs IMG SECS OUT.ppm` (indices also in OUT.ppm.idx).
- NaNGlyph 7x11 font (cell 8x13): `src/lib/fbtext.nas` (`fb_char7`, `fb_text7`, `t7_clip`) + `font7.nas`. Draws per pixel with VPOKE (slow; speed up later, e.g. row blits).
- Sierpinski reference colours taken from the uploaded HTML: fire #42ef8a, idle #10311e, panel #181536 (palette 16/17/18 in `src/lib/fb.nas`). Reference behaviour: 1-D rule 90 (all cells op 6 XOR), single centre seed, cyclic edges, time flows UP (rows copy up, new row at the bottom), 2 ticks per frame at 60 fps (~120 rows/s), 200x260 cells in the HTML.
- `src/lib/kbd.nas`: raw PS/2 set-1 keyboard driver in NaN16. `kbd_init` (DISPSET 0xFFFF0001), call `kbd_poll` every frame, `kbd_get` -> event = code | mods<<16 (mods: 1 Shift, 2 Ctrl, 4 Alt, 8 Caps). Codes: ASCII; Enter 13, Bksp 8, Tab 9, Esc 27, Del 127; F1..F12 = 0x101..0x10C; Up/Down/Left/Right = 0x110..0x113; Home/End/PgUp/PgDn/Ins = 0x114..0x118. Tested with `src/tests/kbd_test.nas` + `tools/harness/keyseq.mjs`; nasm0 assembles it with diff=0. The kernel raw ring holds only 15 bytes: poll often.
- Kernel (`kan16.xa`): variable framebuffer, DISPSET raw-key mode, `CPUID` (op 0x44: d = cpuid(leaf a).reg[b]) and `RDTSC` (0x45: a=0 low, 1 high), FBCOPY/FBFILL copy byte tails. NOTE FBCOPY/FBFILL/VPOKE: FBCOPY and FBFILL are NOT clipped (FBBASE+offset), so video memory beyond the visible screen can be used as an offscreen cache (check v86 `vga_memory_size`; keep total under ~2 MB to be safe). VPOKE is clipped to the screen.
- Guest memory mask is 0x3FFFFF words (32 MB); the image loads 256 KB (32768 words) at 8192. Big buffers go above 0x40000.

WIP, NOT INTEGRATED: `src/draft/wm_r25_wip.nas` = new window manager (assembles, UNTESTED, not in any cartridge). Design: 32-word window records at WT=26624 (fields 0..14 as before, 15 FLAGS bit0 = enlarged, 16..19 saved X Y W H), z-order list ZO=26880, per-window 8192-word buffer at 0x40000+id*8192, `wm_rect` clipped to fb_w/fb_h, 15px title bar with close and enlarge boxes, `wm_enlarge(r1=id,r2=fit_w,r3=fit_h; 0 = fill)`, NaNGlyph titles, top bar 17px. `src/lib/wm.nas` and `src/exhibits/gui_cart.nas` are still the OLD 320x200 versions and still boot/draw correctly (the image builds and boots). To finish: replace wm.nas with the WIP, then port gui_cart.nas (see list).

## REMAINING TASKS, in order (r25b, 31 Oct 2026)
DONE + VERIFIED in v86 (1024x768, `/tmp`-style standalone boot of `src/exhibits/gui_cart.nas`; screencaps/main.png = F3-enlarged Terminal after typing `h`+Enter):
- Task 1: new window manager is now `src/lib/wm.nas` (32-word records, 8192-word buffers, clipped rects, NaNGlyph titles, close/enlarge boxes). `gui_cart.nas` ported: `fb_init_mode` 1024x768, fbtext+font7+kbd included, 8x13 NaNGlyph cells, `SHL ,5` indexing, fb_w/fb_h bounds in `g_movekey`, terminal stride VCW=128. `src/draft/` wm file removed; `src/tests/wm_test.nas` proves/draws it (nasm0 diff=0).
- Task 2: kbd.nas wired in (kbd_init/kbd_poll/kbd_get, 16-bit code). Tab focus, F2 move (arrows 0x110..0x113, Enter leaves), F3 enlarge/restore, Esc close all work. Hex also takes PgUp/PgDn.
- Task 3: F3 on every window; Terminal/Hex derive cols/rows from window size at draw time (`term_fit`, `hex_geom`); Monitor fits content (250x96); others fill. (Title-bar boxes are drawn but there is no mouse yet.)
- Task 4 (partial): Sierpinski window is stateless (time counter in A0, redraws any time, so drag/enlarge work), palette 16/17 (fire/idle), rows scroll up via FBCOPY, mask 511 rows. NOT done: offscreen row cache, exact rule-90 cyclic-edge behaviour of the HTML (current rows are Pascal mod 2 from a single seed).
TODO next:
5. Settings (F5): visual modes x86 1024x768, Galaxy A32 5G 720x1600 portrait (check VRAM), RISC-V placeholder, custom WxH; confirm countdown that reverts (TICK). F5/F6/F7 are shown in the bar but not yet handled in `g_onkey`.
6. NaNNet (F6): Connect + Settings stub UI.
7. Utilities (F7): ATA identify (`ata.nas`), memory, CPUID leaf 0/1, RDTSC delta over a TICK interval.
8. Redesigned 5x7 font for the 320x200 museum carts (keep `fb_char5/fb_text5` API).
9. Gates NOT yet rerun after this port: nasm0 proof of `gui_cart.nas` (`sed '/^\.org/d'`, `--big`, no image arg; may need a long timeout), `tools/nasm1check.sh`, `tools/native_check.sh`, seal sweep, update `src/tests/gui_test.nas` for 32-word records/1024x768, README. Image builds via `sh tools/mkall.sh`; museum-shell launch of the GUI cart (TOC entry) not yet screenshot-checked at 1024x768 / mode restore on exit (kbd raw off + fb_mode3) untested.
10. Click the PYTHON SCAFFOLD list at the top (P1..P5); nasm0 hash-only label lookup fix (item 0b).
0b. nasm0 label lookup compares only the 32-bit hash: `dw_c`/`f5_c` collide. Fix in `src/prog/nasm0.nas` and add a collision check to the proof harness.

Known open items from earlier rounds are listed below (unchanged).

---

# NaN/0S TODO (r24 / v42, 30 October 2026)

This is the live recursive plan. The archive headers below are kept so the
older detailed bit-level plans are not lost. Read this file first.

## r21 / v40 STATUS - what actually runs

DONE and tested in v86 this round:

- Full 320x200x8 VGA framebuffer: mode 13h, linear A0000, white-on-black
  pixels, kernel `VPOKE/VPEEK` mode switch, `FBINFO`, `VSYNC`, `FBCOPY`,
  `FBFILL`, `OUTB`, `INB`.
- The VGA register sequence is now NaN16 code in `src/lib/fb.nas`
  (`fb_mode13`, `fb_mode3`). The native kernel only supplies port I/O and
  the framebuffer mapping. This is the smallest possible hardware boundary.
- Homebrew 3x5 font, 64 glyphs, ASCII 32..95, drawn at 2x scale by
  `fb_char3`; `fb_text3` folds lowercase to uppercase. No font was copied.
- Sierpinski cartridge: real 320x128 pixel rule-90 lattice, white on black,
  live scroll; lower 72 pixels are a scrollable 5x7-font museum label. Every
  cell is a class-6 NaN16 word, payload bit 1 guard, bit 0 state, time upward.
  Aligned with the owner reference HTML; see `spec/REFERENCE_HTML.md`.
- Boole 16 cartridge: 98-line scrollable plaque, live 16-function table,
  mirror law, dual-face word lab. `V_SCROLL` is a general shell vector.
- About NaN/0S and About Shemshallah cartridges, both scrollable.
- Thompson Trust exhibit: preface + the full paper, 376 wrapped lines,
  scrollable. Paper at `spec/TRUST_PAPER.md`.
- Unified image is 12,619 guest words. The guest image slot is now 32,768
  words (256 KB) because the boot loader loads 528 sectors (16 kernel + 512
  guest) and the kernel copies 256 KB. Still a small release image.
- Six TOC entries: Baby, Boole, Sierpinski, About NaN/0S, About Shemshallah,
  Trust.

NOT yet done this round:

- Seal mutation sweep (script still unrun; rewrite sequential, short timeout,
  background before running).
- Mirror-law refusal test (status 3) on the new multi-entry layout.
- `nasm1check.sh` must be updated to build/check the six-cart image and the
  new gold bytes (the kernel changed).
- Curator Console first slice: DONE. Secret `~` opens a read-only raw guest
  word view with arrow scrolling and page moves. Spec: `spec/CURATOR_CONSOLE.md`.
- Patriot and Ariane 5 cartridges (specs written, code not yet).
- Two-stage allocation image: spec + `tools/mkalloc.py` prototype DONE (sparse
  64 GiB apparent, ~1.5 MiB allocated). Stage-1 runtime loader still next.
- Apollo AGC emulator (spec written, first slice not yet).

## BARE-METAL MAP - every live item

Legend: NaN = written in NaN16 (.nas, assembled to raw .nan words). HOST =
native x86 or scaffold, only where the machine cannot yet execute NaN.

### A. Cartridge loader and ABI - DONE for one image; scale next
- A1 boot image size: DONE 256 KB guest via 528 sectors. Next: two-stage
  allocation image (see IMAGE_SCALE_PLAN.md).
- A2 TOC: DONE 16-word entries, six live. Next: meta_ptr points at a
  per-exhibit meta block with dates/people/status/sources, so the shell can
  show a detail page without loading the cartridge.
- A3 ABI: DONE vector table 1..12, including `V_SCROLL`. Next: `V_PAGER`
  (generic line-table pager) to remove the duplicated pager code in Boole,
  About, and Trust.
- A4 seals: DONE dual-face FNV-1a/32 + class channel. Next: mutation sweep,
  mirror-law refusal, then a keyed MAC.
- A5 MEMQ: NOT STARTED. Native op 0x38 in the v22 plan is still reserved.
  It must return a region table (base, words, flags) from E820/BIOS and from
  the allocator. nalloc takes (base,size).
- A6 overlay/arena: NOT STARTED. The shell frees an exhibit arena on exit.
- A7 LZ cartridge expander in NaN: NOT STARTED.

### C. Keyboard - DONE basic; Curator chord next
- C1 DONE: Shift+1 -> '!', arrows 0x80..0x83, 15-key ring drop-newest,
  blocking KEY, KEYQ.
- C2 caps/shift tables: 384 B target.
- C3 document key map in NAN16_SPEC.
- C4 v86 key tests in `tools/harness/keyseq.mjs`.
- C5 PS/2 real hardware; USB legacy untested.
- NEW: track Ctrl in the IRQ so Ctrl+Shift+0 can open the Curator Console.
  First hotkey is `~` (Shift+backtick), which already needs no new IRQ state.

### D. Word inspector / debugger exhibit
- D1 needs A5 and a second VM instance in guest memory.
- D2 views: dual-face word, class nibble, opcode/predicate, regs, flags,
  memory hex.
- D3 step/run/break/watch; interpreter-in-NaN, so the debugger cannot kill
  the host.
- D4 gate-trap demo: flip one head bit and show `!G`.
- D5 compare interpreter-in-NaN trace with nan16sim.

### E. Trusting-trust exhibit - DONE as paper + cartridge; proof transcript next
- E1 paper: `spec/TRUST_PAPER.md`, hosted as TOC entry 6.
- E2 demo: DONE. `python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2`
  reaches the fixed point and the transcript is `logs/r21_trust_test.txt`.
- E3 plaque: Ken Thompson 1943- LIVING, Turing Award 1983, lecture 1984.
- E4 honest limit: seals are tamper evidence, not authentication; DDC fails
  if both toolchains are compromised.
- NEXT: add the trojan assembler demo (homebrew, harmless) and the seal
  mutation sweep on the six-entry layout.

### F. Real clock - DONE
- F0 baseline restored.
- F1 hardware kernel boots; serial model matches.
- F2 TICK vs wall clock 500 ms = 500 +-5 ms in v86.
- F3 update nan16sim/nan16.s for new KEY/TICK semantics.
- F4 MIPS ladder prerequisite: TICK-timed ops/s loop.
- F5 real HW PIT reload 1193 and fractional correction.

### G. Pixels / framebuffer - DONE first slice
- DONE: mode 13h 320x200x8, `FBPUT` via VPOKE, `FBCOPY`, `FBFILL`,
  `FBINFO`, `VSYNC`, `OUTB`, `INB`, NaN16 mode-set, 3x5 font.
- NEXT: mode 12h/VESA linear 640x480, palette API, `FBLINE`, `FBRECT`,
  `FBBLIT`, `FBTEXT` with a larger font, double buffer, hardware scroll
  (CRTC start + line compare split screen), and a `VSYNC` timing test.
- Doom/Quake path: code region from A5, nalloc, float library H, C subset I.

### H. Float library
- FEXP, FSIN, FCOS, FATAN2, FLOG, FTANH as NaN polynomials.
- Accuracy table vs numpy float32, ULP report, range reduction.
- Softmax/RMSNorm for H9; donut.nan; Quake.

### I. NaN C-subset compiler
- Tokenizer, parser, codegen NaN16/NaNVM1. int + float32 + pointers +
  structs, no libc. Self-hosting goal.
- First targets: Hall 2 C exhibit, Doom, Quake.
- Plan grammar in `spec/` before coding. Code bloat: 8 B/word; see D1.

### L. Disk write / persistence
- INT13 write from the boot real-mode stub or an ATA/AHCI/NVMe driver.
- Hall of NaN scores, passport, saved edits, seal on write.
- This is the substrate for the two-stage allocation image.

### M. AArch64 emitter + interpreter
- nasm1 -> A64 encodings in NaN16; same-image interpreter.
- UEFI/Pi framebuffer + UART. 83-style encoding test suite.

### N. Sound
- PC speaker via PIT ch2 and port 0x61; `BEEP(freq,ms)`.
- CSIRAC/Baby music exhibits.

### IMAGE SCALE - the gigabyte store
- Spec: `spec/IMAGE_SCALE_PLAN.md`.
- Ship `nan0s.img` (loader) + `work.img` (current work). Do not ship a
  multi-GB allocation image.
- First boot: Stage 1 creates sparse `store.nan` (NaNFS superblock, block
  bitmap, extent tree), writes `work.img` into the first work extent, seals,
  boots it. Later boots verify and load.
- 64-bit block numbers, 4 KiB blocks, extents, B-tree directories,
  content-addressed store, block cache, journal, trim.
- `tools/mkalloc.py` prototype: DONE. Creates a sparse 64 GiB NANFS image,
  writes a superblock and the work image into the first extent.
  Evidence: `logs/mkalloc_r21.txt`: apparent 68,719,476,736 bytes, allocated
  1,478,656 bytes, work image 1,474,560 bytes.
- NEXT: Stage-1 loader reads NANFS via ATA/AHCI, verifies the work seal, and
  boots it. Then corrupt-extent refusal, 1 GiB streaming file through a 1 MiB
  cache, and 100k-file directory enumeration.

### CURATOR CONSOLE - spec written, code next
- Secret `~` (Shift+backtick) DONE, planned Ctrl+Shift+0.
- Raw guest memory hex, 4 payloads per row, address + payload format DONE.
- NEXT: dual-face format toggle, goto, serial dump, follow-PC.
- Up/Down word, Left/Right page, `g` goto, `s` format, `f` follow PC,
  `d` dump serial, ESC return.
- Lives in the shell, read-only, works even with a bad cartridge.
- Move TOC to word 1280 to make room. Update mkimg1.py TOC base.
- Spec: `spec/CURATOR_CONSOLE.md`.

## HALL 7 - FAILURE EXHIBITS (specs written, code next)

### The Patriot Missile Failure (1991) - DONE as a scrollable plaque
- Event: 25 February 1991, Dhahran, Saudi Arabia.
- 24-bit fixed-point clock truncation, about 0.000000095 s/hour drift,
  about 0.34 s after 100 hours, 28 deaths.
- Deep implementation: pixel tracking display, 24-bit fixed-point clock,
  real-time drift accumulator, intercept box narrowing, coordinate becomes a
  NaN word, `!G`, black screen and names.
- Plaque: "This exhibit is a tragedy of representation. The system didn't
  lack processing power; it lacked the bits to represent time accurately.
  Here, in a NaN machine, we have infinite ways to represent 'undefined' -
  but the Patriot had none."
- People: the 28 dead; Theodore A. Postol 1946- LIVING; GAO 1992 report.
- Badge RE-CREATION. Cartridge DONE: `src/exhibits/patriot_cart.nas`,
  TOC entry 7, screenshot `screencaps/patriot.png`. Next: the live
  tracking animation described below. Test log `logs/patriot.txt`.

### The Ariane 5 Explosion (1996)
- Event: 4 June 1996, Kourou, French Guiana. Flight 501, about 37 s.
- 64-bit float to 16-bit signed integer overflow, backup SRI failed the same
  way, vehicle broke up.
- Deep implementation: 16-bit boundary box, 64-bit velocity vector, overflow
  burst, crash log in seal style, flight path and empty payload bay.
- Plaque: "Ariane 5 was a masterpiece of engineering destroyed by a 16-bit
  boundary. Your NaN VM is built on the premise that 'invalid' is a valid
  state. The engineers of Ariane 5 did not have that luxury."
- People: Jacques-Louis Lions 1928-2001 DEAD, inquiry board chair; ESA/CNES/
  Arianespace team.
- Badge RE-CREATION. Test log `logs/ariane5.txt`.
- Specs: `spec/FAILURE_EXHIBITS_PLAN.md`.

## HALL 1 - APOLLO AGC (owner's favourite)
- Spec: `spec/APOLLO_AGC_PLAN.md`.
- 15-bit words, 2K RAM, 36K ROM, ~85k instructions/s.
- People: Draper 1901-1987 DEAD; Hamilton 1936- LIVING; Garman 1945-2016
  DEAD; Kranz 1933- LIVING; Armstrong 1930-2012 DEAD; Aldrin 1930- LIVING;
  Collins 1930-2021 DEAD. Verify before shipping.
- First slice: AGC CPU core in NaN16, assembler subset, DSKY pixel display,
  1202 alarm demo, lunar descent toy, core memory visual.
- No NASA ROM unless public domain verified. Homebrew programs only.
- Badge RE-CREATION until instruction semantics are verified against primary
  sources.

## MUSEUM BUILD ORDER
Hall 0 -> Hall 1 (Apollo) -> 2 -> 3 -> 4 -> 5 crypto -> 6 -> 7 failure ->
8 -> 9. Curator Console is cross-cutting and comes before Hall 7.

## RULES FOR EVERY EXHIBIT
1. Executable NaN program loaded and run from the menu.
2. Badge EXACT / RE-CREATION / INSPIRED.
3. Date of event.
4. People + alive/dead status, verified; mark unverified honestly.
5. History lesson: why it mattered.
6. What the code does and how it does it.
7. Sources.
8. All ROMs/data homebrew unless public domain verified.
9. Golden output log.
10. Everything that can be NaN is NaN. The native kernel is the only
    necessary host boundary, and it is kept small and documented.

## BASELINE GATES
- `python3 tools/nasm1check.py` (83/83, boot/kernel gold, v86 selftest).
- `sh tools/native_check.sh` (host model vs native, fuzz, traps).
- `python3 tools/test_nanvm1.py` (5,810 opcode checks).
- `python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2` (fixed point).
- `sh tools/mkall.sh` (six-cart image, <=2 images in build/).
- Seal mutation sweep, mirror-law refusal.
- Every new exhibit has a v86 screenshot and a log.

## RELEASE PLAN
- r21 = this round: framebuffer + pixel Sierpinski + six-cart museum +
  Trust paper/exhibit + all plans in this TODO.
- r22 = Curator Console + seal sweep + two-stage sparse allocation image.
- r23 = Patriot + Ariane 5 cartridges.
- r24 = Apollo AGC first slice (CPU + DSKY + 1202 demo).
- r25 = Doom-class framebuffer path: mode 12h/VESA, float library, C subset.
- Every release: one small loader image + one work image, no giant upload.


## ALIEN MECHANICS - double-endian time, causal loops, the Orrery
Spec: `spec/ALIEN_MECHANICS.md`.

### Double-Endian Timer
- Memory-mapped live MMIO word. Forward face counts up, reverse face counts
  down. `DTIME.15 = T`, `DTIME.0 = 0xFFFFFFFF - T`.
- `BSWAPM` flips the view. The register is live, not sealed by the cartridge
  mirror law; the gate still checks both heads.
- First implementation in pure NaN16 with TICK + a mailbox word. Native
  hardware version later.
- Causal-loop demo: read forward, compute R, write mailbox, flip to reverse,
  read the future R, modify the input, iterate to a fixed point. Honest label:
  self-consistent computation, not retrocausality.
- Test: forward - reverse is constant; BSWAPM flips; fixed point <=32
  iterations.

### The Orrery / NaN Singularity
- sNaN cascade text engine: prompt class selects a rule, quieting stops the
  trap, output becomes the next prompt.
- Trap handler is the interpreter. Output feeds back as a signaling NaN.
- Hard cap 1,000 iterations, watchdog 2 s without TICK, sealed transcript.
- The plaque, verbatim: "Warning: Do not connect the output of the Orrery to
  its input. It will think forever. The only way to stop it is to physically
  pull the plug, which is the most alien form of interruption known to
  computing."
- Not an AGI and not an LLM. A minimal exception-loop model, kept honest.
- Hall 9 exhibit, after languages/networks. Dark room, one screen, physical
  power switch, scrollable plaque.


### Alien Mechanics II - Paradox Engine
Spec: `spec/ALIEN_MECHANICS.md` sections 6-9.
- Paradox Engine: sNaN/qNaN flip as a clocked contradiction. Exhibit is an
  oscillator and a frequency counter. Plaque says it is not free energy.
- Retired r26j: the Halting Oracle / Asimov loop / EPR retrocausal framing leaves the workline;
  only the Paradox Engine clock and the double-endian carrier stay.
## GUI SHELL - desktop, windows, vcon, NaN/0S header
Spec: `spec/GUI_PLAN.md`.
- 320x200 desktop, 5x7/8x8 fonts, window frames, focus, z-order.
- Every window title and every program page starts with `NaN/0S`.
- Text cartridges run in a virtual console window; pixel cartridges run in a
  pixel window. ESC closes the window, not the machine.
- Implementation order: wm.nas -> vcon.nas -> gui_shell.nas -> redirect
  V_PUTS/V_CLS/V_SCROLL -> text windows -> pixel windows -> multi-window ->
  mouse -> AArch64 backend.
- Readability: 5x7 glyphs in 6x9 cells, 1px horizontal gap, 2px vertical gap,
  optional 2x focus scaling, UTF-8 subset.

## TEXT READABILITY / HEADERS
- 5x7 complete ASCII font + 14 Unicode glyphs: DONE (`src/lib/fb.nas`).
- UTF-8 decoder: DONE (`fb_text5`, `fb_nextbyte`).
- More line spacing: DONE in pixel text (6x9 cell).
- `NaN/0S` added to exhibit titles and the shell banner.
- NEXT: `NaN/0S` in every window title via the GUI, and every text-mode page
  header via the pager. The pager currently uses the exhibit title as header.

## SELF-HOSTING / ATA - first slice in progress
Spec: `spec/SELF_HOSTING.md`.
- `INW`/`OUTW` guest ops: DONE in the native core and model.
- `src/lib/ata.nas` ATA PIO driver: LBA28 read is GREEN. `ata_read28` returns
  0x414E from sector 0 (`NAN0` little-endian). Evidence: `logs/ata_r21.txt`.
- INW/OUTW opcode table bug found and fixed: INW is 0x40, OUTW is 0x41.
- Write path: PARTIAL. `ata_write28` writes word 0 (0xA5A5) but word 255 reads
  back 0. Tried DRQ-before-each-word: hangs. Current blocker: PIO write
  handshake or a native OUTSW block primitive.
- nbuild RAM-only first slice: DONE. `src/prog/nbuild.nas` includes nasm0,
  assembles a cartridge source at runtime, and reports 5 words, 0 errors,
  0 mirror failures, out0=0x01100048. It computes the dual-face seal A/B/C,
  copies the payload to the RAM store at 16384, writes a TOC entry at 12288,
  verifies the store word-for-word, and recomputes the A/B/C seal from the
  store. `STORE PASS` + `SEAL PASS`. Evidence: `logs/nbuild_r21.txt`.
- NaNFS RAM slice: DONE. `src/lib/nanfs.nas` formats 64-word blocks,
  allocates via a bitmap, and writes/reads blocks. `NANFS PASS`,
  evidence `logs/nanfs_r21.txt`.
- Self-replication fixed point: DONE in-guest. `src/prog/nbuild_selfhost.nas`
  embeds the flattened nasm0 source, assembles it with the running nasm0,
  and compares all 661 words (payload + class) to the running assembler.
  `SELFHOST PASS`, evidence `logs/selfhost_r21.txt`.
- Next: add the TOC entry + RAM store to nbuild, fix ATA write, write the
  built cartridge to disk, NaNFS format/mount, self-hosted image.


## DRIVERS IN NaN - current
- VGA: DONE (`src/lib/fb.nas`), mode 13h, 5x7 font, UTF-8, `FBCOPY/FBFILL`.
- Keyboard: native KEY ring; NaN keymap/driver next (raw scancodes).
- Audio: DONE first slice (`src/lib/audio.nas`), PIT ch2 + port 0x61,
  `audio_beep(freq,ms)`, test `AUDIO PASS` (`logs/audio_r21.txt`).
- ATA: read DONE (`ata_read28`, 0x414E from sector 0); write DONE
  (`ata_write28` + flush + readback, word 0 = 0xA5A5, word 255 = 0xA6A4).
  Root cause: nasm1 emitted 32-bit IN/OUT for 16-bit PIO; 0x66 prefix fixed.
  `ATA RW PASS`, evidence `logs/ata_r21.txt`.
- Physical memory: MEMQ/E820 next.
- BIOS: native real-mode trampoline is the only allowed boundary.
- GUI: plan in `spec/GUI_PLAN.md`.

## TRANSLATOR - three NaN files
Spec: `spec/TRANSLATOR.md`.
- `src/translate/common.nas`: IR + emit8/16/32.
- `src/translate/x86.nas`: x86 backend slice (NOP/RET/INT3; full nasm1 extraction next).
- `src/translate/a64.nas`: AArch64 backend slice (NOP/RET/BR/MOVZ/ADD/SVC).
- Test `src/tests/translate_test.nas`: A64 NOP/RET + x86 RET emitted and
  verified, `TRANSLATE PASS` (`logs/translate_r21.txt`).
- Next: A64 B/BL/CMP/MOVK, full x86 table extraction, one IR -> both backends.


## GUI - first slice DONE
- `src/exhibits/gui_cart.nas` + `src/lib/wm.nas`, TOC entry 9.
- 320x200 desktop, 4 windows: Terminal, Sierpinski, Monitor, Hex.
- `NaN/0S` title bars, focus ring, TAB focus, ` move mode, arrow move,
  ESC close. Sierpinski window animates statelessly while moved.
- System menu: Settings, NaNNet, Disk, Memory, CPU pages.
- NEXT: 1024x768 VBE, per-window maximize/zoom, AArch64 phone layout,
  x86/RISC-V visual modes, custom NaN keyboard map, NaNNet NIC.
## ARCHIVES
- `spec/TODO_v23_archive.md`, `spec/TODO_v22_archive.md`: the R21 recursive
  bit-level plans for F/A/C. Keep them.
- `spec/README_v23_archive.md`.
- Old v39 notes: `logs/v39_notes.txt`.

## r22 (31 Oct 2026) - Stage 2 of NAN_MIGRATION_PLAN DONE
- `src/tools/disasm.nas`: NaN16 disassembler in NaN16 (dual-face line, predicate, BOOL.n, all 63 ops). Test `src/tests/disasm_test.nas`, `logs/disasm_r22.txt` (0 mismatches vs oracle).
- `src/tools/mktables.nas`: generates `src/prog/nasm0_tables.nas` in NaN from the disassembler op table; byte-identical to mktables.py. tools/mktables.py is now reference only (and was stale: no kind 'j').
- nasm0 gained operand kind 5 (JMPF/CALLF); nasm0_tables now has 63 mnemonics; fixed point re-proved (`logs/nasm0_r22_fixedpoint.txt`).
- STALE, regenerate next: `src/prog/nbuild_selfhost.nas` / `src/nan/nbuild_selfhost.nan` embed the old flattened nasm0; `.org` unsupported in nasm0 (benign at 0).
- NEXT: port nbuild flatten step (gen_nbuild_selfhost.py) to NaN; NaN16-in-NaN16 interpreter (Stage 3).


## r23 status
- DONE: Stage 3 NaN16 interpreter in NaN16 (`src/tools/n16i.nas`), differential + nested + nasm0 proofs.
- OPEN: fuzz seed 0 mismatch (r5, one register) - root-cause before calling the interpreter exact.
- OPEN: `nbuild_selfhost` still embeds the old flattened nasm0 (port `gen_nbuild_selfhost.py` to NaN).
- OPEN: `.org` support in nasm0 so n16i tests can be assembled in-guest.
- NEXT: run n16i on v86 / real hardware; use it for sandboxed museum exhibits; float ops natively in NaN16.


## r24 status (GUI + Python census)
- DONE: windowed desktop in NaN16: `src/lib/wm.nas`, `src/exhibits/gui_cart.nas` (TOC entry 9),
  Terminal / Sierpinski / Monitor / Hex windows, Tab focus, ESC close, move mode. Runs on v86.
- DONE: `src/tests/gui_test.nas` 20-check self-test, GUI PASS (model).
- DONE: `spec/PYTHON_CENSUS.md`: every Python file, its NaN replacement, removal order. All Python files now say SCAFFOLD.
- FIXED: nan16sim FBFILL/FBCOPY operand bug.
- NEXT (GUI): run gui_test on v86; V_PUTS/V_CLS/V_SCROLL redirect so existing text carts (Boole, About, Trust,
  Patriot) open inside a window (GUI_PLAN step 4-5); pixel-window clipping for Sierpinski/Paradox carts;
  resize; PS/2 mouse; palette programming through OUTB 3C8/3C9 (NaN, no native code); 8x8 chrome font; scroll bars.
- NEXT (Python removal, in order): nasm0 `.include` + `.org`; JS capture writes PNG; nbuild manifest + image out;
  run nasm1 under v86; convert each oracle to a NaN self-test.
- KNOWN: shell status lines after a seal refusal (rows 21-22) can overlap entry 9; cosmetic.
- KNOWN: store of the older carts overlaps SLOT 8192 (baby..paradox); copying a cart to SLOT can overwrite a later
  stored cart. The GUI cart is stored at 14516, clear of SLOT. Needs an audit and a store relocation.

## r26j status - outer-tool census EXECUTED
- EVERY `tools/*.py` deleted. The v86/node/JS harness (`tools/harness/`) deleted.
  `gen_nbuild_selfhost.py`, the legacy shells (`build.sh`, `build_round01.sh`,
  `capture_r21.sh`, `hex2bin.sh`, `sweep_seal.sh`, `native_check.sh`,
  `nasm1check.sh`), `tools/scaffold/`, `src/native/nan16.s`, `src/native/boot.s`,
  `src/native/r22_verified/` deleted.
- Outer dev stack is now POSIX sh + gawk + xxd + qemu-system-i386 only. No Python,
  no JS, no C anywhere in the tree.
- `tools/nmk.awk`: .nas -> .nan emit + check; byte-identical output vs the retired
  tool for all 10 sources (`logs/nmk_parity_r26j.txt`). gui_cart.nas: oversized MOVI
  immediates replaced with LA (split lo/hi); source and .nan agree again.
- `tools/mkimg.awk` + `tools/mkall.sh` build `build/nan0s.img`; byte-identical to the
  r26i reference image (sha256 79cc73edf90915c27d619cb9008979edd4a36b164b440975e
  626785ba6ac5200) before the banner; seals A/B/C and TOC semantics unchanged.
- `tools/qgate.sh` replaces the v86 gate: boots `build/nan0s.img` on qemu-system-i386
  bare metal, greps the guest's own COM1 boot banner. Shell cold entry now emits
  `NaN/0S R26J READY MENU=S` on COM1 (52 words before the shell body). Qgate PASS.
- Puzzle-145 and the RETROCAUSAL LAB workline retired: `src/puzzle/`,
  `spec/PUZZLE_145.md`, `spec/RETROCAUSAL_LAB.md`, `src/tests/retro_test.nas`,
  its TODO sections and plaque wording removed. n16de double-endian carrier stays
  (`src/lib/n16de.nas`, `src/tests/n16de_test.nas`, `logs/n16de_test_r21.txt`).
- Census counts r26j: 0 .py, 0 .mjs, 0 .c/.s x86 sources; kept gold: `kan16.xa`
  + `nan16_x86.nan` (512 boot + 5808 kernel bytes).

## r26k status - AArch64 + RISC-V adapter workline opened (WIP)
- Goal: the SAME guest word stream boots unmodified on x86, AArch64, RISC-V64.
  Per-arch surface = exactly two admissible host files: `src/boot/kboot0_<arch>.xa`
  (boot shim) + `src/native/kan16_<arch>.xa` (native core); per-arch gold bytes
  land in `src/native/nan16_<arch>.nan`. Contract, entry states, and the
  handler-port table: `spec/ARCH_ADAPTERS.md`.
- `qemu-system-aarch64` and `qemu-system-riscv64` (headless, QEMU 10.2.1)
  installed; outer-tool stack unchanged (sh + gawk + xxd).
- M-A64-1 / M-RV-1 boot-path smoke: hand-assembled banner blobs written as pure
  hex (src/draft/a64_smoke.hex: A64 PL011 at 0x09000000, -M virt -kernel raw;
  src/draft/rv64_smoke.hex: RV64 M-mode NS16550A at 0x10000000, -M virt -bios
  none). First boot attempt on BOTH returned an EMPTY serial line: debug open
  (raw -kernel entry point vs loader expectations vs UART reset state). NOT
  gold, NOT shipped path; no PASS claimed.
- Pending after smoke PASS: draft .xa skeletons, `tools/qgate_a64.sh` +
  `tools/qgate_rv64.sh` gate greps (`NaN/0S A64 READY`, `NaN/0S RV64 READY`),
  gawk emitters for the per-arch subsets, per-arch gold `.nan`, then full core
  ports (M-A64-2 / M-RV-2) and the virtio-blk/virtio-gpu legs (v3).
- x86 gold stays frozen; image layout unchanged (boot 512 + kernel 5808 +
  guest 24904 words); build/nan0s.img sha256
  4c79207c93fc0b3639a0c75d6b318487fad5b219565ce6bbee9f7a8c8214a7a2.
- Roadmap: text-only browser (no image or script path). Image ingestion stays
  hard-blocked at the network edge until an in-network classifier exists.
- Roadmap: a standalone NANNET manager owns links (wired/WiFi), addresses,
  routes, DNS and driver load state; NANNETSUITE is a toolkit, not the control
  plane. Config lives in `.nancfg` files.
- NANNET M1/M2 landed: `src/nannet/` (interfaces, addresses, routes, DNS,
  WiFi scan/join/leave fixture, `.nancfg` apply/rollback); gates
  `tools/nannet_gate.sh`, `tools/nannet_link_gate.sh`,
  `tools/nannet_wifi_gate.sh`. M3 is service/menu integration.
- x86 host networking: NE2000 ISA + QEMU user-net ARP gate
  (`sh x86/tools/netgate.sh`) passes. The host's active connection (WiFi or
  wired) carries traffic; next is DHCP/ICMP/UDP and NANNET `eth0` binding.
- Android WiFi: the app has a real WifiManager panel (status, scan, connect
  suggestion) with runtime permissions. Next is the host bridge
  (VpnService/datagram + JNI) into NANNET. The APK build stays on the CI
  `gradle :app:assembleDebug` path.

## CRYPT — public encryption suite
- [x] NSP-7/NSP-8 capsule reference + frozen KATs (`crypt/vectors/capsule.txt`).
- [x] NSPF1 authenticated file container + CLI + gate (`crypt/`; suites 1/2;
      empty/odd files, tamper/truncate/wrong-key/planned refusal).
- [~] Raw NaN16 product port: internal 512-byte capsule round-trip PASS;
      public guest NSPF1 tool and encrypted system boot pending.
- [ ] Encrypted system boot: volume header, operator/TPM key, rollback counter,
      key zeroization.
- [ ] ML-KEM-768, Ed25519, ML-DSA-44, SLH-DSA (suites 3/4/5 stay planned and
      fail closed until implemented).
- [x] NSPV1 volume tool: format/verify/info/read/write; suites 1/2; gate
      (`crypt/volume_gate.sh`).
- [x] Storage probe on C-core disk fd (Android path) and x86 QEMU IDE
      (`crypt/storage_gate.sh`); plug-and-play NSPV magic detection.
- [x] Guest NSPV all-sector decrypt (suite 1) on C-core fd + x86 QEMU IDE;
      public cart `crypt/guest/nspv_decrypt.nan` and `storage_decrypt_gate.sh`.
      The cart walks `data_sectors` for full volumes and `used` for lazy ones,
      skips zero-tag holes, selects tag slots, derives `nonce + lba`, verifies
      every non-zero tag, and prints `VOL PASS 00000010` for a 16-sector volume
      or `VOL PASS 00000003` for a lazy image with sector 2 populated.
- [x] Sparse arbitrary-size NSPV image/device manager (`tools/nan0s_fs.sh`):
      default 1 GiB at `~/nan0s_fs/nan0s_fs.img`, lazy `used` growth, `grow`,
      boot `--verify` plus `tools/nan0s_fs_boot.sh` Termux:Boot hook
      (`crypt/storage_boot_gate.sh`), guest header cart
      (`crypt/guest/nan0s_fs_check.nas`), Android **Fs** sparse-image button
      (arbitrary GiB, default 1, 64 GiB dialog cap).
- [x] nan0s_fs encrypted file layer: `crypt/nan0s_fs` mkfs/put/get/ls/rm/mv/
      df/compact/check/resize, superblock + chained directory blocks +
      contiguous file extents (arbitrary count), rename, first-fit free-extent
      reuse (58 extents, coalesced), compaction/defragmentation, guest `fs=`
      boot marker, guest superblock decrypt/auth (`nan0s_fs_meta.nan`),
      `crypt/nan0s_fs_gate.sh` + `nan0s_fs_meta_gate.sh` PASS C-core + x86 IDE.
- [ ] Guest-side directory/extent mount; subdirectories; larger/better free
      map than 58 superblock extents; chunked NSPF1 file reader; encrypted boot;
      Android SAF wiring for the volume picker; real-HDD validation.
