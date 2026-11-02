#!/bin/sh
# S1 AArch64 gate: build the boundary blob, boot it on qemu virt, require the
# exact serial line. Layer 0 of the AArch64 S1 core (spec/NANVM_SPEC.md §12).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/qgate_a64.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
as -o "$T/s1.o" aarch64/scaffold/s1_a64.s
ld -Ttext=0x40000000 -e _start -o "$T/s1.elf" "$T/s1.o"
timeout 10 qemu-system-aarch64 -M virt -m 128M -cpu cortex-a57 \
    -kernel "$T/s1.elf" -nographic > "$T/out" 2>&1 || true
grep -qx "S1VM OK" "$T/out" || { echo "s1 a64 gate: FAIL"; sed -n '1,6p' "$T/out"; exit 1; }
echo "s1 a64 gate: PASS (boot + NaN16 decode/execute + PUTC)"
