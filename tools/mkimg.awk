# tools/mkimg.awk - builds the bootable NaN/0S floppy image (gawk port of the retired python tool).
# Outer dev-loop only. Run under LC_ALL=C:
#   gawk -f tools/mkimg.awk -v GOLD=x86/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
#        -v CARTS=tools/carts.txt -v OUTB=$T/n0sb.bin -v OUTG=$T/n0sg.bin
# mkall.sh then: cat OUTB OUTG > img; truncate -s 1474560 img.
# Layout: bytes 0-511 boot, 512-8703 kernel (gold, zero-padded), then guest words
# (8 bytes each: far head hi,lo = NEAR[n&3], payload LE, near head lo,hi = NEAR[n>>2]),
# zero-padded to 524288, then zero-padded to 1474560 total.
BEGIN {
  split("7FF1 FFF1 7FF8 FFF8", NETXT, " ")   # NEAR table, text order
  split("F17F F1FF F87F F8FF", FARTEXT, " ") # FAR table, text order (n = NEARidx<<2|FARidx)
  HT = "7FF1 FFF1 7FF8 FFF8"; split(HT, HEADS, " ")  # setw head source (NEAR family), converted below
  M = 4294967296
  for (hq = 1; hq <= 4; hq++) HEADS[hq] = hexv(HEADS[hq])
  # ---- gold machine bytes (boot 512 + kernel 5808) ----
  while ((getline ln < GOLD) > 0){
    i = index(ln, ";"); hx = i>0 ? substr(ln,1,i-1) : ln
    gsub(/[ \t\r\n]+/, "", hx)
    if (hx != "") for (j = 1; j <= length(hx); j += 2) GBY[NGB++] = hexv(substr(hx,j,2))
  }
  close(GOLD)
  if (NGB != 6320) die("gold stream is " NGB " bytes, expected 6320 (512 boot + 5808 kernel)")
  # ---- guest program words ----
  LMAX = loadguest(GUEST)
  if (LMAX == 0) die("no guest words in " GUEST)
  # ---- cartridges ----
  k = 0; top = 6400
  while ((getline cl < CARTS) > 0){
    ci = index(cl, ";"); if (ci > 0) cl = substr(cl, 1, ci-1)
    ci = index(cl, "#"); if (ci > 0) cl = substr(cl, 1, ci-1)
    gsub(/^[ \t]+|[ \t]+$/, "", cl)
    if (cl == "") continue
    pos = index(cl, ":")
    if (pos == 0) die("bad carts.txt line: " cl)
    stn = substr(cl, 1, pos-1); cf = substr(cl, pos+1)
    CN2 = loadguest(cf, 1)
    if (CN2 <= 8192) die(cf " has no payload (needs words 8192+)")
    pay = CN2 - 8192
    st = (stn == "auto") ? top : strtonum2(stn)
    if (st + pay > 65536) die("cartridge too big for store (image carries 65536 guest words): " cf)
    top = st + pay
    for (i = 0; i < pay; i++){
      W0[st+i] = PW0[8192+i]; W1[st+i] = PW1[8192+i]; WSET[st+i] = 1
    }
    h = 0x811C9DC5; h2 = 0x811C9DC5; cc = 0
    for (i = 0; i < pay; i++){
      n_ = W0[st+i]; p_ = W1[st+i]
      h = mul32(xor2(h, p_), 0x01000193)
      h2 = mul32(xor2(h2, bsw(p_)), 0x01000193)
      cc = rotl4(cc)
      cc = xor2(cc, n_)
    }
    tb = 4608 + 16*k
    setw(tb+4, 0, st); setw(tb+5, 0, pay); setw(tb+8, 0, h); setw(tb+10, 0, h2); setw(tb+11, 0, cc)
    if (top > LMAX) LMAX = top
    printf "cart %s store %d len %d seal A %08x B %08x C %08x\n", cf, st, pay, h, h2, cc > "/dev/stderr"
    k++
  }
  close(CARTS)
  if (LMAX < 4096) LMAX = 4096
  if (8*LMAX > 524288) die("guest region " 8*LMAX " bytes exceeds 524288")
  # ---- boot + kernel binary (8704 bytes: 512 boot, kernel zero-padded to 8192) ----
  s = ""
  for (i = 0; i < 512; i++) s = s sprintf("%c", GBY[i])
  for (i = 512; i < 8704; i++) s = s sprintf("%c", i < NGB ? GBY[i] : 0)
  printf "%s", s > OUTB
  # ---- guest region binary (8*LMAX bytes) ----
  s = ""
  for (i = 0; i < LMAX; i++){
    if (i in WSET){
      n_ = W0[i]; p_ = W1[i]
      fw = HEADS[(n_%4)+1]; nw = HEADS[int(n_/4)+1]
      s = s sprintf("%c%c", int(fw/256), fw%256)
      s = s sprintf("%c%c%c%c", p_%256, int(p_/256)%256, int(p_/65536)%256, int(p_/16777216)%256)
      s = s sprintf("%c%c", nw%256, int(nw/256)%256)
    } else {
      s = s "\0\0\0\0\0\0\0\0"
    }
    if ((i+1) % 4096 == 0){ printf "%s", s > OUTG; s = "" }
  }
  if (s != "") printf "%s", s > OUTG
  printf "image: boot 512 kernel %d guest %d words\n", NGB-512, LMAX > "/dev/stderr"
  exit 0
}
function die(m){ print "mkimg: " m > "/dev/stderr"; exit 1 }
function hexv(h,   i,c,v){
  v = 0
  for (i = 1; i <= length(h); i++){ c = toupper(substr(h,i,1)); v = v*16 + index("0123456789ABCDEF", c) - 1 }
  return v
}
function strtonum2(s){ return toupper(substr(s,1,2))=="0X" ? hexv(substr(s,3)) : s+0 }
# ---- .nan loader: fills W0/W1 (class, payload), returns word count ----
function loadguest(path, iscart,  l,ci,t,a,pp,f,n,neari,fari,ok,cnt){
  cnt = 0
  while ((getline l < path) > 0){
    ci = index(l, ";"); t = ci>0 ? substr(l,1,ci-1) : l
    gsub(/^[ \t]+|[ \t\r]+$/, "", t)
    if (t == "") continue
    if (split(t, hp, "_") != 3) die("bad word in " path ": " t)
    a = hexv(hp[1]); pp = hexv(hp[2]); f = hexv(hp[3])
    neari = -1; fari = -1
    for (ok = 1; ok <= 4; ok++){ if (NETXT[ok] == hp[1]) neari = ok-1; if (FARTEXT[ok] == hp[3]) fari = ok-1 }
    if (neari < 0 || fari < 0) die("bad head in " path ": " t)
    W0f = neari*4 + fari
    if (iscart){ PW0[cnt] = W0f; PW1[cnt] = pp } else { W0[cnt] = W0f; W1[cnt] = pp; WSET[cnt] = 1 }
    cnt++
  }
  close(path)
  return cnt
}
# ---- word memory write (mirrors setw semantics) ----
function setw(i, n, p){
  i = i % 65536
  W0[i] = n; W1[i] = p % M; WSET[i] = 1
}
# ---- exact uint32 helpers (split-mul: products stay < 2^33, exact in doubles) ----
function mul32(x, y,   al,ah,bl,bh,m,lb,r){
  x = x % M; if (x < 0) x += M
  y = y % M; if (y < 0) y += M
  al = x % 65536; ah = (x - al)/65536
  bl = y % 65536; bh = (y - bl)/65536
  m = (ah*bl + al*bh) % 65536
  lb = al*bl
  r = m*65536 + lb
  return r % M
}
function bsw(x){
  x = x % M; if (x < 0) x += M
  return ((x%256)*16777216) + ((int(x/256)%256)*65536) + ((int(x/65536)%256)*256) + int(x/16777216)
}
function rotl4(x){
  x = x % M; if (x < 0) x += M
  return (((x*16) % M) + int(x/268435456))
}
function xor2(a, b){
  a = a % M; if (a < 0) a += M
  b = b % M; if (b < 0) b += M
  return xor(a, b)
}
