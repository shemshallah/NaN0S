#!/bin/sh
# S1 AArch64 gate: build real NaN16 tests with nmk, run the reference core,
# then boot the same image on the S1 under qemu virt and require byte-identical
# serial output. Layers 0/1 of the AArch64 S1 core (spec/NANVM_SPEC.md §12).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/qgate_a64.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
run_one(){
  name=$1; src=$2
  awk -f tools/nmk.awk -v CMD=emit "$src" 2>/dev/null > "$T/$name.nan"
  aarch64/android/nan_cli --img "$T/$name.nan" --steps 200000 --serial \
      > "$T/$name.ref" 2>/dev/null
  awk '{ sub(/;.*/, ""); gsub(/[ \t]/, ""); if ($0 == "") next;
         split($0, a, "_");
         if (a[1] ~ /^[0-9A-Fa-f]+$/ && a[2] ~ /^[0-9A-Fa-f]+$/ && a[3] ~ /^[0-9A-Fa-f]+$/)
           print ".quad 0x" a[1] a[2] a[3] }' "$T/$name.nan" > "$T/s1_guest.inc"
  as -I "$T" -o "$T/$name.o" aarch64/scaffold/s1_a64.s
  ld -Ttext=0x40000000 -e _start -o "$T/$name.elf" "$T/$name.o"
  timeout 15 qemu-system-aarch64 -M virt -m 128M -cpu cortex-a57 \
      -kernel "$T/$name.elf" -nographic > "$T/$name.out" 2>"$T/$name.err" || true
  cmp -s "$T/$name.ref" "$T/$name.out" || { echo "s1 a64 gate: FAIL ($name serial differs)";
      echo "ref:"; od -An -c "$T/$name.ref"; echo "s1:"; od -An -c "$T/$name.out"; exit 1; }
}
run_one s1test aarch64/scaffold/s1_test.nas
printf 'Y4O\n' > "$T/gold"
cmp -s "$T/gold" "$T/s1test.ref" || { echo "s1 a64 gate: FAIL (s1test expectation)";
    od -An -c "$T/s1test.ref"; exit 1; }
run_one cprobe src/tests/carry_probe.nas
grep -q "PASS" "$T/cprobe.ref" || { echo "s1 a64 gate: FAIL (carry_probe reference)"; exit 1; }
echo "s1 a64 gate: PASS (differential vs nan_cli: s1_test + carry_probe)"
