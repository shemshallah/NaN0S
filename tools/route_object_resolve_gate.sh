#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/route_object_resolve_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'ROUTE RESOLVE PASS'
echo "NaN route object resolver gate: PASS"
