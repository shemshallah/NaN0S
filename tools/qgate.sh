#!/bin/sh
# tools/qgate.sh - boot gate for the system image (replaces the retired v86/JS harness).
# Boots build/nan0s.img on qemu-system-i386 (bare metal, no guest OS), captures COM1,
# and requires the guest's own boot banner. Outer stack: sh + qemu only; no key injection.
# usage: sh tools/qgate.sh [seconds]   DISK=path.sh  (optional: attach a raw volume, e.g.
# build/disk.nanfs from tools/nmkfs.sh, as a virtual IDE disk - qemu virtual storage; on a
# real machine the same raw volume is dd'ed onto the primary master, the layout is unchanged)
set -e
cd "$(dirname "$0")/.."
export LC_ALL=C
export TMPDIR="${TMPDIR:-/tmp}"
SECS="${1:-25}"
DISK="${DISK:-}"
DARG=""
[ -n "$DISK" ] && DARG="-drive format=raw,if=ide,file=$DISK"
T="$TMPDIR/nan0s_qgate"
rm -rf "$T"; mkdir -p "$T"
[ -f build/nan0s.img ] || { echo "qgate: build/nan0s.img missing (run sh tools/mkall.sh)"; exit 1; }
timeout "$SECS" qemu-system-i386 -m 32 \
  -drive format=raw,if=floppy,file=build/nan0s.img \
  $DARG \
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
