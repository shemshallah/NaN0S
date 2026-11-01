# NaN16 spec v0.1 (frozen at round 02; round 08: documented ops 0x18-0x1B, no semantic change)
## Word (64-bit, memory bytes b0..b7)
near head = LE read of b6,b7 ; far head = BE read of b0,b1 ; payload = b2..b5 (32 bits, LE).
Legal heads (both faces, else GATE TRAP): +s 7FF1, -s FFF1, +q 7FF8, -q FFF8. Class c = 2*Q + S (Q=quiet, S=sign): +s0 -s1 +q2 -q3.
Class nibble n = (c_near<<2) | c_far. n IS the truth table: bit k of n = f(a,b), k = 2a+b. Matches all 16 rows of the 16-operand HTML.
Source line format (.nan): NNNN_PPPPPPPP_FFFF = near head, payload, far head as stored in b0,b1 (LE16, i.e. byte-swapped head). Examples: +q/+q data = 7FF8_pppppppp_F87F. Heads->far LE16: 7FF1:F17F FFF1:F1FF 7FF8:F87F FFF8:F8FF.
bswap of a word swaps the faces: n -> rot2(n) = ((n&3)<<2)|(n>>2) (= f(~a,b)); payload bytes reverse. Neutral words (near==far): n=0,5,10,15; 10 orbits.
Lane trick: BOOL_n(0xCCCCCCCC, 0xAAAAAAAA) == n*0x11111111, so the opcode is literally the output.
## Machine
r0..r15 32-bit. Convention: r0=0, r13=1, r14=SP (software), r15=link (CALL/RET). Flags Z,L; flag index k=2Z+L.
Memory: 8192 words (indices wrap & 0x1FFF), image loaded at word 0, pc starts 0. VGA text B800, 80x25.
Payload: [31:24]=op [23:20]=d [19:16]=a [15:0]=imm16 ; b = imm[3:0].
Predication: every op except BOOL runs only if bit (2Z+L) of n is 1. ALWAYS n=15, NEVER 0, EQ 4, NE 3, LT 2, GE 5, GT 1, LE 6.
Flags: BOOL Z=res==0,L=0 ; ADD L=carry ; SUB L=borrow ; SHL/SHR Z,L=0 ; CMP Z=(a==b),L=(a<b unsigned). (Z,L)=(1,1) unreachable.
## Ops
00 BOOL d,a,b (n = function, bitwise on 32 lanes) | 01 MOVI d,imm | 02 MOVHI d,imm (upper 16) | 03 ADD | 04 SUB | 05 SHL d,a,imm5 | 06 SHR d,a,imm5 | 07 CMP a,b
08 LD d,a,imm (payload of mem[r[a]+imm]) | 09 ST d,a,imm (writes +q/+q word) | 0A JMP imm | 0B CALL imm (r15=pc) | 0C RET | 0D JMPR a | 0F NOP
10 VPOKE d,a (cell r[a] <- r[d]) | 11 VPEEK d,a | 12 KEY d (blocking) | 13 TICK d | 14 BSWAPM a,imm (reverse 8 bytes of word) | 15 PUTC d (BIOS teletype) | 16 STW d,a,b (mem[r[a]] = word(class r[b]&15, payload r[d])) | 17 LDN d,a,imm (class nibble, FFFFFFFF if gate fails) | 18 DISPQ d (r[d]=mode<<16|rows<<8|cols) | 19 DISPSET d (BIOS mode r[d]&255) | 1A KEYQ d (non-blocking key, 0 if none) | 1B BEEP d | FF HALT. Others: bad-op trap.
Traps print !G<pc> (gate) or !O<pc> (bad op) and halt.
## Known prototype discrepancy
The Lattice HTML maps header bits m=(Qn,Sn,Qf,Sf) to n through PERM=[0,1,2,3,8,9,10,11,4,5,6,7,12..15]; the 16-operand HTML (and this spec) use identity. Same word is a different function in the two pages. Spec follows the 16-operand page. Lattice needs PERM removed before it can run NaN/0S words.
