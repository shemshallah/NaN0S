#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/runner_ring_integration_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'RUNNER RING PASS'
echo "BS0/MC0/HW0 router-math integration gate: PASS"
