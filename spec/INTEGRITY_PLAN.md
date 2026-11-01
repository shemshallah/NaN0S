# Integrity from NaN16 dual endianness (round 08)
Facts: a word has two heads (near LE b6b7, far BE b0b1), 4 legal values each; bswap maps class n -> rot2(n) and reverses payload bytes. So each word is readable through two faces.
## Layers
L1 gate: both heads legal before every fetch (exists). Head bits are 32 for 4 bits of class: any single-bit head flip traps.
L2 mirror relation: BSWAPM+LDN == rot2(n) and LD payload == bswap32 (exists in nasm0 for stored words). Honest: this validates the VM/assembler, not RAM faults (same bytes).
L3 class nibble as check channel (new): data words carry class = nibble-fold(payload) (xor of its 8 nibbles) instead of constant 10; detects every single-bit payload error; stored redundantly in both heads. Needs STW with computed class (exists) -> software now, SEAL/CHK ops later.
L4 dual-endian seal of an image: A=sum payload, B=sum bswap32(payload) read via the mirror face, C=fold of class nibbles, D=rotating xor of both faces; stored in the last word; verified by boot/NaNVM0 before run, and by nasm0 on every output.
L5 replica voting: keep a byte-reversed replica of critical blocks; on mismatch the seal picks the good copy (repair), else trap.
L6 chain: H(i)=mix(H(i-1), seal(module i)) with BOOL lanes; manifest of module seals published with each round.
## Limits: tamper evidence and fault detection only; no secrets, so no authentication.
