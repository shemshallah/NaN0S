#!/bin/sh
# Boot disk check gate: sparse 1 GiB lazy NSPV image; used=3, sector 2 populated,
# sectors 0/1 sparse holes. Header check + guest decrypt of the populated prefix
# C-core disk fd; x86 IDE legs run when QEMU is present.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfs.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "storage boot gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 1G --lazy
node -e 'require("fs").writeFileSync(process.argv[1],Buffer.alloc(512,0xAB))' "$T/ab"
node crypt/volume.cjs write "$T/fs.img" "$KEY" 2 "$T/ab" >/dev/null
node crypt/volume.cjs check "$T/fs.img" "$KEY" --verify | grep -q '^VERIFY OK$'
node crypt/volume.cjs check "$T/fs.img" | grep -q '^CHECK OK .*used=3 .*lazy=1 '

# Header check cart.
awk -f tools/nmk.awk -v CMD=emit crypt/guest/nan0s_fs_check.nas > "$T/check.nan"
aarch64/android/nan_cli --img "$T/check.nan" --disk "$T/fs.img" \
  --steps 5000000 --serial > "$T/c.out" 2>/dev/null
grep -q '^NAN0S_FS OK cap=' "$T/c.out" || {
  echo "storage boot gate: FAIL (C-core header check)"; tail -4 "$T/c.out"; exit 1; }
grep -q 'used=00000003' "$T/c.out" || {
  echo "storage boot gate: FAIL (used count)"; tail -4 "$T/c.out"; exit 1; }

# Guest decrypts the used prefix (3 sectors; 0/1 are sparse holes, 2 is populated).
aarch64/android/nan_cli --img crypt/guest/nspv_decrypt.nan --disk "$T/fs.img" \
  --steps 80000000 --serial > "$T/d.out" 2>/dev/null
grep -q '^VOL PASS 00000003$' "$T/d.out" || {
  echo "storage boot gate: FAIL (C-core lazy decrypt)"; tail -4 "$T/d.out"; exit 1; }

if command -v qemu-system-i386 >/dev/null 2>&1; then
  BOOT_SRC="$PWD/crypt/guest/.nan0s_fs_check_boot.nas"
  trap 'rm -f "$BOOT_SRC"; rm -rf "$T"' EXIT
  sed 's/^\.org 0$/.org 8192/' crypt/guest/nan0s_fs_check.nas > "$BOOT_SRC"
  awk -f tools/nmk.awk -v CMD=emit "$BOOT_SRC" > "$T/check_boot.nan"

  mkboot() {
    printf 'boot:%s\n' "$1" > "$T/carts.txt"
    gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
      -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
    cat "$T/b.bin" "$T/g.bin" > "$2"
    truncate -s 1474560 "$2" 2>/dev/null || \
      dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$2"))) >> "$2"
  }
  runqemu() {
    timeout 120 qemu-system-i386 -m 32 \
      -drive format=raw,if=floppy,file="$1" \
      -drive format=raw,if=ide,file="$T/fs.img" \
      -display none -serial "file:$2" -no-reboot >/dev/null 2>&1 || true
  }

  mkboot "$T/check_boot.nan" "$T/check.img"
  runqemu "$T/check.img" "$T/qc.out"
  grep -q '^NAN0S_FS OK cap=' "$T/qc.out" || {
    echo "storage boot gate: FAIL (x86 header check)"; tail -6 "$T/qc.out"; exit 1; }
  grep -q 'used=00000003' "$T/qc.out" || {
    echo "storage boot gate: FAIL (x86 used count)"; tail -6 "$T/qc.out"; exit 1; }

  mkboot "$PWD/crypt/guest/nspv_decrypt_boot.nan" "$T/decrypt.img"
  runqemu "$T/decrypt.img" "$T/qd.out"
  grep -q '^VOL PASS 00000003$' "$T/qd.out" || {
    echo "storage boot gate: FAIL (x86 lazy decrypt)"; tail -6 "$T/qd.out"; exit 1; }
  echo "storage boot gate: PASS (sparse 1 GiB; used=3 with a hole, C-core fd + x86 IDE)"
else
  echo "storage boot gate: PASS (sparse 1 GiB; used=3 with a hole, C-core fd; QEMU skipped)"
fi
