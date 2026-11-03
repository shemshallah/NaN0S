#!/bin/sh
# Storage gate: NSPV volume on the C-core disk fd (Android path) and x86 QEMU IDE.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nspv.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "storage gate: node missing"; exit 77; }
command -v qemu-system-i386 >/dev/null 2>&1 || { echo "storage gate: qemu-system-i386 missing"; exit 77; }
KEY=000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F
NON=A0A1A2A3A4A5A6A7A8A9AAABACADAEAF
node crypt/volume.cjs format 1 "$T/vol.img" "$KEY" "$NON" 16 >/dev/null
node crypt/volume.cjs verify "$T/vol.img" "$KEY" | grep -qx 'VERIFY OK' || { echo "storage gate: FAIL (verify)"; exit 1; }
awk -f tools/nmk.awk -v CMD=emit crypt/guest/nspv_probe.nas > "$T/probe.nan"
aarch64/android/nan_cli --img "$T/probe.nan" --disk "$T/vol.img" --steps 5000000 --serial > "$T/c.out" 2>/dev/null
grep -q 'NSPV OK' "$T/c.out" || { echo "storage gate: FAIL (C-core/Android fd)"; tail -5 "$T/c.out"; exit 1; }
awk -f tools/nmk.awk -v CMD=emit crypt/guest/nspv_probe_boot.nas > "$T/pb.nan"
printf 'boot:%s\n' "$T/pb.nan" > "$T/carts.txt"
gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
  -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
cat "$T/b.bin" "$T/g.bin" > "$T/nspv.img"
truncate -s 1474560 "$T/nspv.img" 2>/dev/null || \
  dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/nspv.img"))) >> "$T/nspv.img"
timeout 20 qemu-system-i386 -m 32 \
  -drive format=raw,if=floppy,file="$T/nspv.img" \
  -drive format=raw,if=ide,file="$T/vol.img" \
  -display none -serial "file:$T/q.out" -no-reboot >/dev/null 2>&1 || true
grep -q 'NSPV OK' "$T/q.out" || { echo "storage gate: FAIL (x86 QEMU IDE)"; tail -8 "$T/q.out"; exit 1; }
echo "storage gate: PASS (NSPV volume on C-core disk fd + x86 QEMU IDE)"
