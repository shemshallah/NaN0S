#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-protocol-gate-$$.out"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
sh tools/nrun.sh src/nannet/train_protocol_test.nas 5000000 --serial | tee "$tmp"
grep -qx 'N16 PROTOCOL PASS' "$tmp"
echo "NaN16 network protocol gate: PASS"
