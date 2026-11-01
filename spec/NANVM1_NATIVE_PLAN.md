# NaNVM1 native plan: arbitrary RAM, then VRAM/GPU (round 11) - PLAN AND PSEUDOCODE ONLY, NOTHING HERE IS IMPLEMENTED OR RUN
## Goal (owner): the native NaN16 VM handles whatever RAM the machine has, later VRAM for GPU integration.
## 1. Address model
Guest address = 32-bit word index (r[a]+imm, already how LD/ST/STW/BSWAPM/LDB/STB/BCOPY work in the sim) = up to 2^32 words = 32 GB of 8-byte words. Past that: a later 64-bit address pair op family (ADDRH register + *64 variants); not needed before ~16 GB machines.
Host side: flat 32-bit protected mode first (4 GB limit, so ~512M words), then long mode + paging for more. Guest words are never segmented.
## 2. Memory discovery (no constants in the guest)
Boot: INT 15h E820 in real mode -> copy the map to a fixed table. Native VM builds a REGION TABLE: {guest_base_word, nwords, host_base, kind}. kind: 0 RAM (8-byte NaN words), 1 DEV (device window, see 3), 2 hole (access = gate trap).
New op (planned 0x38) MEMQ d,a : a=region index -> d = guest_base, d+1 = nwords, d+2 = kind (three consecutive registers, or three MEMQ forms; decide when coding). Guest allocators (nalloc) take (base,size) from MEMQ, so any amount of RAM just works.
Pseudocode of the native load/store path (flat, fast path for region 0):
  ea = (r[a] + imm)            ; 32-bit
  if ea < ram_words:  host = ram_base + ea*8   ; one compare, one shift-add
  else: walk region table (binary search, <=8 entries) -> kind DEV/hole/other RAM
Hot loops live in region 0, so the common case costs one compare.
## 3. VRAM / GPU window (DEV regions)
Problem: pixels are packed (4 bytes per 32-bit pixel), a NaN word is 8 bytes. So a DEV region has stride 4: guest word i = host 32-bit cell i. LD returns the 32 bits as payload; ST writes the payload; the class is synthesized as +q/+q on read and ignored on write. STW/BSWAPM/LDN on DEV: trap (!D) because there is no second face to check. BCOPY RAM->DEV converts 8-byte words to 4-byte cells (payload only) = the blit path; DEV->RAM the reverse.
First target: VBE/linear framebuffer (QEMU/Bochs std-vga, v86 VGA) mapped as a DEV region; the existing Sierpinski/plasma exhibits then draw at 32 bpp with plain ST/BCOPY.
GPU: a command ring is a DEV (or RAM+DMA) region, doorbell = ST to a DEV word. Real vendor GPUs need large drivers; honest order: linear FB -> virtio-gpu (small, well-specified, works in QEMU) -> maybe 2D accel -> anything vendor-specific much later. Doom/Quake render in software into RAM and BCOPY to the DEV window; GPU use comes after.
## 4. Build order
a) Step 1 (checkable here): flat 32-bit asm interpreter, SSE single for FADD..CVTFI, 32-bit pc, built with as --32 / ld -m elf_i386 and run as a host process (32-bit exe runs on the dev box; gcc -m32 libc is absent so the driver is pure asm + syscalls). Differential test against tools/nan16sim.py: selftest, lib, museum, nasm0 --big, gen2 must give word-identical output.
b) Step 2: boot: real -> protected mode, A20, E820, region table, disk load into high memory (unreal mode or temp low buffer + copy).
c) Step 3: v86/QEMU runs (needs the owner's harness; my sandbox has no node_modules or network).
d) Step 4: DEV region + framebuffer, then virtio-gpu.
## 5. Open questions
Interpreter speed target for Quake (see TODO spanbench). Whether MEMQ stays one op. Whether DEV words should read back a fixed class or a per-region class.
