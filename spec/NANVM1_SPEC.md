# NaNVM1 spec v0.2 (draft; ops 0x20-0x37 implemented and tested in tools/nan16sim.py, Sim(..., isa=1))
NaN16 v0.1 ops 0x00-0x1B are unchanged. isa=0 keeps the old rule (op > 0x1F traps !O). The native VM is still NaNVM0 (8192 words); nothing here runs in v86 yet.
Why: Quake needs 32-bit multiply/divide, signed math, byte access, block moves and float32. Without them every pixel and every vertex costs dozens of ops.
## New ops (payload [31:24]=op, d, a, b=imm[3:0] or imm16; predication as before)
20 MUL d,a,b low32 | 21 MULH signed high32 | 22 MULHU | 23 DIV signed trunc | 24 MOD (sign of dividend) | 25 DIVU | 26 MODU
 divide/mod by 0: DIV/DIVU -> 0, MOD/MODU -> a, flags (Z,L)=(1,1) (only ALWAYS ops run next, so a [NE]/[EQ] guard skips)
27 SAR d,a,imm5 | 28 CMPS a,b signed compare (Z=eq, L=signed lt) | 29 ADDI d,a,imm16 (sign-extended, L=carry; write -1 as 0xFFFF)
2A LDB d,a,imm | 2B STB d,a,imm : byte address r[a]+imm, 4 bytes per word payload, little end first; STB rewrites the word as +q/+q
2C CALLR a (r15=pc, pc=r[a]) | 2D BCOPY d,a,b : b words from word r[a] to word r[d], memmove semantics, both-face class kept | 2E BFILL d,a,b : b words at r[d] = +q/+q payload r[a]
2F reserved
30 FADD 31 FSUB 32 FMUL 33 FDIV 34 FSQRT d,a 35 FCMP a,b 36 CVTIF d,a 37 CVTFI d,a : IEEE-754 binary32 in the payload, round to nearest even.
 FCMP sets Z=eq L=lt; unordered (NaN) sets (Z,L)=(1,1), the state the integer ops can never reach, so EQ/NE/LT/GT/LE/GE all skip. CVTFI truncates, saturates, NaN -> 0. Negate/abs = BOOL with 0x80000000 / 0x7FFFFFFF.
 Deliberately NOT yet: FSIN/FCOS/FATAN2 (tables or NaN polynomials first), FMA, SIMD lanes, FB ops.
## Memory and pc
Flat 2^k words, k<=28; LD/ST/STW/BSWAPM/LDB/STB/BCOPY use 32-bit register addresses; pc is 32 bits when nwords>65536 (JMPR/RET/CALLR reach everywhere, JMP/CALL imm stay 16 bits so hot code lives low; far = MOVI+MOVHI+JMPR).
## Evidence
tools/test_nanvm1.py: 5810 checks (random + edge vectors, python ints and numpy float32 as references), logs/nanvm1_ops_test.txt. nasm0 (in the guest) still reaches its fixed point with the 51-mnemonic table: logs/nasm0_selfhost_gen2_round09.txt.
## Still open (native)
x86 implementation of these ops in NaNVM1, protected mode, big memory, then v86 cross-check. All numbers above are Python-model results, not hardware.
