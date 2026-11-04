#!/bin/sh
# Multi-sector create gate: new writes >512 bytes, spans two payload sectors,
# records the real byte count, and re-seals every sector.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfsmulti.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "nan0s_fs multi gate: node missing"; exit 77; }
[ -f crypt/guest/nan0s_fs_sh.nan ] || { echo "nan0s_fs multi gate: shell cart missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null

# 520 printable bytes -> two payload sectors (512 + 8).
K=$(awk 'BEGIN{
  printf "n,e,w,SPACE,f,o,o,ENTER";
  for (i = 1; i <= 520; i++) { printf ",a"; if (i % 5 == 0) printf ",@500000" }
  printf ",ESC"
}')
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_sh.nan --disk "$T/fs.img" \
  --steps 900000000 --keys "$K" --serial > "$T/out" 2>/dev/null
grep -q '^NEW OK$' "$T/out" || { echo "nan0s_fs multi gate: FAIL (new)"; tail -8 "$T/out"; exit 1; }
crypt/nan0s_fs ls "$T/fs.img" "$KEY" | grep -qx 'foo 2 2 520' || {
  echo "nan0s_fs multi gate: FAIL (metadata)"; crypt/nan0s_fs ls "$T/fs.img" "$KEY"; exit 1; }
crypt/nan0s_fs get "$T/fs.img" "$KEY" foo "$T/payload" >/dev/null
awk 'BEGIN{for(i=1;i<=520;i++)printf "a"}' > "$T/expected"
cmp "$T/expected" "$T/payload" || { echo "nan0s_fs multi gate: FAIL (payload)"; exit 1; }
node crypt/volume.cjs verify "$T/fs.img" "$KEY" | grep -qx 'VERIFY OK'
echo "nan0s_fs multi gate: PASS (520-byte file, 2 sealed sectors)"
