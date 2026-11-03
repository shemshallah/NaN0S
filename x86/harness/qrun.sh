#!/bin/sh
# OUTER BOX (not NaN/0S): QEMU boot + screendump. Verified r26e: baseline image boots museum under qemu-system-x86_64 TCG.
# usage: qrun.sh IMG SECS OUT.ppm [MEM] [extra qemu args]
IMG=$1; S=$2; OUT=$3; M=${4:-512}; shift 4 2>/dev/null
( sleep $S; echo "screendump $OUT"; sleep 1; echo quit ) | timeout $((S+20)) qemu-system-x86_64 -machine accel=tcg -cpu qemu64 -m $M -fda $IMG -display none -monitor stdio -no-reboot "$@" >/tmp/q.log 2>&1
ls -la $OUT
