# NaN/0S TODO (round 22) - carried from r20. F, A, C are STILL NOT IMPLEMENTED in kan16.xa (verified r21: tbl 0x12 and 0x1A both h_key, h_tick = STEPS/1000, no IDT, boot SI=136). Baseline gate r21: nasm1check PASS (boot 512 + kernel 4402 identical, 83/83, selftest v86 match). Run with TMPDIR=/tmp and `mkdir -p /tmp/opencode`; use bash/sh, not `time (...)` in dash.

## R21 RECURSIVE PLAN, bare-metal leaves (order F -> A -> C; STI only after BOTH copies)
L0 goal: real clock + cartridge store + keyboard IRQ, kernel stays <= 8192 B (code ends 0x6CB; ~2.3 KB free before .org 0x1000 data).
F. clock
 F1 hw_init (call after the two REPMOVSD copies, before `XOR %ESI,%ESI`; IF is 0 since boot CLI)
  F1a IDT zero: EDI=0x9000, EAX=0, ECX=512, REPSTOSD.
  F1b mkgate(EDI=&gate, EAX=handler): w0=(off&0xFFFF)|0x80000, w1=(off&0xFFFF0000)|0x8E00, EDI+=8; clobbers EDX only. (Selector 8 = GDT code 0x00CF9A00; 0x8E = 32-bit interrupt gate DPL0, so IF clears on entry.)
  F1c exceptions: 32 stubs of 4 B each `PUSH $n (6A nn); JMP rel8 (EB 124-4n)` to xc; xc: POP %ESI; MOV $0x58,%EAX; JMP @trap. Output '!X000n' (trap prints 4 hex digits min). Gates 0..31 via loop with EAX+=4. Reuses existing trap/out1 (serial polled, no IRQ needed).
  F1d IRQ gates: 0x20 @0x9100 -> irq0, 0x21 @0x9108 -> irq1 (iret stub until C), 0x27 @0x9138 and 0x2F @0x9178 -> iret stub (.byte 0xCF). LIDT [idtr]; idtr = .word 2047,.long 0x9000 written as .word/.long.
  F1e port table loop (port,val pairs, 0 terminated; `OUT %AL,%DX` then `OUT %AL,$0x80` as I/O delay for real HW): 20<-11, A0<-11, 21<-20, A1<-28, 21<-04, A1<-02, 21<-01, A1<-01, 43<-36, 40<-A9, 40<-04, 21<-FE, A1<-FF. ESI is free here (re-zeroed after).
  F1f STI.
 F2 irq0: PUSH EAX; ADDL $65526,[MSF]; MOV [MSF],%EAX; SHR $16,%EAX; ANDL $0xFFFF,[MSF]; ADD %EAX,[MS]; MOV $0x20,%AL; OUT %AL,$0x20; POP EAX; .byte 0xCF. (65526 = round(1193000/1193182*65536); residual 0.055 ppm.) Interpreter keeps ESI/EDI/EBP across IRQs; handler touches only EAX, IRET restores EFLAGS.
 F3 h_tick: MOV [MS],%EBX; JMP @st.
 F4 accept: v86 TICK delta over 2 s = 2000 +-100; deliberate #UD prints '!X0006'; fuzz/traptest/native_check unchanged; difftest excludes TICK printers.
A. cartridge store
 A1 kboot0.xa: `MOV $136,%SI` -> `MOV $1024,%SI` (same 3 B; boot stays 512; gold bytes change in that immediate). 64 KB DMA boundary safe: each read is 512 B at segment multiples of 0x20. Last byte lands 0x8FFFF.
 A2 kernel: after image copy, REPMOVSD ECX=0x1BC00 from 0x21000 to 0x800000 (guest word 0xC0000). NOTE found r21: stack top 0x90000 grows down INTO the host store (0x8FFFx); harmless only because the store is dead after this copy and STI comes later. Keep that order.
 A3 TOC/seal/V_EXIT/mkmuseum20.py as in the r20 plan below (unchanged). Guest slot words 4096.. are zero in the image (museum uses 3073 words), so SLOT is free.
C. keyboard (IRQ1; master mask FE -> FC only in this item)
 C1 ktab grows to 384 B at .org 0x1000 area: [0..127] unshifted, [128..255] shifted, [256..383] E0 map (sc 0x47 home 84, 48 up 80, 49 pgup 86, 4B left 82, 4D right 83, 4F end 85, 50 down 81, 51 pgdn 87, 52 ins 88, 53 del 89; 0x2A/0x36 -> 0). Data ends ~0x1280 < 0x2000.
 C2 irq1: PUSH EAX,EBX; XOR EAX; IN $0x60,%AL; E0 byte -> E0=1, EOI. Break (bit7): E0 set -> clear E0 only; else sc&0x7F in {2A,36} -> SHIFT=0. Make: E0 set -> ch=ktab[256+sc], E0=0; 0x2A/0x36 -> SHIFT=1; 0x3A -> XORB $1,[CAPS]; else ECX=SHIFT, if ktab[sc] in 'a'..'z' (LEA -97, CMP 26, JAE) then ECX ^= CAPS; ch=ktab[(ECX<<7)+sc]. ch!=0 and ((RTAIL+1)&15)!=RHEAD -> KRING[RTAIL]=ch, RTAIL++. EOI 0x20; POP; .byte 0xCF.
 C3 h_key (0x12) blocking: loop { RHEAD!=RTAIL -> pop; else HLT }. Benign race (IRQ between test and HLT) is bounded to 1 ms by F's timer, so C depends on F. h_key2 (0x1A) non-blocking pop. Split the shared tbl entries. Single writer per index (IRQ writes RTAIL, main writes RHEAD).
 C4 accept: as r20 list.
OPEN leaves not yet expanded to bytes: lib_seal_verify loop (NaN16), nan16sim blocking KEY + scripted queue, nasm1check gold regeneration. D,E,B,G,H,I,L,M,N unchanged below; expand each to ports/addresses before starting it (G: VGA 0x3C0-0x3DA, FB 0xA0000; N: PIT ch2 port 0x42 + 0x61 bits 0-1; L: floppy INT13 not usable in PM -> needs FDC ports 0x3F0-0x3F7 + ISA DMA ch2, or real-mode thunk; M: separate aarch64 kernel).
r21b: src/draft/fck.draft.xa now holds F+C+exception-stub leaves; it ASSEMBLES under nasm1 (python3 tools/nasm1run.py src/draft/fck.draft.xa OUT.bin; ~1 KB incl. 384 B ktab). Not yet merged into kan16.xa, not yet booted. Draft uses mask 0xFC (C live). Bug caught in review: irq1 must save EAX,EBX,ECX,EDX (the interpreter holds operand values in ECX/EDX between decode and handler), irq0 only touches EAX. Merge steps: (1) paste hw_init/mkgate/xs/xc/irq0/irets/irq1/h_key/h_keyq/idtr/ptab into kan16.xa code area, ktab into data area, call hw_init after copies, tbl[0x12]=h_key tbl[0x1A]=h_keyq, h_tick replaced; (2) regenerate nasm1 gold; (3) v86 acceptance F4/C4.
r21 NOTE: no kernel/boot/guest source changed this round except the draft.


## ROUND 20 PLAN: three items, bare metal first. Order: F -> A -> C (C's IRQ1 stays masked until C lands).

### Host memory map (fixed, below G=0x200000)
0x7C00 boot | 0x8000-0x803F R[0..15] | 0x8040 FLAGM 0x8044 STEPS 0x8048 MAXS 0x804C T0 0x8050 KB 0x8054 OB (existing)
0x8058 MS (ms since boot, dword) | 0x805C MSF (Q16 fraction, dword) | 0x8060 SHIFT(b) 0x8061 E0(b) 0x8062 CAPS(b) | 0x8064 RHEAD(b) 0x8065 RTAIL(b)
0x8068 DISKW sector pos (L) | 0x8070-0x807F key ring (16 bytes)   [r19 had ring at 0x8064 overlapping 0x8068: fixed]
0x9000-0x97FF IDT (256 x 8 B) | 0x10000 kernel | 0x12000 guest image (7680 w) | 0x21000-0x8FFFF cartridge store (host) | 0x90000 stack top
0x200000 G = guest words (MASK 0xFFFFF = 1M words) | cartridge store copy at guest word 0xC0000 = host 0x800000.

### F. Real clock (PIT, IRQ0) - kernel only, ~120 B
Boot of the clock, in `_start` before `loop` (after the G copy):
1. IDT: zero 0x9000..0x97FF (REPSTOSD 512). Vector 0x20 -> irq0, 0x21 -> irq1 (stub iret until C), 0x27/0x2F -> iret. Gate = lo16(off)|0x0008<<16 , 0x8E00|hi16(off)<<16 (selector 8, 32-bit interrupt gate, DPL0). Exceptions 0..0x1F -> existing `trap` with code 'X' (otherwise a stray fault triple-faults silently). LIDT [idtr]; idtr = .word 2047 .long 0x9000 (two .long, no .quad).
2. PIC remap (IRQ0..7 -> 0x20.., IRQ8..15 -> 0x28..): OUT 0x11->0x20, 0x11->0xA0, 0x20->0x21, 0x28->0xA1, 0x04->0x21, 0x02->0xA1, 0x01->0x21, 0x01->0xA1; masks 0xFE->0x21 (only IRQ0), 0xFF->0xA1.
3. PIT ch0 mode 3: OUT 0x36->0x43; OUT 0xA9->0x40; OUT 0x04->0x40 (divisor 1193 = 0x04A9 -> 1000.1526 Hz). Uncorrected drift is 152.6 ppm (9 ms/min), so ms is kept exact with a Q16 step: 1193*1000/1193182*65536 = 65526.0036 -> 65526.
4. STI. (CLI stays in `done`/trap.)
irq0 (all regs saved, flags restored by IRET): PUSH EAX; ADDL $65526,[MSF]; MOV [MSF],%EAX; SHR $16,%EAX; ANDL $0xFFFF,[MSF]; ADD %EAX,[MS]; MOV $0x20,%AL; OUT %AL,$0x20; POP EAX; .byte 0xCF.
h_tick becomes: MOV [MS],%EBX; JMP @st (no DIV, no STEPS/1000). The interpreter keeps ESI/EDI/EBP live across IRQs: safe because the handler only touches EAX and IRET restores EFLAGS.
Model impact: tools/nan16sim.py TICK stays steps//1000 (deterministic); difftest/proofnat must exclude programs that print TICK values (selftest/baby), and a new v86 check compares native TICK deltas to harness wall time (+-5%).
Acceptance: (1) v86 boot, guest loops reading TICK, prints value at harness t=2s,4s: delta 2000 +-100; (2) fuzz/traptest/native_check unchanged; (3) trap text for a deliberate #UD is '!X06<pc>'.
Double-endian: MS is host state. Guest-visible mirror = ordinary LD of TICK result; sealing timing data is a guest concern (L4 over logged samples), not done in the kernel.

### A. Cartridge loader + ABI - boot, kernel, shell, lib, one build script
Bare metal:
1. boot (kboot0.xa): raise SI from 136 to 1024 sectors (stop before ES=0x9000 so data stays < 0x90000 = stack top): store = 0x21000..0x8FFFF = 888 sectors = 56,832 words. Same CHS loop (18 spt, 2 heads) -> cylinders 0..28. No INT 15h/unreal mode needed in this round; >512 KB floppy content is deferred (needs INT 15h AH=87h or unreal mode, after A20).
2. kernel: after the 7680-word image copy, second REPMOVSD ECX=0x1BC00 dwords from 0x21000 to host 0x800000 (guest word 0xC0000). Zero fill already covers it.
3. Guest memory map (words): 0-31 vectors | 32-511 lib | 512-1023 shell | 1024-1279 TOC (64 x 4) | 2048 strings | 4096-0xFFFF SLOT (61,440 w) | 0x10000-0x1FFFF exhibit heap/stack | 0x20000-0x8FFFF compiler/engine zones (item I) | 0xC0000-0xCDFFF cartridge store | rest reserved.
4. TOC entry (4 words): W0 year(16)|hall(8)|badge(8, 1 EXACT 2 RE-CREATION 3 INSPIRED) | W1 title_word_addr(16)|store_off(16, words from 0xC0000) | W2 length words (<=61,440) | W3 seal.
5. Seal (L4), payload 32 bits: A=sum payloads, B=sum bswap32(payload) (read through the mirror face: BSWAPM+LD+BSWAPM), C=xor-fold of the class nibbles (LDN), D=rotating xor over both faces; S = A ^ ROL(B,8) ^ ROL(C,16) ^ ROL(D,24). lib_seal_verify(r1=addr, r2=len, r3=expected) -> r1=1/0 (replaces the always-1 stub; the r19 call passed @baby_len, a label, not a length). Mismatch -> shell prints '!S' + slot id, never runs.
6. Run protocol fixes found in r19: shell must CALL 4096 (JMP left r15 stale), and lib routines clobber r15, so an exhibit cannot RET safely. New vector V_EXIT=12 (JMP @sh_return); exhibits end with JMP @v_exit. ABI vectors 1-11 unchanged.
7. tools/mkmuseum20.py (single new tool): packs exhibits into the 888-sector region, writes TOC + seals, builds the 1.44 MB image via mkimg1 logic. Baby moves out of the image into a cartridge (image rule).
Acceptance: seal flip of one payload bit AND one class bit each caught; Baby runs from cartridge and returns to the menu; a 3000-word dummy cartridge at store_off 50000 loads; v86 end-to-end.

### C. Keyboard: IRQ1, Shift, arrows, ring, blocking KEY - kernel only, ~170 B
1. Unmask IRQ1 (master mask 0xFC) only in this item; vector 0x21 -> irq1.
2. Tables: ktab 128 bytes unshifted + 128 shifted at +128 (set-1 make codes), 256 B in the data area (kernel stays < 8192). Specials: 0x2A/0x36 shift, 0x3A caps (toggle on make), 0xE0 prefix sets E0 flag; with E0: 0x48 up 0x80, 0x50 down 0x81, 0x4B left 0x82, 0x4D right 0x83, 0x47 home 0x84, 0x4F end 0x85, 0x49 pgup 0x86, 0x51 pgdn 0x87, 0x52 ins 0x88, 0x53 del 0x89; E0 2A / E0 36 (fake shifts) ignored.
3. irq1: PUSH EAX,EBX; IN $0x60,%AL; E0 byte -> set E0, EOI; bit7 set (break) -> only shift release clears SHIFT; make -> index = sc (+128 if SHIFT, Caps flips letters), translate, 0 = ignore, else push to ring if ((RTAIL+1)&15) != RHEAD (drop on full); clear E0; EOI 0x20; POP; .byte 0xCF.
4. Ops: KEY (0x12) blocking = loop {if RHEAD!=RTAIL pop; else HLT} with IF=1 (IRQ wakes HLT); KEYQ (0x1A) = non-blocking pop or 0. The tbl entries for 0x12 and 0x1A were both h_key in r19; split them. VM step counter keeps counting only executed ops.
5. Ring holds host bytes; the NaN-word class-nibble key encoding from r19 is dropped from the kernel (no integrity gain on a 1-byte host ring); a guest may re-wrap keys in NaN words.
Acceptance (harness boot.mjs t:scancode list): Shift+1 -> '!'; E0 48 -> 0x80; release codes enqueue nothing; 20 rapid keys with no reader keep the first 15, no hang; blocking KEY returns only after a key; menu '1' still opens the exhibit.

### Model/test follow-ups
nan16sim.py: KEY blocking + scripted input queue so selftest/museum difftest keep passing; tools/nasm1check.sh gold bytes regenerate (kernel size changes from 4402) - update the gold file in the same commit as kan16.xa.

## (carried from round 19)

## ROUND 18 DONE (partial): exhibit cartridge system (A) working - shell fills vectors, displays menu, loads Baby exhibit via BCOPY, runs it, exhibit draws to screen. Vector class fixed to 15 (ALWAYS). BCOPY arg order fixed. BOOL.14 for OR. SHL by 24 for JMP op. Baby exhibit converted to cartridge format.

## ROUND 18 IN PROGRESS: F (PIT), C (keyboard), D (debugger), E (trusting-trust), B (timeline), G (pixels), H (float), etc.

## ROUND 18 PLAN (read this first)

Image rule: the image is used EXCLUSIVELY for allocation (boot + kernel + empty guest slots). It does NOT store programs or the OS. Programs live as exhibit cartridges loaded into the fixed 60 KB guest slot (7,680 words) by the exhibit loader. The guest slot must handle NaN ports of Quake, Doom and other exhibits.

Every museum piece includes: date of event, people involved (alive/dead), history lesson (what/why), code lesson (what/how). Authenticity badge: EXACT / RE-CREATION / INSPIRED. MIPS ladder: VM speed vs each era's machine. All ROMs homebrew.

### Double-Endian Handling (applies to ALL exhibits)

The NaN16 word is the core data structure. Every exhibit leverages:
1. **Class nibble as function**: n=(c_near<<2)|c_far is truth table for f(a,b). BOOL_n computes across 32 lanes. Any 2-input Boolean function = one instruction.
2. **Two faces**: near (LE) and far (BE). Reading both gives n and rot2(n). Integrity checking + dual interpretation.
3. **Lane trick**: BOOL_n(0xCCCCCCCC, 0xAAAAAAAA) == n * 0x11111111. Opcode IS the output. Data words encode their own function.
4. **SWAR**: 32 parallel bit lanes. BOOL = 32 parallel 1-bit ops.
5. **Predicate**: Every op (except BOOL) predicated by bit (2Z+L) of n. Conditional execution encoded in data.
6. **Seal (L4)**: Sum payloads + sum bswap payloads + nibble fold + rotating xor. Detects single-bit errors in both faces.

### The Keystone: Exhibit Cartridges (A)

Format: TOC at guest word 1024, 4 words/entry, max 64:
- W0: year(16)|hall(8)|badge(8). badge: 1=EXACT, 2=RE-CREATION, 3=INSPIRED
- W1: title_offset(16)|storage_addr(16)
- W2: length (words)
- W3: seal (L4)

Loading: boot pulls floppy into high RAM. Shell verifies seal, BCOPYs exhibit into SLOT (word 4096), runs it. Exhibit exits with RET to shell.

ABI: jump-vector table at words 1-31. Each = JMP @lib (opcode 0x0A, class 10). V_PUTS=1, V_HEX=2, V_DEC=3, V_CLS=4, V_KEY=5, V_KEYQ=6, V_TICK=7, V_PUTC=8, V_BCOPY=9, V_SEAL_VERIFY=10, V_SEAL_SHOW=11, V_12..31 reserved (float, FB, sound). Lib clobbers r3-r9, r15. Exhibits assemble with .org 4096.

Seal verification: recompute A (sum payloads), B (sum bswap payloads), C (nibble fold), D (rotating xor). Compare. Mismatch → !S trap.

### NEXT (do in this exact order)

- [ ] F. Real clock (PIT) — DO FIRST. Needed for speed comparisons, Spacewar!, games.
  - IDT + IRQ0 handler. Channel 0 mode 3, divisor 1193 (1000 Hz). TICKS at 0x8058.
  - h_tick (bare metal): read TICKS. Host process: keep steps//1000.
  - TICK d returns ms since boot. Baby uses TICK for wall-time.
  - Double-endian: TICKS stored as NaN word (+q/+q). Seal covers timing data.

- [ ] A. Cartridge loader + ABI. TOC format, jump-vector table, slot copy, exit RET. (partially started in r17)
  - Shell fills vectors (STW class 10) at boot. Reads TOC, verifies seals.
  - On selection: BCOPY storage→SLOT, JMP SLOT. Exhibit RETs to shell.
  - Seal verification: recompute A/B/C/D. Mismatch → !S trap.
  - Double-endian: seal IS the double-endian trick.

- [ ] C. Keyboard: Shift, arrows and blocking KEY.
  - ktab: 128 entries (scancode→ASCII, Shift variant at +128). shift_state at 0x8060.
  - IRQ1 handler: read scancode from 0x60, update shift_state, translate, store in 16-entry ring buffer at 0x8064.
  - KEY: spin until buffer non-empty, pop, return. KEYQ: return 0 if empty.
  - Arrow codes: 0x80-0x89. Key codes stored as NaN words. Class nibble encodes modifier state.

- [ ] D. Word-inspector/debugger exhibit. Step, break, regs, dual-face disassembly.
  - Assembles at SLOT, calls lib via vectors. Uses VPEEK to read debuggee.
  - State: debuggee pc, r0-r15, Z/L flags, steps, break_addr.
  - Display: rows 0-3 regs hex, row 4 pc/flags/steps/break, rows 5-24 disasm.
  - Dual-face: near head, far head, class nibble n, predicate bit, decoded mnemonic. Class nibble IS truth table.
  - Keys: Space=step, B=break, C=continue, Q=quit.

- [ ] E. Trusting-Trust exhibit. Thompson 1984. nasm0 vs nasm1 vs scaffold DDC.
  - Three columns: nasm0 output, nasm1 output, scaffold output.
  - Pre-computed outputs for selftest.nas, museum.nas, nalloc_test.nas.
  - Live: run nasm1 on small .xa at exhibit time.
  - Match → "CLEAN". Mismatch → highlight + explain attack.
  - DDC relies on comparing diverse compiler outputs. Seal ensures exhibit data integrity.

- [ ] B. Timeline shell. Scrolling 1801→2026 spine built from TOC. Passport stamps exhibits run.
  - Shell reads TOC, displays 25 rows: year | title | badge | [run]/[stamped].
  - Scroll Up/Down (needs C). Enter runs exhibit.
  - Passport: 64-word bitmap at PASSPORT_ADDR. Set bit on completion.
  - Footer: "PASSPORT: N/64 stamped". Passport bits stored as NaN words (+q/+q). Class nibble encodes badge.

- [ ] G. Pixels. Mode 13h or VESA, a scaler, and a plasma exhibit.
  - Native: FBPUT d,a: mem[0xA0000+r[a]]=r[d]&0xFF. FBFILL d,a,b. VSYNC: wait retrace (port 0x3DA bit3).
  - Guest: DISPSET 0x13 → 320x200x256. Plasma: sin/cos of x,y,t with palette cycling. Scaler: nearest-neighbor.
  - Double-endian: palette entries as NaN words. Class nibble encodes color channel (R=0,G=1,B=2). BOOL lanes compute plasma in parallel: 32 pixels/instruction.

- [ ] H. Float library. FEXP/FSIN/FCOS/FATAN2 as NaN polynomials.
  - New vectors: V_FEXP=12, V_FSIN=13, V_FCOS=14, V_FATAN2=15.
  - FEXP: range reduction + Taylor/Padé. FSIN/FCOS: range reduction to [-π/2,π/2] + Taylor. FATAN2: Hastings polynomial.
  - Double-endian: float values ARE NaN words (payload IS float bits, head tags as float class 2/3). Class nibble distinguishes float from int. Type punning for free.

- [ ] I. NaN C-subset compiler. Gate to Doom and the LM.
  - Scope: int, float, char, pointers, if/else, while, for, return, break, functions, arrays, operators.
  - Pipeline: Lexer → Parser (recursive descent) → Codegen → nasm0 assembler.
  - Memory: Source 0x20000-0x3FFFF, AST 0x40000-0x5FFFF, output 0x60000-0x7FFFF, symbols 0x80000-0x8FFFF.
  - Double-endian: AST nodes as NaN words. Class nibble encodes node type (expr=0, stmt=1, decl=2, func=3). BOOL lanes compile expressions in parallel.

- [ ] L. DISKW persistence. Passport, Hall of NaN scores and saved edits.
  - Native: DISKW addr,count: write count words to floppy at current sector. Track sector position at 0x8068.
  - Guest: Passport bitmap persists. Hall of NaN scores persist.
  - Double-endian: persisted words verified on reload via seal. Disk corruption detected by face mismatch.

- [ ] M. AArch64 emitter. One image booting on both x86 and a Pi.
  - kan16_aarch64.s mirroring kan16.s. UEFI or Pi bare-metal. PL011 UART, mailbox framebuffer.
  - Double-endian: same word format. AArch64 has bswap (REV). Trick works identically.

- [ ] N. PC-speaker sound. CSIRAC-style music.
  - BEEP op exists (0x1B). Music player: note sequence → BEEP + TICK wait. CSIRAC tunes: "Colonel Bogey".
  - Double-endian: note frequencies as NaN words. Class nibble encodes duration (short=0, medium=1, long=2, rest=3).

## ENGINES (all NaN): NaN compiler (C-subset -> NaN16/NaNVM1), float lib, FB/scaler, WAD loader, Doom, then Quake, then LM

## MUSEUM PIECES (all homebrew ROMs — no copyrighted ROMs)

Every museum piece: date, people (alive/dead), history lesson, code lesson. Authenticity badge: EXACT / RE-CREATION / INSPIRED.

### Hall 0: Before electrons (9 exhibits)
- [ ] Antikythera gear train (c.100 BCE) — Greek craftsmen (died) — lunar phase from gear ratios (Metonic 235/19, Saros 223/18.03). Code: gear ratio multiplication, moon phase. Double-endian: gear ratios as NaN words, class nibble encodes gear type (sun=0, planet=1, moon=2, pointer=3). BOOL lanes compute all gear positions in parallel.
- [ ] Napier's bones (1617) — John Napier (died 1617) — multiplication aid (lattice method). Code: digit multiplication via bone strips. Double-endian: bone strips as NaN words, class nibble encodes digit position.
- [ ] Jacquard loom (1804) — Joseph Marie Jacquard (died 1834) — punch cards controlling weave. Code: punch card → pattern, weaving on screen. Double-endian: punch card as NaN word (holes=1). BOOL computes weave pattern.
- [ ] Babbage Difference Engine (1822) — Charles Babbage (died 1871), Ada Lovelace (died 1852) — method of differences for polynomial tabulation. Code: finite differences, polynomial evaluation. Double-endian: difference table as NaN words. BOOL lanes compute finite differences in parallel.
- [ ] Ada's Note G Bernoulli (1843) — Ada Lovelace (died 1852) — first published program. Code: Bernoulli number computation. Double-endian: Bernoulli coefficients as NaN words.
- [ ] Boole 16 functions (1854) — George Boole (died 1864) — Boolean algebra. Code: BOOL op IS Boole; explore all 16 functions via truth tables. Double-endian: class nibble IS the truth table. Most direct demonstration of double-endian.
- [ ] Turing machine (1936) — Alan Turing (died 1954) — universal computation. Code: tape, head, state machine; universal TM. Double-endian: state transition table encoded in class nibble. Each state = one NaN word.
- [ ] Zuse Z3 (1941) — Konrad Zuse (died 1995) — first programmable computer, binary float. Code: 22-bit float, relay logic emulation. Double-endian: Z3's 22-bit float mapped to NaN word payload. Two faces show float in two endiannesses.
- [ ] ENIAC π digits (1949) — Eckert (died 1995), Mauchly (died 1980) — first electronic computer, π to 2000 digits. Code: Monte Carlo or series. Double-endian: π digits as NaN words. SWAR lanes compute digits in parallel.

### Hall 1: Dawn (7 exhibits)
- [x] Baby 1948 (done, RE-CREATION) — Williams (died 1977), Kilburn (died 2001), Tootill (died 2017) — first stored-program computer.
- [ ] EDSAC initial orders (6 May 1949) — Maurice Wilkes (died 2010) — first practical stored-program computer. Code: initial orders (bootstrap), subroutine library.
- [ ] CSIRAC tunes (1951) — Pearcey (died 1998), Beard (died 2003) — first computer music. Code: note generation via timing loops (needs N sound).
- [ ] Strachey draughts/love letters (1952) — Christopher Strachey (died 1975) — first game AI + generative text. Code: draughts minimax, love letter template.
- [ ] SWAC Lucas-Lehmer (1952) — Derrick Lehmer (died 1991), Emma Lehmer (died 2007) — Mersenne prime hunt. Code: Lucas-Lehmer test.
- [ ] Apollo DSKY + 1202 (20 July 1969) — Margaret Hamilton (alive), Don Eyles (alive) — guidance computer, 1202 alarm. Code: DSKY display, 1202 (executive overflow) simulation. Double-endian: DSKY display as NaN words.
- [ ] Core memory (1950s) — Jay Forrester (died 2016) — magnetic core memory. Code: core plane visualization, read/write/refresh.

### Hall 2: Languages (9 exhibits)
- [ ] Lisp eval (1958) — John McCarthy (died 2011) — "Maxwell's equations of software." Code: eval in NaN, S-expressions, cons cells. Double-endian: S-expressions as NaN words. Class nibble encodes type (atom=0, cons=1, lambda=2, quote=3).
- [ ] FORTRAN (1957) — John Backus (died 2007) — first high-level language. Code: FORTRAN subset → NaN16.
- [ ] ALGOL 60 (1960) — Naur, Dijkstra, et al. — structured programming. Code: ALGOL subset → NaN16.
- [ ] BASIC (1964) — Kemeny (died 2004), Kurtz (died 2017) — beginner's language. Code: BASIC interpreter in NaN.
- [ ] Forth (1970) — Charles Moore (alive) — stack-based, interactive. Code: Forth interpreter in NaN.
- [ ] Logo turtle (1967) — Papert (died 2016), Feurzeig (died 2013) — turtle graphics. Code: turtle with pen, commands (FD, BK, LT, RT).
- [ ] Tiny BASIC (1975) — Dennis Allison (died 2013) — minimal BASIC. Code: Tiny BASIC interpreter.
- [ ] Brainf*** (1993) — Urban Müller (alive) — esoteric language. Code: BF interpreter.
- [ ] C-subset compiler (gated by I).

### Hall 3: Games (10 exhibits)
- [ ] Spacewar! (1962) — Steve Russell (died 2024), et al. — first video game. Code: two ships, gravity, torpedoes.
- [ ] Pong (1972) — Allan Alcorn (alive) — first commercial game. Code: paddles, ball, score.
- [ ] Life (1970) — John Conway (died 2020) — cellular automaton. Code: grid, rules, glider gun. Double-endian: 3x3 neighborhood. BOOL computes next state from 9 inputs in 2 stages.
- [ ] Hunt the Wumpus (1972) — Gregory Yob (died 2005) — text adventure. Code: dodecahedron cave, wumpus, pits, bats.
- [ ] Colossal Cave (1976) — Crowther (alive), Woods (alive) — adventure game. Code: room graph, inventory, parser.
- [ ] Tetris (1984) — Alexey Pajitnov (alive) — falling blocks. Code: 7 tetrominoes, rotation, line clear.
- [ ] Core War (1984) — Jones (alive), Dewdney (alive) — programming game. Code: Redcode VM, warriors. Double-endian: instructions are NaN words. Class nibble = opcode.
- [ ] Snake (1976) — Gremlin Industries — classic. Code: snake, food, collision.
- [ ] Turochamp/holographic chess (1948) — Alan Turing (died 1954) — first chess program. Code: chess with holographic display.
- [ ] Lunar Lander (1979) — Atari — physics game. Code: thrust, gravity, fuel, landing.

### Hall 4: Graphics and demoscene (8 exhibits)
- [ ] Munching Squares (1962) — PDP-1, Jack Dennis (alive) — XOR pattern. Code: XOR of coordinates → pattern.
- [ ] Bresenham (1962) — Jack Bresenham (alive) — line drawing. Code: Bresenham's algorithm.
- [x] Sierpinski (done, r14) — fractal. Code: Sierpinski triangle.
- [ ] Plasma and fire — demoscene classic. Code: sin/cos plasma, fire effect. (needs G)
- [ ] Mandelbrot/Julia — fractals. Code: complex iteration, color mapping.
- [ ] donut.c (2006) — Andy Sloane (alive) — rotating donut. Code: donut with float lib. (needs H)
- [ ] Raycaster — pseudo-3D. Code: ray casting, texture mapping.
- [ ] Doom/Quake — gated by I + H.

### Hall 5: Crypto and math (7 exhibits)
- [ ] Euclid's GCD (c.300 BCE) — Euclid (died) — oldest algorithm. Code: Euclidean algorithm.
- [ ] Sieve of Eratosthenes (c.200 BCE) — Eratosthenes (died) — prime sieve. Code: sieve.
- [x] Collatz (done, in selftest) — Lothar Collatz (died 1990) — 3n+1.
- [ ] Enigma + Bombe (WWII) — Turing (died 1954), Welchman (died 1985) — cipher + cryptanalysis. Code: Enigma machine, Bombe crib attack.
- [ ] Toy RSA + DH (1976/77) — Diffie (alive), Hellman (alive), Rivest (alive), Shamir (alive), Adleman (alive) — public key crypto. Code: modular exponentiation, key exchange.
- [ ] SHA-256 (2001) — NSA — hash function. Code: SHA-256 implementation. Double-endian: BOOL lanes for parallel bit operations. Seal provides integrity.
- [ ] Lamport signatures (1979) — Leslie Lamport (alive) — one-time signatures. Code: hash-based signatures.

### Hall 6: Machines inside machines (6 exhibits)
- [ ] Gate-level CPU from NAND — digital logic. Code: NAND → gates → ALU → CPU.
- [ ] Intel 4004 + 6502 emulators (1971/1975) — Faggin (alive), Peddle (died 2019). Code: 4-bit/8-bit CPU emulation.
- [ ] CHIP-8 (1977) — Weisbecker (died 2016). Code: CHIP-8 interpreter.
- [ ] PDP-8 (1965) — DEC. Code: PDP-8 emulation.
- [ ] RISC pipeline visualizer — pipeline stages. Code: 5-stage pipeline animation.
- [ ] SWAR lanes — BOOL trick generalized. Code: SIMD within a register. Double-endian: generalized lane operations.

### Hall 7: Systems and OS (7 exhibits)
- [ ] Boot sector self-disassembler — disassemble own 512 bytes. Code: disassembler.
- [ ] A20 gate — keyboard controller hack. Code: A20 enable/disable.
- [ ] Atlas paging (1962) — Kilburn (died 2001). Code: paging simulation.
- [ ] Timesharing scheduler — round-robin. Code: scheduler simulation.
- [ ] nalloc first-fit vs buddy — allocator comparison. Code: animated allocation.
- [ ] FAT12 reader — read boot floppy. Code: FAT12 parsing.
- [ ] Unix pipes and regex (1969/1970s) — Ken Thompson (alive). Code: pipe + regex demo.

### Hall 8: Codes and networks (5 exhibits)
- [ ] Hamming + Golay codes (1950/1949) — Hamming (died 1998), Golay (died 1984). Code: error correction.
- [ ] Class-nibble integrity channel — live. Code: integrity demo. Double-endian: the integrity channel IS the double-endian trick.
- [ ] ARPANET "LO" (1969) — Kleinrock (alive). Code: first message simulation.
- [ ] Ethernet (1973) — Metcalfe (alive). Code: Ethernet frame simulation.
- [ ] NaNNet loopback — COM1. Code: custom network stack.

### Hall 9: Road to the LM (7 exhibits)
- [ ] Markov's Onegin (1913) — Andrey Markov (died 1922). Code: Markov chain vowels.
- [ ] Shannon n-gram (1948) — Claude Shannon (died 2001). Code: n-gram text generation.
- [ ] ELIZA (1966) — Joseph Weizenbaum (died 2008). Code: pattern matching chatbot.
- [ ] Perceptron XOR/backprop (1958/1986) — Rosenblatt (died 1971). Code: perceptron fails XOR, backprop fixes. Double-endian: weights as NaN words. Class nibble = activation function type.
- [ ] Hopfield memory (1982) — John Hopfield (alive). Code: associative memory.
- [ ] Char-level RNN — recurrent neural network. Code: char RNN in NaN.
- [ ] Tiny transformer (260K params, TinyStories) — transformer in NaN float32. Double-endian: weights are NaN words. Class nibble = seal. Two faces provide integrity for every weight. (needs I + H)

## Capstone: LM/OS Hybrid
1. Shell takes plain-English commands via hashed bag-of-words match over plaques.
2. Docent narrates each exhibit from plaque text (n-gram → transformer).
3. Final exhibit: the shell itself. Weights are NaN words, sealed by class nibble.
Double-endian: transformer runs on NaN words natively. Class nibble = seal for every weight.

## Features
- S key: shows running exhibit's source + both word faces.
- Authenticity badge: EXACT / RE-CREATION / INSPIRED.
- MIPS ladder: VM speed vs era machines.
- Easter eggs: secret keys → Hall of NaN.
- ROMs: homebrew only.

## Recommended r18 Scope

Must have: F, A, C, D, E, B + Hall 0 (9 exhibits)
Should have: G, H, N + Hall 1 (6 exhibits)
Nice to have: L, M
Deferred: I, remaining museum pieces

## Build
sh tools/build.sh | python3 tools/mkproof.py TARGET.nas --run [--big] | sh tools/nasm1check.sh

Round 16 BARE build (no as): python3 tools/mkimg1.py src/boot/kboot0.xa src/native/kan16.xa GUEST.nas OUT.img

r18 build: python3 tools/mkmuseum18.py OUT.img (to be created)

Contact shemshallah@gmail.com. Started OCT26 2026.