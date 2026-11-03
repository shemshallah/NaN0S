#!/bin/sh
# x86 host-network gate: NE2000 ISA + QEMU user-mode networking.
# The guest sends an ARP request for the user-net gateway and must see the reply.
set -e; cd "$(dirname "$0")/../.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/netgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v qemu-system-i386 >/dev/null 2>&1 || { echo "netgate: qemu-system-i386 missing"; exit 77; }
qemu-system-i386 -device help 2>/dev/null | grep -q 'ne2k_isa' || { echo "netgate: ne2k_isa unavailable"; exit 77; }
[ -f x86/net/ne2k_probe.nas ] || { echo "netgate: probe missing"; exit 1; }
awk -f tools/nmk.awk -v CMD=emit x86/net/ne2k_probe.nas > "$T/p.nan" 2>/dev/null
printf 'boot:%s\n' "$T/p.nan" > "$T/carts.txt"
gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan \
  -v GUEST=src/nan/museum.nan -v CARTS="$T/carts.txt" \
  -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
cat "$T/b.bin" "$T/g.bin" > "$T/img"
truncate -s 1474560 "$T/img" 2>/dev/null || \
  dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/img"))) >> "$T/img"
timeout 20 qemu-system-i386 -m 32 -drive format=raw,if=floppy,file="$T/img" \
  -netdev user,id=n0 -device ne2k_isa,netdev=n0,iobase=0x300,irq=9 \
  -display none -serial "file:$T/com1" -no-reboot >/dev/null 2>&1 || true
grep -q 'NET PASS' "$T/com1" || { echo "netgate: FAIL"; tail -20 "$T/com1"; exit 1; }
echo "netgate: PASS (NE2000 + QEMU user-net, ARP 10.0.2.2 reply)"
