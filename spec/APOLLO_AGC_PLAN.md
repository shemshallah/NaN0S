# Hall 1 - The Apollo Guidance Computer (AGC)

This is the owner's favourite hall. The goal is a homebrew AGC emulator written
in NaN16, a DSKY, a 1202 alarm demo, and a lunar-descent toy. No NASA ROM
contents are shipped unless their public-domain status is verified. The AGC
programs in the exhibit are written by us.

## The machine

- 15-bit words. The AGC stores a word as 15 meaningful bits plus a parity bit.
- 2,048 words of erasable memory (RAM), 36,864 words of fixed memory (core
  rope ROM).
- About 2.048 MHz clock. Roughly 85,000 instructions per second in the class
  used by the flight software.
- Instruction format: 3-bit opcode, 12-bit address, and extra bits. The exact
  encoding is documented in the AGC instruction set and must be verified
  before the emulator is called EXACT.
- Registers: A, L, Q, Z, and the 12-bit program counter. The AGC has a
  four-stage instruction pipeline and special central-register instructions.
- I/O: DSKY keyboard and display, inertial measurement unit, radar, hand
  controller, and downlink telemetry.

## People

- Charles Stark Draper, 1901-1987, DEAD. Founder of the MIT Instrumentation
  Laboratory. The AGC is named after him.
- Margaret Hamilton, 1936-, LIVING. Software lead for the Apollo flight
  software. Her team's error detection and recovery is the reason the 1202
  alarm was survivable.
- Jack Garman, 1945-2016, DEAD. Mission Operations Computer engineer who
  recognised the 1202 alarm and called "go" during the descent.
- Gene Kranz, 1933-, LIVING. Flight Director during the Apollo 11 landing.
- Neil Armstrong, 1930-2012, DEAD. Commander, Apollo 11.
- Buzz Aldrin, 1930-, LIVING. Lunar Module Pilot, Apollo 11.
- Michael Collins, 1930-2021, DEAD. Command Module Pilot, Apollo 11.

Verify each status against a current source before shipping the plaque. The
dates above are the working values.

## Exhibit plan

1. **AGC CPU core in NaN16.** Pack a 15-bit word into the 32-bit payload. Use
   the class nibble for parity/validity. Implement the full documented
   instruction set in phases, starting with the central registers, TC, CCS,
   INDEX, XCH, CS, TS, AD, MASK, and EXTEND.
2. **Assembler.** An AGC assembly subset in NaN16: labels, octal constants,
   the instruction mnemonics, and the DSKY channel words. The assembler is a
   museum tool, not a copy of NASA's assembler.
3. **DSKY.** A pixel display with the PROG, VERB, NOUN, and data registers,
   plus the keyboard. The DSKY is drawn with the framebuffer font or a custom
   7-segment font.
4. **1202 alarm demo.** A scripted descent where the computer is overloaded
   and the executive issues a 1202. The visitor sees the DSKY flash, the
   mission controller call "go", and the landing continue. This is a
   re-creation, not the flight software.
5. **Lunar descent toy.** A homebrew guidance program: throttle, attitude,
   altitude, and fuel. The physics is simple and documented. The point is the
   interface, not a flight-certified simulation.
6. **Core memory visual.** A grid of 15-bit words with parity bits and a
   sense-line animation.
7. **MIPS ladder.** The AGC row is about 85k instructions per second class.
   The exhibit prints "this VM = N x AGC" and cites the source.

## Bare-metal mapping

- The AGC core is a NaN16 interpreter. It does not need a new native op.
- The DSKY uses the mode 13h framebuffer and the 3x5 font (or a 7-segment font
  written in NaN16).
- The keyboard uses KEY/KEYQ. The museum shell already has the ring.
- The AGC word is packed into the NaN16 payload. The near/far heads carry
  validity and parity, so an illegal AGC word is a gate trap, not a crash.
- The AGC memory is a region allocated by nalloc when A5 lands. Until then,
  the exhibit uses a fixed buffer below the cartridge store.

## Test gates

- A 15-bit arithmetic test vector set from the AGC instruction manual.
- A known program trace: fetch, index, execute, branch.
- DSKY key sequence produces the expected display words.
- 1202 demo reaches the alarm word and recovers.
- The exhibit returns to the shell with ESC.
- The plaque is scrollable and includes dates, people, statuses, sources,
  and a code tutorial.

## Honest limit

The AGC is a re-creation. It is not a certified flight simulator. The
instruction semantics must be verified against primary sources before the
badge can move from RE-CREATION to EXACT. The ROM contents are homebrew.
