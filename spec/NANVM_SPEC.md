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
Guest address = 64-bit effective address. RAM effective addresses are word
indices; the high half comes from a per-context ADDRH register (op 0x40) and
the low half from r[a]+imm as today, so existing code is unchanged while
ADDRH=0. The reach is 2^64 words = 128 EiB of words: "arbitrary numbers of
words" for any machine we will build. 16 GB RAM = 2^31 words. 32 GB VRAM =
2^33 32-bit cells as a DEV window; DEV effective addresses count 32-bit
cells, so the same 64-bit ea covers 2^64 cells.
Host side: flat 32-bit protected mode for small machines, long mode +
paging for the platform; host memory is demand-mapped (mmap) so a 16 GB
guest heap does not have to be resident. Guest words are never segmented;
ADDRH is address extension, not a segment base.

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
c) Step 2b: IDT/PIC/PIT timer, SVC gate, trap frames, preemptive tick and
   context switch (§9).
d) Step 2c: port I/O ops, DEV windows, storage (ATA PIO read/write, NaNFS
   write) and the program loader (§10).
e) Step 3: v86/QEMU runs (needs the owner's harness).
f) Step 4: DEV region + framebuffer, then virtio-gpu.
g) Step 5: process/thread scheduler, per-process heaps, then the Quake
   trace in §8.4.

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

## 8. System model — one machine, many programs

### 8.1 Memory ceiling and word budget

A guest word is 8 bytes with a 32-bit payload. NaNVM1 addresses words with
64 bits (§4.1): practical ceilings are host-bounded, not ISA-bounded.
16 GB RAM = 2,147,483,648 words; 32 GB VRAM = 8,589,934,592 32-bit cells in
DEV windows (64-bit cell addresses). The reference C core today has
`NAN_WORDS 0x400000` (4M words, 32 MiB) and 32-bit word indices; the
platform revision makes NAN_WORDS configurable, indices 64-bit and host
memory demand-mapped. NaNVM0 stays an 8,192-word museum machine for a single
job; it is not the platform.

Quake trace (requirements -> words):

| need | size | words (8 B) |
|---|---|---|
| engine working set, comfortable | 16 MiB | 2,097,152 |
| target platform (zone/hunk/sound/renderer headroom) | 32 MiB | 4,194,304 |
| engine code + data translated to NaN16 | well under 8 MiB | < 1,048,576 |
| shareware pak0 (streamed, not resident) | ~18 MB | storage only |
| full id1 data (streamed) | ~50 MB | storage only |
| framebuffer 320x200 8bpp (packed 4/word) | 64 KiB | 16,384 |
| framebuffer 640x480 32bpp (DEV stride 4) | 1.2 MiB | DEV window |

The engine is compiled to NaN16 from the C subset (int32, float32, pointers,
function pointers, byte access, block moves; all covered by the op set in
§2). Every byte of the machine is a NaN word: no raw side-regions
(`spec/MEMORY_PLAN.md`). Performance is a separate target; the route is a
fast NaNVM1 native core plus a NaN -> native translator written in NaN, kept
small and audited (`spec/MEMORY_PLAN.md`, `spec/PERF_ESTIMATE.md`).

### 8.2 Allocators

Page-frame bitmap -> buddy -> per-process heap. The heap allocator is
nalloc: next-fit rover over an implicit block list with boundary tags and
coalescing, proven by `src/prog/nalloc_test.nas` (`spec/NALLOC_PLAN.md`);
the Quake zone/hunk sits on it as an arena layer. Heap base/size come from
MEMQ, so the same code serves any RAM size. MALLOC/MFREE/MQUERY fast-path
ops are optional and planned; ordinary SVC calls into nalloc are the
baseline.

### 8.3 Storage

Block device behind port I/O plus a DEV window (ATA PIO; read already in the
tree, write planned as the DISKW convenience op or OUTW sequences). On-disk
layout: sealed images, NaNFS (read implemented; write/extend planned), and a
system-owned block bitmap. Files are extents in NaNFS; a process receives
handles, never raw blocks (capability check in the syscall layer). The
loader verifies the L4 seal before mapping a process image
(`spec/INTEGRITY_PLAN.md`).

### 8.4 Quake trace (need -> VM feature)

| Quake need | VM feature |
|---|---|
| 32-bit mul/div, signed math | 0x20-0x29 (v1) |
| byte access, block moves | 0x2A/0x2B, 0x2D/0x2E (v1) |
| float32 math | 0x30-0x37 (v1) |
| function pointers / callbacks | 0x2C CALLR, 0x2C-adjacent jump model |
| malloc/free, zone | nalloc + SVC 2/3 (regions), arena layer |
| pak/file loading | SVC 4-8, storage driver, NaNFS |
| timing | PIT IRQ0, SVC 11 (ticks) |
| input | IRQ1 keyboard, mouse (planned), SVC read |
| rendering | DEV framebuffer window, BCOPY blit |
| NetQuake | NaNNet bytecode carts + NIC driver |
| savegames/config | storage write + NaNFS write |

## 9. Processes and threads

### 9.1 Processes

A process is an address-space region set + heap + entry point + capability
set. Isolation is enforced in software by the interpreter: every memory
access is checked against the current process's region table; holes and
foreign regions trap the gate (no silent read). This is mandatory and keeps
one VM across aarch64/x86/riscv/wasm and the C core; hardware paging is an
optional x86 accelerator, never a correctness requirement.

Process table entry: pid, state (ready/running/blocked/dead), region table,
heap base/end, thread list, capability handles, parent. Lifecycle: load a
sealed image from storage, build regions, spawn the main thread, reap on
exit and reclaim the address space. IPC: explicitly granted shared RAM
regions plus message passing over the NaNNet link layer (identical local and
remote).

### 9.2 Threads

A thread is a context {r0-r15, pc, flags, stack pointer, ADDRH} plus a stack
region. Preemption: a per-core PIT raises IRQ0 at 100 Hz; the boundary sets
a pending bit; the interpreter tests it between instructions and at backward
branches and vectors to the kernel entry. Time slice in ticks, round-robin;
per-core run queues with atomic work stealing. Cooperative yield is SVC 0.
The trap frame (r0-r15, pc, flags, ADDRH at fixed offsets) is the
context-switch ABI: the scheduler stores it in the TCB and restores the next
thread.

SMP is in scope: up to K native cores run K interpreters in parallel over
one shared word memory. Per-core state is exactly the state the C core
already keeps per `nan_vm` (registers, pc, flags, timers); shared memory plus
the atomic ops (0x41-0x44) and fences are the synchronization contract. A
guest thread is scheduled onto a core; a process keeps one address space and
may run threads on several cores. The kernel keeps a global ready queue and
per-core queues; IPIs are a pending word plus FENCE. Stacks are per-thread
regions with a guard hole; overflow traps. This is the multithreading that AI
workloads need: tiled matrix work, parallel reductions, and a barrier/fence
model that is explicit rather than accidental.

### 9.3 New ops (v1 revision, 0x38-0x3F)

    38 MEMQ d,a (planned)      region query: base/nwords/kind
    39 SVC imm                 syscall/trap gate (trap frame, kernel entry)
    3A INB d,a | 3B OUTB a,b | 3C INW d,a | 3D OUTW a,b   port I/O
    3E DISKW (optional)        write sealed block range
    3F reserved                IRQ control stays in the kernel via port I/O
    40-4F scale + AI family (candidate encodings, frozen when coded):
      40 ADDRH a                 address high half (64-bit ea; §4.1)
      41 CAS d,a,b               atomic compare-exchange on ea(d) payload
      42 XADD d,a,b              atomic fetch-add, d = old
      43 XCHG d,a,b              atomic swap, d = old
      44 FENCE                   full memory barrier
      45 FMA d,a,b               fused float32 multiply-add
      46 DP2H d,a,b              dot 2 x f16 (packed payload lanes)
      47 DP4B d,a,b              dot 4 x i8 (packed payload lanes)
      48 CVTPK d,a               convert f32 <-> 2 x f16 (packed)
      49-4F reserved             bf16 variants and lane select when coded

All atomics operate on the 32-bit payload of one aligned word and are
sequentially consistent with FENCE; they are the only shared-memory
primitives the scheduler and the AI kernels need. Existing ops keep 32-bit
value semantics; only effective addresses widen.

SVC syscall ABI (v1 draft; numbers stable once used, new calls append):
0 yield, 1 exit(code), 2 region_map(id, base, words, kind), 3 region_query,
4 open(path, flags) -> handle, 5 read(handle, buf, len), 6 write(handle,
buf, len), 7 seek, 8 close, 9 spawn(path, args) -> pid, 10 wait(pid),
11 time(ticks), 12 share(pid, region, perms).

Interrupt model: a kernel-owned vector table; the timer is IRQ0, keyboard
IRQ1, NIC per driver; guest handlers are registered through SVC; EOI via
OUTB to the PIC. Keyboard/mouse rings are kernel-owned; SVC read drains them.

### 9.4 Interface

Port I/O ops and memory-mapped DEV windows (§4.3) are the only ways out:
timer, keyboard, mouse, display, NIC, audio later, storage. A process never
touches a device directly; it holds capability handles and calls SVC. This
is the same boundary on every target (x86 IN/OUT, aarch64 MMIO, C core
host callbacks).

### 9.5 One VM: revisions and modes, not builds

There is one machine, not a family:

- **NaNVM0** is revision 0 (NaN16 v0.1 ops, 8,192-word museum profile).
- **NaNVM1** is revision 1 of the same machine (ops 0x20-0x37 plus the
  scale/SMP/AI families in §9.3); nothing forks a new machine.
- **NaNNet VM** is not a second machine and not a separate image: its
  bytecode is the VM's second instruction form. The unified VM boots as the
  main process, owns memory and devices, and executes native NaN16 words
  and NaNNet bytecode cells as processes under the same scheduler, regions
  and device interface. A bytecode program is loaded like any other process
  image; the interpreter is part of the machine, not a cart on top of it.

The three historical names describe revision and execution mode, never a
separate build or file. Everything ships as one image.

Rule: no feature lives outside this document. A subsystem either fits an
existing op/ABI or its op is added here with a version.

## 10. What exists vs what is to build

| piece | state |
|---|---|
| nalloc (next-fit + coalesce), 3,156 checks | DONE (`src/prog/nalloc*.nas`) |
| NaNFS read, ATA PIO read | DONE |
| DISPQ/DISPSET text boundary | DONE |
| sealed-image verify (L4) | DONE (`spec/INTEGRITY_PLAN.md`) |
| NaNVM1 op set 0x20-0x37 (32-bit mul/div, bytes, BCOPY, float32) | DONE in the C core (`aarch64/android/core/nan16.c`, `tests/test_core.c`); native implementation PLAN (§4) |
| 64-bit effective addresses (ADDRH, 0x40) | PLAN (§4.1) |
| SMP cores, atomics, fences (0x41-0x44) | PLAN (§9.2, §9.3) |
| AI packed math: FMA, DP2H, DP4B, CVTPK (0x45-0x48) | PLAN (§11) |
| 16 GB RAM configuration (NAN_WORDS, 64-bit indices, demand-mapped host memory) | PLAN — C core revision |
| nalloc64 (heaps > 2^31 words, 64-bit pointers/sizes) | PLAN (§11) |
| NaNVM1 native flat memory + 32-bit pc | PLAN (§4.1-4.2) |
| MEMQ region table | PLAN (§4.2) |
| port I/O ops INB/OUTB/INW/OUTW | PLAN (§9.3) |
| SVC gate + trap frames | PLAN (§9.3) |
| PIT timer, IRQ0, preemptive tick | PLAN (§9.2; proven recipe in early r21 notes) |
| context switch + scheduler | PLAN (§9.2) |
| software region checks per process | PLAN (§9.1) |
| per-process heap on nalloc + MEMQ | PLAN (§8.2) |
| storage write, NaNFS write, loader/spawn | PLAN (§8.3, SVC 4-9) |
| framebuffer DEV + scaler | PLAN (§4.3) |
| NaN compiler C subset -> NaN16 | PLAN (`spec/NAN_MIGRATION_PLAN.md`, `spec/TRANSLATOR.md`) |
| Quake in NaN, complete | blocked on the four rows above |

Honest blockers for Quake: NaNVM1 native memory/pc, the compiler, storage
write, input/audio. Speed remains an interpreter problem; the fast core and
the in-NaN translator are the route, not a license to skip correctness.

## 11. AI profile — why the scale, SMP and atomics matter

The same VM hosts the museum language model, Quake and NaNNet; there is no
AI-specific second machine.

- **Memory.** Weights in f32/f16/bf16 live in 16 GB RAM = 2^31 words; the KV
  cache and activation buffers come from the same heap. Models larger than
  RAM stream sealed weights from storage (§8.3). 32 GB+ VRAM is mapped as
  DEV windows with 64-bit cell addresses; first use is a linear framebuffer,
  later virtio-gpu command rings.
- **Compute.** f32 scalar math already exists (0x30-0x37). The AI family
  adds FMA (0x45), packed f16 dot (0x46), packed i8 dot (0x47) and packed
  conversions (0x48) so matrix work is bandwidth-bound instead of
  instruction-bound. Packing f16/bf16 pairs and i8 quads inside the 32-bit
  payload is deliberate: the word stays 8 bytes, the gated class stays
  intact, and no raw side-regions appear.
- **Threads.** Tiled matmul spreads across K native cores (§9.2); per-core
  run queues, atomic reductions via XADD, barriers via FENCE. The identical
  scheduler serves Quake's parallel renderer and the network carts.
- **Allocator.** nalloc64: nalloc's 32-bit size field caps a block at
  2^31-1 words (just under 16 GB); nalloc64 carries 64-bit pointers/sizes
  with the same next-fit/coalescing invariants. Page-frame bitmap and buddy
  layers stay system-owned; arenas serve the LM, the Quake zone and hunk.
- **Storage.** Datasets and weights are sealed NaNFS files, streamed through
  the block device; the block bitmap allocates storage, processes hold only
  capability handles.
- **Honesty.** Interpreter throughput is the limiting factor before GPU
  offload; the route is the fast native core plus the in-NaN translator
  (`spec/MEMORY_PLAN.md`, `spec/PERF_ESTIMATE.md`). This contract makes the
  model fit and the threads real; it does not claim wire-speed inference.

Rule, restated: one machine, one memory, one thread model, one device
interface. Quake, the LM, the museum and NaNNet are processes on it.

## 12. Implementation authority, the main process, and the terminal

### 12.1 Authority

The norm is this document plus the NaN image. The C code under
`aarch64/android/core/` is a **non-normative host harness** (S6 in
`spec/SELF_HOSTING.md`): it runs the same image on hosts that cannot boot the
native boundary and cross-checks vectors. No opcode, flag or device
semantic may land in C first. If C and this spec disagree, the spec wins and
C is fixed. Older notes that called `nan16.c` the line of truth are retired
(`spec/TOOL01_PLAN.md` corrected).

### 12.2 The product boundary

S0 (512 B boot sector) and S1 (native core: fetch/decode/gate/trap, memory,
clock, keyboard ring, text plane, port I/O, halt) are the only native code
in the product. S2-S5 (assembler, builder, disk driver, filesystem, shell,
museum, tools, terminal) are NaN. Hosts: x86 first, AArch64 next (the
Android product boundary), then riscv64/wasm32. S1 is per-host and small; it
contains no ATA logic, no filesystem, no allocator, no shell, no builder, no
font, no VGA mode table.

Status: the AArch64 S1 has its boot and NaN16 decode/execute layers gated by
`tools/qgate_a64.sh`: the gate assembles real `.nas` tests with nmk, runs the
reference harness for the serial golden, converts the emitted image to the S1
guest and requires byte-identical output on qemu virt. Covered ops: BOOL MOVI
MOVHI ADD SUB MUL MULH MULHU DIV MOD DIVU MODU CMP CMPS ADDI SHL SHR SAR JMP
JMPF JMPR CALL CALLF CALLR RET NOP PUTC LD ST LDB STB STW LDN BSWAPM BCOPY
BFILL HALT, with predication and exact `!G`/`!O` + pc hex traps, over a
4M-word writable guest RAM (image copied at boot); HALT exits qemu via
semihosting. The gate runs seven real programs differentially: s1_test,
carry_probe, nalloc_test (3,156 allocator checks), a64_test (portable core
self-test), n16de_test, a2_boot_test and nan16dump_test. Remaining: float
ops, device/port ops (TICK/KEY/DISP/FB), then the work image.

### 12.3 Android: bare-minimum C

The Android build keeps only the JNI glue, display surface, input forwarding
and audio hand-off in C/Kotlin. The C interpreter is not part of the product
once the AArch64 S1 core passes the same vectors; until then it is the test
bench. Retirement order:

1. freeze new semantics in C (the spec-first rule above);
2. land the AArch64 S1 core with the existing vector suite behind it;
3. Android loads the same unified image through S1;
4. the C core remains only in CI as a conformance oracle, then leaves the
   product builds; any harness that stays lives outside the machine.

No second VM implementation is allowed to grow back.

### 12.4 The VM is the main process

On bare metal the unified VM is the kernel/main process: it owns memory, the
scheduler, the terminal and the devices. On a hosted build (Android,
desktop, WASM) the host process only loads the image, provides the surface,
forwards input, and steps the machine; it does not own VM semantics.

### 12.5 The terminal extension

The terminal is a VM service, not a host program: a text plane (the existing
80x25 cell interface) plus an input ring, owned by the VM. The shell and
command dispatcher run as NaN code inside the VM. A CLI binary is a
**terminal client**: it opens the surface (serial or window), forwards
keystrokes, renders the text plane, and may attach to an already running
machine. One terminal ABI serves bare-metal serial, the Android window and
the host CLI, so the same session looks identical everywhere. The moment a
CLI needs VM knowledge, that knowledge belongs in S1 (the boundary) or in
NaN (the service) — never in the CLI.
