#!/bin/sh
# S1 AArch64 gate: build real NaN16 tests with nmk, run the reference core,
# then boot the same image on the S1 under qemu virt and require byte-identical
# serial output. Layers 0/1 of the AArch64 S1 core (spec/NANVM_SPEC.md §12).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/qgate_a64.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
run_one(){
  name=$1; src=$2; clk=$3; keys=$4; kbytes=$5
  awk -f tools/nmk.awk -v CMD=emit "$src" 2>/dev/null > "$T/$name.nan"
  if [ -n "$clk" ]; then CLK="--clock $clk"; else CLK=""; fi
  if [ -n "$keys" ]; then KEYS="--keys $keys"; else KEYS=""; fi
  aarch64/android/nan_cli --img "$T/$name.nan" --steps 20000000 --serial \
      $CLK $KEYS > "$T/$name.ref" 2>/dev/null
  if [ -n "$kbytes" ]; then printf '%s\n' "$kbytes" > "$T/s1_keys.inc"; else : > "$T/s1_keys.inc"; fi
  awk '{ sub(/;.*/, ""); gsub(/[ \t_]/, ""); if (length($0) != 16 || $0 !~ /^[0-9A-Fa-f]+$/) next;
         s = ""; for (i = 15; i >= 1; i -= 2) s = s substr($0, i, 2); print s }' \
       "$T/$name.nan" | xxd -r -p > "$T/s1_guest.bin"
  as -I "$T" -o "$T/$name.o" aarch64/scaffold/s1_a64.s
  ld -Ttext=0x40000000 -e _start -o "$T/$name.elf" "$T/$name.o"
  timeout 30 qemu-system-aarch64 -M virt -m 128M -cpu cortex-a57 \
      -kernel "$T/$name.elf" -nographic -semihosting > "$T/$name.out" 2>"$T/$name.err" || true
  cmp -s "$T/$name.ref" "$T/$name.out" || { echo "s1 a64 gate: FAIL ($name serial differs)";
      echo "ref:"; od -An -c "$T/$name.ref"; echo "s1:"; od -An -c "$T/$name.out"; exit 1; }
}
run_one s1test aarch64/scaffold/s1_test.nas
printf 'Y4O\n' > "$T/gold"
cmp -s "$T/gold" "$T/s1test.ref" || { echo "s1 a64 gate: FAIL (s1test expectation)";
    od -An -c "$T/s1test.ref"; exit 1; }
run_one cprobe src/tests/carry_probe.nas
grep -q "PASS" "$T/cprobe.ref" || { echo "s1 a64 gate: FAIL (carry_probe reference)"; exit 1; }
run_one nalloc src/prog/nalloc_test.nas
grep -q "PASS" "$T/nalloc.ref" || { echo "s1 a64 gate: FAIL (nalloc reference)"; exit 1; }
run_one a64test src/tests/a64_test.nas
grep -q "PASS" "$T/a64test.ref" || { echo "s1 a64 gate: FAIL (a64_test reference)"; exit 1; }
run_one fptest aarch64/scaffold/s1_fp_test.nas
grep -q "FP PASS" "$T/fptest.ref" || { echo "s1 a64 gate: FAIL (fp test reference)"; exit 1; }
run_one devtest aarch64/scaffold/s1_dev_test.nas
grep -q "DEV PASS" "$T/devtest.ref" || { echo "s1 a64 gate: FAIL (device test reference)"; exit 1; }
run_one ring src/tests/ring_test.nas steps:1000
grep -q "E" "$T/ring.ref" || { echo "s1 a64 gate: FAIL (ring test reference)"; exit 1; }
run_one keytest aarch64/scaffold/s1_key_test.nas "" "A,B,ENTER" ".byte 65,66,13"
printf 'AB\r' > "$T/key.gold"
cmp -s "$T/key.gold" "$T/keytest.ref" || { echo "s1 a64 gate: FAIL (key test reference)"; od -An -c "$T/keytest.ref"; exit 1; }
# full work image: guest words from the shipped floppy image, 3M-step budget
img=aarch64/android/app/src/main/assets/nan0s.img
aarch64/android/nan_cli --img "$img" --steps 3000000 --serial > "$T/img.ref" 2>/dev/null
grep -q "READY" "$T/img.ref" || { echo "s1 a64 gate: FAIL (work image reference)"; exit 1; }
dd if="$img" of="$T/s1_guest.bin" bs=8 skip=1088 count=65536 2>/dev/null
: > "$T/s1_keys.inc"
as -I "$T" --defsym S1_MAXSTEPS=3000000 -o "$T/img.o" aarch64/scaffold/s1_a64.s
ld -Ttext=0x40000000 -e _start -o "$T/img.elf" "$T/img.o"
timeout 30 qemu-system-aarch64 -M virt -m 128M -cpu cortex-a57 -kernel "$T/img.elf" \
    -nographic -semihosting > "$T/img.out" 2>"$T/img.err" || true
cmp -s "$T/img.ref" "$T/img.out" || { echo "s1 a64 gate: FAIL (work image serial differs)";
    echo "ref:"; od -An -c "$T/img.ref" | head -3; echo "s1:"; od -An -c "$T/img.out" | head -3; exit 1; }
for t in n16de_test a2_boot_test nan16dump_test; do
  run_one "$t" "src/tests/$t.nas"
  grep -q "PASS" "$T/$t.ref" || { echo "s1 a64 gate: FAIL ($t reference)"; exit 1; }
done
echo "s1 a64 gate: PASS (differential vs nan_cli: s1_test + carry_probe + nalloc_test + a64_test + fp_test + dev_test + ring + keytest + n16de + a2_boot + nan16dump + work image)"
