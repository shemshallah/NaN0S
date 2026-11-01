#!/bin/sh
# tools/ngate_fuzz.sh - differential gate for the fuzz cart (replaces the retired tools/n16i_fuzz.py).
# The SAME generated 60-word NaN16 program per seed must execute identically (a) natively in the
# C core (mode 0: one nan_cli invocation per seed, window reached via JMPR) and (b) inside
# src/tools/n16i.nas (mode 1: N seeds in one image, window via CALL @n16i_run). Per-seed serial
# segments (marker M<hex seed> + 10 register rows) must match byte-for-byte and every run must
# end in the dump stub's HALT (rc=3). Optimizer-free by design: no host-side model, only engine
# vs engine. Outer box = POSIX sh + awk + cmp only.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C; T="${TMPDIR:-/tmp}/fzgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
N=60
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
asm(){ awk -f tools/nmk.awk -v CMD=emit -v LABELS="$T/$2.lab" "$1" > "$T/$2.nan" 2>/dev/null; }
lab(){ awk -v k="$2" '$1==k{print $2}' "$T/$1.lab"; }
dw(){ printf '.org %d\n7FF8_%08X_F87F\n' "$2" "$3" >> "$1"; }
run(){ "$CLI" --img "$1" --steps 4000000000 --serial > "$1.out" 2> "$1.err"; }
rc(){ sed -n 's/.*: \([0-9]*\) steps, rc=\([0-9]*\).*/\1 \2/p' "$1"; }
asm src/tests/n16fuzz.nas fz; FM=$(lab fz fz_fmode); SC=$(lab fz fz_seedc); CT=$(lab fz fz_count)
[ -n "$FM" ] && [ -n "$SC" ] && [ -n "$CT" ] || { echo "fuzz cart: mode/seed slots not found"; exit 1; }
# one interp image, N seeds: FMODE=1 SEED=0 COUNT=N
dw "$T/fz.nan" "$FM" 1; dw "$T/fz.nan" "$SC" 0; dw "$T/fz.nan" "$CT" "$N"
run "$T/fz.nan"; r1=$(rc "$T/fz.nan.err"); [ "${r1#* }" = 3 ] || { echo "interp rc=${r1#* } (want 3)"; bad=1; }
# split the interp serial on the per-seed markers
awk -v d="$T/i." '/^M[0-9A-F][0-9A-F][0-9A-F][0-9A-F]$/ {if (o!="") close(o); o=d substr($0,2); print > o; next} o!="" {print > o}' "$T/fz.nan.out"
# one native run per seed: FMODE=0 SEED=s (COUNT is ignored in native mode)
for s in $(seq 0 $((N-1))); do
  h=$(printf '%04X' "$s"); f="$T/z.$h.nan"; cp "$T/fz.nan" "$f"
  dw "$f" "$FM" 0; dw "$f" "$SC" "$s"
  run "$f"; r0=$(rc "$f.err"); [ "${r0#* }" = 3 ] || { echo "native seed $s rc=${r0#* } (want 3)"; bad=1; }
  if cmp -s "$T/i.$h" "$f.out"; then st=ok; else printf 'seed %04X MISMATCH\n' "$s"; bad=1; fi
done
ns=$(ls "$T"/i.* 2>/dev/null | grep -c .); [ "$ns" = "$N" ] || { echo "interp segments: $ns (want $N)"; bad=1; }
[ -z "$bad" ] && { echo "ngate_fuzz: PASS ($N seeds, both engines rc=3)"; exit 0; } || true
echo "ngate_fuzz: FAIL"; exit 1
