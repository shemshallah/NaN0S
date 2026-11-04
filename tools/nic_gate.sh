#!/bin/sh
# NIC bring-up gate: boot a tiny image whose boot cart probes RTL8139.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nicgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v gawk >/dev/null 2>&1 || { echo "nic gate: gawk missing"; exit 77; }
command -v qemu-system-i386 >/dev/null 2>&1 || { echo "nic gate: qemu missing"; exit 77; }
[ -f src/nan/nic_cart.nan ] || awk -f tools/nmk.awk -v CMD=emit src/nan/nic_cart.nas > src/nan/nic_cart.nan 2>/dev/null
printf 'boot:src/nan/nic_cart.nan\n' > "$T/carts.txt"
gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
  -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" >/dev/null 2>"$T/mk.err"
cat "$T/b.bin" "$T/g.bin" > "$T/img"; truncate -s 1474560 "$T/img"
timeout 15 qemu-system-i386 -m 32 -drive format=raw,if=floppy,file="$T/img" \
  -netdev user,id=n0 -device rtl8139,netdev=n0 -display none \
  -serial "file:$T/com1.txt" -no-reboot >/dev/null 2>&1 || true
grep -q 'NIC 10EC 8139 BASE C000 52:54:00:12:34:56: RESET' "$T/com1.txt" &&
grep -q '^TX OK$' "$T/com1.txt" &&
grep -q '^RX OK$' "$T/com1.txt" || {
  echo "nic gate: FAIL"; tail -8 "$T/com1.txt" | cat -v; exit 1; }
echo "nic gate: PASS (RTL8139 PCI/BAR/MAC/reset + raw-DMA TX/RX)"
