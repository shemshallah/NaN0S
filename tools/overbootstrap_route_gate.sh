#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/overbootstrap_route_test.nas 3000000 --serial)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'OVERBOOTSTRAP PASS'
echo "NaN16 overbootstrap route gate: PASS"
