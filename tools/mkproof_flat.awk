# tools/mkproof_flat.awk - builds the proof image (awk implementation).
#   awk -f tools/mkproof_flat.awk -v HARNESS=h.nan -v EXPECTE=t.nan -v SRCFILE=flat.nas -v OUTFILE=proof.nan -v BIG=1
# BIG layout (1M words): nasm0+proof harness words at 0 (<= 6271 words, VARS live 6272..),
# flattened source packed 4 bytes/word LE + NUL end (class 10) at SRC=0x40000, expected host-seed words
# (nmk.awk, verbatim heads) at EXP=0x60000 + EXPC=0x70000 class table (8 low nibbles/word),
# OUT=0x80000, LAB=0xA0000; V_EXPN/V_SRCB/V_OUTB/V_LABB/V_EXPB/V_EXPCB patched last.
BEGIN {
  split("7FF1 FFF1 7FF8 FFF8", NE, " ")      # near head text per int(class/4)
  split("F17F F1FF F87F F8FF", FA, " ")      # far head text per class%4
  for (i = 0; i < 256; i++) VBY[sprintf("%c", i)] = i
  NEX["7FF1"] = 0; NEX["FFF1"] = 1; NEX["7FF8"] = 2; NEX["FFF8"] = 3
  FEX["F17F"] = 0; FEX["F1FF"] = 1; FEX["F87F"] = 2; FEX["F8FF"] = 3
  PW16[0] = 1; for (i = 1; i <= 7; i++) PW16[i] = PW16[i - 1] * 16
  if (BIG) { NW = 1048576; SRC = 262144; EXP = 393216; EXPC = 458752; OUT = 524288; LAB = 655360 }
  else     { NW = 8192;     SRC = 2048;     EXP = 5120;     EXPC = 6144;     OUT = 6400;   LAB = 7424 }
  V_EXPN = 6290; V_SRCB = 6293; V_OUTB = 6294; V_LABB = 6295; V_EXPB = 6296; V_EXPCB = 6297
  NEA = 0
  while ((getline ln < HARNESS) > 0) { take(ln) }
  close(HARNESS)
  if (NEA == 0) die("empty harness " HARNESS)
  if (NEA > 6271) die(sprintf("harness is %d words, must be < 6272 (VARS)", NEA))
  CHA = packsrc(SRCFILE)
  NEP = 0
  while ((getline ln < EXPECTE) > 0) {
    if (index(ln, ";") > 0) ln = substr(ln, 1, index(ln, ";") - 1)
    gsub(/[ \t\r\n]+/, "", ln)
    if (ln == "") continue
    split(ln, a, "_")
    if (length(a) != 3) die("bad expected word line: " ln)
    ep[NEP] = ln
    cc = NEX[a[1]] * 4 + FEX[a[3]]
    kp = int(NEP / 8)
    xw[kp] = xw[kp] + cc * PW16[NEP % 8]        # low nibble first, like the expected table reader
    NEP++
  }
  close(EXPECTE)
  if (NEP == 0) die("no expected words in " EXPECTE)
  srcw = int((CHA + 3) / 4)
  if (SRC + srcw > EXP) die(sprintf("source %d bytes (%d words) too big for SRC..EXP", CHA, srcw))
  if (EXP + NEP > EXPC) die("expected words too big for EXP..EXPC")

  o = OUTFILE
  for (i = 0; i < NEA; i++) print hp[i] > o                                     # words 0..HVARS
  print ".org " SRC > o
  for (i = 0; i < srcw; i++) print wl(10, sw[i]) > o                            # class 10 source words
  print ".org " EXP > o
  for (i = 0; i < NEP; i++) print ep[i] > o                                     # expected words verbatim
  print ".org " EXPC > o
  for (i = 0; i < int((NEP + 7) / 8); i++) print wl(10, xw[i] + 0) > o           # class table
  printf ".org %d\n%s\n", V_EXPN, wl(10, NEP) > o
  printf ".org %d\n%s\n", V_SRCB,  wl(10, SRC) > o
  printf ".org %d\n%s\n", V_OUTB,  wl(10, OUT) > o
  printf ".org %d\n%s\n", V_LABB,  wl(10, LAB) > o
  printf ".org %d\n%s\n", V_EXPB,  wl(10, EXP) > o
  printf ".org %d\n%s\n", V_EXPCB, wl(10, EXPC) > o
  close(o)
  printf "mkproof_flat: harness %d words | source %d bytes/%d words | expected %d words | %s\n", \
    NEA, CHA, srcw, NEP, OUTFILE > "/dev/stderr"
}
function take(ln,   a) {   # one harness .nan line -> hp[] verbatim + class check
  if (index(ln, ";") > 0) ln = substr(ln, 1, index(ln, ";") - 1)
  gsub(/[ \t\r\n]+/, "", ln)
  if (ln == "") return
  split(ln, a, "_")
  if (length(a) != 3) die("bad harness word line: " ln)
  hp[NEA] = a[1] "_" a[2] "_" a[3]
  NEA++
}
function packsrc(f,   ln, s, i, b0, b1, b2, b3) {
  NW_ = 0
  while ((getline ln < f) > 0) s = s ln "\n"
  close(f); sub(/\r$/, "", s); s = s "\0"
  while (length(s) % 4) s = s "\0"
  for (i = 1; i + 3 <= length(s); i += 4) {
    b0 = VBY[substr(s, i + 0, 1)]; b1 = VBY[substr(s, i + 1, 1)]
    b2 = VBY[substr(s, i + 2, 1)]; b3 = VBY[substr(s, i + 3, 1)]
    if (b0 == "" || b1 == "" || b2 == "" || b3 == "") die(sprintf("non-byte char in source at offset %d", i - 1))
    sw[NW_] = b0 + b1 * 256 + b2 * 65536 + b3 * 16777216
    NW_++
  }
  return length(s)
}
# word text encoder: class n (near = NE[int(n/4)+1], far = FA[(n%4)+1]) + 32-bit payload
function wl(n, p,   q) {
  q = p < 0 ? p + 4294967296 : p
  if (q > 4294967295) die("payload overflow " p)
  return sprintf("%s_%08X_%s", NE[int(n / 4) + 1], q, FA[(n % 4) + 1])
}
function die(m) { print "mkproof_flat: " m > "/dev/stderr"; exit 1 }
