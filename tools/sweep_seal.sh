#!/bin/sh
# Mutation sweep for the cartridge seal. Every mutant must be REFUSED ("SEAL MISMATCH", no Baby plaque); the control must load.
# usage: TMPDIR=/tmp sh tools/sweep_seal.sh   (cart words 0..612; payload bit flips after sealing, and seal-word bit flips)
cd "$(dirname "$0")/.."; T="${TMPDIR:-/tmp}/opencode"; mkdir -p "$T"
B="x86/boot/kboot0.xa x86/native/kan16.xa src/museum/museum.nas"
run(){ # name envassign
  env $2 python3 tools/mkimg1.py $B "$T/sw_$1.img" --cart 3072:src/exhibits/baby_cart.nas >/dev/null
  (cd x86/harness && node boot.mjs "$T/sw_$1.img" 12 "8:02" > "$T/sw_$1.out" 2>&1)
  if grep -q "SEAL MISMATCH" "$T/sw_$1.out" && ! grep -q "MANCHESTER SMALL" "$T/sw_$1.out"; then echo "$1 REFUSED"; elif grep -q "MANCHESTER SMALL" "$T/sw_$1.out"; then echo "$1 LOADED"; else echo "$1 OTHER"; fi; }
echo "control LOADED expected:"; run ctl "X=1" &
for w in 0 1 2 100 305 611 612; do for b in 0 15 31; do run "w${w}b${b}" "NAN_FLIP=$w NAN_BIT=$b" & 
 [ $(jobs -p | wc -l) -ge 6 ] && wait; done; done
for b in 0 7 16 31; do run "seal$b" "NAN_SEALBIT=$b" & [ $(jobs -p | wc -l) -ge 6 ] && wait; done
wait
