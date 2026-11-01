# Public Puzzle 145 - Exact Target and NaN16 Verifier Architecture

## Target

- Puzzle: Bitcoin puzzle 145 (public challenge).
- Public key:
  `03afdda497369e219a2c1c369954a930e4d3740968e5e4352475bcffce3140dae5`
- Address:
  `19GpszRNUej5yYqxXoLnbZWKew3KdVLkXg`
- Key range, decimal:
  `2^144 .. 2^145 - 1`
- Key range, hex:
  `1000000000000000000000000000000000000 : 1ffffffffffffffffffffffffffffffffffff`
- Bit width: 145 bits. Search space: `2^144` keys.

The constants above are the published puzzle constants. They are hardcoded in
the verifier. There is no arbitrary-address mode.

## The honest limit

`Q = kG` is a bijection on the secp256k1 scalar field. Inverting it is the
elliptic-curve discrete logarithm problem. The proposed BE oracle is a
statistical candidate generator. It does not make the ECDLP easy. A search over
`2^144` keys is not feasible on current hardware. The retrocausal loop is a
representation of a self-consistent computation, not a physical time machine.

The museum can build and test the full verifier. The museum cannot honestly
claim to find the key in this range. Any output that claims otherwise is a
simulation, not a solved puzzle.

## NaN16 architecture

Everything below is NaN16. No Python is used in the runtime verifier.

```
p145/
  big/
    u256.add         8 limbs, carry, conditional wrap
    u256.sub         8 limbs, borrow
    u256.mul         8x8 limb product, 512-bit intermediate
    u256.divmod      Knuth D or shift-subtract (slow, correct)
    u256.inv         Fermat: a^(p-2) mod p
  curve/
    fe.add fe.sub fe.mul fe.sqr fe.inv
    point.add        Jacobian
    point.double     Jacobian
    scalar.mul       double-and-add, fixed 145-bit window
    point.compress   02/03 || x
  hash/
    sha256           Merkle-Damgard, 64-round
    ripemd160        5-word state, 80 rounds
    hash160          ripemd160(sha256(pubkey))
  base58/
    base58check      version 0x00, 4-byte double-SHA256 checksum
  puzzle/
    p145.constants   pubkey, address, range
    p145.verify      k -> kG -> compress -> hash160 -> base58 -> compare
    p145.search      range-limited loop, hard cap, no network
  carrier/
    n16de            pair-vote transcript for candidate and proof
```

## Contracts

- `big.u256.*` operate on eight 32-bit limbs, little-endian limb order.
  Carry and borrow are explicit. All operations are modulo `2^256` except
  `u256.divmod` and `u256.inv`, which take the field prime.
- `curve.fe.*` reduce modulo
  `p = 2^256 - 2^32 - 977`.
- `curve.point.*` use Jacobian coordinates. Every add/double has a verifier:
  recompute the affine point and check the curve equation.
- `curve.scalar.mul` is fixed 145-bit double-and-add. It is constant-time in
  the scalar length, not in the scalar value. The output is checked by
  recomputing `kG` with a second window size.
- `hash.sha256` and `hash.ripemd160` have standard test vectors. A hash that
  fails a vector is a bug and must be refused.
- `p145.verify` returns 1 only if the recomputed Base58Check address equals
  `19GpszRNUej5yYqxXoLnbZWKew3KdVLkXg`. A candidate with no verifier hit is
  discarded.
- `p145.search` is range-limited to the hardcoded range. It has a hard
  iteration cap and a cost ledger. It never broadcasts, never opens a socket,
  and never accepts a user-supplied address.

## Suggested staging

1. **u256 arithmetic.** Test add/sub/mul/divmod/inv against fixed vectors.
2. **Field arithmetic.** Test `p`, `p+1`, `p-1`, associativity, inversion.
3. **Curve arithmetic.** Test `G`, `2G`, `kG` for small known k.
4. **Hash160 + Base58Check.** Reproduce the target address from the target
   public key. This is the first end-to-end gate.
5. **Verifier.** Given a candidate k, produce the address and a pass/fail bit.
6. **Small-range search.** Test on a 20-bit toy range with a known key. This
   proves the pipeline, not the 145-bit puzzle.
7. **Puzzle 145 search.** Run only with a hard cap and an honest cost meter.
   The expected work is `2^144` group operations. The exhibit says so.

## Cost receipt

- Search space: `2^144`.
- Expected group operations: `2^144` (birthday methods do not apply to a
  single-target interval search without a known public-key relation beyond the
  target; even a kangaroo is about `2^72` group operations for a 145-bit
  interval, still far beyond this machine).
- Landauer floor per irreversible bit erase: `kT ln 2`.
- The exhibit prints the budget and refuses to claim completion when the cap
  is reached. A capped run is a transcript, not a solution.

## Constants to change for another published puzzle

The only place to change a target is `puzzle/p145.constants`:

```
PUBKEY  = 03afdda497369e219a2c1c369954a930e4d3740968e5e4352475bcffce3140dae5
ADDRESS = 19GpszRNUej5yYqxXoLnbZWKew3KdVLkXg
LO      = 0x1000000000000000000000000000000000000
HI      = 0x1ffffffffffffffffffffffffffffffffffff
BITS    = 145
```

A different published puzzle requires a new constants record and a new
allowlist entry. There is no runtime arbitrary-target input.

## Museum plaque

> This is a public puzzle, not a private wallet. The range is 2^144. The
> machine can verify a candidate in NaN16. It cannot invert the curve. The
> double-ended word gives the search two faces; the mathematics still gives it
> one answer in 2^144 tries.

## Status

- n16de carrier: DONE in NaN16 (`src/lib/n16de.nas`, test PASS).
- LE/BE clock, fixed-point loop, capped singularity: DONE in NaN16
  (`src/tests/retro_test.nas`, PASS).
- u256/field/curve/hash/base58/verifier: NOT YET. This is the next build.
- Full 145-bit inversion: not possible with the stated machinery. The verifier
  and a capped transcript are the honest deliverable.
