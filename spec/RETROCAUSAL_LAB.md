# Retrocausal Lab - safe primitives and the public-puzzle boundary

This is the safe implementation plan for the LE/BE architecture. It has three
independent layers:

1. **n16de carrier** - a double-ended qNaN pair codec. Data only.
2. **Retrocausal clock + fixed-point loop** - a LE forward clock, a BE reverse
   clock, and a contractive loop that reaches a self-consistent value.
3. **Singularity loop** - a capped, sealed exception loop that demonstrates a
   self-sustaining trap cycle without claiming to be an AI.

The layers are implemented and tested separately in NaN16:

- `src/lib/n16de.nas` + `src/tests/n16de_test.nas`
- `src/tests/retro_test.nas`

## n16de in NaN16

The IEEE binary64 bit pattern in the sketch is not a legal NaN16 word: the
gate checks both heads. The NaN16 carrier therefore uses the legal class nibble
and puts the tag/data in the 32-bit payload:

```
near head : +q (class 2)
far head  : +q (class 2)
class n   : 10
payload   : tag<<16 | chunk
tag 0     : big-endian member
tag 1     : byte-swapped member
tag 2     : DELIM
tag 3     : RESYNC
tag 4     : CTRL (class 11)
```

Encode writes the chunk twice. Decode byte-swaps the tag-1 member and votes.
Disagreement returns 0; the caller resyncs. `src/tests/n16de_test.nas` encodes
0x1234 and 0xABCD, decodes both, and prints `N16DE PASS` on COM1.

## Retrocausal clock

`TICK` is the forward count. The reverse count is `0xFFFFFFFF - TICK`. The
test prints both:

```
LE=00000000 BE=FFFFFFFF
```

The fixed-point loop is a contractive map `x -> x/2` starting at 100. It reaches
100, 50, 25, 12, 6, 3, 1, 0 in seven steps. A self-consistent loop is a value
that reproduces itself; this toy demonstrates the shape of the computation.

## Singularity loop

The singularity test is a 1,000-iteration LCG with a 15-bit quieting mask and a
seal. It is a toy, not a language model. The point is the control flow:

```
trap -> quiet -> generate -> seal -> repeat
```

The cap is hard. The seal is the transcript. `src/tests/retro_test.nas` prints:

```
FIX=00000007 SING=000003E8 SEAL=00005B6C RETRO PASS
```

## Public-puzzle target boundary

A public Bitcoin puzzle is a published challenge. The target adapter for that
case is **offline, range-limited, and verifier-first**:

- The puzzle address, public key, and range are constants in the build.
- The solver searches only the published range.
- Every candidate is verified by recomputing the public key and the address.
- No network code. No broadcast code. No arbitrary address input.
- The output is a candidate tuple and a local proof transcript.

The general `glass` suite, real PGP/FIDO2/TOTP adapters, arbitrary wallet
sweeping, and session hijacking are out of scope. They are not part of the
museum and are not built.

## What is real and what is a representation

The n16de codec, LE/BE clock, fixed-point loop, and capped exception loop are
real NaN16 programs. The "retrocausal inversion" is a representation of a
self-consistent search, not a physical time machine. The public-puzzle adapter
is a conventional range search with a verifier, presented in the double-ended
frame. It does not break secp256k1 in general.

## Next

- Add a NaN16 public-puzzle verifier with the published address/range constants.
- Add a text exhibit that shows the n16de stream and the fixed-point trace.
- Add the Orrery transcript seal to the museum.
