#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-train-gate-$$"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp"
printf 'N16TXT/1\nNaN16 owns the corpus codec.\nRunner and Android share one trainer.\nThe intake stages updates before merge.\n' > "$tmp/corpus.txt"
make -s -C aarch64/android nan_cli
aarch64/android/nan_cli --nannet-train "$tmp/corpus.txt" --serial --peek 8448:3 > "$tmp/out"
grep -qx 'N16 TRAIN PASS' "$tmp/out"
aarch64/android/nan_cli --nannet-train --serial > "$tmp/sample.out"
grep -qx 'N16 TRAIN PASS' "$tmp/sample.out"
printf 'N16TXT/1\ncaf\303\251\nemoji \360\237\214\\215\n' > "$tmp/utf8.txt"
aarch64/android/nan_cli --nannet-train "$tmp/utf8.txt" --serial > "$tmp/utf8.out"
grep -qx 'N16 TRAIN PASS' "$tmp/utf8.out"
printf 'N16TXT/1\nbad \300\257\n' > "$tmp/invalid.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/invalid.txt" --serial > "$tmp/invalid.out"; then echo "invalid UTF-8 unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/invalid.out"
echo "N16 corpus trainer gate: PASS"
