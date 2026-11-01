#!/bin/sh
# tools/nmkfs.sh SRC.nas OUT.img  - one-time host seed: flatten SRC and write it into a NaNFS disk image for nan_cli --disk.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
awk -f tools/nflat.awk -v F="$1" | awk -f tools/nmkfs.awk > "$2.esc"; printf '%b' "$(cat "$2.esc")" > "$2"; rm -f "$2.esc"
