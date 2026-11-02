#!/bin/sh
# tools/nlink.sh - host link manager: interface detection, frame relay, self-test.
# Frames travel as text lines of hex words. The tool checks shape and counts only;
# it never interprets payloads and holds no secrets.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C

usage(){ cat >&2 <<'EOF'
nlink.sh ls                    list interfaces (name, state, ipv4)
nlink.sh relay [file]          read frame lines, check shape, echo to stdout
nlink.sh fifo DIR              relay DIR/in -> DIR/out through fifos
nlink.sh tcp HOST PORT         relay stdin -> HOST:PORT -> stdout (needs nc)
nlink.sh selftest              run the stored frame-cart sample
EOF
exit 2
}

relay(){
  src=${1:--}
  [ "$src" = "-" ] || exec 0< "$src"
  n=0; bad=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    first=${line%% *}
    words=$(printf '%s\n' "$line" | wc -w)
    case "$first" in
      4E53*|534E*) [ "$words" -le 130 ] && n=$((n+1)) || bad=$((bad+1)) ;;
      *) bad=$((bad+1)) ;;
    esac
    printf '%s\n' "$line"
  done
  printf 'nlink: frames %d, rejected %d\n' "$n" "$bad" >&2
}

case "${1:-}" in
ls)
  out=$(ip -o link show 2>/dev/null) || out=""
  if [ -n "$out" ]; then
    printf '%s\n' "$out" | awk -F': ' '{split($2,a,"@"); printf "%s%s", (NR>1?" ":""), a[1]} END{print ""}'
    ip -o -4 addr show 2>/dev/null | awk '{print "  "$2" "$4}' || true
  else
    found=""
    for i in /sys/class/net/*; do [ -e "$i" ] || continue; printf "%s " "${i##*/}"; found=1; done
    [ -n "$found" ] && echo || echo "(no interfaces)"
  fi
  ;;
relay)
  relay "${2:--}"
  ;;
fifo)
  d=${2:-}; [ -n "$d" ] || usage
  mkdir -p "$d"; rm -f "$d/in" "$d/out"
  mkfifo "$d/in" "$d/out"
  echo "nlink: fifo ready: $d/in -> $d/out" >&2
  relay "$d/in" > "$d/out"
  ;;
tcp)
  host=${2:-}; port=${3:-}
  [ -n "$host" ] && [ -n "$port" ] || usage
  if command -v nc >/dev/null 2>&1; then
    relay - | nc "$host" "$port" | relay -
  else
    echo "nlink: SKIP (nc not available)"
  fi
  ;;
selftest)
  sh tools/lanegate3.sh
  ;;
*)
  usage
  ;;
esac
