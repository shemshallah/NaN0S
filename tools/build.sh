#!/bin/sh
# SCAFFOLD build: base image (nasm0 proofs), generated Baby data, then the unified image. See tools/mkall.sh for the image rule (max 2 images in build/).
set -e
cd "$(dirname "$0")/.."
sh tools/mkbase.sh
sh tools/mkall.sh
# default NaNFS volume (raw ATA volume; guest reads it over ATA PIO LBA28 with nanfs_read):
# third kind of disk, NOT one of the two bootable images in the image rule
sh tools/nmkfs.sh src/tests/nfix_test.nas build/disk.nanfs
[ -d aarch64/android/app/src/main/assets ] && cp build/disk.nanfs aarch64/android/app/src/main/assets/disk.nanfs
[ -d x86/build ] && cp build/disk.nanfs x86/build/disk.nanfs
# published live demo (docs/ is the GitHub Pages site): keep nan0s.img beside index.html
[ -d docs ] && cp build/nan0s.img docs/nan0s.img
# the APK ships the same image (assets/ held a stale copy until r29m)
[ -d aarch64/android/app/src/main/assets ] && cp build/nan0s.img aarch64/android/app/src/main/assets/nan0s.img
