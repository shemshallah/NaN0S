#!/bin/sh
# SCAFFOLD: build x86/native/nan16.s and run every native-vs-model check. usage: sh x86/tools/native_check.sh
set -e
cd "$(dirname "$0")/../.."
as --32 -o /tmp/n.o x86/native/nan16.s && ld -m elf_i386 -o /tmp/nan16 /tmp/n.o
size /tmp/n.o | tail -1
for p in selftest sierpinski spanbench; do python3 tools/difftest.py /tmp/nan16 src/prog/$p.nas 400000; done
python3 tools/difftest.py /tmp/nan16 src/prog/nalloc_test.nas 3000000
python3 tools/difftest.py /tmp/nan16 src/museum/museum.nas 300000 0x6d,0x31,0x32,0x71,0x6d,0x33
python3 tools/fuzz.py /tmp/nan16 1000
python3 tools/traptest.py /tmp/nan16
for t in selftest sierpinski nalloc_test spanbench; do python3 tools/proofnat.py /tmp/nan16 src/prog/$t.nas logs/nasm0_proof_${t}_flat1M.txt; done
python3 tools/proofnat.py /tmp/nan16 src/museum/museum.nas logs/nasm0_proof_museum_flat1M.txt
