#!/bin/sh
# tools/mutate.sh - mutation sweep for src/prog/nalloc.nas (awk port of the retired python tool). No Python.
# Verifies the clean selftest (src/prog/nalloc_test.nas) still PASSes on the C core, then applies 9 single-edit
# mutants (first-occurrence LITERAL replacement via awk index/substr - no regex) to a copy of the test+allocator
# in $TMPDIR/mut_<name>/ and requires every mutant to lose the PASS verdict (FAIL/STOP/trap/no marker => CAUGHT).
# Mutant dirs: $TMPDIR/mut_<name>/{nalloc_test.nas,nalloc.nas,out.txt,err.txt}; kept for post-mortem.
# Run: export TMPDIR=<writable scratch>; sh tools/mutate.sh    (cds to repo root)
export LC_ALL=C
cd "$(dirname "$0")/.."
STEPS=20000000            # C core is fast; do not reduce
T="${TMPDIR:-/tmp}"
missed=0
cleanok=1

# literal first-occurrence replace, stdin -> stdout; ORIG/REPL/TAG via env (awk -v would eat backslash escapes)
mreplace() {
  awk '{ buf = buf $0 "\n" }
    END {
      o = ENVIRON["ORIG"]; r = ENVIRON["REPL"]
      i = index(buf, o)
      if (i == 0) { printf "mutate.sh: mutation string not found (src drift?): %s\n", ENVIRON["TAG"] > "/dev/stderr"; exit 3 }
      printf "%s", substr(buf, 1, i-1) r substr(buf, i + length(o))
    }' "$@"
}

one() {                   # one NAME <orig-literal> <repl-literal>
  name=$1; o=$2; r=$3
  d="$T/mut_${name}"
  rm -rf "$d"; mkdir -p "$d"
  cp src/prog/nalloc_test.nas src/prog/nalloc.nas "$d/"
  if ! ORIG="$o" REPL="$r" TAG="$name" mreplace < "$d/nalloc.nas" > "$d/nalloc.nas.new"; then
    printf '%-28s %s  %s\n' "$name" "DRIFT" "(literal not found in nalloc.nas; mutant not run)"
    missed=$((missed+1))
    return
  fi
  mv "$d/nalloc.nas.new" "$d/nalloc.nas"
  if sh tools/nrun.sh "$d/nalloc_test.nas" "$STEPS" > "$d/out.txt" 2> "$d/err.txt"; then rc=0; else rc=$?; fi
  last=$(awk '{ sub(/\r$/, ""); if ($0 != "") last=$0 } END { if (last=="") last="<no serial output>"; print substr(last,1,60) }' "$d/out.txt")
  case "$last" in *PASS*) st=MISSED;; *) st=CAUGHT;; esac
  if [ "$rc" -ne 0 ] && [ "$st" = MISSED ]; then st=CAUGHT; fi    # nonzero exit (trap/assembly kill) => no clean PASS
  if [ "$st" = MISSED ]; then missed=$((missed+1)); fi
  printf '%-28s %s  %s\n' "$name" "$st" "$last"
}

# ---- clean run first; abort unless the final serial line PASSes
if sh tools/nrun.sh src/prog/nalloc_test.nas "$STEPS" > "$T/mutate_clean.out.txt" 2> "$T/mutate_clean.err.txt"; then rc=0; else rc=$?; fi
cleanline=$(awk '{ sub(/\r$/, ""); if ($0 != "") last=$0 } END { if (last=="") last="<no serial output>"; print last }' "$T/mutate_clean.out.txt")
printf 'clean: %s\n' "$cleanline"
case "$cleanline" in
  *PASS*) [ "$rc" -eq 0 ] && cleanok=0 ;;
esac
if [ "$cleanok" -ne 0 ]; then
  printf 'mutate.sh: clean run has no PASS verdict (rc=%d); aborting sweep\n' "$rc" > /dev/stderr
  exit 1
fi

# ---- mutation table: original -> replacement (literal, first occurrence). Keep in sync with nalloc.nas.
one no-next-coalesce 'ADD r5,r5,r7
nf_prev:' 'nf_prev:'
one no-prev-coalesce 'SUB r2,r2,r7
ADD r5,r5,r7
nf_wr:' 'nf_wr:'
one split-threshold 'MOVI r9,3
CMP r8,r9
JMP[LT] @na_all' 'MOVI r9,4
CMP r8,r9
JMP[LT] @na_all'
one rover-not-reset-in-free 'ST r2,r0,#NV_ROVER
nf_done:' 'nf_done:'
one rover-not-advanced-on-split 'ST r6,r0,#NV_ROVER
ADD r1,r2,r13
RET
na_all:' 'ADD r1,r2,r13
RET
na_all:'
one no-wrap-in-next 'na_next:
ADD r2,r2,r7
CMP r2,r3
JMP[LT] @na_nw
BOOL.12 r2,r4,r4
na_nw:' 'na_next:
ADD r2,r2,r7
na_nw:'
one foot-off-by-one 'ADD r6,r2,r1
SUB r7,r6,r13
ST r9,r7,0' 'ADD r6,r2,r1
ST r9,r6,0'
one double-free-undetected 'CMP r6,r0
JMP[EQ] @nf_bad
SHR r5,r5,1' 'SHR r5,r5,1'
one min-size-2 'MOVI r2,3
CMP r1,r2
MOVI[LT] r1,3' 'MOVI r2,2
CMP r1,r2
MOVI[LT] r1,2'

printf 'missed %d\n' "$missed"
[ "$missed" -eq 0 ] || exit 1
