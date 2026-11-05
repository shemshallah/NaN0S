#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-train-gate-$$.out"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
sh tools/nrun.sh src/training/n16_train.nas 2000000 --serial | tee "$tmp"
grep -qx 'N16 TRAIN PASS' "$tmp"
echo "N16 corpus trainer gate: PASS"
