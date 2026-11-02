# Trusting Trust in a Double-Endian NaN Machine

## Self-Hosting, Diverse Double Compilation, and Dual-Face Seals in NaN/0S

**NaN/0S Trust Paper, draft r21, October 2026**

**Author: Shemshallah**

**Contact: shemshallah@gmail.com**

---

## Abstract

Can a program be trusted when the toolchain that built it may be
malicious? Ken Thompson asked this question in his 1984 Turing Award
lecture, "Reflections on Trusting Trust." He showed that a compiler can
insert a backdoor into a login program, and then re-insert the backdoor
into itself when it compiles its own source. The source of the compiler
can look clean. Reading the source is not enough.

This paper answers the question for NaN/0S, a bare-metal museum
operating system whose instructions are 64-bit double-ended NaN-like
words. We define the trust base, a self-hosting fixed point, a diverse
double compilation (DDC) procedure, and a dual-face seal. We report the
experiments that the museum can run today: nasm0 assembling itself to a
fixed point, an independent scaffold assembler rebuilding the same
source, and a seal that checks both faces of every word plus the class
channel. We state exactly what the experiments prove and what they do
not. The result is not absolute trust. It is reproducible, inspectable,
independently cross-checked trust, with honest limits.

## 1. Thompson's Question

Thompson's lecture asks:

> To what extent should one trust a statement that a program is free of
> Trojan horses? Perhaps it is more important to trust the people who
> wrote the software.

The lecture gives a concrete attack. A compiler is modified so that:

1. When it compiles the login program, it inserts a backdoor that accepts
   a known password.
2. When it compiles the compiler itself, it inserts the code that performs
   step 1 and step 2 into the new compiler.

The modified compiler's source can be clean. The binary is infected. If
the compiler is then used to rebuild itself, the infection survives. A
source review of the compiler finds nothing, because the malicious logic
is in the binary, not in the source being reviewed.

The question is not "is this source pretty?" The question is "what do we
trust, and why?" A trust argument must name its root of trust, its
procedure, its evidence, and its limits.

## 2. The NaN/0S Machine

NaN/0S is a bare-metal museum. The boot sector loads a small native
kernel. The kernel loads one guest image. The guest image is a museum
shell plus sealed cartridges. The shell runs in ring 0. There is no host
operating system underneath an exhibit.

Every NaN16 instruction is one 64-bit word:

- A near head at one end, read little-endian from bytes 6 and 7.
- A far head at the other end, read big-endian from bytes 0 and 1.
- A 32-bit payload in bytes 2 through 5.
- The payload carries opcode, destination, source, and a 16-bit
  immediate.

The class nibble is

```
n = (near class << 2) | far class
```

The four legal heads are +s, -s, +q, and -q. The class of a head is
`2*Q + S`, where Q is the quiet bit and S is the sign bit. The gate
decoder checks both faces. A word with an illegal head traps with `!G`.

For the BOOL opcode, the class nibble is the truth table. Bit k of n is
`f(a,b)` for `k = 2*a + b`. `BOOL.n d,a,b` applies that truth table
independently in all 32 bit lanes. There is no lookup table and no
branch. The opcode nibble is the function. The lane identity

```
BOOL.n(0xCCCCCCCC, 0xAAAAAAAA) = n * 0x11111111
```

is used by the Boole exhibit to prove that the class nibble really is the
function.

`BSWAPM` reverses all eight bytes of a word. It swaps the faces. For a
BOOL word with class n, the far face becomes

```
rot2(n) = ((n & 3) << 2) | (n >> 2)
```

which is exactly `f(~a,b)`. The mirror law is

```
BOOL.rot2(n)(a,b) = BOOL.n(~a,b)
```

The seal checks both faces, both payload hashes, and a class channel.
Double endianness is not a convention here. It is a second, independent
view of every word.

## 3. Threat Model

We consider an adversary who can modify any part of the toolchain that is
not in the trust base. The adversary wants a target program T to contain
a behavior that is not visible in T's source. The adversary may modify:

- the assembler,
- the linker or image builder,
- the source-to-source tools,
- the seal generator,
- the build scripts.

The adversary cannot modify the published trust base, or if they can, the
argument must say so. The adversary may know the entire procedure. There
is no secret key in the current seal. The seal is an integrity check, not
an authentication code.

The defender has:

- a small trust base that can be inspected by hand,
- multiple independent toolchains,
- a way to compare the words produced by those toolchains,
- a way to detect corruption of the shipped words,
- a way to reproduce the build from source.

## 4. The Trust Base

The trust base is deliberately small:

- **S0** is the 512-byte boot sector. It is hand-checkable and has no
  dependencies beyond the PC BIOS.
- **S1** is the native kernel. It is the only host-machine code in the
  system. It provides the NaN16 interpreter, traps, clock, keyboard,
  framebuffer, and port I/O primitives.
- **S2** is the seed assembler, nasm0, written as NaN16 words. It is the
  first program in the guest that can assemble text.
- **S3** is the source of the rest of the system: the shell, the museum,
  the exhibits, the libraries, and the paper you are reading.

Nothing above S3 is trusted by assumption. The goal is to make the gap
between S0+S1 and the rest of the system as small and as inspectable as
possible. The native kernel is an absolute necessity: a machine must
execute something before it can execute NaN words. The design keeps that
boundary narrow and documents it.

## 5. The Self-Hosting Fixed Point

Let `A` be the assembler. Let `gen0` be the binary of `A` produced by the
independent scaffold. Let `gen1 = A(gen0 source)`, the binary produced by
running gen0 on A's source. Let `gen2 = gen1(A source)`. A fixed point is
reached when `gen1` and `gen2` are word-for-word identical.

The museum's proof is:

```
python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2
```

The expected form of the output is:

```
gen0 steps ... | gen1 (guest-built code) steps ... | PASS | gen1 output == gen0 output: True
```

The important comparison is not the text output. It is the words. The
guest writes its output into a known region. The proof harvests those
words, makes them the code of gen1, runs gen1 again, and compares the new
output region word by word. If the words match, the assembler has
reproduced itself.

A fixed point alone does not prove trust. A trojan that reproduces itself
also reaches a fixed point. The fixed point proves reproducibility and
self-consistency. It is necessary, not sufficient.

## 6. Diverse Double Compilation

Diverse double compilation (DDC) is the answer to the self-reproducing
trojan. Build the same source with two independent toolchains. Compare
the resulting words. If they differ, at least one toolchain is wrong or
malicious. If they agree, a trojan must be present in both toolchains in
exactly the same way, which is a much stronger assumption for the
adversary.

NaN/0S has three builders:

- **nasm0**, the in-guest NaN16 assembler.
- **nasm1**, the in-guest x86 emitter used to build the native kernel.
- **nanchk**, the Python scaffold used as the independent reference for
  the guest image.

The DDC procedure is:

1. Build the target T with builder A. Record every word.
2. Build T with builder B. Record every word.
3. Compare the words, not the source text.
4. Build A with A and with B. Compare.
5. Build B with A and with B. Compare.
6. Repeat until the comparison is stable.

The museum's gates include:

```
python3 tools/nasm1check.py
python3 tools/test_nanvm1.py
python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2
sh tools/mkall.sh
```

`nasm1check.py` compares the boot sector and kernel bytes with the gold
image, runs the 83 encoding tests, and checks that the model and v86 agree
on the selftest serial output. `test_nanvm1.py` runs the 5,810 opcode
vectors. `mkproof.py --gen2` is the self-host fixed point. `mkall.sh`
builds the one museum image and enforces the image rule.

DDC is not a proof that both builders are honest. It is a proof that a
single-builder trojan cannot hide. If the adversary controls both
builders, DDC fails. The defense against that is provenance: publish the
builders, publish the hashes, and make the independent builder genuinely
independent.

## 7. Dual-Face Seals

Each cartridge is sealed. The seal has three channels:

- **A**: FNV-1a/32 over the near-face payload of every word.
- **B**: FNV-1a/32 over the far-face payload of every word.
- **C**: a rotate-and-XOR channel over the class nibble of every word.

The TOC stores A, B, and C. The loader recomputes all three before it
copies the cartridge to the slot. If any channel differs, the cartridge
is refused. The loader also checks:

- every head is legal,
- the far payload is the byte-swap of the near payload,
- the far class is `rot2` of the near class.

The seal is an integrity check, not a signature. It detects accidental
corruption and a large class of tampering. It does not stop an adversary
who can rewrite both the payload and the seal. A future version will add
a keyed MAC and a published append-only log of seals.

The museum's seal experiments are:

```
python3 tools/sweep_seal.py
NAN_FLIP=... python3 tools/mkimg1.py ...
NAN_HEADFLIP=... python3 tools/mkimg1.py ...
NAN_SEALBIT=... python3 tools/mkimg1.py ...
```

The mutation sweep flips payload bits, head bits, and seal bits. The
expected result is refusal with the correct status: payload mismatch,
illegal head, or mirror-law break. The seal is tested on both faces
because the word has two faces.

## 8. What Would Count as an Answer

Thompson's question asks for trust, not certainty. A complete answer for
NaN/0S has five parts:

1. **A named trust base.** S0 and S1 are small, published, and
   inspectable. The rest is built from S2 and S3.
2. **A reproducible fixed point.** nasm0 rebuilds itself word for word.
3. **Independent agreement.** A second, independently written builder
   produces the same words for the same source.
4. **Tamper evidence.** Every shipped cartridge carries a dual-face seal,
   and the loader refuses a mismatch.
5. **Honest limits.** The seal is not a signature. DDC does not defeat a
   compromised pair of builders. The native kernel is trusted, not proved.

If all five parts hold, then a claim of the form "this program was built
from this source by this published procedure, and any single-toolchain
tampering would have shown up" is justified. That is the strongest claim
the current system can make. It is stronger than source review alone and
weaker than a formal proof of the entire stack.

## 9. The Experiments

The museum records each experiment as a log:

- `logs/nasm0_selfhost_gen2_round09.txt`: the self-host fixed point.
- `logs/nasm1_check.txt`: the 83 encoding tests and the v86 selftest.
- `logs/nanvm1_ops_test.txt`: the 5,810 opcode checks.
- `logs/v29_seal.txt`: the first corrupted-cartridge refusal.
- `logs/v37_seal2.txt`: dual-face seal tests.
- `logs/r21_trust_test.txt`: the r21 Trust test transcript.

The r21 transcript is generated by running the commands in this paper
and saving the output. The reader can rerun them. A result that cannot
be rerun is not evidence.

## 10. Limitations

The current answer has real limits:

- The native kernel is host-machine code. It is small, but it is trusted.
  A full proof would need a verified kernel or a verified translation.
- The seal is FNV-1a/32, not a cryptographic MAC. It detects corruption,
  not a determined forger.
- The DDC independence is only as good as the independence of the
  builders. The Python scaffold and the in-guest assemblers share ideas,
  even if they do not share code.
- The fixed point is a word-level comparison. It does not prove semantic
  equivalence to a specification.
- The museum's exhibits are re-creations and inspired works, not all
  bit-for-bit historical artifacts.

These limits are part of the paper. A trust argument that hides its
limits is not a trust argument.

## 11. Conclusion

Thompson's question does not have a single yes-or-no answer. It has a
procedure. Name the trust base. Reproduce the build. Cross-check it with
an independent builder. Seal the result. Publish the evidence. State the
limits. Repeat when the toolchain changes.

NaN/0S is a machine that can show its work. Its words have two faces. Its
assembler can rebuild itself. Its museum refuses a cartridge whose faces
disagree. That is not absolute trust. It is the beginning of an answer,
and it is small enough to inspect.

## References

1. Ken Thompson, "Reflections on Trusting Trust," Communications of the
   ACM, 27(8), 1984. Turing Award lecture.
2. David A. Wheeler, "Countering Trusting Trust through Diverse Double
   Compiling," 2005.
3. Ken Thompson and Dennis Ritchie, The UNIX Time-Sharing System, 1974.
4. NaN/0S, spec/NAN16_SPEC.md and spec/NANVM_SPEC.md.
5. NaN/0S, logs/nasm0_selfhost_gen2_round09.txt and logs/r21_trust_test.txt.

---

*This paper is hosted in the museum as a scrollable exhibit. The preface
names Thompson and his question. The body is the paper. The reader can
walk from the question to the procedure to the evidence without leaving
the machine.*
