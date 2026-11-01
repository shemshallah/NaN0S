#!/bin/sh
# tools/a64_run.sh GUEST.nan [SECS] - assemble the A64 core, pack core + guest words, run on qemu-system-aarch64 -M virt, print the UART.
# CARTS=tools/carts.txt embeds the exhibit cartridges. KEYS="s\r" feeds those bytes to the guest UART (KEY/KEYQ) after 1 s. Outer stack only: sh + gawk + xxd + qemu. Example: sh tools/a64_run.sh /tmp/a64_test.nan   (emit with: gawk -f tools/nmk.awk -v CMD=emit src/tests/a64_test.nas)
set -e
cd "$(dirname "$0")/.."
export LC_ALL=C
T="${TMPDIR:-/tmp}/a64run"; rm -rf "$T"; mkdir -p "$T"
head -c 6320 /dev/zero | xxd -p > "$T/gold0.hex"; : > "$T/nocarts.txt"
gawk -f tools/mkimg.awk -v GOLD="$T/gold0.hex" -v GUEST="$1" -v CARTS="${CARTS:-$T/nocarts.txt}" -v OUTB="$T/ob.bin" -v OUTG="$T/og.bin" >/dev/null
gawk -f tools/a64.awk src/native/kan16_a64.xa64 | xxd -r -p > "$T/core.bin"
cp "$T/core.bin" "$T/blob.bin"; truncate -s 8704 "$T/blob.bin"; cat "$T/og.bin" >> "$T/blob.bin"
if [ -n "$KEYS" ]; then (sleep 1; printf "$KEYS") | timeout "${2:-8}" qemu-system-aarch64 -M virt -m 512M -cpu cortex-a57 -display none -serial stdio -monitor none -kernel "$T/blob.bin" > "$T/ser.txt" 2>/dev/null || true
else
  timeout "${2:-8}" qemu-system-aarch64 -M virt -m 512M -cpu cortex-a57 -nographic -kernel "$T/blob.bin" -serial file:"$T/ser.txt" -monitor none 2>/dev/null || true
fi
cat "$T/ser.txt"; echo
