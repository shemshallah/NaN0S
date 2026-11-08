#!/bin/sh
# Execute actual NaN16 guest logic, not a host-language storage simulation.
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/n16_head_store_test.nas 3000000 --serial)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'N16 HEAD STORE PASS'
echo "NaN16 255-head scratch persistence gate: PASS"
