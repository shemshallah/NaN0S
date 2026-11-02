#!/bin/sh
# S1 AArch64 gate: build a real NaN16 test with nmk, run the reference core,
# then boot the same image on the S1 under qemu virt and require byte-identical
# serial output. Layer 0/1 of the AArch64 S1 core (spec/NANVM_SPEC.md §12).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/qgate_a64.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
# 1. assemble the test and get the reference serial from the C harness
awk -f tools/nmk.awk -v CMD=emit aarch64/scaffold/s1_test.nas 2>/dev/null > "$T/s1.nan"
aarch64/android/nan_cli --img "$T/s1.nan" --steps 200000 --serial \
    > "$T/ref.out" 2>/dev/null
printf 'Y4O\n' > "$T/gold"
cmp -s "$T/gold" "$T/ref.out" || { echo "s1 a64 gate: FAIL (test expectation)"; od -An -c "$T/ref.out"; exit 1; }
# 2. convert the image to assembler words (AAA_PPPP_BBBB -> 0xAAAAPPPPBBBB)
awk '{ sub(/;.*/, ""); gsub(/[ \t]/, ""); if ($0 == "") next;
       split($0, a, "_");
       if (a[1] ~ /^[0-9A-Fa-f]+$/ && a[2] ~ /^[0-9A-Fa-f]+$/ && a[3] ~ /^[0-9A-Fa-f]+$/)
         print ".quad 0x" a[1] a[2] a[3] }' "$T/s1.nan" > "$T/s1_guest.inc"
# 3. build the S1 with the generated image and boot it
as -I "$T" -o "$T/s1.o" aarch64/scaffold/s1_a64.s
ld -Ttext=0x40000000 -e _start -o "$T/s1.elf" "$T/s1.o"
timeout 10 qemu-system-aarch64 -M virt -m 128M -cpu cortex-a57 \
    -kernel "$T/s1.elf" -nographic > "$T/out" 2>"$T/qerr" || true
cmp -s "$T/ref.out" "$T/out" || { echo "s1 a64 gate: FAIL (serial differs)"; echo "ref:"; od -An -c "$T/ref.out"; echo "s1:"; od -An -c "$T/out"; exit 1; }
echo "s1 a64 gate: PASS (differential vs nan_cli: Y4O)"
