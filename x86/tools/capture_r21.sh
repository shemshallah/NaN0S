#!/bin/sh
# Screenshots of the museum, taken by the one JS outer box (x86/harness/shot.mjs). Text screens -> .txt, graphics -> .png.
set -e
cd "$(dirname "$0")/../.."
ROOT=$(pwd); IMG=$ROOT/x86/build/nan0s.img; mkdir -p screencaps
cap() { (cd "$ROOT/x86/harness" && node shot.mjs "$IMG" "$1" "$ROOT/screencaps/$2" "$3" >/dev/null); }
cap 8  menu ""
cap 10 boole_plaque "7:03"
cap 11 boole_live "7:03;9:02"
cap 12 boole_scrolled "7:03;9:E0 50 E0 D0;10:E0 50 E0 D0"
cap 10 about_nan0s "7:05"
cap 10 about_dev "7:06"
cap 10 trust_preface "7:07"
cap 12 trust_paper "7:07;9:E0 4D E0 CD"
cap 10 curator "8:2A 29 A9 AA"
cap 34 sierpinski_pixels "7:04"
cap 34 sierpinski_details "7:04;15:E0 50 E0 D0;16:E0 50 E0 D0"
cap 14 gui_desktop "7:0A"
