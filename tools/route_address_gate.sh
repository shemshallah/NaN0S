#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/route_address_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'NAN ADDRESS PASS'
echo "NaN route address parser gate: PASS"
