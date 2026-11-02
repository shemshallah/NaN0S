# NaN/0S display + big-guest plan (Doom, Quake, and more)
## Principle
Guests never hardcode a resolution. They ASK (DISPQ), CHOOSE from what exists, and render into a logical surface that the system scales. Same rule for sound, input, timers later.
## Done in round 04
- DISPQ d: r[d] = mode<<16 | rows<<8 | cols (BIOS mode + BDA rows). DISPSET d: BIOS set mode r[d]&255.
- Verified: sierpinski exhibit auto-fits 80x25 (disp=00031950) and 40x25 (disp=00011928) with no code change, only DISPSET before DISPQ (logs/sierpinski_*.txt).
## Resolution ladder (guest asks for a target, system picks nearest not exceeding, never fails)
1. Text 80x25 / 40x25 (done). Half-block pixels (U+2580 style via CP437 DF/DC) give 80x50 / 40x50 logical pixels.
2. VGA mode 13h 320x200x256 (BIOS mode 0x13): Doom's native size. 64000 bytes = one whole 64KB segment, so NaNVM needs a second segment/bank for the framebuffer. Needs ops: FBSET (palette entry), FBPUT/FBFILL (bulk byte store), VSYNC.
3. VESA 640x480+ (VBE 0x4F02, linear framebuffer) for scaled output; needs protected mode (4. below).
4. Logical surface + scaler written IN NaN: guest draws WxH; scaler (integer/nearest, later bilinear via BOOL/ADD lanes) fills the real mode. Auto-choose integer scale; letterbox the rest.
Query contract: DISPQ returns current; DISPLIST (planned) enumerates modes; DISPSET (planned: take w,h,bpp, return what you actually got).
## What running Doom/Quake really needs (honest)
- Memory: current guest = 8192 words (64 KB). Doom wants ~4-8 MB, Quake ~16+ MB. => NaNVM1 in 32-bit protected mode (or long mode): flat memory, 32-bit word indices (LDI/LDHI address pair since imm is 16-bit), A20, no 64KB segments.
- Speed: a pure interpreter on an interpreter will not run Quake. Options: (a) port the engine source to NaN16 (needs a NaN compiler, TODO 4.2); (b) NaN-written x86 emulator running original binaries = too slow unless NaNVM1 gains a translator; (c) NaN16 vector ops: BOOL over 32 lanes already gives 32 parallel bit ops, add lane-packed ADD/MUL (SWAR) for pixels; (d) native fast paths (spans, blits) exposed as boundary ops, kept few and audited.
- Quake also needs FPU/float: NaN-boxed floats are on-theme (payload carries the value, head tags it as float); needs FADD/FMUL/FDIV/FSQRT boundary ops or software float in NaN.
- Input (KEY exists, blocking only): add KEYQ (non-blocking), mouse, PIT timer; sound (SB/AC97 or PC speaker) later. The IRQ/SVC interface contract is `spec/NANVM_SPEC.md` §9.3 (one VM spec).
- Real path: 1) NaNVM1 protected mode + flat memory, 2) NaN compiler, 3) framebuffer ops + scaler, 4) software-rendered Doom-class port, 5) revisit Quake.
## Next code steps
DISPLIST/DISPSET(w,h) -> mode map; mode 13h FBFILL/FBPUT with a plasma/Mandelbrot exhibit; scaler routine in NaN; KEYQ; interpreter size is 1011/1024 bytes so NaNVM0 must grow to 3 sectors (change boot0 + image offset) before more native ops.
