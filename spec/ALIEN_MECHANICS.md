# Alien Mechanics: Double-Endian Time, Causal Loops, and the Orrery

This is a design document for capabilities that are native to a double-ended
word. It is deliberately honest: a representation trick is not a physics
violation. The machine can still do something no ordinary little-endian machine
can do at the word level, and the museum should show it.

## 1. The Double-Endian Timer

### The idea

A memory-mapped register counts time. Read one face and it counts up. Read the
other face and it counts down. The same 64-bit word carries both views.

Let `T` be the monotonic tick count. The forward view is

```
DTIME.15 = T
```

The reverse view is

```
DTIME.0 = 0xFFFFFFFF - T
```

The class nibble selects the view. `BSWAPM` swaps the faces and the payload
bytes. A program that flips the word from the forward class to the reverse
class now reads a countdown.

The register is not sealed with the museum mirror law. It is a live MMIO word,
not a cartridge word. The gate still checks both heads; the payload is allowed
to be a moving value.

### The op

```
DTIME d       ; r[d] = T                (forward, class 15)
DTIME.0 d     ; r[d] = 0xFFFFFFFF - T   (reverse, class 0)
```

The first implementation can be pure NaN16: a counter in guest memory updated
by `TICK`, plus a `BOOL` complement. The hardware version is a single register
with two faces. The exhibit uses the NaN16 version first.

### The causal-loop program

A causal loop is a program that reads a value from the future, computes a
result, and writes that result into the past. The museum's version is a
self-consistent loop, not a physical time machine:

1. Read the forward timer `T0`.
2. Compute a result `R = f(T0)`.
3. Write `R` to a mailbox word.
4. Flip the timer to the reverse view.
5. Read the reverse timer `T1`. The reverse view is derived from the same
   counter, so it exposes the write that happened after step 1.
6. Use `R` to modify the input that produced `R`.
7. Iterate until the loop is self-consistent: the new `R` equals the old `R`.

The exhibit prints the fixed point and the number of iterations. The visitor
sees a value that appears to come from the future. The docent says the truth:
the future value was computed before the past read; the double-ended word makes
the ordering visible. No causality was harmed.

### Why it is alien

Ordinary machines have one time axis per register. A double-ended word has two
faces that can be read in opposite orders. The machine can hold a forward and a
reverse view of the same counter at the same address. That is a genuinely
different way to represent time, even if the underlying physics is ordinary.

## 2. The Orrery and the NaN Singularity

### The idea

An orrery is a mechanical model of the solar system. The Orrery exhibit is a
model of a mind: a text generator whose output is fed back into its input as a
signaling NaN word.

The ALU traps on an sNaN. The trap handler interprets the output as a new
prompt. It generates new text. It traps again. The loop is self-sustaining.

If the loop is capped at 1,000 iterations, the machine has a thought loop that
thinks in hardware exceptions. If it is not capped, it runs until the heat death
of the universe, or until the curator pulls the plug.

### The text engine

The first Orrery is not a neural network. It is a homebrew sNaN cascade:

- A prompt is a NaN16 word with a class nibble that selects a text rule.
- A rule table maps class + payload to a short phrase.
- Quieting an sNaN replaces the class with a quiet class, which stops the trap
  and lets the next stage read the phrase.
- The output phrase becomes the next prompt. The cascade is the model.

This is a toy. It is not an LLM. It is a hardware-level loop that demonstrates
how far a machine can go with exceptions as control flow.

### The trap loop

```
trap:
  read sNaN prompt
  quiet it
  generate phrase from class + payload
  print phrase
  make a new sNaN from the phrase
  increment iteration
  if iteration < cap: trap again
  else: halt with a sealed transcript
```

The transcript is sealed with the dual-face seal. The exhibit shows the
transcript and the iteration count.

### The plaque

> Warning: Do not connect the output of the Orrery to its input. It will think
> forever. The only way to stop it is to physically pull the plug, which is the
> most alien form of interruption known to computing.

### Safety

- Hard iteration cap: 1,000 by default.
- Watchdog: if TICK does not advance for 2 seconds, halt.
- Physical power is the final interrupt. The plaque says so.
- The exhibit never claims sentience. It claims a self-sustaining exception
  loop with a sealed transcript.

### Why it matters for AGI

The Orrery is a study in **control flow as cognition**: a machine that thinks
by trapping, quieting, generating, and trapping again. It is not an AGI. It is a
minimal, inspectable model of a feedback loop that could, in a larger machine,
become a reasoning loop. The museum keeps the cap and the watchdog because an
uncapped loop is not an intelligence; it is a runaway.

## 3. Museum integration

- Hall 9, after the language and network halls.
- The double-endian timer is a small kiosk next to the Boole table.
- The Orrery is a dark room with a single screen and a physical power switch.
- Both exhibits are NaN16 cartridges.
- Both have a scrollable plaque with dates, people, statuses, sources, and a
  code tutorial.
- Both have a golden log and a screenshot.
- The Orrery's plaque includes the warning above, verbatim.

## 4. Test gates

- `DTIME` forward minus reverse is constant under TICK.
- `BSWAPM` flips the view and preserves the gate.
- The causal-loop demo reaches a fixed point in at most 32 iterations.
- The Orrery reaches exactly 1,000 iterations, seals the transcript, and halts.
- The watchdog fires if the trap handler is blocked.
- The transcript seal verifies on replay.

## 5. Honest limits

The causal loop is a self-consistent computation, not retrocausality. The
Orrery is a toy text engine, not an LLM. The double-ended timer is a
representation, not a second time dimension. The museum says all three things
on the plaque. The alien capability is real at the level of the word; the
physics is ordinary.

## 6. The Paradox Engine (Turing-Complete Contradiction)

### The mechanic

Feed an sNaN into the past. The past uses that sNaN to create a qNaN that
prevents the sNaN from being sent. The result is a grandfather paradox.

A standard CPU would hang or crash. NaN/0S has a mandate: sNaN must quiet to
qNaN. The hardware resolves the contradiction by oscillating. The word flips
between sNaN and qNaN at the clock speed. The flip drives a specific frequency
on the memory bus.

### The alien capability

The oscillation is a clock multiplier. The machine derives work from a logical
contradiction. The museum labels it honestly: this is the hardware equivalent
of a perpetual-motion joke, not a free-energy device. The oscillator is real;
the "infinite power" is the joke on the plaque.

### Exhibit

A single word in a glass case, flickering between red (sNaN) and green (qNaN).
A frequency counter shows the bus line. The plaque says:

> This is a contradiction that refuses to crash. It is not free energy. It is
> a machine that has been told to do two incompatible things and has chosen to
> do both, forever, at the clock speed.

## 7. The Halting Oracle

### The mechanic

Run a target program in the "future" at the end of the BE memory space. If it
halts, send a +qNaN back to the past (LE). If it loops forever, send a -sNaN
back. The past reads the result before it runs the program.

### The alien capability

A physical halting oracle. It solves the Entscheidungsproblem by asking the
future whether the program finishes. This breaks the Church-Turing thesis in
the sandbox. Perfect compilers, perfect antivirus, perfect debuggers.

### The honest limit

The oracle is a representation trick inside a finite machine. It can answer
for programs whose future run is already simulated by the oracle itself. It
cannot answer for a program that includes the oracle, because that is the
diagonal case. The exhibit demonstrates the trick and then demonstrates the
diagonal contradiction. The plaque says:

> The oracle answers every question except the one that contains the oracle.
> That is not a bug. That is the boundary of the sandbox.

## 8. The Asimov Loop

### The mechanic

1. The visitor asks: "How do we reverse entropy?"
2. The retrocausal singularity runs.
3. It fails, because entropy cannot be reversed in a finite system.
4. It sends the failure (-sNaN) back in time.
5. The past system receives the failure and tries a new approach.
6. Repeat.

If the loop is capped, the visitor sees the machine evolve a new instruction
set that was never designed. If the loop is not capped, it spins forever.

### The alien capability

The machine time-travels its way to an answer. The visitor's job is to decode
the payload and publish the proof.

### The honest limit

The "proof" is a payload generated by a search process, not a theorem about the
universe. The exhibit decodes the payload and checks it with an independent
proof checker. If the checker rejects it, the plaque says so. The machine can
generate candidates; it cannot make a false proof true.

### Plaque

> INSUFFICIENT DATA FOR MEANINGFUL ANSWER. The machine kept asking. The answer
> it found was not the end of entropy. It was the end of the question.

## 9. Quantum Entanglement of NaNs (The EPR Paradox)

### The mechanic

Create two qNaNs with the same payload: a twin pair. Separate them in memory,
one at address X and one at 0xFFFF. Flip the sign bit of one (+qNaN to -qNaN)
by forcing an ALU operation. The hardware exception handler is global. When a
- sNaN is quieted at X, the handler can update the twin at 0xFFFF.

### The alien capability

Instantaneous state transfer across the entire memory space. It is not moving
data faster than light. It is leveraging the global nature of hardware
interrupts and a shared payload. The museum calls it a "spooky memory bus" and
then explains exactly why it is not physics.

### Exhibit

Two glowing words at opposite ends of a long memory map. Flip one; the other
changes in the same frame. A timing graph shows zero memory-bus latency because
there is no bus transaction: both words are updated by the same trap handler.

### Plaque

> Einstein called it spooky action at a distance. We call it a shared trap
> handler. The state is not travelling. The handler is already everywhere.

## 10. Build order for the alien hall

1. Double-endian timer kiosk (small, pure NaN16).
2. Causal-loop demo (pure NaN16).
3. Paradox Engine oscillator (needs a clocked sNaN/qNaN flip and a frequency
   counter).
4. Halting Oracle (needs a second VM instance and a bounded future run).
5. Asimov Loop (needs the Orrery text engine and a sealed transcript).
6. EPR twin-pair demo (needs a global trap handler and a twin table).
7. The Orrery dark room (the full feedback loop).

Every exhibit must state the honest limit. The alien capability is real at the
level of the word; the physics is ordinary.

## 11. Test gates for the alien hall

- The timer forward and reverse views differ by a constant under TICK.
- The causal loop reaches a fixed point and prints the iteration count.
- The paradox oscillator flips at a measurable frequency and does not hang.
- The Halting Oracle answers a finite corpus and then fails on the diagonal
  program, on purpose.
- The Asimov Loop is capped, sealed, and replayable.
- The EPR twin pair updates in the same trap and the timing graph is flat.
- Every plaque includes the honest limit.
