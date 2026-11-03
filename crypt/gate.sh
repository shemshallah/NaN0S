#!/bin/sh
# Public crypt suite gate: capsule KATs + NSPF1 file container properties.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/cryptgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "crypt gate: node missing"; exit 77; }
node --check crypt/reference/nsp.cjs
node crypt/reference/nsp.cjs selftest > "$T/kat"
cmp -s "$T/kat" crypt/vectors/capsule.txt || { echo "crypt gate: FAIL (KATs)"; diff crypt/vectors/capsule.txt "$T/kat" | head; exit 1; }
KEY=000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F
NON=A0A1A2A3A4A5A6A7A8A9AAABACADAEAF
BAD=0000000000000000000000000000000000000000000000000000000000000000
node -e 'const fs=require("fs");const b=Buffer.alloc(4096);for(let i=0;i<b.length;i++)b[i]=(i*37+11)&255;fs.writeFileSync(process.argv[1],b)' "$T/plain"
for s in 1 2; do
  node crypt/reference/nsp.cjs file-seal "$s" "$T/plain" "$T/enc$s" "$KEY" "$NON" >/dev/null
  node crypt/reference/nsp.cjs file-open "$T/enc$s" "$T/dec$s" "$KEY" >/dev/null
  cmp -s "$T/plain" "$T/dec$s" || { echo "crypt gate: FAIL (suite $s)"; exit 1; }
done
sh crypt/nspfile seal 1 "$T/plain" "$T/ecli" "$KEY" "$NON" >/dev/null
sh crypt/nspfile open "$T/ecli" "$T/dcli" "$KEY" >/dev/null
cmp -s "$T/plain" "$T/dcli" || { echo "crypt gate: FAIL (CLI)"; exit 1; }
node -e 'require("fs").writeFileSync(process.argv[1], Buffer.alloc(0))' "$T/empty"
node crypt/reference/nsp.cjs file-seal 1 "$T/empty" "$T/e0" "$KEY" "$NON" >/dev/null
node crypt/reference/nsp.cjs file-open "$T/e0" "$T/d0" "$KEY" >/dev/null
cmp -s "$T/empty" "$T/d0" || { echo "crypt gate: FAIL (empty)"; exit 1; }
node -e 'require("fs").writeFileSync(process.argv[1],Buffer.from("hello nspf\n"))' "$T/odd"
node crypt/reference/nsp.cjs file-seal 1 "$T/odd" "$T/eodd" "$KEY" "$NON" >/dev/null
node crypt/reference/nsp.cjs file-open "$T/eodd" "$T/dodd" "$KEY" >/dev/null
cmp -s "$T/odd" "$T/dodd" || { echo "crypt gate: FAIL (odd)"; exit 1; }
node -e 'const fs=require("fs");const b=fs.readFileSync(process.argv[1]);b[0]^=255;fs.writeFileSync(process.argv[2],b)' "$T/enc1" "$T/badh"
if node crypt/reference/nsp.cjs file-open "$T/badh" "$T/x" "$KEY" >/dev/null 2>&1; then echo "crypt gate: FAIL (header tamper)"; exit 1; fi
node -e 'const fs=require("fs");const b=fs.readFileSync(process.argv[1]);b[80]^=255;fs.writeFileSync(process.argv[2],b)' "$T/enc1" "$T/badc"
if node crypt/reference/nsp.cjs file-open "$T/badc" "$T/x" "$KEY" >/dev/null 2>&1; then echo "crypt gate: FAIL (ciphertext tamper)"; exit 1; fi
node -e 'const fs=require("fs");const b=fs.readFileSync(process.argv[1]);fs.writeFileSync(process.argv[2],b.subarray(0,b.length-1))' "$T/enc1" "$T/badt"
if node crypt/reference/nsp.cjs file-open "$T/badt" "$T/x" "$KEY" >/dev/null 2>&1; then echo "crypt gate: FAIL (truncation)"; exit 1; fi
if node crypt/reference/nsp.cjs file-open "$T/enc1" "$T/x" "$BAD" >/dev/null 2>&1; then echo "crypt gate: FAIL (wrong key)"; exit 1; fi
if node crypt/reference/nsp.cjs file-seal 4 "$T/plain" "$T/e4" "$KEY" "$NON" >/dev/null 2>&1; then echo "crypt gate: FAIL (planned suite)"; exit 1; fi
echo "crypt gate: PASS (capsule KATs; suites 1/2; empty/odd; tamper/truncate/wrong-key/planned refused)"
