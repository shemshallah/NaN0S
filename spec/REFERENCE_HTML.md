# Reference HTML: Sierpinski and the 16-Operand Table

Two browser references in the owner's Download folder define the visual and
logical target:

1. `NaN Lattice_ a computer made of not-a-numbers.html`
2. `NaN Bare Metal — 16 Operand Test.html`

## Sierpinski reference

The lattice page is a 200 x 260 spacetime diagram. Time flows upward: each
tick copies the live row into the next row and the oldest row leaves the top.
Every cell is a genuine 64-bit word. The header bits store the opcode; the
payload bit 0 is the state; payload bit 1 is a guard that keeps FALSE a NaN
rather than infinity. The Sierpinski preset sets every cell to opcode 6 (XOR)
and fires one centre cell. Each tick reads the left and right neighbours and
runs the cell's own truth table. Colour is the opcode; bright is firing.

The HTML also demonstrates:
- endian flip on fire: BSWAP the header, near and far faces swap;
- the 4 endian-neutral words (FALSE, b, not-b, TRUE);
- the 6 mirror pairs;
- x86 arithmetic quieting sNaN on addsd;
- a live 16-op census and a per-cell inspector.

## 16-operand reference

The Bare Metal page shows all 16 two-input Boolean operations, each with:
- truth table n,
- n in binary and hex,
- near/far face encoding,
- a live evaluator for a and b,
- the endian mirror partner,
- a batch test of all 16 ops x all 4 input combinations.

Its JavaScript uses a PERM table because the IEEE-754 header bits are not in
truth-table order:

```
PERM = [0,1,2,3,8,9,10,11,4,5,6,7,12,13,14,15]
```

## How NaN/0S maps

NaN16 does not use the IEEE header bits for the opcode. The class nibble is
already the truth table:

```
n = (near class << 2) | far class
bit k of n = f(a,b), k = 2a + b
```

So PERM is the identity in NaN16. This is the important difference and the
reason the NaN16 BOOL op can be its own function without a lookup.

The Sierpinski cartridge now follows the reference:
- every cell is a class-6 NaN16 word,
- payload bit 1 is the guard, bit 0 is the state,
- time flows upward,
- the viewport is 320x128 white-on-black pixels (the owner's requested palette),
- the plaque states the guard and the BSWAPM 6 -> 9 (XOR -> XNOR) mirror.

The Boole plaque states the IEEE PERM table and the NaN16 identity mapping.

## Deliberate differences

- The HTML uses IEEE-754 binary64 headers; NaN16 uses the legal near/far heads.
- The HTML uses a 200x260 canvas; the museum uses 320x128 pixels plus a 72px
  text panel.
- The HTML colours by opcode; the Sierpinski exhibit is white-on-black by
  request. The Boole exhibit still shows all 16 classes.
- The HTML is a browser demo; the museum exhibit is NaN16 on bare metal.
