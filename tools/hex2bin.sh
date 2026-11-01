#!/bin/sh
# SCAFFOLD: hex .nan (bytes, ; comments) -> binary.  usage: hex2bin.sh in.nan out.bin
sed 's/;.*//' "$1" | tr -s ' \n\t' '\n' | grep . | perl -ne 'chomp; print pack("H2",$_)' > "$2"
