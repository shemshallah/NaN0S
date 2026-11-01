# Memory plan: Doom, Quake and a language model, all in NaN (round 08, replaces the raw-region idea)
Decision (owner): the engines are written entirely in NaN16, so all memory is NaN words (64-bit, gated, 32-bit payload). No raw side-regions.
## NaNVM1 (next native task)
Flat word-addressed memory, 2^k words (k up to 28 = 2 GB of words; 4M words = 32 MB is the first target). 32-bit register addresses already work in LD/ST/STW/BSWAPM; pc becomes 32-bit (JMPR/RET reach everywhere; add CALLR; JMP/CALL imm stay 16-bit, far jumps = MOVI+MOVHI+JMPR). Real mode -> protected mode switch, A20, E820 map. Modelled and proven in tools/nan16sim.py (nwords) and by nasm0 --big.
## Round 09: NaNVM1 op set (MUL/DIV, float32, bytes, BCOPY) is spec'd in spec/NANVM1_SPEC.md and passes in the model.
## Costs, honestly
A NaN word holds 32 payload bits in 8 bytes: Doom's ~4-8 MB is 8-16 MB of words, Quake ~16-32 MB is 32-64 MB; weights likewise. Pixels/bytes pack 4 per payload word in software (SHR/BOOL lanes). Speed: an interpreter of NaN16 will be slow for Quake; the route is a fast NaNVM1 core, then a NaN->native translator written in NaN, kept small and audited. No claim yet.
## Allocators (written in NaN16, sim-tested first)
page-frame bitmap -> buddy -> first-fit+coalesce heap (nalloc.nas) -> arenas: Doom zone, Quake hunk, LM weights. Ops (planned, optional fast paths): MALLOC/MFREE/MQUERY.
## Also needed: float (NaN-boxed or software), FB/scaler ops, KEYQ/mouse/PIT/sound, DISKW (see DISPLAY_PLAN.md).
