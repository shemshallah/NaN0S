# tools/a64.awk - minimal AArch64 assembler (gawk), outer dev-loop only. Hand-written NaN core sources
# (src/native/kan16_a64.xa64) go in; a hex text stream comes out:  LC_ALL=C gawk -f tools/a64.awk S.xa64 | xxd -r -p > S.bin
# Subset: movz/movk/mov, add/sub(s)/cmp/neg, and/orr/eor/bic/orn/ands/tst/mvn, lsl/lsr/asr, ubfx/sbfx/ubfm/sbfm,
# mul/madd/msub/udiv/sdiv/umulh, rev/rev16, ldr/str/ldrb/strb/ldrh/strh (offset, reg, post-index), b/bl/b.cc/br/blr/ret,
# cbz/cbnz, adr, csel/csinc/cset, mrs cntvct/cntfrq, nop/wfi/isb. Directives: .word .quad .byte .ascii .space .align .org .equ
# 2-pass, labels `name:`, comments `;` or `//`. Registers x0-x30 w0-w30 xzr wzr sp.
function die(m){ printf("a64.awk: line %d: %s\n", LN, m) > "/dev/stderr"; bad=1; exit 1 }
function trim(s){ gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
function num(s,   neg){ s=trim(s); sub(/^#/, "", s); neg=0; if (s ~ /^-/) { neg=1; sub(/^-/, "", s) }
  if (s ~ /^0[xX][0-9a-fA-F]+$/) s = strtonum(s); else if (s ~ /^[0-9]+$/) s = s+0; else if (s in EQU) s = EQU[s]; else if (s in LAB) s = LAB[s]; else if (P==1) s = 0; else die("bad number/label: " s)
  return neg ? -s : s }
function isreg(s){ s=tolower(trim(s)); return (s ~ /^[xw][0-9]+$/ && substr(s,2)+0 <= 30) || s=="xzr" || s=="wzr" || s=="sp" }
function reg(s){ s=tolower(trim(s)); if (s=="xzr"||s=="sp") { W=1; return 31 } if (s=="wzr") { W=0; return 31 }
  if (s !~ /^[xw][0-9]+$/) die("bad register: " s); W = (substr(s,1,1)=="x"); return substr(s,2)+0 }
function hex8(v){ return sprintf("%02x%02x%02x%02x", v%256, int(v/256)%256, int(v/65536)%256, int(v/16777216)%256) }
function emit(v){ if (P==2) OUT = OUT hex8(v) "\n"; PC += 4 }
function emitb(v){ if (P==2) OUT = OUT sprintf("%02x", v%256); PC += 1 }
function ORr(a,b,   r,i,x,y,bit){ r=0; bit=1; for(i=0;i<32;i++){ x=int(a/bit)%2; y=int(b/bit)%2; if (x||y) r+=bit; bit*=2 } return r }
function cc(s){ s=tolower(s); return (s in CC) ? CC[s] : -1 }
function shiftarg(s,   t){ t=tolower(trim(s)); sub(/^lsl[ \t]*#?/, "", t); return t+0 }
function ldst(m, rt, mem, post,   base, off, rm, p, sz, ld, opU, opR, opP, imm, sh, parts, np, rn, i)
{
  rt0 = reg(rt); w = W
  ld = (m ~ /^ldr/) ? 1 : 0
  if (m ~ /b$/) { sz = 0; opU = ld ? 0x39400000 : 0x39000000; opR = ld ? 0x38606800 : 0x38206800; opP = ld ? 0x38400400 : 0x38000400 }
  else if (m ~ /h$/) { sz = 1; opU = ld ? 0x79400000 : 0x79000000; opR = ld ? 0x78606800 : 0x78206800; opP = ld ? 0x78400400 : 0x78000400 }
  else if (w) { sz = 3; opU = ld ? 0xF9400000 : 0xF9000000; opR = ld ? 0xF8606800 : 0xF8206800; opP = ld ? 0xF8400400 : 0xF8000400 }
  else { sz = 2; opU = ld ? 0xB9400000 : 0xB9000000; opR = ld ? 0xB8606800 : 0xB8206800; opP = ld ? 0xB8400400 : 0xB8000400 }
  mem = trim(mem); gsub(/[\[\]]/, "", mem); np = split(mem, parts, ",")
  rn = reg(parts[1])
  if (post != "") { imm = num(post); if (imm < -256 || imm > 255) die("post-index range"); return opP + (((imm+512)%512)*4096) + rn*32 + rt0 }
  if (np == 1) return opU + rn*32 + rt0
  if (parts[2] ~ /#/ || !isreg(parts[2])) { imm = num(parts[2]); if (imm < 0 || imm % (2^sz) || imm/(2^sz) > 4095) die("ldr/str offset"); return opU + (imm/(2^sz))*1024 + rn*32 + rt0 }
  rm = reg(parts[2]); sh = 0
  if (np >= 3) { sh = shiftarg(parts[3]); if (sh != 0 && sh != sz) die("ldr/str reg shift must be 0 or size"); sh = (sh != 0) ? 4096 : 0 }
  return opR + rm*65536 + sh + rn*32 + rt0
}
function enc(m, o, n,   rd, rn, rm, ra, sf, imm, sh, t, op, s, x, i, lsb, wd, immr, imms, base, c)
{
  if (m == ".word") { for (i=1;i<=n;i++) emit(num(o[i])); return -1 }
  if (m == "movz" || m == "movk" || m == "mov" && !isreg(o[2])) {
    rd = reg(o[1]); sf = W; imm = num(o[2]); sh = 0
    if (n >= 3) sh = shiftarg(o[3])/16
    if (imm < 0 || imm > 65535) die("movz/movk imm16 range")
    base = (m == "movk") ? (sf ? 0xF2800000 : 0x72800000) : (sf ? 0xD2800000 : 0x52800000)
    return base + sh*2097152 + imm*32 + rd }
  if (m == "mov") { rd = reg(o[1]); sf = W; rm = reg(o[2]); return (sf ? 0xAA0003E0 : 0x2A0003E0) + rm*65536 + rd }
  if (m == "add" || m == "sub" || m == "adds" || m == "subs" || m == "cmp" || m == "neg") {
    if (m == "cmp") { for (i=n;i>=1;i--) o[i+1]=o[i]; o[1]="xzr"; n++; rd = 31; sf = reg(o[2]) ; m = "subs"; rd=31; rn = reg(o[2]); sf = W; W = sf }
    else if (m == "neg") { o[3]=o[2]; o[2]=(substr(tolower(trim(o[1])),1,1)=="w")?"wzr":"xzr"; n=3; m="sub"; rd=reg(o[1]); sf=W; rn=31 }
    else { rd = reg(o[1]); sf = W; rn = reg(o[2]) }
    if (m != "subs" || rd != 31 || 1) { }
    if (!isreg(o[3])) { imm = num(o[3]); sh = 0; if (n >= 4) sh = (shiftarg(o[4]) == 12) ? 1 : 0
      if (imm < 0 || imm > 4095) die("add/sub imm12 range")
      op = (m=="add") ? 0x11000000 : (m=="adds") ? 0x31000000 : (m=="sub") ? 0x51000000 : 0x71000000
      return op + (sf ? 0x80000000 : 0) + sh*4194304 + imm*1024 + rn*32 + rd }
    rm = reg(o[3]); s = (n >= 4) ? shiftarg(o[4]) : 0
    op = (m=="add") ? 0x0B000000 : (m=="adds") ? 0x2B000000 : (m=="sub") ? 0x4B000000 : 0x6B000000
    return op + (sf ? 0x80000000 : 0) + rm*65536 + s*1024 + rn*32 + rd }
  if (m == "and" || m == "orr" || m == "eor" || m == "ands" || m == "bic" || m == "orn" || m == "tst" || m == "mvn") {
    if (m == "tst") { for (i=n;i>=1;i--) o[i+1]=o[i]; o[1]=(substr(tolower(trim(o[2])),1,1)=="w")?"wzr":"xzr"; n++; m="ands" }
    if (m == "mvn") { o[3]=o[2]; o[2]=(substr(tolower(trim(o[1])),1,1)=="w")?"wzr":"xzr"; n=3; m="orn" }
    rd = reg(o[1]); sf = W; rn = reg(o[2]); if (!isreg(o[3])) die(m " needs a register (no logical immediates)")
    rm = reg(o[3]); s = (n >= 4) ? shiftarg(o[4]) : 0
    op = (m=="and") ? 0x0A000000 : (m=="orr") ? 0x2A000000 : (m=="eor") ? 0x4A000000 : (m=="ands") ? 0x6A000000 : (m=="bic") ? 0x0A200000 : 0x2A200000
    return op + (sf ? 0x80000000 : 0) + rm*65536 + s*1024 + rn*32 + rd }
  if (m == "lsl" || m == "lsr" || m == "asr") {
    rd = reg(o[1]); sf = W; rn = reg(o[2])
    if (isreg(o[3])) { rm = reg(o[3]); op = (m=="lsl") ? 0x1AC02000 : (m=="lsr") ? 0x1AC02400 : 0x1AC02800
      return op + (sf ? 0x80000000 : 0) + rm*65536 + rn*32 + rd }
    imm = num(o[3]); wd = sf ? 64 : 32
    if (imm < 0 || imm >= wd) die("shift range")
    if (m == "lsl") { immr = (wd - imm) % wd; imms = wd - 1 - imm; op = sf ? 0xD3400000 : 0x53000000 }
    else if (m == "lsr") { immr = imm; imms = wd - 1; op = sf ? 0xD3400000 : 0x53000000 }
    else { immr = imm; imms = wd - 1; op = sf ? 0x93400000 : 0x13000000 }
    return op + immr*65536 + imms*1024 + rn*32 + rd }
  if (m == "ubfx" || m == "sbfx" || m == "ubfm" || m == "sbfm") {
    rd = reg(o[1]); sf = W; rn = reg(o[2]); lsb = num(o[3]); wd = num(o[4])
    if (m ~ /x$/) { immr = lsb; imms = lsb + wd - 1 } else { immr = lsb; imms = wd }
    if (m ~ /^u/) op = sf ? 0xD3400000 : 0x53000000; else op = sf ? 0x93400000 : 0x13000000
    return op + immr*65536 + imms*1024 + rn*32 + rd }
  if (m == "mul" || m == "udiv" || m == "sdiv" || m == "umulh" || m == "smulh") {
    rd = reg(o[1]); sf = W; rn = reg(o[2]); rm = reg(o[3])
    if (m == "mul") return (sf ? 0x9B007C00 : 0x1B007C00) + rm*65536 + rn*32 + rd
    if (m == "udiv") return (sf ? 0x9AC00800 : 0x1AC00800) + rm*65536 + rn*32 + rd
    if (m == "sdiv") return (sf ? 0x9AC00C00 : 0x1AC00C00) + rm*65536 + rn*32 + rd
    if (m == "umulh") return 0x9BC07C00 + rm*65536 + rn*32 + rd
    return 0x9B407C00 + rm*65536 + rn*32 + rd }
  if (m == "madd" || m == "msub") {
    rd = reg(o[1]); sf = W; rn = reg(o[2]); rm = reg(o[3]); ra = reg(o[4])
    return (sf ? 0x9B000000 : 0x1B000000) + (m=="msub" ? 0x8000 : 0) + rm*65536 + ra*1024 + rn*32 + rd }
  if (m == "rev" || m == "rev16") { rd = reg(o[1]); sf = W; rn = reg(o[2])
    if (m == "rev16") return (sf ? 0xDAC00400 : 0x5AC00400) + rn*32 + rd
    return (sf ? 0xDAC00C00 : 0x5AC00800) + rn*32 + rd }
  if (m == "ldr" || m == "str" || m == "ldrb" || m == "strb" || m == "ldrh" || m == "strh") {
    if (n >= 3) return ldst(m, o[1], o[2], o[3])
    return ldst(m, o[1], o[2], "") }
  if (m == "b" || m == "bl") { t = num(o[1]); return (m=="b" ? 0x14000000 : 0x94000000) + (((t - PC)/4 + 67108864) % 67108864) }
  if (m ~ /^b\./) { c = cc(substr(m,3)); if (c < 0) die("bad cond " m); t = num(o[1]); return 0x54000000 + (((t - PC)/4 + 524288) % 524288)*32 + c }
  if (m == "br") return 0xD61F0000 + reg(o[1])*32
  if (m == "blr") return 0xD63F0000 + reg(o[1])*32
  if (m == "ret") return 0xD65F03C0
  if (m == "cbz" || m == "cbnz") { rd = reg(o[1]); sf = W; t = num(o[2])
    return (m=="cbz" ? 0x34000000 : 0x35000000) + (sf ? 0x80000000 : 0) + (((t - PC)/4 + 524288) % 524288)*32 + rd }
  if (m == "adr") { rd = reg(o[1]); t = num(o[2]) - PC; if (t < -1048576 || t > 1048575) die("adr range"); t = (t + 2097152) % 2097152
    return 0x10000000 + (t % 4)*536870912 + int(t/4)*32 + rd }
  if (m == "csel" || m == "csinc") { rd = reg(o[1]); sf = W; rn = reg(o[2]); rm = reg(o[3]); c = cc(o[4]); if (c < 0) die("bad cond")
    return (sf ? 0x9A800000 : 0x1A800000) + (m=="csinc" ? 0x400 : 0) + rm*65536 + c*4096 + rn*32 + rd }
  if (m == "cset") { rd = reg(o[1]); sf = W; c = cc(o[2]); if (c < 0) die("bad cond"); c = (c % 2) ? c - 1 : c + 1
    return (sf ? 0x9A9F07E0 : 0x1A9F07E0) + c*4096 + rd }
  if (m == "mrs") { rd = reg(o[1]); t = tolower(trim(o[2])); if (t == "cntvct_el0") return 0xD53BE040 + rd; if (t == "cntfrq_el0") return 0xD53BE000 + rd; die("mrs reg") }
  if (m == "nop") return 0xD503201F
  if (m == "wfi") return 0xD503207F
  if (m == "isb") return 0xD5033FDF
  die("unknown mnemonic " m)
}
function splitops(s, o,   n, i, c, cur, depth, ch) {
  n = 0; cur = ""; depth = 0
  for (i = 1; i <= length(s); i++) { ch = substr(s, i, 1)
    if (ch == "[") depth++; if (ch == "]") depth--
    if (ch == "," && depth == 0) { o[++n] = trim(cur); cur = "" } else cur = cur ch }
  if (trim(cur) != "") o[++n] = trim(cur)
  return n }
function asmline(line,   m, rest, o, n, v, str, i, c, p)
{
  line = trim(line)
  if (line == "") return
  if (match(line, /^[A-Za-z_][A-Za-z0-9_]*:/)) { c = substr(line, 1, RLENGTH-1); if (P==1) LAB[c] = PC; line = trim(substr(line, RLENGTH+1)); if (line == "") return }
  m = line; sub(/[ \t].*$/, "", m); rest = trim(substr(line, length(m)+1)); m = tolower(m)
  if (m == ".equ") { n = splitops(rest, o); EQU[trim(o[1])] = num(o[2]); return }
  if (m == ".org") { v = num(rest); while (PC < v) emitb(0); return }
  if (m == ".space") { v = num(rest); for (i=0;i<v;i++) emitb(0); return }
  if (m == ".align") { v = 2^num(rest); while (PC % v) emitb(0); return }
  if (m == ".byte") { n = splitops(rest, o); for (i=1;i<=n;i++) emitb(num(o[i])); return }
  if (m == ".quad") { n = splitops(rest, o); for (i=1;i<=n;i++) { v = num(o[i]); emit(v % 4294967296); emit(int(v/4294967296)) } return }
  if (m == ".ascii" || m == ".asciz") { if (match(rest, /"[^"]*"/)) { str = substr(rest, RSTART+1, RLENGTH-2)
      for (i=1;i<=length(str);i++) { c = substr(str, i, 1); if (c == "\\" && substr(str,i+1,1) == "n") { emitb(10); i++ } else if (c == "\\" && substr(str,i+1,1) == "r") { emitb(13); i++ } else emitb(index(CH, c) + 31) }
      if (m == ".asciz") emitb(0) } return }
  n = splitops(rest, o)
  if (m == ".word") { for (i=1;i<=n;i++) emit(num(o[i])); return }
  v = enc(m, o, n)
  if (v < 0) return
  emit(v)
}
BEGIN {
  split("eq ne cs cc mi pl vs vc hi ls ge lt gt le al hs lo", cn, " ")
  for (i = 1; i <= 15; i++) CC[cn[i]] = i - 1; CC["hs"] = 2; CC["lo"] = 3
  CH = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
}
{ L[NR] = $0 }
END {
  for (P = 1; P <= 2; P++) { PC = 0; OUT = ""
    for (LN = 1; LN <= NR; LN++) { t = L[LN]
      # strip comments, but not inside a string
      if (match(t, /"[^"]*"/)) { pre = substr(t, 1, RSTART-1); st = substr(t, RSTART, RLENGTH); post = substr(t, RSTART+RLENGTH); sub(/(;|\/\/).*$/, "", post); t = pre st post; sub(/(;|\/\/).*$/, "", pre); if (pre != substr(t,1,length(pre))) { } }
      else sub(/(;|\/\/).*$/, "", t)
      asmline(t) } }
  printf("%s", OUT)
}
