# Migration to NaN: Minimum Native Boundary

## Goal

Move every tool that can be NaN into NaN16. Leave only the smallest possible
native boundary: the code that must run before a NaN word can execute, and the
code that touches hardware the guest cannot touch safely.

The target is not "no native code." A machine must execute something before it
can execute NaN. The target is a **published, audited, minimal native core**,
with everything above it self-hosted in NaN.

## The layers

```
S0  boot sector             native, 512 B
S1  native core             x86 or AArch64, minimum
S2  nasm0 seed              NaN16 words, assembler
S3  system source           NaN16 text, packed
S4  shell, museum, tools    NaN16
S5  host test harness       scaffold only, outside the machine
```

S0 and S1 are the only native trust base. S2..S4 are NaN. S5 is not part of
the machine; it is a test bench that can be deleted.

## What S1 must provide

Keep this list as short as possible:

- fetch a 64-bit word from guest memory,
- decode both faces and check the gate,
- execute the NaN16 opcode,
- trap on a gate or bad op,
- read/write guest memory,
- read the clock,
- read the keyboard ring,
- write text cells and framebuffer bytes,
- port I/O (`OUTB`/`INB`) for the NaN16 VGA driver,
- halt.

Everything else is NaN: mode-set sequences, font, paging policy, allocator,
shell, loader, seals, assembler, disassembler, compiler, decompiler, image
builder, museum, and tests.

## Migration order

### Stage 1 - Freeze the Python reference

The Python tools remain as a reference oracle until the NaN version passes the
same vectors. They are not shipped as runtime. Every Python file gets a header:
`SCAFFOLD - reference only`.

### Stage 2 - NaN disassembler

Write `src/tools/disasm.nas`. Input: word address and count. Output: mnemonic,
predicate, class nibble, dual-face view. It reuses the nasm0 opcode tables.
Test: disassemble the selftest and compare with the Python disassembler.

### Stage 3 - NaN VM / interpreter

Write a NaN16-in-NaN16 interpreter. It executes a second VM instance in guest
memory. This is the debugger core (TODO D) and the replacement for
`nan16sim.py` inside the machine. The native core remains the outer interpreter.
Test: the same program trace as `nan16sim.py` on the selftest.

### Stage 4 - NaN assembler and build orchestrator

`nasm0` already assembles itself. Extend it to the full mnemonic table,
including the new ops (`FBINFO`, `VSYNC`, `FBCOPY`, `FBFILL`, `OUTB`, `INB`).
Write a NaN build orchestrator that reads a manifest, assembles cartridges,
seals them, and writes the image through the block layer. The Python
`mkimg1.py` becomes a reference only.

### Stage 5 - NaN image builder and loader

The loader is already NaN16 in the shell. The image builder becomes a NaN
program:
- read the manifest,
- assemble each cartridge,
- compute the dual-face seal,
- place the payload in the store,
- write the TOC,
- write the image to the allocation device.

The block layer is a NaN driver over ATA/AHCI/NVMe; the native core only
provides port I/O and DMA windows.

### Stage 6 - NaN compiler and decompiler

- Compiler: the C subset from TODO I. Tokenizer, parser, codegen NaN16.
- Decompiler: NaN16 words to a C-like listing, with predicate/class annotation.
- Disassembler: already Stage 2.
All three share the opcode tables and the nested-word metadata.

### Stage 7 - AArch64

- `nasm2`: an AArch64 emitter written in NaN16. Same source language, second
  backend. Test with an encoding suite (83-style, plus A64-specific vectors).
- AArch64 native core: the same S1 contract, written in AArch64 assembly,
  for bare-metal Pi/UEFI and for an AArch64 emulator.
- AArch64 emulator: a NaN16 interpreter of A64 instructions, so the museum can
  run AArch64 programs inside the NaN machine.

### Stage 8 - Native minimization

Measure S1 in bytes and instructions. Remove anything that can move up. The
target is a core small enough to audit by hand and reproduce from a published
listing. The boot sector and core are the only non-NaN artifacts.

## Nested NaNs

A NaN16 word is 64 bits: near head, 32-bit payload, far head. A nested NaN
stores an inner word across two outer words:

```
outer A payload = inner near head (16) || inner payload low 16
outer B payload = inner payload high 16 || inner far head (16)
```

Both outer words are class 10. The decoder reconstructs the inner 64-bit word,
checks the inner gate, and returns it. The pair is written in opposite byte
orders so the outer pair also votes. This gives:

- self-describing metadata (a word that contains a word),
- nested seals (outer seal over inner words),
- a natural place for the Orrery and exhibit transcript records,
- a double-endian redundancy at two levels.

Test: pack a legal inner word, corrupt one outer byte, confirm the vote fails
and the inner gate is not trusted.

## Double endianness as a first-class rule

- Every stored word is written in both faces.
- The seal checks near payload, far payload, and class channel.
- The loader checks the mirror law before execution.
- Paired structures (TOC, n16de, nested words) vote across faces.
- The disassembler shows both faces and the class nibble.
- The compiler emits both faces; the decompiler reads either and reports the
  other.

## What remains Python

Only the host test bench:

- `tools/textshot.py`, `tools/fbshot.py`: screenshot rendering.
- `tools/harness/*.mjs`: v86 test driver.
- `tools/gen_*.py`: source generators for long museum text and fonts.

These are not part of the machine. They can be deleted without changing the
image. The migration target is that no runtime path depends on them. The
release still ships the generated `.nas` and `.nan` files.

## Gates

- S1 size and instruction count published.
- nasm0 fixed point passes.
- NaN disassembler matches Python on the corpus.
- NaN VM matches nan16sim on the selftest trace.
- NaN image builder produces a byte-identical image to mkimg1.py.
- Nested NaN pack/unpack passes corruption tests.
- AArch64 emitter passes its encoding suite.
- AArch64 core boots the same NaN image.
- Every Python scaffold is marked reference-only or removed.
