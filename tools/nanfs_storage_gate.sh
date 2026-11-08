#!/bin/sh
# Compile NaNFS guests with the canonical NaN0S assembler, run on nan_cli.
set -eu
cd "$(dirname "$0")/.."
for test_file in src/tests/nanfs_test.nas src/tests/nanfs_storage_test.nas; do
  case "$test_file" in
    *nanfs_storage_test.nas) marker='NANFS STORAGE PASS';;
    *) marker='NANFS PASS';;
  esac
  if out="$(sh tools/nrun.sh "$test_file" 3000000 2>&1)"; then
    :
  else
    printf '%s\n' "$out"
    printf 'NaN16 storage guest execution failed: %s\n' "$test_file" >&2
    exit 1
  fi
  printf '%s\n' "$out"
  printf '%s\n' "$out" | grep -qx "$marker" || {
    printf 'NaN16 storage guest did not emit %s: %s\n' "$marker" "$test_file" >&2
    exit 1
  }
done
printf '%s\n' 'Native NaN16 storage gate: PASS'
