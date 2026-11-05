#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-train-gate-$$"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp"
printf 'N16TXT/1\nNaN16 owns the corpus codec.\nRunner and Android share one trainer.\nThe intake stages updates before merge.\n' > "$tmp/corpus.txt"
make -s -C aarch64/android nan_cli
if ! aarch64/android/nan_cli --nannet-train "$tmp/corpus.txt" --serial --candidate-out "$tmp/candidate.nan1" --peek 8448:3,8270:1,36449:1,12288:3 > "$tmp/out"; then cat "$tmp/out"; echo "trainer invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/out" || { cat "$tmp/out"; exit 1; }
test -s "$tmp/candidate.nan1" || { echo "candidate checkpoint was not written"; exit 1; }
grep -qx '00000001' "$tmp/out" || { echo "candidate bigram count missing"; cat "$tmp/out"; exit 1; }
if ! aarch64/android/nan_cli --nannet-train --serial > "$tmp/sample.out"; then cat "$tmp/sample.out"; echo "sample invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/sample.out" || { cat "$tmp/sample.out"; exit 1; }
sh tools/nannet-train.sh > "$tmp/launcher.out"
grep -qx 'N16 TRAIN PASS' "$tmp/launcher.out" || { cat "$tmp/launcher.out"; exit 1; }
printf 'N16TXT/1\ncaf\303\251\nemoji \360\237\214\215\n' > "$tmp/utf8.txt"
if ! aarch64/android/nan_cli --nannet-train "$tmp/utf8.txt" --serial > "$tmp/utf8.out"; then cat "$tmp/utf8.out"; echo "UTF-8 invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/utf8.out" || { cat "$tmp/utf8.out"; exit 1; }
printf 'N16TXT/1\nbad \300\257\n' > "$tmp/invalid.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/invalid.txt" --serial > "$tmp/invalid.out"; then echo "invalid UTF-8 unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/invalid.out" || { cat "$tmp/invalid.out"; exit 1; }
printf 'N16TXT/1\ncontrol \302\200\n' > "$tmp/control.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/control.txt" --serial > "$tmp/control.out"; then echo "C1 control unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/control.out" || { cat "$tmp/control.out"; exit 1; }
echo "N16 corpus trainer gate: PASS"
