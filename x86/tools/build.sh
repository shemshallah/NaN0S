#!/bin/sh
# SCAFFOLD build: base image (nasm0 proofs), generated Baby data, then the unified image. See x86/tools/mkall.sh for the image rule (max 2 images in build/).
set -e
cd "$(dirname "$0")/../.."
python3 tools/mkbase.py
sh x86/tools/mkall.sh
