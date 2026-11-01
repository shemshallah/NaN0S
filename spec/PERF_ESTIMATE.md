# Span cost and guest-speed estimate (round 12). Guest op counts are MEASURED in the Python model; everything after "Arithmetic" is ARITHMETIC, not a hardware measurement.
## Measured (logs/spanbench.txt, src/prog/spanbench.nas, isa=1, 64000 pixels, checked byte for byte against a MUL/DIVU reference)
plain loop: 0x2C2 kilo-ops = 706000 / 64000 = 11.03 guest ops per pixel (11 in the loop body + row setup)
unrolled x4: 0x232 kilo-ops = 562000 / 64000 = 8.78 guest ops per pixel (8.75 in the body)
Loop body per pixel: SHR s, SHR t, SHL t, ADD, LDB, STB, ADD s, ADD t (+ loop overhead). No lighting/colormap lookup, no perspective subdivision, no mip choice: a real Quake span adds some of those.
## Arithmetic
320x200 at 30 fps = 1.92 M pixels/s. At 1x overdraw, spans alone: 1.92M x 8.78 = 16.9 M guest ops/s (21.2 M plain).
640x400 at 30 fps is 4x that: 67 M guest ops/s unrolled.
A 3 GHz host has 3000/16.9 = about 177 host cycles per guest op at 320x200 for spans alone. A table-driven x86 interpreter step is typically tens of cycles, so spans alone look affordable; edges, vertices, BSP walk, lighting and overdraw come on top and are NOT measured here.
## What would change the picture
Fused ops for the span step (e.g. a single op for the s/t split and address build) cut the 8.78. A NaN->native translator cuts the interpretation cost to near 1 host instruction per guest op. Neither exists yet.
