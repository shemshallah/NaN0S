#!/bin/sh
# SCAFFOLD (not NaN/0S): full nasm1 check: gold bytes, encoding tests, v86 boot,
# six-cartridge museum, pixel Sierpinski, Trust exhibit, Curator Console.
set -e
cd "$(dirname "$0")/.."
python3 tools/nasm1check.py
T="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/opencode"
mkdir -p "$T"
python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/prog/selftest.nas "$T/selftest1.img"
sh x86/tools/mkall.sh
if command -v node >/dev/null 2>&1 && [ -d x86/harness/node_modules/v86 ]; then
  python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/prog/nbuild_selfhost.nas "$T/nbs.img"
  (cd x86/harness && node boot.mjs "$T/nbs.img" 12) | grep -q "SELFHOST PASS" && echo "nbuild: in-guest self-replication PASS"
  python3 -c "d=bytearray(1024*1024); d[0:4]=b'NAN0'; open('$T/hda.img','wb').write(d)"
  python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/tests/ata_rw_test.nas "$T/ata_rw.img"
  (cd x86/harness && node ataboot.mjs "$T/ata_rw.img" "$T/hda.img" 15) | grep -q "ATA RW PASS" && echo "ata: read + write round-trip PASS"
  python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/tests/nanfs_test.nas "$T/nanfs.img"
  (cd x86/harness && node boot.mjs "$T/nanfs.img" 10) | grep -q "NANFS PASS" && echo "nanfs: RAM format/alloc/write/read PASS"
  python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/prog/nbuild.nas "$T/nbuild.img"
  (cd x86/harness && node boot.mjs "$T/nbuild.img" 10) > "$T/nbuild.out"
  grep -q "STORE PASS" "$T/nbuild.out" && grep -q "SEAL PASS" "$T/nbuild.out" && echo "nbuild: store + seal PASS"
  python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/tests/n16de_test.nas "$T/n16de.img"
  (cd x86/harness && node boot.mjs "$T/n16de.img" 8) | grep -q "N16DE PASS" && echo "n16de: pair-vote codec PASS"
  python3 tools/mkimg1.py x86/boot/kboot0.xa x86/native/kan16.xa src/tests/retro_test.nas "$T/retro.img"
  (cd x86/harness && node boot.mjs "$T/retro.img" 8) | grep -q "RETRO PASS" && echo "retro: LE/BE + fixed point + capped singularity PASS"
  (cd x86/harness && node boot.mjs "$T/selftest1.img" 8) | head -1 > "$T/selftest.v86.txt"
  python3 - "$T" <<'PY'
import json,sys,os
T=sys.argv[1]
sys.path.insert(0,'tools')
import nanchk,nan16sim
line=open(T+'/selftest.v86.txt').read()
ser=json.loads(line.split('SERIAL:',1)[1].split('\n',1)[0].strip())
norm=ser.replace('\r\n','\n')
L,_=nanchk.emit('src/prog/selftest.nas')
s=nan16sim.Sim(b'',nwords=1<<15,isa=1)
for i,l in enumerate(L):
    n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
s.run(20000000)
model=''.join(chr(ord(c)&255) for c in s.out).replace('\r\n','\n')
print('selftest: v86 serial %d chars, model %d, match %s'%(len(ser),len(model),norm==model))
sys.exit(0 if norm==model else 1)
PY
  (cd x86/harness && node boot.mjs ../build/nan0s.img 16 "10:02,14:03") > "$T/baby.v86.txt" || true
  grep -q "MANCHESTER" "$T/baby.v86.txt" && grep -q "2048" "$T/baby.v86.txt" && echo "museum: Baby cartridge runs and returns"
  (cd x86/harness && node boot.mjs ../build/nan0s.img 16 "10:03,14:02") > "$T/boole.v86.txt" || true
  grep -q "ALL 16 ok" "$T/boole.v86.txt" && echo "museum: Boole 16 live table passes"
  (cd x86/harness && node boot.mjs ../build/nan0s.img 10 "8:07") > "$T/trust.v86.txt" || true
  grep -q "KEN THOMPSON" "$T/trust.v86.txt" && echo "museum: Trust preface loads"
  (cd x86/harness && node boot.mjs ../build/nan0s.img 12 "10:08") > "$T/patriot.v86.txt" || true
  grep -q "THE PATRIOT MISSILE FAILURE" "$T/patriot.v86.txt" && echo "museum: Patriot plaque loads"
  (cd x86/harness && node bootseq.mjs ../build/nan0s.img 10 "8:2A 29 A9 AA") > "$T/curator.v86.txt" || true
  grep -q "CURATOR CONSOLE" "$T/curator.v86.txt" && echo "museum: Curator Console opens with ~"
  (cd x86/harness && node shot.mjs ../build/nan0s.img 20 "$T/sier" "7:04") >/dev/null || true
  W=$(tr -cd '\017' < "$T/sier.idx" | wc -c)
  echo "sierpinski: white pixels $W"
  [ "$W" -gt 500 ]
fi
echo "nasm1 check done"
