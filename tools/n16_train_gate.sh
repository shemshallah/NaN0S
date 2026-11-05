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
if grep -a -q 'NaN16 owns the corpus codec' "$tmp/candidate.nan1"; then echo "candidate checkpoint retained raw corpus text"; exit 1; fi
grep -qx '00000001' "$tmp/out" || { echo "candidate bigram count missing"; cat "$tmp/out"; exit 1; }
if ! aarch64/android/nan_cli --nannet-train --serial > "$tmp/sample.out"; then cat "$tmp/sample.out"; echo "sample invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/sample.out" || { cat "$tmp/sample.out"; exit 1; }
sh tools/nannet-train.sh > "$tmp/launcher.out"
grep -qx 'N16 TRAIN PASS' "$tmp/launcher.out" || { cat "$tmp/launcher.out"; exit 1; }
printf 'N16TXT/1\ncaf\303\251\nemoji \360\237\214\215\n' > "$tmp/utf8.txt"
if ! aarch64/android/nan_cli --nannet-train "$tmp/utf8.txt" --serial > "$tmp/utf8.out"; then cat "$tmp/utf8.out"; echo "UTF-8 invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/utf8.out" || { cat "$tmp/utf8.out"; exit 1; }
printf 'N16TXT/1\r\nCRLF record\r\n' > "$tmp/crlf.txt"
aarch64/android/nan_cli --nannet-train "$tmp/crlf.txt" --serial > "$tmp/crlf.out"
grep -qx 'N16 TRAIN PASS' "$tmp/crlf.out" || { cat "$tmp/crlf.out"; exit 1; }
printf 'N16TXT/1\nstray\rCR\n' > "$tmp/lone-cr.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/lone-cr.txt" --serial > "$tmp/lone-cr.out"; then echo "lone CR unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/lone-cr.out" || { cat "$tmp/lone-cr.out"; exit 1; }
printf 'N16TXT/1\r\nCRLF header and records.\r\n' > "$tmp/crlf-header.txt"
if ! aarch64/android/nan_cli --nannet-train "$tmp/crlf-header.txt" --serial --peek 8449:1 > "$tmp/crlf-header.out"; then cat "$tmp/crlf-header.out"; echo "CRLF header invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/crlf-header.out" || { cat "$tmp/crlf-header.out"; exit 1; }
grep -qx '00000001' "$tmp/crlf-header.out" || { echo "CRLF header was not parsed as one record"; cat "$tmp/crlf-header.out"; exit 1; }
printf 'CRLF body record one.\r\nCRLF body record two.\r\n' > "$tmp/crlf-body.txt"
if ! aarch64/android/nan_cli --nannet-train "$tmp/crlf-body.txt" --serial --peek 8449:1 > "$tmp/crlf-body.out"; then cat "$tmp/crlf-body.out"; echo "CRLF body invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/crlf-body.out" || { cat "$tmp/crlf-body.out"; exit 1; }
grep -qx '00000002' "$tmp/crlf-body.out" || { echo "CRLF body record count mismatch"; cat "$tmp/crlf-body.out"; exit 1; }
printf 'N16TXT/1\nbare\rreturn\n' > "$tmp/bare-cr.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/bare-cr.txt" --serial > "$tmp/bare-cr.out"; then echo "bare CR unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/bare-cr.out" || { cat "$tmp/bare-cr.out"; exit 1; }
printf 'N16TXT/1\nbad \300\257\n' > "$tmp/invalid.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/invalid.txt" --serial --candidate-out "$tmp/rejected.nan1" > "$tmp/invalid.out"; then echo "invalid UTF-8 unexpectedly accepted"; exit 1; fi
test ! -e "$tmp/rejected.nan1" || { echo "rejected corpus exported a candidate"; exit 1; }
grep -qx 'N16 TRAIN REJECT' "$tmp/invalid.out" || { cat "$tmp/invalid.out"; exit 1; }
printf 'N16TXT/1\ncontrol \302\200\n' > "$tmp/control.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/control.txt" --serial > "$tmp/control.out"; then echo "C1 control unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/control.out" || { cat "$tmp/control.out"; exit 1; }
echo "N16 corpus trainer gate: PASS"
