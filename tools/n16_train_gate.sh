#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/training/n16_train.nas 2000000 --serial 2>/dev/null)"
printf '%s\n' "$out" | grep -qx 'N16 TRAIN PASS'
echo "N16 corpus trainer gate: PASS"
