#!/bin/sh
# Guest shell gate: nsh over the encrypted nan0s_fs volume (read/write/df).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfssh.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "nan0s_fs shell gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null
printf 'hello nan0s_fs\n' > "$T/hello.txt"
crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/hello.txt" hello.txt >/dev/null
KEYS='l,s,ENTER,c,a,t,SPACE,h,e,l,l,o,.,t,x,t,ENTER'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 80000000 --keys "$KEYS" --serial > "$T/out" 2>/dev/null
grep -q '^nsh> ls$' "$T/out" || { echo "nan0s_fs shell gate: FAIL (prompt/ls)"; tail -8 "$T/out"; exit 1; }
grep -q '^FILE hello.txt start=00000002 sectors=00000001 size=0000000F$' "$T/out" || {
  echo "nan0s_fs shell gate: FAIL (ls metadata)"; tail -8 "$T/out"; exit 1; }
grep -q '^hello nan0s_fs$' "$T/out" || { echo "nan0s_fs shell gate: FAIL (cat payload)"; tail -8 "$T/out"; exit 1; }
grep -q '^CAT OK$' "$T/out" || { echo "nan0s_fs shell gate: FAIL (cat status)"; tail -8 "$T/out"; exit 1; }

WKEYS='w,r,i,t,e,SPACE,h,e,l,l,o,.,t,x,t,ENTER,a,b,LEFT,RIGHT,UP,DOWN,HOME,DEL,X,END,Y,BS,ESC'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 80000000 --keys "$WKEYS" --serial > "$T/w.out" 2>/dev/null
grep -q '^WRITE OK$' "$T/w.out" || { echo "nan0s_fs shell gate: FAIL (write)"; tail -8 "$T/w.out"; exit 1; }
printf 'Xb' > "$T/new"
crypt/nan0s_fs get "$T/fs.img" "$KEY" hello.txt "$T/readback" >/dev/null
cmp -n 2 "$T/new" "$T/readback" || { echo "nan0s_fs shell gate: FAIL (write payload)"; exit 1; }

# edit loads the existing payload, Home returns to byte 0, Y replaces it, Esc saves.
EKEYS='e,d,i,t,SPACE,h,e,l,l,o,.,t,x,t,ENTER,HOME,DEL,Y,ESC'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 100000000 --keys "$EKEYS" --serial > "$T/e.out" 2>/dev/null
grep -q '^WRITE OK$' "$T/e.out" || { echo "nan0s_fs shell gate: FAIL (edit save)"; tail -8 "$T/e.out"; exit 1; }
printf 'Yb' > "$T/edit.new"
crypt/nan0s_fs get "$T/fs.img" "$KEY" hello.txt "$T/edit.read" >/dev/null
cmp -n 2 "$T/edit.new" "$T/edit.read" || { echo "nan0s_fs shell gate: FAIL (edit payload)"; exit 1; }

SKEYS='s,t,a,t,SPACE,h,e,l,l,o,.,t,x,t,ENTER'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 80000000 --keys "$SKEYS" --serial > "$T/s.out" 2>/dev/null
grep -q '^STAT start=00000002 sectors=00000001 size=00000002$' "$T/s.out" || { echo "nan0s_fs shell gate: FAIL (stat)"; tail -8 "$T/s.out"; exit 1; }
grep -q '^STAT OK$' "$T/s.out" || { echo "nan0s_fs shell gate: FAIL (stat status)"; exit 1; }

node crypt/volume.cjs verify "$T/fs.img" "$KEY" | grep -qx 'VERIFY OK'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 80000000 --keys 'd,f,ENTER' --serial > "$T/df.out" 2>/dev/null
grep -q '^DF cap=' "$T/df.out" || { echo "nan0s_fs shell gate: FAIL (df)"; tail -8 "$T/df.out"; exit 1; }

RKEYS='r,m,SPACE,h,e,l,l,o,.,t,x,t,ENTER,l,s,ENTER'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 100000000 --keys "$RKEYS" --serial > "$T/r.out" 2>/dev/null
grep -q '^RM OK$' "$T/r.out" || { echo "nan0s_fs shell gate: FAIL (rm)"; tail -8 "$T/r.out"; exit 1; }
grep -q '^LS OK files=00000000$' "$T/r.out" || { echo "nan0s_fs shell gate: FAIL (rm ls)"; tail -8 "$T/r.out"; exit 1; }
grep -q '^FILE hello.txt' "$T/r.out" && { echo "nan0s_fs shell gate: FAIL (rm tombstone visible)"; exit 1; }
crypt/nan0s_fs ls "$T/fs.img" "$KEY" | grep -qx 'EMPTY' || { echo "nan0s_fs shell gate: FAIL (host rm)"; exit 1; }

NKEYS='n,e,w,SPACE,f,o,o,ENTER,c,r,e,a,t,e,d,ESC'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 150000000 --keys "$NKEYS" --serial > "$T/n.out" 2>/dev/null
grep -q '^NEW OK$' "$T/n.out" || { echo "nan0s_fs shell gate: FAIL (new)"; tail -8 "$T/n.out"; exit 1; }
crypt/nan0s_fs get "$T/fs.img" "$KEY" foo "$T/newfile" >/dev/null
printf 'created' > "$T/created"
cmp "$T/created" "$T/newfile" || { echo "nan0s_fs shell gate: FAIL (new payload)"; exit 1; }
node crypt/volume.cjs verify "$T/fs.img" "$KEY" | grep -qx 'VERIFY OK'

# Fresh volume: new allocates dir/payload, seals both, updates the superblock,
# then advances the lazy header's used high-water mark.
node crypt/volume.cjs create 1 "$T/fresh.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fresh.img" "$KEY" >/dev/null
NKEYS='n,e,w,SPACE,f,o,o,ENTER,c,r,e,a,t,e,d,ESC'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fresh.img" \
  --steps 150000000 --keys "$NKEYS" --serial > "$T/f.out" 2>/dev/null
grep -q '^NEW OK$' "$T/f.out" || { echo "nan0s_fs shell gate: FAIL (fresh new)"; tail -8 "$T/f.out"; exit 1; }
crypt/nan0s_fs ls "$T/fresh.img" "$KEY" | grep -qx 'foo 2 1 7' || {
  echo "nan0s_fs shell gate: FAIL (fresh metadata)"; exit 1; }
crypt/nan0s_fs get "$T/fresh.img" "$KEY" foo "$T/freshfile" >/dev/null
cmp "$T/created" "$T/freshfile" || { echo "nan0s_fs shell gate: FAIL (fresh payload)"; exit 1; }

# Chained create: insert a second file at the head of the authenticated chain.
CKEYS='n,e,w,SPACE,b,a,r,ENTER,t,w,o,ESC'
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fresh.img" \
  --steps 150000000 --keys "$CKEYS" --serial > "$T/c.out" 2>/dev/null
grep -q '^NEW OK$' "$T/c.out" || { echo "nan0s_fs shell gate: FAIL (chained new)"; tail -8 "$T/c.out"; exit 1; }
crypt/nan0s_fs ls "$T/fresh.img" "$KEY" | grep -q '^foo 2 1 7$' || {
  echo "nan0s_fs shell gate: FAIL (chained foo)"; exit 1; }
crypt/nan0s_fs ls "$T/fresh.img" "$KEY" | grep -q '^bar 4 1 3$' || {
  echo "nan0s_fs shell gate: FAIL (chained bar)"; exit 1; }
crypt/nan0s_fs get "$T/fresh.img" "$KEY" bar "$T/barfile" >/dev/null
printf 'two' > "$T/two"
cmp "$T/two" "$T/barfile" || { echo "nan0s_fs shell gate: FAIL (chained payload)"; exit 1; }
node crypt/volume.cjs verify "$T/fresh.img" "$KEY" | grep -qx 'VERIFY OK'
echo "nan0s_fs shell gate: PASS (nsh ls/cat/edit/write/rm/new/chained/first-create/df)"
