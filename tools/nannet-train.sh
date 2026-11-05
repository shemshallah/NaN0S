#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -lt 1 ]; then
  echo "usage: tools/nannet-train.sh corpus.txt [nan_cli options]" >&2
  exit 2
fi
CORPUS=$1
shift
make -s -C aarch64/android nan_cli
exec aarch64/android/nan_cli --nannet-train "$CORPUS" --serial "$@"
