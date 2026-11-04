#!/bin/sh
# Guest shell gate: interactive nsh over the encrypted nan0s_fs volume.
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
echo "nan0s_fs shell gate: PASS (nsh ls + cat <name> on encrypted volume)"
