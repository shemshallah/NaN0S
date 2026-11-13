#!/bin/sh
# tools/tm_gate.sh - table-driven Turing machine gate.
#
# Assembles the same NaN16 TM guest twice:
#   native   -> tm_test.nas on the canonical portable core
#   nested   -> tm_test.nas inside n16i (NaN16 interpreter in NaN16)
# Requires byte-identical serial output and the exact tape results.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/tm_gate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli
[ -x "$CLI" ] || (cd aarch64/android && make -s nan_cli)
asm(){ awk -f tools/nmk.awk -v CMD=emit "$1" > "$2" 2>/dev/null; }
run(){ "$CLI" --img "$1" --steps 10000000 --serial 2>"$2.err" >"$2.out"; }
asm src/tests/tm_test.nas "$T/tm.nan"
asm src/tests/tm_n16i_test.nas "$T/tm_n16i.nan"
run "$T/tm.nan" "$T/native"
run "$T/tm_n16i.nan" "$T/nested"
expected='TM BINARY 1100 PASS
TM UNARY 1111 PASS
TM CARRY 1000 PASS
TM ALL PASS'
printf '%s\n' "$expected" > "$T/expected"
cmp -s "$T/expected" "$T/native.out" || {
  echo "TM GATE FAIL: native tape result differs from expected"; od -An -c "$T/native.out"; exit 1; }
cmp -s "$T/native.out" "$T/nested.out" || {
  echo "TM GATE FAIL: native and n16i outputs differ"; od -An -c "$T/native.out"; od -An -c "$T/nested.out"; exit 1; }
grep -q 'TM ALL PASS' "$T/nested.out" || { echo "TM GATE FAIL: nested marker missing"; exit 1; }
printf 'TM GATE PASS (native == n16i; binary 1011->1100, unary 111->1111, carry ->1000)\n'
cat "$T/native.out"
