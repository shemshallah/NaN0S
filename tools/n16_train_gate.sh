#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-train-gate-$$"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp"
printf 'N16TXT/1\nNaN16 owns the corpus codec.\nRunner and Android share one trainer.\nThe intake stages updates before merge.\n' > "$tmp/corpus.txt"
make -s nan_cli
./nan_cli --nannet-train "$tmp/corpus.txt" --serial --peek 8448:3 > "$tmp/out"
grep -qx 'N16 TRAIN PASS' "$tmp/out"
echo "N16 corpus trainer gate: PASS"
