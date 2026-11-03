#!/bin/sh
# Suite-load gate: boot the real image, type the literal command "nannetsuite"
# in the GUI terminal, and require the staged slot 9 to be seal-loaded by the
# shell (the suite cart's banner on COM1), then exit with 7.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
[ -f build/nan0s.img ] || { echo "suite gate: build/nan0s.img missing"; exit 1; }
CLI=aarch64/android/nan_cli
OUT=$("$CLI" --img build/nan0s.img --steps 30000000 \
    --keys "@3000000,n,a,n,n,e,t,s,u,i,t,e,ENTER,@500000,7" --serial 2>/dev/null || true)
printf '%s\n' "$OUT" | grep -q "READY MENU=S" || { echo "suite gate: FAIL (boot)"; exit 1; }
printf '%s\n' "$OUT" | grep -q "SUITE" || { echo "suite gate: FAIL (suite not loaded)"; exit 1; }
echo "suite gate: PASS (nannetsuite -> staged slot 9 -> seal-loaded cart)"
