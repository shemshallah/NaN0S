#!/bin/sh
# SCAFFOLD: hex .nan (bytes, ; comments) -> binary.  usage: hex2bin.sh in.nan out.bin
# Each whitespace-separated token is one byte pair (former perl pack "H2" semantics: the
# token's first two hex digits become one byte; a stray \r before it is ignored). gawk port;
# no Perl, no Python. Outer stack: POSIX sh + sed + tr + grep + gawk only.
# NOTE: LC_ALL=C is REQUIRED - printf "%c" of values > 127 goes multibyte UTF-8 otherwise.
set -e
export LC_ALL=C
sed 's/;.*//' "$1" | tr -s ' \n\t' '\n' | grep . | gawk '
{
  sub(/\r$/, "")
  T = substr($0, 1, 2)
  if (T == "") next   # former perl pack("H2","") produced zero bytes for blank \r-only lines
  V = 0
  for (i = 1; i <= length(T); i++){
    C = toupper(substr(T, i, 1))
    V = V * 16 + index("0123456789ABCDEF", C) - 1
  }
  printf "%c", V
}' > "$2"
