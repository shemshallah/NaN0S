#!/bin/sh
# tools/ngate_nfix.sh - nasm0 fixpoint gate (r29h). Seed = nmk.awk (build image) + nmkfs.sh (source onto a NaNFS disk); everything
# after that runs in the guest: disk -> nasm0 -> compare (gen1==gen0) -> gen1 under n16i -> compare (gen2==gen1). Needs awk, printf, nan_cli.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C; T="${TMPDIR:-/tmp}/nfix.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
S=src/tests/nfix_test.nas
awk -f tools/nmk.awk -v CMD=emit -v LABELS="$T/l" $S > "$T/i.nan" 2>"$T/e"; sh tools/nmkfs.sh $S "$T/d.img"
$CLI --img "$T/i.nan" --disk "$T/d.img" --steps ${NSTEPS:-4000000000} --serial 2>"$T/err" >"$T/out" || true
cat "$T/out"; sed -n 's/.*\] //p' "$T/err" | tail -1
grep -q '^F1 PASS' "$T/out" && grep -q '^F2 PASS' "$T/out" && grep -q '^FIX PASS' "$T/out" && echo "RESULT PASS" || { echo "RESULT FAIL"; exit 1; }
