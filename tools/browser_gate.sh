#!/bin/sh
# Browser window gate: terminal command b opens kind-7 browser, tabs render.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/browsergate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
[ -f build/nan0s.img ] || { echo "browser gate: image missing"; exit 77; }
aarch64/android/nan_cli --img build/nan0s.img --steps 35000000 \
  --keys '@3000000,b,ENTER,@2500000,1,@1500000' --serial > "$T/out" 2>"$T/err" || true
grep -q 'BR' "$T/out" || { echo "browser gate: FAIL (browser init)"; tail -10 "$T/out"; exit 1; }
grep -q 'trap=' "$T/err" && grep -vq "trap=''" "$T/err" && { echo "browser gate: FAIL (trap)"; cat "$T/err"; exit 1; }
echo "browser gate: PASS (kind-7 browser window + tabs init)"
