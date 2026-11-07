#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/runner_task_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'ROUTER TASK PASS'
echo "NaNLMROUTER task ledger gate: PASS"
