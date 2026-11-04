#!/bin/sh
# ATA read/write gate: write a pattern to sector 1 and read it back on the C core.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/atarw.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
truncate -s 4096 "$T/disk.img"
awk -f tools/nmk.awk -v CMD=emit src/tests/ata_rw_test.nas > "$T/t.nan"
aarch64/android/nan_cli --img "$T/t.nan" --disk "$T/disk.img" \
  --steps 1000000 --serial > "$T/out" 2>/dev/null
grep -q '^ATA RW PASS$' "$T/out" || {
  echo "ata rw gate: FAIL"; tail -4 "$T/out"; exit 1; }
echo "ata rw gate: PASS (16-bit PIO write + readback)"
