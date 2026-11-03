#!/bin/sh
# Boot disk check gate: sparse 1 GiB lazy NSPV image, header check on the
# C-core disk fd and, when QEMU is present, as an x86 IDE boot cart.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfs.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "storage boot gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 1G --lazy
node -e 'require("fs").writeFileSync(process.argv[1],Buffer.alloc(512,0xAB))' "$T/ab"
node crypt/volume.cjs write "$T/fs.img" "$KEY" 0 "$T/ab" >/dev/null
node crypt/volume.cjs check "$T/fs.img" "$KEY" --verify | grep -q '^VERIFY OK$'
node crypt/volume.cjs check "$T/fs.img" | grep -q '^CHECK OK .*used=1 .*lazy=1 '
awk -f tools/nmk.awk -v CMD=emit crypt/guest/nan0s_fs_check.nas > "$T/check.nan"
aarch64/android/nan_cli --img "$T/check.nan" --disk "$T/fs.img" \
  --steps 5000000 --serial > "$T/c.out" 2>/dev/null
grep -q '^NAN0S_FS OK cap=' "$T/c.out" || {
  echo "storage boot gate: FAIL (C-core header check)"; tail -4 "$T/c.out"; exit 1; }
grep -q 'used=00000001' "$T/c.out" || {
  echo "storage boot gate: FAIL (used count)"; tail -4 "$T/c.out"; exit 1; }
if command -v qemu-system-i386 >/dev/null 2>&1; then
  BOOT_SRC="$PWD/crypt/guest/.nan0s_fs_check_boot.nas"
  trap 'rm -f "$BOOT_SRC"; rm -rf "$T"' EXIT
  sed 's/^\.org 0$/.org 8192/' crypt/guest/nan0s_fs_check.nas > "$BOOT_SRC"
  awk -f tools/nmk.awk -v CMD=emit "$BOOT_SRC" > "$T/check_boot.nan"
  printf 'boot:%s\n' "$T/check_boot.nan" > "$T/carts.txt"
  gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
    -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
  cat "$T/b.bin" "$T/g.bin" > "$T/boot.img"
  truncate -s 1474560 "$T/boot.img" 2>/dev/null || \
    dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/boot.img"))) >> "$T/boot.img"
  timeout 30 qemu-system-i386 -m 32 \
    -drive format=raw,if=floppy,file="$T/boot.img" \
    -drive format=raw,if=ide,file="$T/fs.img" \
    -display none -serial "file:$T/q.out" -no-reboot >/dev/null 2>&1 || true
  grep -q '^NAN0S_FS OK cap=' "$T/q.out" || {
    echo "storage boot gate: FAIL (x86 IDE header check)"; tail -6 "$T/q.out"; exit 1; }
  echo "storage boot gate: PASS (sparse 1 GiB NSPV header check on C-core fd + x86 IDE)"
else
  echo "storage boot gate: PASS (sparse 1 GiB NSPV header check on C-core fd; QEMU skipped)"
fi
