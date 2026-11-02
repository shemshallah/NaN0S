#!/bin/sh
# tools/ncc_lex.sh - ncc M0 gate: the C lexer written in raw NaN16 must reproduce the
# golden token stream exactly (kinds, FNV values, lengths, line numbers).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/ncclex.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
awk -f tools/nmk.awk -v CMD=emit src/tests/ncc_lex_test.nas > "$T/t.nan" 2>"$T/e" || { cat "$T/e"; exit 1; }
"$CLI" --img "$T/t.nan" --steps 5000000 --serial > "$T/out" 2>"$T/err" || true
if cmp -s "$T/out" src/tests/ncc_lex.expected; then
  echo "ncc_lex: PASS ($(wc -l < "$T/out") tokens, exact)"
else
  echo "ncc_lex: FAIL"; diff src/tests/ncc_lex.expected "$T/out" | head -20; exit 1
fi
