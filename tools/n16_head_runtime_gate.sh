#!/bin/sh
# Native NaN16 only. Both opcode logic and learning execute inside nan_cli.
set -eu
cd "$(dirname "$0")/.."
awk -f tools/nmk.awk -v CMD=emit src/nannet/n16_head_runtime_test.nas > /dev/null
if out="$(sh tools/nrun.sh src/nannet/n16_head_runtime_test.nas 5000000 --serial 2>&1)"; then
  :
else
  printf '%s\n' "$out"
  exit 1
fi
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'N16 HEAD RUNTIME PASS'
