#!/bin/sh
# tools/mkall.sh - builds THE unified image build/nan0s.img (boot + hw kernel + shell + every
# cartridge listed in tools/carts.txt). Outer stack: POSIX sh + gawk + xxd only. Overwrites; keeps no history.
# IMAGE RULE: build/ holds at most TWO images: nan0s.img (the system) and base.img (scaffold
# input for nasm0 proofs). All test/mutant images go to $TMPDIR and are deleted.
set -e
cd "$(dirname "$0")/.."
export LC_ALL=C
export TMPDIR="${TMPDIR:-/tmp}"
T="$TMPDIR/nan0s_build"
rm -rf "$T"; mkdir -p "$T"
gawk -f tools/mkimg.awk \
     -v GOLD=src/native/nan16_x86.nan \
     -v GUEST=src/nan/museum.nan \
     -v CARTS=tools/carts.txt \
     -v OUTB="$T/n0sb.bin" -v OUTG="$T/n0sg.bin"
cat "$T/n0sb.bin" "$T/n0sg.bin" > build/nan0s.img
truncate -s 1474560 build/nan0s.img 2>/dev/null || dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < build/nan0s.img))) >> build/nan0s.img
ls build/*.img | wc -l | sed 's/^/images in build\/: /'
