# NaNVM spec — one machine, one document (NaNVM0 / NaNVM1 / NaNNet VM)

Status: NaNVM0 is implemented (native boundary, 8192 words, x86 scaffold);
NaNVM1 is specified here (ops 0x20-0x37, flat memory; native implementation
pending); the NaNNet VM bytecode is the program format this machine executes.
There is no second VM document and no forked VM: NaNVM0 and NaNVM1 are
revisions of this one VM, and the NaNNet VM is its program format.

Rule: `NaNVM` is the machine. A revision bump edits this file; it never forks
a new filename. The names `NaNVM0` and `NaNVM1` remain valid in prose for the
revision being discussed, but all three names resolve to this document.

## 0. The three names

- **NaNVM0** — the VM as it exists: NaN16 v0.1 payload ops 0x00-0x1B,
  r0..r15, 8192 words, VGA text boundary (§1).
- **NaNVM1** — the same VM at revision 1: adds ops 0x20-0x37 (32-bit
  mul/div, signed math, byte access, block moves, float32) and 32-bit flat
  addressing; op set in §2-§3, native build plan in §4.
- **NaNNet VM** — the bytecode stack machine whose cells are
  `[op:8][arity:8]` followed by arity u16 immediates; it runs on
  NaNVM0/NaNVM1 and is the program format of the network/value carts (§5).

## 1. NaNVM0 — the base machine (NaN16 v0.1)

The word, registers, flags, memory and payload layout are defined in
`spec/NAN16_SPEC.md`. The VM adds:

- 8192-word memory (indices wrap `& 0x1FFF`), image loaded at word 0, pc
  starts at 0; r0=0, r13=1, r14=SP (software), r15=link (CALL/RET).
- Payload `[31:24]=op [23:20]=d [19:16]=a [15:0]=imm16`, `b = imm[3:0]`.
- `isa=0` keeps the rule that `op > 0x1F` traps `!O`.
- Boundary ops DISPQ/DISPSET on the native side (see the scaffold).
- Native boundary bytes: `x86/scaffold/nanvm0.s` (objdump-verified);
  `tools/mkbase.sh` derives `src/vm/nanvm0.nan` (hex dump of the bytes)
  and `x86/build/base.img`; the scaffold is held to 1536 bytes.
- Text boundary: VGA B800, 80x25.

## 2. NaNVM1 — new ops (v0.2 draft)

NaN16 v0.1 ops 0x00-0x1B are unchanged. Why: Quake needs 32-bit
multiply/divide, signed math, byte access, block moves and float32.
Without them every pixel and every vertex costs dozens of ops.

Payload `[31:24]=op, d, a, b=imm[3:0] or imm16`; predication as before.

    20 MUL d,a,b low32 | 21 MULH signed high32 | 22 MULHU
    23 DIV signed trunc | 24 MOD (sign of dividend) | 25 DIVU | 26 MODU
      divide/mod by 0: DIV/DIVU -> 0, MOD/MODU -> a, flags (Z,L)=(1,1)
      (only ALWAYS ops run next, so a [NE]/[EQ] guard skips)
    27 SAR d,a,imm5 | 28 CMPS a,b signed compare (Z=eq, L=signed lt)
    29 ADDI d,a,imm16 (sign-extended, L=carry; write -1 as 0xFFFF)
    2A LDB d,a,imm | 2B STB d,a,imm : byte address r[a]+imm, 4 bytes per
      word payload, little end first; STB rewrites the word as +q/+q
    2C CALLR a (r15=pc, pc=r[a])
    2D BCOPY d,a,b : b words from word r[a] to word r[d], memmove
      semantics, both-face class kept
    2E BFILL d,a,b : b words at r[d] = +q/+q payload r[a]
    2F reserved
    30 FADD 31 FSUB 32 FMUL 33 FDIV 34 FSQRT d,a 35 FCMP a,b
    36 CVTIF d,a 37 CVTFI d,a
      IEEE-754 binary32 in the payload, round to nearest even. FCMP sets
      Z=eq L=lt; unordered (NaN) sets (Z,L)=(1,1), the state the integer
      ops can never reach, so EQ/NE/LT/GT/LE/GE all skip. CVTFI truncates,
      saturates, NaN -> 0. Negate/abs = BOOL with 0x80000000 / 0x7FFFFFFF.

Deliberately NOT yet: FSIN/FCOS/FATAN2 (tables or NaN polynomials first),
FMA, SIMD lanes, FB ops.

## 3. NaNVM1 — memory and pc

Flat 2^k words, k<=28; LD/ST/STW/BSWAPM/LDB/STB/BCOPY use 32-bit register
addresses; pc is 32 bits when nwords>65536 (JMPR/RET/CALLR reach everywhere,
JMP/CALL imm stay 16 bits so hot code lives low; far = MOVI+MOVHI+JMPR).

## 4. NaNVM1 — native plan (arbitrary RAM, then VRAM/GPU)

PLAN AND PSEUDOCODE ONLY, NOTHING HERE IS IMPLEMENTED OR RUN.

Goal: the native NaN16 VM handles whatever RAM the machine has, later VRAM
for GPU integration.

### 4.1 Address model
Guest address = 32-bit word index (r[a]+imm, already how
LD/ST/STW/BSWAPM/LDB/STB/BCOPY work in the model) = up to 2^32 words = 32 GB
of 8-byte words. Past that: a later 64-bit address pair op family (ADDRH
register + *64 variants); not needed before ~16 GB machines.
Host side: flat 32-bit protected mode first (4 GB limit, so ~512M words),
then long mode + paging for more. Guest words are never segmented.

### 4.2 Memory discovery (no constants in the guest)
Boot: INT 15h E820 in real mode -> copy the map to a fixed table. Native VM
builds a REGION TABLE: {guest_base_word, nwords, host_base, kind}. kind:
0 RAM (8-byte NaN words), 1 DEV (device window, see 4.3), 2 hole
(access = gate trap).
New op (planned 0x38) MEMQ d,a : a=region index -> d = guest_base,
d+1 = nwords, d+2 = kind (three consecutive registers, or three MEMQ forms;
decide when coding). Guest allocators (nalloc) take (base,size) from MEMQ,
so any amount of RAM just works.
Load/store fast path: ea = (r[a] + imm) (32-bit); if ea < ram_words:
host = ram_base + ea*8 (one compare, one shift-add); else walk the region
table (binary search, <=8 entries) -> kind DEV/hole/other RAM. Hot loops
live in region 0, so the common case costs one compare.

### 4.3 VRAM / GPU window (DEV regions)
Pixels are packed (4 bytes per 32-bit pixel), a NaN word is 8 bytes. A DEV
region has stride 4: guest word i = host 32-bit cell i. LD returns the 32
bits as payload; ST writes the payload; the class is synthesized as +q/+q on
read and ignored on write. STW/BSWAPM/LDN on DEV: trap (!D) because there is
no second face to check. BCOPY RAM->DEV converts 8-byte words to 4-byte
cells (payload only) = the blit path; DEV->RAM the reverse.
First target: VBE/linear framebuffer (QEMU/Bochs std-vga, v86 VGA) mapped as
a DEV region; the existing Sierpinski/plasma exhibits then draw at 32 bpp
with plain ST/BCOPY.
GPU: a command ring is a DEV (or RAM+DMA) region, doorbell = ST to a DEV
word. Honest order: linear FB -> virtio-gpu (small, well-specified, works in
QEMU) -> maybe 2D accel -> vendor-specific much later. Doom/Quake render in
software into RAM and BCOPY to the DEV window; GPU use comes after.

### 4.4 Build order
a) Step 1 (checkable here): flat 32-bit asm interpreter, SSE single for
   FADD..CVTFI, 32-bit pc, built with `as --32` / `ld -m elf_i386` and run
   as a host process (32-bit exe runs on the dev box; `gcc -m32` libc is
   absent so the driver is pure asm + syscalls). Differential test against
   the frozen model: selftest, lib, museum, nasm0 --big, gen2 must give
   word-identical output.
b) Step 2: boot real -> protected mode, A20, E820, region table, disk load
   into high memory (unreal mode or temp low buffer + copy).
c) Step 3: v86/QEMU runs (needs the owner's harness).
d) Step 4: DEV region + framebuffer, then virtio-gpu.

### 4.5 Open questions
Interpreter speed target for Quake (see TODO spanbench). Whether MEMQ stays
one op. Whether DEV words should read back a fixed class or a per-region
class.

## 5. NaNNet VM — the bytecode program format

Cells are u16. `[op:8][arity:8]` then arity u16. Arity mismatch is
`-EPROTO`. Jumps are i16 relative to next cell. The stack holds 64-bit
words; the word/tag model (tagged iff `(w>>48) >= 0xFFF8`, canonical NaN
`0xFFF8000000000000`, arithmetic NaN rewrites to it) is defined in the
value-layer document set and enforced by the interpreter's ALU/CMP/TEST
operand checks.

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
    80..87 value-shell extensions (arity 1, total; value-layer contract)

The interpreter is a cart: program words live in its memory, the arity
table, constants and state cells sit below the stack, and self-tests run at
program head so the operand stack starts empty. Halting with a 64-bit word
2 in the low half is the gate success condition.

## 6. Evidence

- NaNVM0: boot image + scaffold objdump; hex dump in `src/vm/nanvm0.nan`.
- NaNVM1 op set: `logs/nanvm1_ops_test.txt` (5,810 checks, 0 FAIL;
  historical model evidence) and the nasm0 self-host fixed point
  (`logs/nasm0_selfhost_gen2_round09.txt`). The model tool named by older
  revisions is retired (see `TODO.md` r29h); the logs are the frozen
  evidence.
- NaNNet VM: interpreter dispatch, arity table and self-tests are in-cart
  and verified by the VM gate in the build chain; the 52-op program plus
  the self-test blocks must end with `VM 0000000000000002 / VM OK` and no
  error.

## 7. Open

- NaNVM1 native: protected mode, E820 region table, MEMQ, DEV windows.
- NaNNet VM: netcart integration (the network cart embedding the
  interpreter). Until then the interpreter is exercised by its own gate.
