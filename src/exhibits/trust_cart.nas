; TEXT CARTRIDGE: scrollable museum page. Runtime code is NaN16 only.
; ABI: r0=0 r13=1; V_SCROLL is the general shell 80x25 scroll vector.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_SCROLL 12
.equ NLINES 376
.equ VISIBLE 24
.org 8192
cart_entry:
ST r15,r0,@tr_ret
MOVI r13,1
MOVI r10,0
CALL @tr_render
tr_poll:
KEY r1
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @tr_exit
MOVI r4,0x80
CMP r1,r4
JMP[EQ] @tr_up
MOVI r4,0x81
CMP r1,r4
JMP[EQ] @tr_down
MOVI r4,0x82
CMP r1,r4
JMP[EQ] @tr_pgup
MOVI r4,0x83
CMP r1,r4
JMP[EQ] @tr_pgdn
JMP @tr_poll
tr_exit:
LD r15,r0,@tr_ret
RET
tr_ret:
.word 0
tr_up:
CMP r10,r0
JMP[EQ] @tr_poll
SUB r10,r10,r13
MOVI r1,0
SUB r1,r1,r13
MOVI r2,0x0720
CALL #V_SCROLL
CALL @tr_clr0
ADD r1,r10,r0
CALL @tr_lineptr
CMP r1,r0
JMP[EQ] @tr_foot
MOVI r2,0
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
JMP @tr_foot
tr_down:
MOVI r4,#NLINES
MOVI r5,#VISIBLE
SUB r4,r4,r5
CMP r10,r4
JMP[GE] @tr_poll
ADD r10,r10,r13
MOVI r1,1
MOVI r2,0x0720
CALL #V_SCROLL
CALL @tr_clr23
ADD r1,r10,r0
MOVI r5,#VISIBLE
SUB r5,r5,r13
ADD r1,r1,r5
CALL @tr_lineptr
CMP r1,r0
JMP[EQ] @tr_foot
MOVI r2,1840
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
JMP @tr_foot
tr_foot:
CALL @tr_footer
JMP @tr_poll
tr_pgup:
MOVI r4,10
CMP r10,r4
JMP[LT] @tr_pgup0
SUB r10,r10,r4
JMP @tr_redraw
tr_pgup0:
MOVI r10,0
JMP @tr_redraw
tr_pgdn:
MOVI r4,#NLINES
MOVI r5,#VISIBLE
SUB r4,r4,r5
MOVI r5,10
ADD r10,r10,r5
CMP r10,r4
JMP[LE] @tr_redraw
ADD r10,r4,r0
JMP @tr_redraw
tr_redraw:
CALL @tr_render
JMP @tr_poll
tr_render:
ST r15,r0,@trr_ret
CALL #V_CLS
MOVI r11,0
trr_loop:
MOVI r4,#VISIBLE
CMP r11,r4
JMP[GE] @trr_foot
ADD r1,r10,r0
ADD r1,r1,r11
CALL @tr_lineptr
CMP r1,r0
JMP[EQ] @trr_foot
MOVI r2,80
MUL r2,r11,r2
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
ADD r11,r11,r13
JMP @trr_loop
trr_foot:
CALL @tr_footer
LD r15,r0,@trr_ret
RET
trr_ret:
.word 0
tr_lineptr:
MOVI r3,#NLINES
CMP r1,r3
JMP[GE] @trl_none
MOVI r3,@tr_lines
ADD r3,r3,r1
LD r1,r3,0
RET
trl_none:
MOVI r1,0
RET
tr_clr0:
MOVI r4,0
MOVI r5,80
MOVI r6,0x0720
JMP @tr_fill
tr_clr23:
MOVI r4,1840
MOVI r5,1920
MOVI r6,0x0720
tr_fill:
CMP r4,r5
JMP[GE] @tr_fill_done
VPOKE r6,r4
ADD r4,r4,r13
JMP @tr_fill
tr_fill_done:
RET
tr_footer:
ST r15,r0,@trf_ret
MOVI r1,@tr_foot_str
MOVI r2,1920
MOVI r3,0x0E00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
ADD r1,r10,r0
ADD r1,r1,r13
MOVI r2,1982
MOVI r3,0x0E00
CALL #V_DEC
LD r15,r0,@trf_ret
RET
trf_ret:
.word 0
tr_foot_str:
.str "UP/DOWN scroll  LEFT/RIGHT page  ESC shell  line "
; ---- page text ----
TP000:
.str " NaN/0S - THE TRUST EXHIBIT"
TP001:
.str " KEN THOMPSON AND THE QUESTION OF TRUST"
TP002:
.str ""
TP003:
.str " THE MAN"
TP004:
.str " Ken Thompson was born 4 February 1943 in New Orleans, Louisiana."
TP005:
.str " Status: LIVING. He joined Bell Labs in 1966. With Dennis Ritchie he"
TP006:
.str " created Unix. He created the B language, co-created Plan 9 and Inferno,"
TP007:
.str " co-created UTF-8 with Rob Pike, and co-created Go with Rob Pike and"
TP008:
.str " Robert Griesemer. He received the Turing Award in 1983. In 1984 he gave"
TP009:
.str " the Turing Award lecture 'Reflections on Trusting Trust'."
TP010:
.str ""
TP011:
.str " THE QUESTION"
TP012:
.str " To what extent should one trust a statement that a program is free of"
TP013:
.str " Trojan horses? Perhaps it is more important to trust the people who"
TP014:
.str " wrote the software. Thompson showed a compiler that inserts a backdoor"
TP015:
.str " into login, then re-inserts the backdoor into itself when it compiles"
TP016:
.str " its own source. The source looks clean. The binary is infected. Source"
TP017:
.str " review alone cannot answer the question."
TP018:
.str ""
TP019:
.str " THE ANSWER THIS MUSEUM BUILDS"
TP020:
.str " A named trust base. A self-hosting fixed point. An independent builder."
TP021:
.str " A dual-face seal. A published log. And an honest list of limits. The"
TP022:
.str " paper below is the whole argument. UP/DOWN scrolls one line. LEFT/RIGHT"
TP023:
.str " moves ten lines. ESC returns to the museum."
TP024:
.str ""
TP025:
.str " ------------------------------------------------------------------"
TP026:
.str ""
TP027:
.str "# Trusting Trust in a Double-Endian NaN Machine"
TP028:
.str ""
TP029:
.str "## Self-Hosting, Diverse Double Compilation, and Dual-Face Seals in NaN/0S"
TP030:
.str ""
TP031:
.str "**NaN/0S Trust Paper, draft r21, October 2026**"
TP032:
.str ""
TP033:
.str "**Author: Shemshallah**"
TP034:
.str ""
TP035:
.str "**Contact: shemshallah@gmail.com**"
TP036:
.str ""
TP037:
.str "---"
TP038:
.str ""
TP039:
.str "## Abstract"
TP040:
.str ""
TP041:
.str "Can a program be trusted when the toolchain that built it may be"
TP042:
.str "malicious? Ken Thompson asked this question in his 1984 Turing Award"
TP043:
.str "lecture, 'Reflections on Trusting Trust.' He showed that a compiler can"
TP044:
.str "insert a backdoor into a login program, and then re-insert the backdoor"
TP045:
.str "into itself when it compiles its own source. The source of the compiler"
TP046:
.str "can look clean. Reading the source is not enough."
TP047:
.str ""
TP048:
.str "This paper answers the question for NaN/0S, a bare-metal museum"
TP049:
.str "operating system whose instructions are 64-bit double-ended NaN-like"
TP050:
.str "words. We define the trust base, a self-hosting fixed point, a diverse"
TP051:
.str "double compilation (DDC) procedure, and a dual-face seal. We report the"
TP052:
.str "experiments that the museum can run today: nasm0 assembling itself to a"
TP053:
.str "fixed point, an independent scaffold assembler rebuilding the same"
TP054:
.str "source, and a seal that checks both faces of every word plus the class"
TP055:
.str "channel. We state exactly what the experiments prove and what they do"
TP056:
.str "not. The result is not absolute trust. It is reproducible, inspectable,"
TP057:
.str "independently cross-checked trust, with honest limits."
TP058:
.str ""
TP059:
.str "## 1. Thompson's Question"
TP060:
.str ""
TP061:
.str "Thompson's lecture asks:"
TP062:
.str ""
TP063:
.str "> To what extent should one trust a statement that a program is free of"
TP064:
.str "> Trojan horses? Perhaps it is more important to trust the people who"
TP065:
.str "> wrote the software."
TP066:
.str ""
TP067:
.str "The lecture gives a concrete attack. A compiler is modified so that:"
TP068:
.str ""
TP069:
.str "1. When it compiles the login program, it inserts a backdoor that accepts"
TP070:
.str "   a known password."
TP071:
.str "2. When it compiles the compiler itself, it inserts the code that performs"
TP072:
.str "   step 1 and step 2 into the new compiler."
TP073:
.str ""
TP074:
.str "The modified compiler's source can be clean. The binary is infected. If"
TP075:
.str "the compiler is then used to rebuild itself, the infection survives. A"
TP076:
.str "source review of the compiler finds nothing, because the malicious logic"
TP077:
.str "is in the binary, not in the source being reviewed."
TP078:
.str ""
TP079:
.str "The question is not 'is this source pretty?' The question is 'what do we"
TP080:
.str "trust, and why?' A trust argument must name its root of trust, its"
TP081:
.str "procedure, its evidence, and its limits."
TP082:
.str ""
TP083:
.str "## 2. The NaN/0S Machine"
TP084:
.str ""
TP085:
.str "NaN/0S is a bare-metal museum. The boot sector loads a small native"
TP086:
.str "kernel. The kernel loads one guest image. The guest image is a museum"
TP087:
.str "shell plus sealed cartridges. The shell runs in ring 0. There is no host"
TP088:
.str "operating system underneath an exhibit."
TP089:
.str ""
TP090:
.str "Every NaN16 instruction is one 64-bit word:"
TP091:
.str ""
TP092:
.str "- A near head at one end, read little-endian from bytes 6 and 7."
TP093:
.str "- A far head at the other end, read big-endian from bytes 0 and 1."
TP094:
.str "- A 32-bit payload in bytes 2 through 5."
TP095:
.str "- The payload carries opcode, destination, source, and a 16-bit"
TP096:
.str "  immediate."
TP097:
.str ""
TP098:
.str "The class nibble is"
TP099:
.str ""
TP100:
.str "```"
TP101:
.str "n = (near class << 2) | far class"
TP102:
.str "```"
TP103:
.str ""
TP104:
.str "The four legal heads are +s, -s, +q, and -q. The class of a head is"
TP105:
.str "`2*Q + S`, where Q is the quiet bit and S is the sign bit. The gate"
TP106:
.str "decoder checks both faces. A word with an illegal head traps with `!G`."
TP107:
.str ""
TP108:
.str "For the BOOL opcode, the class nibble is the truth table. Bit k of n is"
TP109:
.str "`f(a,b)` for `k = 2*a + b`. `BOOL.n d,a,b` applies that truth table"
TP110:
.str "independently in all 32 bit lanes. There is no lookup table and no"
TP111:
.str "branch. The opcode nibble is the function. The lane identity"
TP112:
.str ""
TP113:
.str "```"
TP114:
.str "BOOL.n(0xCCCCCCCC, 0xAAAAAAAA) = n * 0x11111111"
TP115:
.str "```"
TP116:
.str ""
TP117:
.str "is used by the Boole exhibit to prove that the class nibble really is the"
TP118:
.str "function."
TP119:
.str ""
TP120:
.str "`BSWAPM` reverses all eight bytes of a word. It swaps the faces. For a"
TP121:
.str "BOOL word with class n, the far face becomes"
TP122:
.str ""
TP123:
.str "```"
TP124:
.str "rot2(n) = ((n & 3) << 2) | (n >> 2)"
TP125:
.str "```"
TP126:
.str ""
TP127:
.str "which is exactly `f(~a,b)`. The mirror law is"
TP128:
.str ""
TP129:
.str "```"
TP130:
.str "BOOL.rot2(n)(a,b) = BOOL.n(~a,b)"
TP131:
.str "```"
TP132:
.str ""
TP133:
.str "The seal checks both faces, both payload hashes, and a class channel."
TP134:
.str "Double endianness is not a convention here. It is a second, independent"
TP135:
.str "view of every word."
TP136:
.str ""
TP137:
.str "## 3. Threat Model"
TP138:
.str ""
TP139:
.str "We consider an adversary who can modify any part of the toolchain that is"
TP140:
.str "not in the trust base. The adversary wants a target program T to contain"
TP141:
.str "a behavior that is not visible in T's source. The adversary may modify:"
TP142:
.str ""
TP143:
.str "- the assembler,"
TP144:
.str "- the linker or image builder,"
TP145:
.str "- the source-to-source tools,"
TP146:
.str "- the seal generator,"
TP147:
.str "- the build scripts."
TP148:
.str ""
TP149:
.str "The adversary cannot modify the published trust base, or if they can, the"
TP150:
.str "argument must say so. The adversary may know the entire procedure. There"
TP151:
.str "is no secret key in the current seal. The seal is an integrity check, not"
TP152:
.str "an authentication code."
TP153:
.str ""
TP154:
.str "The defender has:"
TP155:
.str ""
TP156:
.str "- a small trust base that can be inspected by hand,"
TP157:
.str "- multiple independent toolchains,"
TP158:
.str "- a way to compare the words produced by those toolchains,"
TP159:
.str "- a way to detect corruption of the shipped words,"
TP160:
.str "- a way to reproduce the build from source."
TP161:
.str ""
TP162:
.str "## 4. The Trust Base"
TP163:
.str ""
TP164:
.str "The trust base is deliberately small:"
TP165:
.str ""
TP166:
.str "- **S0** is the 512-byte boot sector. It is hand-checkable and has no"
TP167:
.str "  dependencies beyond the PC BIOS."
TP168:
.str "- **S1** is the native kernel. It is the only host-machine code in the"
TP169:
.str "  system. It provides the NaN16 interpreter, traps, clock, keyboard,"
TP170:
.str "  framebuffer, and port I/O primitives."
TP171:
.str "- **S2** is the seed assembler, nasm0, written as NaN16 words. It is the"
TP172:
.str "  first program in the guest that can assemble text."
TP173:
.str "- **S3** is the source of the rest of the system: the shell, the museum,"
TP174:
.str "  the exhibits, the libraries, and the paper you are reading."
TP175:
.str ""
TP176:
.str "Nothing above S3 is trusted by assumption. The goal is to make the gap"
TP177:
.str "between S0+S1 and the rest of the system as small and as inspectable as"
TP178:
.str "possible. The native kernel is an absolute necessity: a machine must"
TP179:
.str "execute something before it can execute NaN words. The design keeps that"
TP180:
.str "boundary narrow and documents it."
TP181:
.str ""
TP182:
.str "## 5. The Self-Hosting Fixed Point"
TP183:
.str ""
TP184:
.str "Let `A` be the assembler. Let `gen0` be the binary of `A` produced by the"
TP185:
.str "independent scaffold. Let `gen1 = A(gen0 source)`, the binary produced by"
TP186:
.str "running gen0 on A's source. Let `gen2 = gen1(A source)`. A fixed point is"
TP187:
.str "reached when `gen1` and `gen2` are word-for-word identical."
TP188:
.str ""
TP189:
.str "The museum's proof is:"
TP190:
.str ""
TP191:
.str "```"
TP192:
.str "python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2"
TP193:
.str "```"
TP194:
.str ""
TP195:
.str "The expected form of the output is:"
TP196:
.str ""
TP197:
.str "```"
TP198:
.str "gen0 steps ... | gen1 (guest-built code) steps ... | PASS | gen1 output =="
TP199:
.str "gen0 output: True"
TP200:
.str "```"
TP201:
.str ""
TP202:
.str "The important comparison is not the text output. It is the words. The"
TP203:
.str "guest writes its output into a known region. The proof harvests those"
TP204:
.str "words, makes them the code of gen1, runs gen1 again, and compares the new"
TP205:
.str "output region word by word. If the words match, the assembler has"
TP206:
.str "reproduced itself."
TP207:
.str ""
TP208:
.str "A fixed point alone does not prove trust. A trojan that reproduces itself"
TP209:
.str "also reaches a fixed point. The fixed point proves reproducibility and"
TP210:
.str "self-consistency. It is necessary, not sufficient."
TP211:
.str ""
TP212:
.str "## 6. Diverse Double Compilation"
TP213:
.str ""
TP214:
.str "Diverse double compilation (DDC) is the answer to the self-reproducing"
TP215:
.str "trojan. Build the same source with two independent toolchains. Compare"
TP216:
.str "the resulting words. If they differ, at least one toolchain is wrong or"
TP217:
.str "malicious. If they agree, a trojan must be present in both toolchains in"
TP218:
.str "exactly the same way, which is a much stronger assumption for the"
TP219:
.str "adversary."
TP220:
.str ""
TP221:
.str "NaN/0S has three builders:"
TP222:
.str ""
TP223:
.str "- **nasm0**, the in-guest NaN16 assembler."
TP224:
.str "- **nasm1**, the in-guest x86 emitter used to build the native kernel."
TP225:
.str "- **nanchk**, the Python scaffold used as the independent reference for"
TP226:
.str "  the guest image."
TP227:
.str ""
TP228:
.str "The DDC procedure is:"
TP229:
.str ""
TP230:
.str "1. Build the target T with builder A. Record every word."
TP231:
.str "2. Build T with builder B. Record every word."
TP232:
.str "3. Compare the words, not the source text."
TP233:
.str "4. Build A with A and with B. Compare."
TP234:
.str "5. Build B with A and with B. Compare."
TP235:
.str "6. Repeat until the comparison is stable."
TP236:
.str ""
TP237:
.str "The museum's gates include:"
TP238:
.str ""
TP239:
.str "```"
TP240:
.str "python3 tools/nasm1check.py"
TP241:
.str "python3 tools/test_nanvm1.py"
TP242:
.str "python3 tools/mkproof.py src/prog/nasm0_proof.nas --gen2"
TP243:
.str "sh tools/mkall.sh"
TP244:
.str "```"
TP245:
.str ""
TP246:
.str "`nasm1check.py` compares the boot sector and kernel bytes with the gold"
TP247:
.str "image, runs the 83 encoding tests, and checks that the model and v86 agree"
TP248:
.str "on the selftest serial output. `test_nanvm1.py` runs the 5,810 opcode"
TP249:
.str "vectors. `mkproof.py --gen2` is the self-host fixed point. `mkall.sh`"
TP250:
.str "builds the one museum image and enforces the image rule."
TP251:
.str ""
TP252:
.str "DDC is not a proof that both builders are honest. It is a proof that a"
TP253:
.str "single-builder trojan cannot hide. If the adversary controls both"
TP254:
.str "builders, DDC fails. The defense against that is provenance: publish the"
TP255:
.str "builders, publish the hashes, and make the independent builder genuinely"
TP256:
.str "independent."
TP257:
.str ""
TP258:
.str "## 7. Dual-Face Seals"
TP259:
.str ""
TP260:
.str "Each cartridge is sealed. The seal has three channels:"
TP261:
.str ""
TP262:
.str "- **A**: FNV-1a/32 over the near-face payload of every word."
TP263:
.str "- **B**: FNV-1a/32 over the far-face payload of every word."
TP264:
.str "- **C**: a rotate-and-XOR channel over the class nibble of every word."
TP265:
.str ""
TP266:
.str "The TOC stores A, B, and C. The loader recomputes all three before it"
TP267:
.str "copies the cartridge to the slot. If any channel differs, the cartridge"
TP268:
.str "is refused. The loader also checks:"
TP269:
.str ""
TP270:
.str "- every head is legal,"
TP271:
.str "- the far payload is the byte-swap of the near payload,"
TP272:
.str "- the far class is `rot2` of the near class."
TP273:
.str ""
TP274:
.str "The seal is an integrity check, not a signature. It detects accidental"
TP275:
.str "corruption and a large class of tampering. It does not stop an adversary"
TP276:
.str "who can rewrite both the payload and the seal. A future version will add"
TP277:
.str "a keyed MAC and a published append-only log of seals."
TP278:
.str ""
TP279:
.str "The museum's seal experiments are:"
TP280:
.str ""
TP281:
.str "```"
TP282:
.str "python3 tools/sweep_seal.py"
TP283:
.str "NAN_FLIP=... python3 tools/mkimg1.py ..."
TP284:
.str "NAN_HEADFLIP=... python3 tools/mkimg1.py ..."
TP285:
.str "NAN_SEALBIT=... python3 tools/mkimg1.py ..."
TP286:
.str "```"
TP287:
.str ""
TP288:
.str "The mutation sweep flips payload bits, head bits, and seal bits. The"
TP289:
.str "expected result is refusal with the correct status: payload mismatch,"
TP290:
.str "illegal head, or mirror-law break. The seal is tested on both faces"
TP291:
.str "because the word has two faces."
TP292:
.str ""
TP293:
.str "## 8. What Would Count as an Answer"
TP294:
.str ""
TP295:
.str "Thompson's question asks for trust, not certainty. A complete answer for"
TP296:
.str "NaN/0S has five parts:"
TP297:
.str ""
TP298:
.str "1. **A named trust base.** S0 and S1 are small, published, and"
TP299:
.str "   inspectable. The rest is built from S2 and S3."
TP300:
.str "2. **A reproducible fixed point.** nasm0 rebuilds itself word for word."
TP301:
.str "3. **Independent agreement.** A second, independently written builder"
TP302:
.str "   produces the same words for the same source."
TP303:
.str "4. **Tamper evidence.** Every shipped cartridge carries a dual-face seal,"
TP304:
.str "   and the loader refuses a mismatch."
TP305:
.str "5. **Honest limits.** The seal is not a signature. DDC does not defeat a"
TP306:
.str "   compromised pair of builders. The native kernel is trusted, not proved."
TP307:
.str ""
TP308:
.str "If all five parts hold, then a claim of the form 'this program was built"
TP309:
.str "from this source by this published procedure, and any single-toolchain"
TP310:
.str "tampering would have shown up' is justified. That is the strongest claim"
TP311:
.str "the current system can make. It is stronger than source review alone and"
TP312:
.str "weaker than a formal proof of the entire stack."
TP313:
.str ""
TP314:
.str "## 9. The Experiments"
TP315:
.str ""
TP316:
.str "The museum records each experiment as a log:"
TP317:
.str ""
TP318:
.str "- `logs/nasm0_selfhost_gen2_round09.txt`: the self-host fixed point."
TP319:
.str "- `logs/nasm1_check.txt`: the 83 encoding tests and the v86 selftest."
TP320:
.str "- `logs/nanvm1_ops_test.txt`: the 5,810 opcode checks."
TP321:
.str "- `logs/v29_seal.txt`: the first corrupted-cartridge refusal."
TP322:
.str "- `logs/v37_seal2.txt`: dual-face seal tests."
TP323:
.str "- `logs/r21_trust_test.txt`: the r21 Trust test transcript."
TP324:
.str ""
TP325:
.str "The r21 transcript is generated by running the commands in this paper"
TP326:
.str "and saving the output. The reader can rerun them. A result that cannot"
TP327:
.str "be rerun is not evidence."
TP328:
.str ""
TP329:
.str "## 10. Limitations"
TP330:
.str ""
TP331:
.str "The current answer has real limits:"
TP332:
.str ""
TP333:
.str "- The native kernel is host-machine code. It is small, but it is trusted."
TP334:
.str "  A full proof would need a verified kernel or a verified translation."
TP335:
.str "- The seal is FNV-1a/32, not a cryptographic MAC. It detects corruption,"
TP336:
.str "  not a determined forger."
TP337:
.str "- The DDC independence is only as good as the independence of the"
TP338:
.str "  builders. The Python scaffold and the in-guest assemblers share ideas,"
TP339:
.str "  even if they do not share code."
TP340:
.str "- The fixed point is a word-level comparison. It does not prove semantic"
TP341:
.str "  equivalence to a specification."
TP342:
.str "- The museum's exhibits are re-creations and inspired works, not all"
TP343:
.str "  bit-for-bit historical artifacts."
TP344:
.str ""
TP345:
.str "These limits are part of the paper. A trust argument that hides its"
TP346:
.str "limits is not a trust argument."
TP347:
.str ""
TP348:
.str "## 11. Conclusion"
TP349:
.str ""
TP350:
.str "Thompson's question does not have a single yes-or-no answer. It has a"
TP351:
.str "procedure. Name the trust base. Reproduce the build. Cross-check it with"
TP352:
.str "an independent builder. Seal the result. Publish the evidence. State the"
TP353:
.str "limits. Repeat when the toolchain changes."
TP354:
.str ""
TP355:
.str "NaN/0S is a machine that can show its work. Its words have two faces. Its"
TP356:
.str "assembler can rebuild itself. Its museum refuses a cartridge whose faces"
TP357:
.str "disagree. That is not absolute trust. It is the beginning of an answer,"
TP358:
.str "and it is small enough to inspect."
TP359:
.str ""
TP360:
.str "## References"
TP361:
.str ""
TP362:
.str "1. Ken Thompson, 'Reflections on Trusting Trust,' Communications of the"
TP363:
.str "   ACM, 27(8), 1984. Turing Award lecture."
TP364:
.str "2. David A. Wheeler, 'Countering Trusting Trust through Diverse Double"
TP365:
.str "   Compiling,' 2005."
TP366:
.str "3. Ken Thompson and Dennis Ritchie, The UNIX Time-Sharing System, 1974."
TP367:
.str "4. NaN/0S, spec/NAN16_SPEC.md and spec/NANVM1_SPEC.md."
TP368:
.str "5. NaN/0S, logs/nasm0_selfhost_gen2_round09.txt and logs/r21_trust_test.txt."
TP369:
.str ""
TP370:
.str "---"
TP371:
.str ""
TP372:
.str "*This paper is hosted in the museum as a scrollable exhibit. The preface"
TP373:
.str "names Thompson and his question. The body is the paper. The reader can"
TP374:
.str "walk from the question to the procedure to the evidence without leaving"
TP375:
.str "the machine.*"
; ---- pointer table ----
tr_lines:
.word @TP000
.word @TP001
.word @TP002
.word @TP003
.word @TP004
.word @TP005
.word @TP006
.word @TP007
.word @TP008
.word @TP009
.word @TP010
.word @TP011
.word @TP012
.word @TP013
.word @TP014
.word @TP015
.word @TP016
.word @TP017
.word @TP018
.word @TP019
.word @TP020
.word @TP021
.word @TP022
.word @TP023
.word @TP024
.word @TP025
.word @TP026
.word @TP027
.word @TP028
.word @TP029
.word @TP030
.word @TP031
.word @TP032
.word @TP033
.word @TP034
.word @TP035
.word @TP036
.word @TP037
.word @TP038
.word @TP039
.word @TP040
.word @TP041
.word @TP042
.word @TP043
.word @TP044
.word @TP045
.word @TP046
.word @TP047
.word @TP048
.word @TP049
.word @TP050
.word @TP051
.word @TP052
.word @TP053
.word @TP054
.word @TP055
.word @TP056
.word @TP057
.word @TP058
.word @TP059
.word @TP060
.word @TP061
.word @TP062
.word @TP063
.word @TP064
.word @TP065
.word @TP066
.word @TP067
.word @TP068
.word @TP069
.word @TP070
.word @TP071
.word @TP072
.word @TP073
.word @TP074
.word @TP075
.word @TP076
.word @TP077
.word @TP078
.word @TP079
.word @TP080
.word @TP081
.word @TP082
.word @TP083
.word @TP084
.word @TP085
.word @TP086
.word @TP087
.word @TP088
.word @TP089
.word @TP090
.word @TP091
.word @TP092
.word @TP093
.word @TP094
.word @TP095
.word @TP096
.word @TP097
.word @TP098
.word @TP099
.word @TP100
.word @TP101
.word @TP102
.word @TP103
.word @TP104
.word @TP105
.word @TP106
.word @TP107
.word @TP108
.word @TP109
.word @TP110
.word @TP111
.word @TP112
.word @TP113
.word @TP114
.word @TP115
.word @TP116
.word @TP117
.word @TP118
.word @TP119
.word @TP120
.word @TP121
.word @TP122
.word @TP123
.word @TP124
.word @TP125
.word @TP126
.word @TP127
.word @TP128
.word @TP129
.word @TP130
.word @TP131
.word @TP132
.word @TP133
.word @TP134
.word @TP135
.word @TP136
.word @TP137
.word @TP138
.word @TP139
.word @TP140
.word @TP141
.word @TP142
.word @TP143
.word @TP144
.word @TP145
.word @TP146
.word @TP147
.word @TP148
.word @TP149
.word @TP150
.word @TP151
.word @TP152
.word @TP153
.word @TP154
.word @TP155
.word @TP156
.word @TP157
.word @TP158
.word @TP159
.word @TP160
.word @TP161
.word @TP162
.word @TP163
.word @TP164
.word @TP165
.word @TP166
.word @TP167
.word @TP168
.word @TP169
.word @TP170
.word @TP171
.word @TP172
.word @TP173
.word @TP174
.word @TP175
.word @TP176
.word @TP177
.word @TP178
.word @TP179
.word @TP180
.word @TP181
.word @TP182
.word @TP183
.word @TP184
.word @TP185
.word @TP186
.word @TP187
.word @TP188
.word @TP189
.word @TP190
.word @TP191
.word @TP192
.word @TP193
.word @TP194
.word @TP195
.word @TP196
.word @TP197
.word @TP198
.word @TP199
.word @TP200
.word @TP201
.word @TP202
.word @TP203
.word @TP204
.word @TP205
.word @TP206
.word @TP207
.word @TP208
.word @TP209
.word @TP210
.word @TP211
.word @TP212
.word @TP213
.word @TP214
.word @TP215
.word @TP216
.word @TP217
.word @TP218
.word @TP219
.word @TP220
.word @TP221
.word @TP222
.word @TP223
.word @TP224
.word @TP225
.word @TP226
.word @TP227
.word @TP228
.word @TP229
.word @TP230
.word @TP231
.word @TP232
.word @TP233
.word @TP234
.word @TP235
.word @TP236
.word @TP237
.word @TP238
.word @TP239
.word @TP240
.word @TP241
.word @TP242
.word @TP243
.word @TP244
.word @TP245
.word @TP246
.word @TP247
.word @TP248
.word @TP249
.word @TP250
.word @TP251
.word @TP252
.word @TP253
.word @TP254
.word @TP255
.word @TP256
.word @TP257
.word @TP258
.word @TP259
.word @TP260
.word @TP261
.word @TP262
.word @TP263
.word @TP264
.word @TP265
.word @TP266
.word @TP267
.word @TP268
.word @TP269
.word @TP270
.word @TP271
.word @TP272
.word @TP273
.word @TP274
.word @TP275
.word @TP276
.word @TP277
.word @TP278
.word @TP279
.word @TP280
.word @TP281
.word @TP282
.word @TP283
.word @TP284
.word @TP285
.word @TP286
.word @TP287
.word @TP288
.word @TP289
.word @TP290
.word @TP291
.word @TP292
.word @TP293
.word @TP294
.word @TP295
.word @TP296
.word @TP297
.word @TP298
.word @TP299
.word @TP300
.word @TP301
.word @TP302
.word @TP303
.word @TP304
.word @TP305
.word @TP306
.word @TP307
.word @TP308
.word @TP309
.word @TP310
.word @TP311
.word @TP312
.word @TP313
.word @TP314
.word @TP315
.word @TP316
.word @TP317
.word @TP318
.word @TP319
.word @TP320
.word @TP321
.word @TP322
.word @TP323
.word @TP324
.word @TP325
.word @TP326
.word @TP327
.word @TP328
.word @TP329
.word @TP330
.word @TP331
.word @TP332
.word @TP333
.word @TP334
.word @TP335
.word @TP336
.word @TP337
.word @TP338
.word @TP339
.word @TP340
.word @TP341
.word @TP342
.word @TP343
.word @TP344
.word @TP345
.word @TP346
.word @TP347
.word @TP348
.word @TP349
.word @TP350
.word @TP351
.word @TP352
.word @TP353
.word @TP354
.word @TP355
.word @TP356
.word @TP357
.word @TP358
.word @TP359
.word @TP360
.word @TP361
.word @TP362
.word @TP363
.word @TP364
.word @TP365
.word @TP366
.word @TP367
.word @TP368
.word @TP369
.word @TP370
.word @TP371
.word @TP372
.word @TP373
.word @TP374
.word @TP375
