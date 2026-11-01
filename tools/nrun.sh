#!/bin/sh
# tools/nrun.sh PROG.nas|PROG.nan [steps] [extra nan_cli args]  - assemble (POSIX awk nmk) and run on the C core. No Python.
# Replaces runbig.py / nan16sim.py as the outer box (nan_cli is step-identical to nan16sim.py on 10 programs, r29f).
set -e
cd "$(dirname "$0")/.."; export LC_ALL=C
P="$1"; S="${2:-200000000}"; [ $# -ge 2 ] && shift 2 || shift
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
case "$P" in *.nas) T="${TMPDIR:-/tmp}/nrun.$$.nan"; awk -f tools/nmk.awk -v CMD=emit "$P" > "$T" 2>/dev/null; trap 'rm -f "$T"' EXIT;; *) T="$P";; esac
$CLI --img "$T" --steps "$S" --serial "$@"
