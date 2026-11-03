#!/bin/sh
# Suite gate: boot the real image, type "nannetsuite" in the GUI terminal,
# require the staged slot 9 to be seal-loaded (banner), the windowed menu to
# draw, and a menu action (TOOLS) to reach the terminal; exit with 7.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
[ -f build/nan0s.img ] || { echo "suite gate: build/nan0s.img missing"; exit 1; }
CLI=aarch64/android/nan_cli
CMD="@3000000,n,a,n,n,e,t,s,u,i,t,e,ENTER"
OUT=$("$CLI" --img build/nan0s.img --steps 30000000 --keys "$CMD,@500000,7" --serial 2>/dev/null || true)
printf '%s\n' "$OUT" | grep -q "READY MENU=S" || { echo "suite gate: FAIL (boot)"; exit 1; }
printf '%s\n' "$OUT" | grep -q "SUITE" || { echo "suite gate: FAIL (suite not loaded)"; exit 1; }
WIN=$("$CLI" --img build/nan0s.img --steps 4500000 --keys "$CMD" --dump-text --serial 2>/dev/null || true)
printf '%s\n' "$WIN" | grep -q "NANNETSUITE v2" || { echo "suite gate: FAIL (window)"; exit 1; }
OUT2=$("$CLI" --img build/nan0s.img --steps 30000000 --keys "$CMD,@500000,2,@300000,6" --serial 2>/dev/null || true)
printf '%s\n' "$OUT2" | grep -q "VLAN-ENC" || { echo "suite gate: FAIL (menu action)"; exit 1; }
echo "suite gate: PASS (nannetsuite -> seal-load -> window -> menu -> exit)"
