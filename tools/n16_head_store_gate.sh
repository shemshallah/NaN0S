#!/bin/sh
# Execute actual NaN16 guest logic, not a host-language storage simulation.
set -eu
cd "$(dirname "$0")/.."
echo "Assembling native head store" 
awk -f tools/nmk.awk -v CMD=emit src/nannet/n16_head_store_test.nas > /dev/null
if out="$(sh tools/nrun.sh src/nannet/n16_head_store_test.nas 3000000 --serial 2>&1)"; then
  :
else
  printf '%s\n' "$out"
  echo "native guest assembler or VM failed" >&2
  exit 1
fi
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'N16 HEAD STORE PASS'
echo "NaN16 255-head scratch persistence gate: PASS"
