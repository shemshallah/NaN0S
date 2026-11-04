#!/bin/sh
# Guest file-read gate: decrypt/auth the FS, find hello.txt, print payload.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfscat.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "nan0s_fs cat gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null
printf 'hello nan0s_fs\n' > "$T/hello.txt"
crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/hello.txt" hello.txt >/dev/null
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_cat.nan --disk "$T/fs.img" \
  --steps 80000000 --serial > "$T/c.out" 2>/dev/null
grep -q '^hello nan0s_fs$' "$T/c.out" || {
  echo "nan0s_fs cat gate: FAIL (payload)"; tail -4 "$T/c.out"; exit 1; }
grep -q '^NAN0S_FS CAT OK$' "$T/c.out" || {
  echo "nan0s_fs cat gate: FAIL (status)"; tail -4 "$T/c.out"; exit 1; }

node crypt/volume.cjs create 1 "$T/empty.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/empty.img" "$KEY" >/dev/null
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_cat.nan --disk "$T/empty.img" \
  --steps 80000000 --serial > "$T/n.out" 2>/dev/null
grep -q '^NAN0S_FS CAT NO$' "$T/n.out" || {
  echo "nan0s_fs cat gate: FAIL (missing file)"; tail -4 "$T/n.out"; exit 1; }
echo "nan0s_fs cat gate: PASS (guest decrypt + file lookup + payload; missing-file fail)"
