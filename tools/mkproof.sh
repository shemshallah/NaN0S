#!/bin/sh
# tools/mkproof.sh TARGET.nas [--steps N] [nan_cli args...] - nasm0 in-guest assembler proof on the C core.
# awk/sh implementation (no external interpreters). Flat BIG layout: the guest gets
# nasm0+nasm0_proof at word 0, the flattened (nflat.awk) target source packed at #SRC, the HOST SEED's words
# (tools/nmk.awk, proven byte-identical to nanchk.py r29g) as the expected table at #EXP/#EXPC. The guest runs
# BOTH nasm0 passes over the source and compares OUT vs EXP class-for-class. Expected serial: ' PASS' with diff=0.
# Example gates:
#   sh tools/mkproof.sh src/tests/key_test.nas
set -e
cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/mkproof.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
S=2000000000; if [ "$1" = "--steps" ]; then S="$2"; shift 2; fi
TARGET="$1"; shift || true
[ -f "$TARGET" ] || { echo "mkproof: no such target $TARGET"; exit 1; }
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
gawk -f tools/nmk.awk -v CMD=emit src/prog/nasm0_proof.nas > "$T/h.nan" 2>"$T/he" || { cat "$T/he"; exit 1; }
gawk -f tools/nmk.awk -v CMD=emit "$TARGET" > "$T/t.nan" 2>"$T/te" || { cat "$T/te"; exit 1; }
awk -f tools/nflat.awk -v F="$TARGET" > "$T/s.txt"
awk -f tools/mkproof_flat.awk -v HARNESS="$T/h.nan" -v EXPECTE="$T/t.nan" -v SRCFILE="$T/s.txt" -v OUTFILE="$T/proof.nan" -v BIG=1
$CLI --img "$T/proof.nan" --steps "$S" --serial "$@" >"$T/out" 2>"$T/err" || true
tail -3 "$T/out"
sed -n 's/.*\] //p' "$T/err" | tail -1
grep -q 'diff=00000000' "$T/out" && grep -q ' PASS' "$T/out" && echo "PROOF PASS" || { echo "PROOF FAIL"; exit 1; }
