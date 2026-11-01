#!/bin/sh
# tools/ngate_n16i.sh - differential gate (replaces n16i_check.py): the SAME NaN16 image runs natively (mode 0) and under
# src/tools/n16i.nas (mode 1, raw-NaN interpreter) on the C core; serial bytes must be identical and both must halt.
# Cases: suite, both-face gate trap (!G), bad-op trap (!O), nest depth 0/1/2 (n16i_nest). Outer box = nan_cli only.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C; T="${TMPDIR:-/tmp}/ngate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
asm(){ awk -f tools/nmk.awk -v CMD=emit -v LABELS="$T/$2.lab" "$1" > "$T/$2.nan" 2>/dev/null; }
lab(){ awk -v k="$2" '$1==k{print $2}' "$T/$1.lab"; }
dw(){ printf '.org %d\n7FF8_%08X_F87F\n' "$2" "$3" >> "$1"; }
run(){ "$CLI" --img "$1" --steps 4000000000 --serial 2>"$1.err" >"$1.out"; sed -n 's/.*: \([0-9]*\) steps, rc=\([0-9]*\).*/\1 \2/p' "$1.err"; }
bad=0; asm src/tests/n16i_test.nas t; M=$(lab t mode); G=$(lab t gsel); B=$(lab t gbad)
for c in "suite 0 0" "gate-trap 1 1" "badop-trap 2 0"; do set -- $c; n=$1; gs=$2; bh=$3
  for m in 0 1; do f="$T/$n.$m.nan"; cp "$T/t.nan" "$f"; dw "$f" "$M" "$m"; dw "$f" "$G" "$gs"
    if [ "$bh" = 1 ]; then L=$(sed -n "$((B+2))p" "$T/t.nan" | cut -d' ' -f1); printf '.org %d\n0000_%s\n' "$B" "${L#*_}" >> "$f"; fi; done
  r0=$(run "$T/$n.0.nan"); r1=$(run "$T/$n.1.nan")
  if cmp -s "$T/$n.0.nan.out" "$T/$n.1.nan.out" && [ "${r0#* }" = 3 ] && [ "${r1#* }" = 3 ]; then s=MATCH; else s=MISMATCH; bad=$((bad+1)); fi
  printf '%-11s native %9s steps | interp %11s steps | out %5d bytes | %s\n' "$n" "${r0% *}" "${r1% *}" "$(wc -c < "$T/$n.0.nan.out")" "$s"
done
asm src/tests/n16i_nest.nas n; NM=$(lab n mode); first=
for m in 0 1 2; do f="$T/nest.$m.nan"; cp "$T/n.nan" "$f"; dw "$f" "$NM" "$m"; r=$(run "$f")
  printf 'nest depth %d: %11s steps, rc=%s\n' "$m" "${r% *}" "${r#* }"; [ "${r#* }" = 3 ] || bad=$((bad+1)); done
if cmp -s "$T/nest.0.nan.out" "$T/nest.1.nan.out" && cmp -s "$T/nest.1.nan.out" "$T/nest.2.nan.out" && grep -q 'sum of squares' "$T/nest.0.nan.out"; then echo "nested outputs identical (native / 1 level / 2 levels): True"; else echo "nested outputs identical: False"; bad=$((bad+1)); fi
[ -n "$NGATE_SHOW" ] && for n in gate-trap badop-trap; do printf "%s: " $n; cat "$T/$n.1.nan.out"; echo; done
[ $bad = 0 ] && echo "RESULT PASS" || { echo "RESULT FAIL"; exit 1; }
