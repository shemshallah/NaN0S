<div align="center">

<img src="assets/nan0-banner.svg" alt="NaN/0" width="100%"/>

<br/>

![](https://img.shields.io/badge/-7ff8-0b0b1a?style=flat-square&labelColor=0b0b1a&color=8f9bff)
![](https://img.shields.io/badge/-%E2%96%88%E2%96%88%E2%96%88%E2%96%88-ff2bd6?style=flat-square)
![](https://img.shields.io/badge/-%E2%88%85-39ff14?style=flat-square)
![](https://img.shields.io/badge/-NaN%20!%3D%20NaN-00f0ff?style=flat-square)

*there is a number that isn't one.*
*there is an operation that isn't allowed.*
*you have been asked to put them together.*

<img src="assets/nan0-rule.svg" alt="" width="100%"/>

</div>

<br/>

## `> transcript`

NaN/0S round 22 (draft round; r21 plan: PIT clock, cartridge loader, keyboard IRQ). A from-scratch bare-metal OS whose every layer above a ~1.5 KB native boundary is NaN words (64-bit IEEE encodings carrying 16-operand logic). It boots from a floppy, runs a museum of computing history, and grows into an LM/OS hybrid.

## Image rule (r17)

The image is used EXCLUSIVELY for allocation: boot sector + kernel + empty guest slots. It does NOT store programs or the OS. Programs live as exhibit cartridges loaded into the fixed 60 KB guest slot (7680 words) by the exhibit loader, then run via RET to the shell. No re-uploading of a 1 GB+ image.

The guest slot is large enough to hold NaN ports of Quake, Doom and other exhibits.

## `> keystone: exhibit cartridges`

Format: a TOC in the image with one entry per exhibit: year, hall, title, start, length, authenticity badge (EXACT / RE-CREATION / INSPIRED), and a seal (INTEGRITY L4).

Loading: boot pulls the whole floppy into high RAM, so no disk driver is needed. The shell verifies the seal, BCOPYs the exhibit into a fixed slot, and runs it.

ABI: the lib sits behind a fixed jump-vector table, so exhibits assemble independently with `.org`. An exhibit exits with RET to the shell.

Bonus: the TOC sorted by year gives you the walk for free.

## `> manifest` (round 17 TODO order)

A. Cartridge loader + ABI (unlocks everything else)
F. Real clock (PIT) - DO FIRST (speed comparisons, Spacewar!, games)
C. Keyboard: Shift, arrows and blocking KEY
D. Word-inspector/debugger exhibit: step, break, regs, dual-face disassembly
E. Trusting-Trust exhibit: nasm0 vs nasm1 vs scaffold DDC
B. Timeline shell: scrolling 1801 -> 2026 spine, passport stamps exhibits run
G. Pixels: Mode 13h / VESA, scaler, plasma
H. Float library: FEXP/FSIN/FCOS/FATAN2 as NaN polynomials
I. NaN C-subset compiler: gate to Doom and the LM
L. DISKW persistence: passport, Hall of NaN, saved edits
M. AArch64 emitter: one image, x86 and Pi
N. PC-speaker sound: CSIRAC-style music

Engines (all NaN): NaN compiler, float lib, FB/scaler, WAD loader, Doom, Quake, LM

## `> the museum`

Every exhibit is a program the menu loads and runs. Every museum piece carries:
- date of event
- people involved (alive / died)
- history lesson (what was important and why)
- code lesson (what the code actually does and how)

Authenticity badge: EXACT / RE-CREATION / INSPIRED. The Baby program is flagged honestly as RE-CREATION (20-instruction re-creation, not Kilburn's 17-instruction listing).

MIPS ladder: VM speed against each era's machine.

All ROMs are homebrew — no copyrighted ROMs shipped.

### Hall 0: Before electrons
Antikythera gear train · Napier's bones · Jacquard loom · Babbage Difference Engine · Ada's Note G Bernoulli · Boole 16 boolean functions · Turing machine · Zuse Z3 · ENIAC pi digits

### Hall 1: Dawn
Baby 1948 (done) · EDSAC initial orders · CSIRAC tunes · Strachey draughts/love letters · SWAC Lucas-Lehmer · Apollo Guidance Computer DSKY + 1202 alarm · Core memory

### Hall 2: Languages
Lisp eval · FORTRAN · ALGOL 60 · BASIC · Forth · Logo turtle · Tiny BASIC · Brainf*** · C-subset compiler

### Hall 3: Games
Spacewar! · Pong · Life (glider gun) · Hunt the Wumpus · Colossal Cave adventure · Tetris · Core War · Snake · Turochamp/holographic chess · Lunar Lander

### Hall 4: Graphics and demoscene
Munching Squares · Bresenham · Sierpinski (done) · Plasma and fire · Mandelbrot/Julia · donut.c · Raycaster · Doom · Quake

### Hall 5: Crypto and math
Euclid GCD · Sieve of Eratosthenes · Collatz · Enigma+Bombe · Toy RSA + Diffie-Hellman · SHA-256 · Lamport signatures

### Hall 6: Machines inside machines
Gate-level CPU from NAND · Intel 4004 + 6502 emulators · CHIP-8 · PDP-8 · RISC pipeline visualizer · SWAR lanes

### Hall 7: Systems and OS
Boot sector self-disassembler · A20 gate · Atlas paging · Timesharing scheduler · nalloc first-fit vs buddy · FAT12 reader · Unix pipes and regex

### Hall 8: Codes and networks
Hamming + Golay codes · class-nibble integrity channel · ARPANET "LO" · Ethernet · NaNNet loopback over COM1

### Hall 9: The road to the LM
Markov's Onegin · Shannon n-gram · ELIZA · Perceptron XOR/backprop · Hopfield memory · Char-level RNN · tiny transformer (NaN float32)

## `> capstone: LM/OS hybrid`

1. Shell takes plain-English commands ("show me the first stored program") via hashed bag-of-words match over plaques.
2. A docent narrates each exhibit from its plaque text (n-gram model, later the transformer).
3. Final exhibit: the shell itself. Weights are NaN words, each sealed by the class nibble.

## `> features`

- S key: shows any running exhibit's own source and both word faces.
- Authenticity badge: EXACT / RE-CREATION / INSPIRED.
- MIPS ladder: VM speed against each era's machine.
- Easter eggs: secret keys feed the Hall of NaN.
- ROMs: homebrew only.

## `> door`

```sh
git clone https://github.com/shemshallah/nan0
# the door is painted on.
```

⭐ if you understood any of this.
⭐⭐ if you didn't, and it bothered you.

<br/>

<div align="center">

`7ff8 ····`

**`NaN ≠ NaN`**

<sub>divide by nothing. get everything.</sub>

</div>
