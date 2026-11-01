# ARCH_ADAPTERS.md (r26k WIP) - AArch64 + RISC-V boot adapters

Adopted policy r26j-26k: NO Python, NO JS, minimal translation interfaces per
ISA. For every target architecture exactly TWO admissible host files exist:

- `src/boot/kboot0_<arch>.xa`  - boot shim (sector-0 / -kernel entry);
- `src/native/kan16_<arch>.xa` - the NaN16 native core (dispatch + hi ops).

On x86 these are `kboot0.xa` + `kan16.xa` (frozen gold, 512 + 5,808 bytes in
`src/native/nan16_x86.nan`). Per-arch adapters follow the same rule: the .xa
file is a symbolic source of record; its gold bytestream lands in
`src/native/nan16_<arch>.nan` and is what `tools/mkimg.awk` packs.

## The core invariance promise

The guest word state is ISA-NEUTRAL. The museum's 24,904 guest words
(museum.nan + all carts) are 8-byte double-ended NaN words carrying class and
payload only. The application runs UNMODIFIED on every target; only
  (a) the boot shim,
  (b) the native core bytes,
change per host. `tools/mkimg.awk` already separates GOLD vs GUEST: a per-arch
build is `-v GOLD=src/native/nan16_<arch>.nan` + the SAME guest stream.

## Machines and entry modes (qemu 10.2.1 verified binaries on this host: i386,
x86-64, aarch64, riscv64)

| arch | run | entry state | RAM base | image load |
|---|---|---|---|---|
| x86   | `qemu-system-i386 -drive format=raw,if=floppy,file=IMG` | 16-bit real, BIOS | 1 MiB | floppy CHS, BIOS INT |
| AArch64 | `qemu-system-aarch64 -M virt -m 512M -cpu cortex-a57 -kernel IMG` | A64, EL2 | 0x40000000 | whole blob, entered at base |
| RISC-V64 | `qemu-system-riscv64 -M virt -m 512M -bios none -kernel IMG` | RV64, M-mode | 0x80000000 | whole blob, entered at base |

Shim job per arch (v1, qemu-parity first; hardware SD/eMMC/SBI paths are v3):

| step | x86 (DOEN) | kboot0_a64 | kboot0_rv |
|---|---|---|---|
| CPUs/regs init | BIOS, real->prot | x30 stack, DAIF clear, EL re-throw | mtvec clear, x2 stack |
| memory map    | INT 15 E820 -> 0x600 | virt DTB pass-through (fixed 512M) | DTB pass-through (x1=a1) |
| UART          | 0x3F8 NS16550, BIOS-less init | PL011 0x09000000 | NS16550A 0x10000000 |
| guest load    | CHS 1040 sectors to 0x100_00 | copy [GB_BASE+0x2200 ..] whole-image blob | copy [0x80000000+0x2200 ..] |
| jump core     | prot-mode jump 0x10000000 | branch vm_start_a64 | branch vm_start_rv |

Image layout stays FIXED (1474560 B): 0 x boot/512, 512..8703 kernel, 8704.. guest.
Per-arch kernels read their own guest range at [RAM_BASE + 0x2200..] - clear
in both adapters; only the base register differs.

## Native core port table (kan16 op -> handler; same payload state)

| NaN op | x86 (kan16.xa DOEN) | kan16_a64 | kan16_rv |
|---|---|---|---|
| PUTC  | COM1 0x3F8 polling | PL011 send byte 0x09000000 (FR 0x09000018 TXFF bit 5) | NS16550A W0x10000000 LSR 0x10000005 bit 5 |
| TICK/RDTSC | rdtsc TSC | CNTVCT_EL0 (counter freq ID_AA64PFR0) | rdcycle/mrtime 0x200BFF8 (virt 10 MHz) |
| INB/OUTB/INW/OUTW | IN/OUT 0x66 prefix | MMIO leg | MMIO leg / virtio |
| OUTSW/OUTL | rep outsb/outsd | virtio (v3) | virtio (v3) |
| VPOKE/VPEEK/DISPSET | 0xA0000/0xB8000 + VBE | RAM FB "console" mirror + virtio-gpu (v3); VMODE 0 -> UART fbless | same |
| CPUID | CPUID.1/0x8000 | midr EL0/EL1 pass | misa/mhartid/mimpi |
| KEY/KEYQ | IRQ keyboard ring (0x8050 KRING) | PL061@virt 0x09008000/pl011 receive side | ns16550a WR - UART, virtio-input (v3) |
| ATA ops | ATA PIO 0x66 prefix | virtio-blk (v3, open) | virtio-blk (v3, open) |
| BSWAPM | bswap 16/32 | rev32 x-reg / swap | rev8 + packing shift |
| MUL..MODU | 32x32/64 div | MUL/UDIV/MSUB | mul/divu/remu/rem |

Dispatch decode (fetch word, class gate flags via 0x000b flag pattern etc.)
is byte-identical lyrics to x86; the ISA difference is REGISTER NAME ONLY.

## Emitters (outer gawk, no python)

`tools/nasm1_<arch>.awk` will compile the .xa subset to nan16_<arch>.nan gold.
Subset scope (kept minimum; DOCUMENTED per file): register moves, immediates,
load/store, add/sub/cmp/branch, system read/write for the UART/COUNTER/MMIO
legs, b/ret. The retired x86 nasm1 stays retired - x86 gold is frozen even
for the r26k rework.

(REJECTED path, permanently: host .py/.py-alt compilers, C bootstrap, a
guest-in-x86 interpreter loop. Also REJECTED for v1: SE/B consoles; the file
list per arch stays at exactly two .xa entries until a Guest PASS demands
basenamegrowth.)

## Gate plan (per arch, run on bare metal, same shape as qgate.sh)

- `tools/qgate_a64.sh`: `qemu-system-aarch64 -M virt -m 512M -cpu cortex-a57
  -kernel build/nan0s_a64.img -display none -serial file:...` requires COM PL011
  bannanner `NaN/0S A64 READY`; RETIRED after first core op-set PASS.
- `tools/qgate_rv64.sh`: `qemu-system-riscv64 -M virt -m 512M -bios none
  -kernel build/nan0s_rv64.img ...` requires `NaN/0S RV64 READY`.
- Both shells print PASS exactly like tools/qgate.sh. NO keys, no JS.

## Milestones (honest, each gate-grepped)

- M-A64-1: boot-path smoke: hand-assembled A64 shim prints the AArch64 gate
  banner from the -M virt load point. (blob = shim only, NOT the core yet).
- M-A64-2: kan16_a64.xa full handler port + nasm1_a64.awk emits gold; guest
  word stream byte-identical; qgate_a64 PASS with core ops.
- M-RV-1/2: same for RISC-V64 (M-mode, no SBI oracle).
- M-v3: virtio-blk / virtio-gpu legs (both arches), then hardware focuses.

STATUS r26k: M-A64-1 in progress. Smoke blobs written as pure hex
(src/draft/a64_smoke.hex, rv64_smoke.hex); the FIRST bare-metal boot attempt
on both targets returned an EMPTY serial line - debug open (raw -kernel
entry semantics vs PL011/16550A reset state). No .xa skeletons, no per-arch
gates yet. NOT gold, NOT the shipped path. M-A64-1 / M-RV-1 PASS pending.
