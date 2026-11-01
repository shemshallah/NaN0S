#!/bin/sh
# x86/tools/qgate.sh - boot gate for the system image (replaces the retired v86/JS harness).
# Boots x86/build/nan0s.img on qemu-system-i386 (bare metal, no guest OS), captures COM1,
# and requires the guest's own boot banner. Outer stack: sh + qemu only; no key injection.
# usage: sh x86/tools/qgate.sh [seconds]
set -e
cd "$(dirname "$0")/../.."
export LC_ALL=C
export TMPDIR="${TMPDIR:-/tmp}"
SECS="${1:-25}"
T="$TMPDIR/nan0s_qgate"
rm -rf "$T"; mkdir -p "$T"
[ -f x86/build/nan0s.img ] || { echo "qgate: x86/build/nan0s.img missing (run sh x86/tools/mkall.sh)"; exit 1; }
timeout "$SECS" qemu-system-i386 -m 32 \
  -drive format=raw,if=floppy,file=x86/build/nan0s.img \
  -display none -serial "file:$T/com1.txt" -no-reboot >/dev/null 2>&1 || true
rc=0
grep -q "NaN/0S" "$T/com1.txt" || { echo "qgate: NaN/0S banner MISSING on COM1"; rc=1; }
grep -q "READY MENU=S" "$T/com1.txt" || { echo "qgate: READY/MENU banner MISSING on COM1"; rc=1; }
if [ $rc -eq 0 ]; then
  echo "qgate: PASS (banner $(wc -c < "$T/com1.txt") bytes on COM1)"
  cp "$T/com1.txt" logs/qgate_com1.txt
else
  echo "qgate: FAIL"; cat "$T/com1.txt" | head -20
fi
rm -rf "$T"
exit $rc
