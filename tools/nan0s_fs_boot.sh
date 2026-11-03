#!/bin/sh
# Termux:Boot hook for the default nan0s_fs image.
# Header check plus verification of every populated sector. Does not create an
# image; run `tools/nan0s_fs.sh check` once if the image is missing.
set -e
cd "$(dirname "$0")/.."
exec sh tools/nan0s_fs.sh boot --verify
