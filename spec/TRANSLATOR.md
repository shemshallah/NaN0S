# Three-File NaN Translator

## Goal

One NaN16 front end, two native back ends:

```
src/translate/common.nas   NaN16 IR, operand model, byte emitters
src/translate/x86.nas      x86 encoders
src/translate/a64.nas      AArch64 encoders
```

The translator reads NaN16 source/IR and emits x86 or AArch64 bytes. It is
itself NaN16. The native core only executes the translator.

## Common IR

`common.nas` owns:

- opcode IDs and mnemonic hashes,
- predicate/class mapping,
- operand form (`d`, `a`, `b`, `i`, `j`),
- label and relocation records,
- `common_emit8`, `common_emit16`, `common_emit32`,
- little-endian byte writing into a guest buffer,
- error codes for unsupported forms.

The IR is the same for both backends. A backend never parses text; it consumes
the IR.

## x86 backend

`x86.nas` owns:

- REX/ModRM/SIB encoding,
- immediate widths,
- the x86 mnemonic table (the same table as nasm1),
- fixed encodings for NOP, RET, INT3, MOV, ADD, SUB, CMP, JMP, CALL, etc.

The existing `src/prog/nasm1.nas` is the reference. The long-term move is to
extract its encoder bodies into `x86.nas` and have nasm1 call them.

## AArch64 backend

`a64.nas` owns:

- fixed 32-bit instruction words,
- register fields Rd/Rn/Rm,
- MOVZ/MOVK, ADD/SUB, CMP, B/BL, RET, BR, SVC, HLT,
- little-endian emit through `common_emit32`.

The first slice implements NOP, RET, BR, MOVZ, ADD, SVC, HLT. The encoding
test compares the emitted words to the ARM ARM values.

## Self-hosting

The translator is a NaN16 program. It can be loaded as a cartridge, fed a
source buffer, and asked to emit bytes. `nbuild` uses it to produce the native
image and the AArch64 image. The host Python tools are reference only.

## Gates

- `translate_test.nas` emits A64 NOP/RET and x86 RET, reads them back, PASS.
- A64 encoding suite: NOP, RET, BR, MOVZ, ADD, SVC, HLT.
- x86 encoding suite: the existing 83/83 nasm1 tests.
- The same IR emits both backends.
- No Python in the translator path.
