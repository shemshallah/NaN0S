#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/mirror_pair_map_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'MIRROR PAIRS PASS'
echo "mirror-pair map gate: PASS"
