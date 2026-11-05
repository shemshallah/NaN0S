#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
make -s -C aarch64/android nan_cli
if [ "$#" -gt 0 ] && [ "${1#-}" = "$1" ]; then
  corpus=$1
  shift
  exec aarch64/android/nan_cli --nannet-train "$corpus" --serial "$@"
fi
exec aarch64/android/nan_cli --nannet-train --serial "$@"
