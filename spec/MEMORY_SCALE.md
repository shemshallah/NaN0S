# NaN/0S memory at scale: Doom/Quake now, 16 GB RAM + 32 GB VRAM for LLM training later (round 33 plan)
## Facts and arithmetic
- 1 NaN word = 8 bytes = 32-bit payload + class nibble in the heads. 16 GB RAM = 2^31 words = 8 GB of payload. 32 GB VRAM = 2^32 words if coded as NaN words (16 GB of payload) or 32 GB if raw.
- A 32-bit register word index reaches 2^32 words (32 GB of word space). RAM fits in it; VRAM does NOT fit beside RAM, so VRAM is reached through windows and bulk DMA, not through ordinary LD/ST.
- fp32 tensors as NaN words waste half the RAM. Pack two bf16/fp16 per payload (SWAR on BOOL/ADD lanes) or keep tensors in raw VRAM windows. Rule of thumb for later: mixed-precision Adam needs about 16-18 bytes per parameter, so 32 GB of VRAM trains on the order of 1-2 billion parameters before activations (estimate, not measured).
## Tension with an earlier decision (owner to confirm)
spec/MEMORY_PLAN.md (round 08) says all memory is NaN words, no raw side-regions. VRAM tensors are raw. Proposal: raw windows are explicit and named (RAWMAP), never reachable by LD/ST/fetch, and every block that crosses between NaN space and a raw window carries the dual-face seal (see INTEGRITY_PLAN.md L4): sealed before DMA out, verified after read back. That turns the double-endian seal into silent-corruption detection for long training runs.
## Milestones
M0 DONE (v32, tested in model + v86): 4M words (32 MB), JMPF/CALLF 24-bit far code, 64 MB v86 RAM. tools/test_far.py, src/tests/far_test.nas -> FKMN.
M1: mask becomes a variable (not an assembler constant); RAM size from the BIOS memory map (E820) read in the boot sector; guest array sized to what exists, up to about 2 GB (2^28 words) in 32-bit flat mode. Needs memory-operand forms in nasm1 or a register-held mask.
M2: x86-64 long-mode kernel (nasm1 gains REX/64-bit encodings), identity-mapped large pages, guest word array above 4 GB, 16 GB = 2^31 words. Register word index stays 32-bit; word index 2^31 and up is reserved.
M3: PCIe enumeration (config space), find the GPU, map its BARs (resizable BAR for a full VRAM aperture), RAWMAP window ops, DMA block copy RAM <-> window with seal-on-transfer.
M4: GPU compute: command submission and kernels emitted from NaN source (a GPU emitter like nasm1 is for x86). Honest risk: this needs a documented GPU ISA and a bring-up path without a vendor driver. AMD publishes ISA documents and has open drivers to read; NVIDIA keeps SASS and firmware closed. Choice of GPU decides feasibility.
## Rules for code written now (so nothing has to be redone)
1. Never hard-code a memory size in guest code: ask the kernel (planned MEMQ op: words of RAM, raw windows present).
2. Addresses are 32-bit word indices; code beyond word 65535 is reached with CALLF/JMPF (24-bit) or CALLR/JMPR (32-bit register).
3. Big cartridges run in place at their load address; store a 32-bit load address and entry in the TOC (reserved words 10-15), never assume the slot at 4096.
4. Every bulk block that leaves or enters NaN space is sealed (dual-face seal) and verified.
5. Allocators (nalloc) take a region base+length from MEMQ, not constants.
