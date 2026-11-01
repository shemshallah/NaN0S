# Self-bootstrap and self-replication plan (round 08)
Goal: from bare metal, a small inspectable seed rebuilds the whole system and can copy itself.
## Trust base (smallest first)
S0 boot sector (512 B, hand-checkable) -> S1 NaNVM0 (<=1536 B native x86, objdump-verified, tools/scaffold) -> S2 seed = nasm0 as hex NaN words (728 words) -> S3 source text of everything (packed .str / disk) -> S4 museum, tools, later NaNVM1.
## Fixed point (verified in sim, round 08)
nasm0 assembling its own source yields words identical to the ones running it (M7). Two independent assemblers (Python scaffold, nasm0) agree on the whole corpus: diverse double compilation, so a bug or trojan in one shows as a diff. Only S0+S1 are not yet regenerable from NaN source.
## Replication ladder
R1 in-memory clone: assemble self into a free region, mirror-check, seal, jump (needs relocation-free code: all labels are absolute from word 0, so clone = rebuild with base .org, or run clone via copy to word 0 after seal). R2 disk: DISKW op writes sealed image (needs NaNVM1/INT13 write). R3 network: NaNNet serial/NIC sends the seed + source; receiver verifies the seal and rebuilds. R4 native regeneration: NaN-written x86 emitter regenerates S1 and S0, closing the loop.
## Honest limits
Seals give tamper evidence and fault detection, not authentication (no secret). Real attestation needs published seals plus a keyed MAC later.
