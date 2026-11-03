#!/bin/sh
# NSPV volume gate: suites 1/2, write/read, header/tag/data tamper, wrong key.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nspvvol.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "volume gate: node missing"; exit 77; }
KEY=000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F
NON=A0A1A2A3A4A5A6A7A8A9AAABACADAEAF
BAD=0000000000000000000000000000000000000000000000000000000000000000
node crypt/volume.cjs format 1 "$T/v1" "$KEY" "$NON" 16 >/dev/null
node crypt/volume.cjs verify "$T/v1" "$KEY" | grep -qx 'VERIFY OK' || { echo "volume gate: FAIL (v1 verify)"; exit 1; }
node crypt/volume.cjs info "$T/v1" | grep -q 'SUITE 1 DATA 3 SECTORS 16' || { echo "volume gate: FAIL (info)"; exit 1; }
printf 'HELLO NSPV' > "$T/p"
node crypt/volume.cjs write "$T/v1" "$KEY" 0 "$T/p" >/dev/null
node crypt/volume.cjs read "$T/v1" "$KEY" 0 "$T/r" >/dev/null
N=$(wc -c < "$T/p"); head -c "$N" "$T/r" > "$T/rh"
cmp -s "$T/p" "$T/rh" || { echo "volume gate: FAIL (write/read)"; exit 1; }
node crypt/volume.cjs format 2 "$T/v2" "$KEY" "$NON" 16 >/dev/null
node crypt/volume.cjs verify "$T/v2" "$KEY" | grep -qx 'VERIFY OK' || { echo "volume gate: FAIL (v2 verify)"; exit 1; }
node -e 'const fs=require("fs");let b=fs.readFileSync(process.argv[1]);b[0]^=255;fs.writeFileSync(process.argv[2],b)' "$T/v1" "$T/badh"
if node crypt/volume.cjs verify "$T/badh" "$KEY" >/dev/null 2>&1; then echo "volume gate: FAIL (header tamper)"; exit 1; fi
node -e 'const fs=require("fs");let b=fs.readFileSync(process.argv[1]);b[512]^=255;fs.writeFileSync(process.argv[2],b)' "$T/v1" "$T/badt"
if node crypt/volume.cjs verify "$T/badt" "$KEY" >/dev/null 2>&1; then echo "volume gate: FAIL (tag tamper)"; exit 1; fi
node -e 'const fs=require("fs");let b=fs.readFileSync(process.argv[1]);b[1536]^=255;fs.writeFileSync(process.argv[2],b)' "$T/v1" "$T/badd"
if node crypt/volume.cjs verify "$T/badd" "$KEY" >/dev/null 2>&1; then echo "volume gate: FAIL (data tamper)"; exit 1; fi
if node crypt/volume.cjs verify "$T/v1" "$BAD" >/dev/null 2>&1; then echo "volume gate: FAIL (wrong key)"; exit 1; fi
if node crypt/volume.cjs format 4 "$T/v4" "$KEY" "$NON" 16 >/dev/null 2>&1; then echo "volume gate: FAIL (planned suite)"; exit 1; fi
echo "volume gate: PASS (suites 1/2; write/read; header/tag/data tamper; wrong key)"
