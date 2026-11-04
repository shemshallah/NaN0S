#!/bin/sh
# Guest directory gate: decrypt/auth every populated block, count NDIR1 blocks,
# compare with the superblock file count, and reject a tampered directory byte.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfsdir.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "nan0s_fs dir gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null
for i in $(seq 1 12); do
  printf 'dir gate %02d\n' "$i" > "$T/f"
  crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/f" "f$i" >/dev/null
done
crypt/nan0s_fs check "$T/fs.img" "$KEY" | grep -q '^FS OK files=12 '
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_dir.nan --disk "$T/fs.img" \
  --steps 120000000 --serial > "$T/c.out" 2>/dev/null
grep -q '^NAN0S_FS DIR OK files=0000000C$' "$T/c.out" || {
  echo "nan0s_fs dir gate: FAIL (C-core directory count)"; tail -4 "$T/c.out"; exit 1; }
grep -q '^FILE f1 start=00000002 ' "$T/c.out" && grep -q '^FILE f12 start=' "$T/c.out" || {
  echo "nan0s_fs dir gate: FAIL (C-core names)"; tail -8 "$T/c.out"; exit 1; }

cp "$T/fs.img" "$T/tamper.img"
node -e '
const fs=require("fs"), v=require("./crypt/volume.cjs");
const [p]=process.argv.slice(1); const h=v.readHeaderFile(p);
const off=(h.dataLba+1)*512+20; const fd=fs.openSync(p,"r+"); const b=Buffer.alloc(1);
fs.readSync(fd,b,0,1,off); b[0]^=1; fs.writeSync(fd,b,0,1,off); fs.closeSync(fd);
' "$T/tamper.img"
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_dir.nan --disk "$T/tamper.img" \
  --steps 120000000 --serial > "$T/t.out" 2>/dev/null
grep -q '^VOL FAIL$' "$T/t.out" || {
  echo "nan0s_fs dir gate: FAIL (tampered directory accepted)"; tail -4 "$T/t.out"; exit 1; }

if command -v qemu-system-i386 >/dev/null 2>&1; then
  printf 'boot:%s\n' "$PWD/crypt/guest/nan0s_fs_dir_boot.nan" > "$T/carts.txt"
  gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
    -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
  cat "$T/b.bin" "$T/g.bin" > "$T/boot.img"
  truncate -s 1474560 "$T/boot.img" 2>/dev/null || \
    dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/boot.img"))) >> "$T/boot.img"
  timeout 120 qemu-system-i386 -m 32 \
    -drive format=raw,if=floppy,file="$T/boot.img" \
    -drive format=raw,if=ide,file="$T/fs.img" \
    -display none -serial "file:$T/q.out" -no-reboot >/dev/null 2>&1 || true
  grep -q '^NAN0S_FS DIR OK files=0000000C$' "$T/q.out" || {
    echo "nan0s_fs dir gate: FAIL (x86 directory count)"; tail -6 "$T/q.out"; exit 1; }
  grep -q '^FILE f1 start=00000002 ' "$T/q.out" && grep -q '^FILE f12 start=' "$T/q.out" || {
    echo "nan0s_fs dir gate: FAIL (x86 names)"; tail -8 "$T/q.out"; exit 1; }
  echo "nan0s_fs dir gate: PASS (12 authenticated names + tamper reject, C-core + x86 IDE)"
else
  echo "nan0s_fs dir gate: PASS (12 authenticated names + tamper reject, C-core; QEMU skipped)"
fi
