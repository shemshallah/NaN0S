#!/bin/sh
# GUI launch gate: desktop terminal command f hands off to the VGA nsh cart
# (slot 10), which lists and writes the encrypted nan0s_fs volume.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfsguigate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
IMG=build/nan0s.img
[ -f "$IMG" ] || { echo "nan0s_fs GUI gate: image missing (run tools/build.sh)"; exit 77; }
command -v node >/dev/null 2>&1 || { echo "nan0s_fs GUI gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null
printf 'hello nan0s_fs\n' > "$T/hello.txt"
crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/hello.txt" hello.txt >/dev/null

K='@3000000,f,ENTER,@5000000,l,s,ENTER'
aarch64/android/nan_cli --img "$IMG" --disk "$T/fs.img" --steps 120000000 \
  --keys "$K" --dump-text > "$T/ls.out" 2>/dev/null
grep -q '^nsh> ls$' "$T/ls.out" || { echo "nan0s_fs GUI gate: FAIL (nsh launch)"; head -8 "$T/ls.out"; exit 1; }
grep -q '^FILE hello.txt start=00000002 sectors=00000001 size=0000000F$' "$T/ls.out" || {
  echo "nan0s_fs GUI gate: FAIL (ls)"; head -8 "$T/ls.out"; exit 1; }
grep -q '^LS OK files=00000001$' "$T/ls.out" || { echo "nan0s_fs GUI gate: FAIL (ls status)"; exit 1; }

W='@3000000,f,ENTER,@5000000,w,r,i,t,e,SPACE,h,e,l,l,o,.,t,x,t,ENTER,@1500000,n,e,w,SPACE,t,e,x,t,ESC,@1500000'
aarch64/android/nan_cli --img "$IMG" --disk "$T/fs.img" --steps 200000000 \
  --keys "$W" --dump-text > "$T/w.out" 2>/dev/null
grep -q '^WRITE OK$' "$T/w.out" || { echo "nan0s_fs GUI gate: FAIL (write)"; tail -8 "$T/w.out"; exit 1; }
printf 'new text' > "$T/new"
crypt/nan0s_fs get "$T/fs.img" "$KEY" hello.txt "$T/readback" >/dev/null
cmp -n 8 "$T/new" "$T/readback" || { echo "nan0s_fs GUI gate: FAIL (write payload)"; exit 1; }
node crypt/volume.cjs verify "$T/fs.img" "$KEY" | grep -qx 'VERIFY OK'

R='@3000000,f,ENTER,@5000000,r,m,SPACE,h,e,l,l,o,.,t,x,t,ENTER,@1500000,l,s,ENTER'
aarch64/android/nan_cli --img "$IMG" --disk "$T/fs.img" --steps 150000000 \
  --keys "$R" --dump-text > "$T/rm.out" 2>/dev/null
grep -q '^RM OK$' "$T/rm.out" || { echo "nan0s_fs GUI gate: FAIL (rm)"; tail -8 "$T/rm.out"; exit 1; }
grep -q '^LS OK files=00000000$' "$T/rm.out" || { echo "nan0s_fs GUI gate: FAIL (rm ls)"; exit 1; }
crypt/nan0s_fs ls "$T/fs.img" "$KEY" | grep -qx 'EMPTY' || { echo "nan0s_fs GUI gate: FAIL (host rm)"; exit 1; }
node crypt/volume.cjs verify "$T/fs.img" "$KEY" | grep -qx 'VERIFY OK'
echo "nan0s_fs GUI gate: PASS (desktop f -> VGA nsh -> ls/write/rm)"
