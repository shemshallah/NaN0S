#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/boolean_bootstrap_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'BS0 BOOLEAN PASS'
echo "BS0 Boolean bootstrap gate: PASS"
