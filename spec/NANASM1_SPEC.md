# NANASM1 - the x86 emitter written in NaN16 (round 16)

Status: DONE. `src/prog/nasm1.nas` is a two-pass x86 assembler written entirely in
NaN16 (double-endian) guest code. It turns the `.xa` sources in this tree into the
exact bytes of the BARE build: boot sector 512 B, kernel 4402 B, 4914 B total,
byte-identical to `src/native/nan16_x86.nan` (the round-15 gold). Boot and kernel
now build with no `as`.

The CPU still executes x86 - it must. What changed is who writes those bytes: a
NaN16 program, run by NaNVM1, emits them. `as` is no longer in the build path.

## How to run it

    python3 tools/nasm1run.py FILE.xa OUT.bin      # one file through the model
    python3 tools/mkimg1.py BOOT.xa KERNEL.xa GUEST.nas OUT.img
    sh tools/nasm1check.sh                        # gold bytes + 83 tests + v86 boot

`tools/nasm1run.py` packs the minified `.xa` text (4 chars/word, LSB first) at
guest word 0x20000, runs nasm1 in `tools/nan16sim.py`, splits the status line and
writes the rest as the binary. `tools/mkimg1.py` composes boot + kernel (8 KB
slot) + guest words (60 KB) into a 1.44 MB floppy image.

## Source language (`.xa`)

- `;` starts a comment (inside `"..."` it does not).
- Mnemonics, register names, directive names and label lookups are
  case-insensitive (hash is djb2/5381 over the uppercased name).
- One statement per line. `label:` may be followed by a statement on the same
  line (`pm: HLT`).
- Labels: `[A-Za-z_][A-Za-z0-9_]*`, no dots, no numeric local labels (`1:` is not
  supported; use `L1:`).
- References: `@label`, `#EQU`, or a bare name (all three resolve through the
  same label/equ table). Inside `[...]` a bare name is a symbol unless it is a
  register.
- Numbers: decimal and `0x` hex (either case). Expressions are sums of terms
  with `+`/`-` and an optional leading `-`.
- Memory: `[disp]`, `[reg]`, `[disp+reg]`, `[base+index*scale+disp]`, with scale
  in {1,2,4,8} and any term order; `%` before registers is optional.
- Operand order is AT&T: `MOV src,dst`. `MOV %EAX,[X]` stores; `MOV [X],%EAX`
  loads. A register as the operand of `JMP`/`CALL` means indirect (`JMP %EAX`).

Directives:

    .byte e[,e...]   .word e[,e...]   .long e[,e...]   .str "text"
    .equ NAME expr   .org expr        .align n
    .base expr       .code16          .code32

`.base 0x7C00` / `.base 0x10000` makes labels absolute while output offsets stay
0-based; PC-relative branch math cancels the base. `.org 510` pads with zeros.
`.quad` is not implemented (write two `.long`s; that is how the GDT is done).

## Registers

    EAX ECX EDX EBX ESP EBP ESI EDI     32-bit gpr
    AX  CX  DX  BX  SP  BP  SI  DI      16-bit gpr
    AL  CL  DL  BL  AH  CH  DH  BH       8-bit gpr
    ES  CS  SS  DS  FS  GS              segment
    CR0 CR2 CR3                          control
    XMM0..XMM7                           SSE

## Instructions

Data: `MOV MOVB MOVW MOVL MOVZX MOVZXB MOVZXW MOVZBL MOVZWL MOVSX MOVSXB MOVSXW
MOVSBL MOVSWL MOVD MOVQ MOVQL MOVQS LEA PUSH POP XCHG`(no) `IN OUT`.
`MOVZX`/`MOVSX` pick 0F B6/B7 or 0F BE/BF from the source register class; the
suffixed forms are fixed.
ALU: `ADD OR AND SUB XOR CMP TEST INC DEC NOT NEG MUL IMUL DIV IDIV` with
`B/W/L` suffixes; two-operand `IMUL reg,reg` and `IMUL $imm,reg` are supported
(the one-operand form goes through F7 /5).
Shifts: `SHL SAL SHR SAR ROL ROR` by `$imm` or `%CL`, with `B/W/L` suffixes.
Control: `JMP CALL RET LOOP JECXZ` plus all `Jcc` (`JO JNO JB JC JAE JNC JE JZ
JNE JNZ JBE JA JS JNS JP JNP JL JGE JLE JG`) and all `SETcc`.
Bit/string: `BT BSWAP SHRD REPSTOSD REPMOVSD`.
System: `INT LGDT LIDT LJMP HLT CLI STI CLD STD CLC STC CLTD NOP`.
SSE single: `ADDSS SUBSS MULSS DIVSS SQRTSS UCOMISS XORPS CVTSI2SS CVTTSS2SI`.

Not implemented: CMOVcc, x87, AVX, MMX, segment-override prefixes, far CALL,
8-bit IMUL, `.quad`, `.include` in `.xa` (the emitter's own `nasm1_tables.nas`
is included by the scaffold assembler that builds nasm1).

## Encoding rules (matched to GNU as, proven by the gold bytes)

- Accumulator <-> absolute memory uses moffs A0-A3 (`MOV EAX,[addr]` = A1).
- Immediate ALU: byte ops use 80 /r ib (but AL uses 04/05/0C/... when the op has
  an accumulator form); wider ops prefer `83 /r ib` when the immediate fits
  signed 8, then the accumulator short form, else `81 /r id`.
- `TEST` has no 83 form: A8/A9 for AL/AX/EAX, F6/F7 otherwise.
- Reg-reg ALU uses the r/m,r direction with reg=src, rm=dst (so SUB/CMP keep
  their meaning); `TEST`/`XOR` match gas byte-for-byte.
- 16-bit INC/DEC use 40+r/48+r; 8-bit use FE /0 or /1.
- SIB: scale 1/2/4/8 -> 0/1/2/3, index 4 is illegal, no base -> base field 5
  plus disp32.
- Short-first branch relaxation: `jcc rel8` (2 B) grows to `0F 8x rel32` (6 B),
  `jmp rel8` (EB) to `E9 rel32` (5 B); `call` is always E8 rel32; `loop`/`jecxz`
  are rel8 only. Growth is iterated to a fixpoint.
- `.code16`/`.code32` control the 66 prefix: size 2 needs 66 only in 32-bit
  mode, size 4 needs 66 only in 16-bit mode.

## Output protocol and internals

stdout is `Y\n` (clean) or `N\n` (errors), then the raw bytes via PUTC.

Memory map: source text at 0x20000, output at 0x24000 (source area 0x20000..0x23FFF = 64 KB), label table 0x30000
(stride 2), long-branch map 0x31000 (8 bytes/branch), stack 0x3F000, variables
0x4000-0x4023, operand slots 0x4030 (8 words each: type, value, base, index,
scale, disp). Hash tables (mnemonics 3 words/entry, registers 2, directives 3)
are generated by `tools/gen_nasm1_tables.py`.

Passes: two warm-up pass1 runs (so forward `.long @handler` data labels exist),
then pass1 is repeated until no branch grew (`V_REDO==0`), then pass2 emits.
Labels and equs are upserted in the same table across passes.

## Honest limits

- `.xa` is a text language; it is not itself NaN16. The emitter is NaN16, the
  model that runs it is a Python scaffold (the same model used for every guest).
- Gas compatibility is proven on the instructions this system uses plus the
  83-case hand-checked suite; it is not a complete x86 assembler.
- The image still needs the Python model to execute nasm1. Running the emitter
  on bare metal (nasm1 as a guest of the booted kernel, reading `.xa` from disk)
  is the natural next step after the guest loader TODO.
- Not tested on real hardware; v86 is the x86 stand-in here.
