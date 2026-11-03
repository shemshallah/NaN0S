#!/bin/sh
# Guest metadata gate: decrypt+authenticate the nan0s_fs superblock, reject a
# tampered data sector, and run the metadata cart as an x86 IDE boot cart.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfmeta.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "nan0s_fs meta gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null
printf 'meta gate\n' > "$T/x"
crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/x" x >/dev/null
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_meta.nan --disk "$T/fs.img" \
  --steps 80000000 --serial > "$T/c.out" 2>/dev/null
grep -q '^NAN0S_FS META OK$' "$T/c.out" || {
  echo "nan0s_fs meta gate: FAIL (C-core superblock decrypt)"; tail -4 "$T/c.out"; exit 1; }

cp "$T/fs.img" "$T/tamper.img"
node -e '
const fs=require("fs"), v=require("./crypt/volume.cjs");
const [p]=process.argv.slice(1); const h=v.readHeaderFile(p);
const off=h.dataLba*512+100; const fd=fs.openSync(p,"r+"); const b=Buffer.alloc(1);
fs.readSync(fd,b,0,1,off); b[0]^=1; fs.writeSync(fd,b,0,1,off); fs.closeSync(fd);
' "$T/tamper.img"
aarch64/android/nan_cli --img crypt/guest/nan0s_fs_meta.nan --disk "$T/tamper.img" \
  --steps 80000000 --serial > "$T/t.out" 2>/dev/null
grep -q '^VOL FAIL$' "$T/t.out" || {
  echo "nan0s_fs meta gate: FAIL (tamper accepted)"; tail -4 "$T/t.out"; exit 1; }

if command -v qemu-system-i386 >/dev/null 2>&1; then
  printf 'boot:%s\n' "$PWD/crypt/guest/nan0s_fs_meta_boot.nan" > "$T/carts.txt"
  gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
    -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
  cat "$T/b.bin" "$T/g.bin" > "$T/boot.img"
  truncate -s 1474560 "$T/boot.img" 2>/dev/null || \
    dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/boot.img"))) >> "$T/boot.img"
  timeout 30 qemu-system-i386 -m 32 \
    -drive format=raw,if=floppy,file="$T/boot.img" \
    -drive format=raw,if=ide,file="$T/fs.img" \
    -display none -serial "file:$T/q.out" -no-reboot >/dev/null 2>&1 || true
  grep -q '^NAN0S_FS META OK$' "$T/q.out" || {
    echo "nan0s_fs meta gate: FAIL (x86 superblock decrypt)"; tail -6 "$T/q.out"; exit 1; }
  echo "nan0s_fs meta gate: PASS (guest superblock decrypt/auth + tamper reject, C-core + x86 IDE)"
else
  echo "nan0s_fs meta gate: PASS (guest superblock decrypt/auth + tamper reject, C-core; QEMU skipped)"
fi
