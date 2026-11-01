#!/bin/sh
# tools/ngate_boot.sh - cold-boot gate on the REAL system image (build/nan0s.img):
#   1. the guest serial banner appears on COM1,
#   2. the machine has booted INTO THE GUI (museum shell autostarts the hidden GUI slot),
#   3. the desktop has exactly ONE window (wm_zn == 1),
#   4. that window is a live terminal (W_ALIVE == 1, W_KIND == 0 = terminal, A2).
# Addresses are the fixed wm.nas table: WT=0x58000, W_ALIVE=0, W_KIND=6; wm_zn is a
# gui_cart label (11705 for this build) - resolved from nmk LABELS at run time.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/bootgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
[ -f build/nan0s.img ] || { echo "ngate_boot: build/nan0s.img missing (run sh tools/build.sh)"; exit 1; }
awk -f tools/nmk.awk -v CMD=emit -v LABELS="$T/g.lab" src/exhibits/gui_cart.nas >/dev/null 2>&1
ZN=$(awk '$1=="wm_zn"{print $2}' "$T/g.lab"); [ -n "$ZN" ] || { echo "ngate_boot: wm_zn label not found"; exit 1; }
OUT="$T/out"
"$CLI" --img build/nan0s.img --steps 20000000 --serial --peek "$ZN:1,360448:7" >"$OUT" 2>"$T/err" || true
rc=$(sed -n 's/.*steps, rc=\([0-9]*\).*/\1/p' "$T/err" | tail -1)
bad=0
grep -q 'READY MENU=S' "$OUT" || { echo "boot: serial banner MISSING"; bad=1; }
# peek lines are the last 8 hex lines (1 wm_zn + 7 window words); everything before is serial
W=$(tail -8 "$OUT")
zn=$(printf '%s\n' "$W" | sed -n '1p')
alive=$(printf '%s\n' "$W" | sed -n '2p')
kind=$(printf '%s\n' "$W" | sed -n '8p')
[ "$zn" = "00000001" ] || { echo "boot: wm_zn=$zn (want 1 window)"; bad=1; }
[ "$alive" = "00000001" ] || { echo "boot: W_ALIVE=$alive (want 1)"; bad=1; }
[ "$kind" = "00000000" ] || { echo "boot: W_KIND=$kind (want 0 = terminal)"; bad=1; }
[ "$rc" = "0" ] || { echo "boot: rc=$rc (want 0 = still running in the GUI event loop)"; bad=1; }
if [ $bad = 0 ]; then
  echo "ngate_boot: PASS (serial banner; booted to GUI; exactly one terminal window)"
  exit 0
fi
echo "ngate_boot: FAIL"; exit 1
