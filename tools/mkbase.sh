#!/bin/sh
# tools/mkbase.sh - builds x86/build/base.img, the scaffold input for nasm0 proofs: a full
# 1474560-byte floppy with boot0.bin at byte 0, the 55 AA boot signature at 510/511, and
# nanvm0.bin (NaNVM0 native boundary, 1536-byte limit) at 512; rest zero. Also writes
# src/vm/nanvm0.nan, a hex dump of x86/scaffold/nanvm0.bin (';' comments, sixteen bytes per
# row with the byte offset). gawk port of the retired tools/mkbase.py, byte-for-byte on the image
# and all data; the emitted header comment names tools/scaffold/nanvm0.s (py said x86/scaffold/,
# but the .s lives in tools/scaffold now). no Python. Outer stack: POSIX sh + gawk + xxd only. Run under LC_ALL=C. Overwrites; keeps
# no history.
set -e
cd "$(dirname "$0")/.."
export LC_ALL=C
BHEX=$(xxd -p x86/scaffold/boot0.bin | tr -d '\n')
VHEX=$(xxd -p x86/scaffold/nanvm0.bin | tr -d '\n')
gawk -v BHEX="$BHEX" -v VHEX="$VHEX" \
     -v OUTB=x86/build/base.img -v OUTN=src/vm/nanvm0.nan '
function die(m){ print "mkbase: " m > "/dev/stderr"; exit 1 }
function hexv(h,   i, c, v){
  v = 0
  for (i = 1; i <= length(h); i++){ c = toupper(substr(h, i, 1)); v = v*16 + index("0123456789ABCDEF", c) - 1 }
  return v
}
function unhex(t, arr,   h, i, n){
  h = t; gsub(/[^0-9a-fA-F]/, "", h)
  n = 0
  for (i = 1; i <= length(h); i += 2) arr[n++] = hexv(substr(h, i, 2))
  return n
}
function zpad(n,   z){
  if (n <= 0) return ""
  z = sprintf("%c", 0)
  while (length(z) < n) z = z z
  return substr(z, 1, n)
}
BEGIN {
  nb = unhex(BHEX, BY)   # x86/scaffold/boot0.bin
  nv = unhex(VHEX, VY)   # x86/scaffold/nanvm0.bin
  if (nv > 1536) die("nanvm0.bin is " nv " bytes, the mkbase limit is 1536")
  if (nb > 510)  die("boot0.bin is " nb " bytes, overruns the 55 AA signature at 510/511")
  if (nb > 1474560) die("boot0.bin is " nb " bytes, overruns the floppy")
  # ---- base.img: mirror of python img=bytearray(1474560); img[0:len(b)]=b; 55 AA; img[512:512+len(v)]=v ----
  IMG = ""
  if (nb > 0) for (i = 0; i < nb; i++) IMG = IMG sprintf("%c", BY[i])
  IMG = IMG zpad(510 - nb)
  IMG = IMG sprintf("%c", 0x55) sprintf("%c", 0xAA)
  for (i = 0; i < nv; i++) IMG = IMG sprintf("%c", VY[i])
  IMG = IMG zpad(1474560 - 512 - nv)
  printf "%s", IMG > OUTB; close(OUTB)
  # ---- nanvm0.nan: header line + rows of 16 hex bytes + "   ; +off", one trailing newline ----
  TXT = "; NaNVM0 native boundary (NaN16 + DISPQ/DISPSET); bytes from tools/scaffold/nanvm0.s, objdump-verified"
  for (i = 0; i < nv; i += 16){
    ROW = ""
    for (j = i; j < i + 16 && j < nv; j++){
      D = sprintf("%02x", VY[j])
      ROW = (j == i) ? D : ROW " " D
    }
    TXT = TXT "\n" ROW "   ; +" sprintf("%04x", i)
  }
  TXT = TXT "\n"
  printf "%s", TXT > OUTN; close(OUTN)
  exit 0
}'
