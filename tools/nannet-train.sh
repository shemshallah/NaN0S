#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -lt 1 ]; then
  echo "usage: tools/nannet-train.sh corpus.txt [nan_cli options]" >&2
  exit 2
fi
CORPUS=$1
shift
TMP="${TMPDIR:-/tmp}/n16-train-$$.nan"
trap 'rm -f "$TMP"' EXIT HUP INT TERM
awk -f tools/nmk.awk -v CMD=emit src/training/n16_train.nas > "$TMP"
make -s -C aarch64/android nan_cli
aarch64/android/nan_cli --img "$TMP" --nannet-train "$CORPUS" --serial "$@"
