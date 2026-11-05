#!/bin/sh
# NANNET service gate: the slot-less service cart is packed at word 4816 and
# launched from the SYSTEM menu; link and WiFi controls mutate control-plane
# state; ESC returns to the museum without a slot/catalog entry.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
CLI=aarch64/android/nan_cli
[ -x "$CLI" ] || { echo "nannet service gate: nan_cli missing"; exit 1; }
[ -f build/nan0s.img ] || { echo "nannet service gate: build/nan0s.img missing"; exit 1; }
T="${TMPDIR:-/tmp}/nnsvc.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
# service record at word 4816 is live (record [0] = 1)
"$CLI" --img build/nan0s.img --steps 6000000 --keys '@3000000' --peek '4816:1' >"$T/rec" 2>/dev/null
rec=$(tail -1 "$T/rec")
[ "$rec" = "00000001" ] || { echo "nannet service gate: FAIL (service record $rec)"; exit 1; }
# GUI ESC -> museum -> s SYSTEM -> 2 NANNET; toggle wlan0 up, scan, join
"$CLI" --img build/nan0s.img --steps 60000000 \
  --keys '@3000000,ESC,@1000000,s,@1000000,2,@1000000,3,@300000,S,@300000,J,@1500000' \
  --dump-text >"$T/svc" 2>/dev/null
grep -q 'NANNET SERVICE' "$T/svc" || { echo "nannet service gate: FAIL (service screen)"; exit 1; }
grep -q '^0 LO     loop   up$' "$T/svc" || { echo "nannet service gate: FAIL (lo link)"; exit 1; }
grep -q '^2 WLAN0   wifi  ok$' "$T/svc" || { echo "nannet service gate: FAIL (wlan join)"; exit 1; }
grep -q '^UP    2' "$T/svc" || { echo "nannet service gate: FAIL (link counter)"; exit 1; }
grep -q '^0 HomeNet   RSSI  60$' "$T/svc" || { echo "nannet service gate: FAIL (scan fixture)"; exit 1; }
# ESC leaves the service cart and lands back on the museum menu
"$CLI" --img build/nan0s.img --steps 60000000 \
  --keys '@3000000,ESC,@1000000,s,@1000000,2,@1000000,ESC,@1500000' \
  --dump-text >"$T/exit" 2>/dev/null
grep -q 'MUSEUM OF COMPUTING' "$T/exit" || { echo "nannet service gate: FAIL (exit menu)"; exit 1; }
echo "nannet service gate: PASS (slot-less record, SYSTEM launch, link+WiFi state, exit)"
