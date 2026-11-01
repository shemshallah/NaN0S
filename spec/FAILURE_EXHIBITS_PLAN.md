# Hall 7 - Failure Exhibits: Patriot (1991) and Ariane 5 (1996)

These are not celebration exhibits. They are precision-failure exhibits. The
visitor watches a representation fail. Both are executable NaN16 cartridges.

## Exhibit: The Patriot Missile Failure (1991)

**Date of event:** 25 February 1991, Dhahran, Saudi Arabia.

**Badge:** RE-CREATION.

### Nerd hook

A 24-bit fixed-point truncation caused a clock drift of roughly
0.000000095 seconds per hour. After about 100 hours of continuous operation the
tracking clock was off by about 0.34 seconds. A Scud at roughly 1.6 km/s moves
about 550 metres in that time. The intercept window was tens of metres. The
battery missed. Twenty-eight soldiers died.

The exact drift figure and the exact number of hours are reported in the U.S.
General Accounting Office report on the Patriot. The exhibit prints the model
and the source of each number, and marks the figures that are approximate.

### Deep implementation

The screen is a tracking display, not a text page:

- A radar sweep and a target track in VGA mode 13h.
- A 24-bit fixed-point clock. The low bits are truncated exactly as the
  historical software truncated them.
- A real-time drift accumulator. The visitor watches the predicted intercept
  point slide away from the true point.
- The track box narrows as the miss grows.
- When the error exceeds the intercept window, the coordinate is replaced by
  a NaN word. The screen prints `!G` and the exhibit ends with a black screen
  and the names of the dead.

The NaN16 code uses the class nibble as the representation warning: a
coordinate that is "not a number" is a legal NaN word, not an exception. The
Patriot had no such state. That is the point.

### Plaque

> This exhibit is a tragedy of representation. The system didn't lack
> processing power; it lacked the bits to represent time accurately. Here, in a
> NaN machine, we have infinite ways to represent 'undefined' - but the Patriot
> had none.

### People and sources

- The 28 soldiers killed in Dhahran, 25 February 1991. Status: DEAD.
- Theodore A. Postol, 1946-, MIT physicist who publicly analysed the failure.
  Status: LIVING.
- U.S. General Accounting Office, "Patriot Missile Defense: Software Problem
  Led to System Failure at Dhahran, Saudi Arabia," 1992.
- The exhibit is a re-creation. It is not the classified Patriot software.

### Test gate

A fixed seed produces a known miss distance and a known `!G` word. The log is
`logs/patriot.txt`.

## Exhibit: The Ariane 5 Explosion (1996)

**Date of event:** 4 June 1996, Kourou, French Guiana.

**Badge:** RE-CREATION.

### Nerd hook

A 64-bit floating-point value was converted to a 16-bit signed integer. The
value was too large. The conversion raised a hardware exception. The backup
computer ran the same software and failed for the same reason. The rocket
disintegrated about 37 seconds after launch. The payload, Cluster, was lost.

This is the exact opposite of NaN. The system demanded a number and got an
overflow. NaN/0S is built on the premise that "invalid" is a valid state. The
Ariane 5 software did not have that luxury.

### Deep implementation

The screen is a 16-bit boundary box:

- A 64-bit velocity vector grows as the rocket climbs.
- A 16-bit signed boundary box is drawn around the allowed range.
- The vector crosses the box. The box flashes.
- The conversion fault prints a crash log in the museum's seal style:
  `SEAL MISMATCH` is not used as a joke; the log says `CONVERSION OVERFLOW`,
  then the two inertial reference system traces, then the breakup.
- The final screen is the flight path and the empty payload bay.

The arithmetic is done in NaN16 with a 64-bit software float (two 32-bit
words) and a 16-bit signed check. The overflow is forced at the same
horizontal-bias value class as the historical failure. The exhibit prints the
model and says which numbers are illustrative.

### Plaque

> Ariane 5 was a masterpiece of engineering destroyed by a 16-bit boundary.
> Your NaN VM is built on the premise that 'invalid' is a valid state. The
> engineers of Ariane 5 did not have that luxury.

### People and sources

- Jacques-Louis Lions, 1928-2001, DEAD, chairman of the Ariane 5 inquiry board.
- The Ariane 5 project team, ESA, CNES, and Arianespace. The team is an
  organisation, not a list of named living people.
- Ariane 5 Flight 501 Inquiry Board Report, 1996.
- The exhibit is a re-creation. It is not the flight software.

### Test gate

A fixed seed produces a known overflow word and crash log. The log is
`logs/ariane5.txt`.

## Shared requirements

- Both exhibits run from the museum menu as cartridges.
- Both have a scrollable plaque and a test log.
- Both carry dates, people, statuses, sources, and a code tutorial.
- Both use the framebuffer driver, not ASCII art, for the main visual.
- Both can be interrupted with ESC; the shell must remain alive.
- Both are homebrew. No proprietary flight software is shipped.
