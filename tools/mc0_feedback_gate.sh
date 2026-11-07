#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/mc0_feedback_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'PASS'
echo "MC0 candidate feedback gate: PASS"
