#!/bin/sh
# SCAFFOLD (not NaNLang): hex .nan -> bytes, pads boot sector to 512 with 55 AA.
# usage: build.sh in.nan out.bin
sed 's/;.*//' "$1" | tr -s ' \n\t' '\n' | grep . | perl -ne 'chomp; print pack("H2",$_)' > "$2.tmp"
perl -e 'local $/; $d=<STDIN>; die "too big" if length($d)>510; print $d, "\0" x (510-length($d)), "\x55\xaa"' < "$2.tmp" > "$2"; rm "$2.tmp"
