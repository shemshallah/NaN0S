# Memory plan: Doom, Quake and a language model, all in NaN (round 08, replaces the raw-region idea)
Decision (owner): the engines are written entirely in NaN16, so all memory is NaN words (64-bit, gated, 32-bit payload). No raw side-regions.
## NaNVM1 (next native task)
Flat word-addressed memory with 64-bit effective addresses (ADDRH high half; 2^64 words reachable, host-bounded). 16 GB RAM = 2^31 words; 32 GB+ VRAM = 2^33+ 32-bit cells as DEV windows. The reference C core currently has NAN_WORDS 0x400000 (4M words) and 32-bit indices; the platform revision makes the count configurable, indices 64-bit and host memory demand-mapped. Real mode -> protected mode switch, A20, E820 map; long mode + paging for the platform. Modelled and proven in the frozen model (nwords) and by nasm0 --big.
## Round 09: NaNVM1 op set (MUL/DIV, float32, bytes, BCOPY) is spec'd in spec/NANVM_SPEC.md and passes in the model.
## Costs, honestly
A NaN word holds 32 payload bits in 8 bytes: Doom's ~4-8 MB is 8-16 MB of words, Quake ~16-32 MB is 32-64 MB; weights likewise. Pixels/bytes pack 4 per payload word in software (SHR/BOOL lanes). Speed: an interpreter of NaN16 will be slow for Quake; the route is a fast NaNVM1 core, then a NaN->native translator written in NaN, kept small and audited. No claim yet.
## Allocators (written in NaN16, sim-tested first)
page-frame bitmap -> buddy -> first-fit+coalesce heap (nalloc.nas) -> arenas: Doom zone, Quake hunk, LM weights. Ops (planned, optional fast paths): MALLOC/MFREE/MQUERY.
## Also needed: float (NaN-boxed or software), FB/scaler ops, KEYQ/mouse/PIT/sound, DISKW (see DISPLAY_PLAN.md).

The platform contract — memory ceiling, allocators, storage, processes, threads and the device interface — is `spec/NANVM_SPEC.md` §8-§9. This file and that one must not disagree; the VM spec wins.
