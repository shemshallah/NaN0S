# tools/sweep_patch.awk - flip one bit of a word payload inside the hex dump of the guest section (no Python).
#   gawk -f tools/sweep_patch.awk -v X=$T/x0.hex -v W=$word -v B=$bit -v OUT=$T/xp.hex   [pour: OFFB byte base]
# X = concatenated lowercase hex of the guest bytes (od -An -tx1 -v ... | tr -d ' \n'). Word W byte base OFFB
# (8704 for guest words in the floppy layout); payload LE bytes are wordstart+2..+5; bit B (0..31) flips byte
# int(B/8) of the payload, bit B%8. Exact hex-decimal arithmetic only (POSIX awk, no bitwise ops).
BEGIN {
  for (i = 0; i < 16; i++) for (j = 0; j < 16; j++) XL[i, j] = x4(i, j)
  HEX = "0123456789ABCDEF"
  off = (OFFB + 8 * W + 2 + int(B / 8)) * 2   # word bytes: [far_hi,far_lo][payload LE x4][near_lo,near_hi]
  m = 2 ^ (B % 8)
  while ((getline ln < X) > 0) Q = Q ln
  close(X)
  v = toupper(substr(Q, off + 1, 2))
  d = (index(HEX, substr(v, 1, 1)) - 1) * 16 + (index(HEX, substr(v, 2, 1)) - 1)
  d = xor8(d, m)
  o = sprintf("%02X", d)
  printf "%s%s%s", substr(Q, 1, off), o, substr(Q, off + 3) > OUT
}
function xor8(a, b) { return x4(a % 16, b % 16) + 16 * x4(int(a / 16) % 16, int(b / 16) % 16) }
function x4(i, j,   r) { # 4-bit xor via four 1-bit columns: (p+q)%2 with + and % only
  r = x1(i % 2, j % 2) + 2 * x1(int(i / 2) % 2, int(j / 2) % 2) + 4 * x1(int(i / 4), int(j / 4)) + 8 * x1(int(i / 8), int(j / 8))
  return r
}
function x1(p, q) { return (p + q) % 2 }
