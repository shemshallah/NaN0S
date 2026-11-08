#!/bin/sh
# Build runnable standalone native NaN16 worker image and export entry map.
set -eu
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export LC_ALL=C
awk -f tools/nmk.awk -v CMD=emit -v LABELS="$TMP/labels" \
    src/nannet/n16_head_worker.nas > "$TMP/worker.nan"
awk -f tools/nmk.awk -v CMD=check "$TMP/worker.nan"
for label in nh_format nh_open nh_put nh_get nhr_attach nhr_detach nhr_read nhr_observe; do
  grep -Eq "^$label [0-9]+$" "$TMP/labels"
done
if out="$(sh tools/nrun.sh src/nannet/n16_head_worker.nas 5000 --serial 2>&1)"; then
  :
else
  printf '%s\n' "$out"
  exit 1
fi
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -q "rc=3"
printf '%s\n' 'N16 HEAD WORKER IMAGE PASS'
