#!/bin/sh
set -u
cd "$(dirname "$0")/.."
rc=0
out="$(sh tools/nrun.sh src/nannet/mc0db_scratch_test.nas 2>&1)" || rc=$?
printf '%s\n' "$out"
if [ "$rc" -ne 0 ]; then
  echo "MC0DB/BS0DB scratch guest exited: $rc" >&2
  exit "$rc"
fi
printf '%s\n' "$out" | grep -qx 'PASS'
echo "MC0DB/BS0DB scratch quota gate: PASS"
