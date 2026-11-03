#!/bin/sh
# Guest storage-decrypt gate: NSPV sector 0 on the C-core disk fd; QEMU IDE if present.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nspvdec.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "storage decrypt gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs format 1 "$T/v.img" "$KEY" "$NON" 16 >/dev/null
node -e 'require("fs").writeFileSync(process.argv[1],Buffer.alloc(512,0xAB))' "$T/ab"
node crypt/volume.cjs write "$T/v.img" "$KEY" 0 "$T/ab" >/dev/null
node crypt/volume.cjs verify "$T/v.img" "$KEY" | grep -qx 'VERIFY OK'
aarch64/android/nan_cli --img crypt/guest/nspv_decrypt.nan --disk "$T/v.img" \
  --steps 50000000 --serial > "$T/c.out" 2>/dev/null
grep -q 'VOL PASS' "$T/c.out" || { echo "storage decrypt gate: FAIL (C-core)"; tail -4 "$T/c.out"; exit 1; }
if command -v qemu-system-i386 >/dev/null 2>&1; then
  printf 'boot:%s\n' "$PWD/crypt/guest/nspv_decrypt_boot.nan" > "$T/carts.txt"
  gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
    -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
  cat "$T/b.bin" "$T/g.bin" > "$T/boot.img"
  truncate -s 1474560 "$T/boot.img" 2>/dev/null || \
    dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/boot.img"))) >> "$T/boot.img"
  timeout 30 qemu-system-i386 -m 32 \
    -drive format=raw,if=floppy,file="$T/boot.img" \
    -drive format=raw,if=ide,file="$T/v.img" \
    -display none -serial "file:$T/q.out" -no-reboot >/dev/null 2>&1 || true
  grep -q 'VOL PASS' "$T/q.out" || { echo "storage decrypt gate: FAIL (QEMU IDE)"; tail -6 "$T/q.out"; exit 1; }
  echo "storage decrypt gate: PASS (guest NSPV sector decrypt on C-core fd + QEMU IDE)"
else
  echo "storage decrypt gate: PASS (guest NSPV sector decrypt on C-core fd; QEMU skipped)"
fi
