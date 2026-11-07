#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/mc0db_scratch_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'PASS'
echo "MC0DB/BS0DB scratch quota gate: PASS"
