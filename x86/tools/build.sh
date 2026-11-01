#!/bin/sh
# SCAFFOLD build: base image (nasm0 proofs), generated Baby data, then the unified image. See x86/tools/mkall.sh for the image rule (max 2 images in build/).
set -e
cd "$(dirname "$0")/../.."
sh tools/mkbase.sh
sh x86/tools/mkall.sh
# default NaNFS volume next to the x86 build (virtual storage today; dd onto a real
# primary-master disk later - the volume is already a raw ATA PIO LBA28 layout)
sh tools/nmkfs.sh src/tests/nfix_test.nas x86/build/disk.nanfs
[ -d build ] && cp x86/build/disk.nanfs build/disk.nanfs
[ -d aarch64/android/app/src/main/assets ] && cp x86/build/disk.nanfs aarch64/android/app/src/main/assets/disk.nanfs
