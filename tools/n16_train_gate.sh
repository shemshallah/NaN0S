#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-train-gate-$$"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp"
printf 'N16TXT/1\nAB N16_GATE_UNIQUE_CORPUS_MARKER_7F31.\nRunner and Android share one trainer.\nThe intake stages updates before merge.\n' > "$tmp/corpus.txt"
make -s -C aarch64/android nan_cli
if ! aarch64/android/nan_cli --nannet-train "$tmp/corpus.txt" --serial --candidate-out "$tmp/candidate.nan1" --peek 8448:3,33090:1,81920:3,8456:1,8457:6 > "$tmp/out"; then cat "$tmp/out"; echo "trainer invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/out" || { cat "$tmp/out"; exit 1; }
test -s "$tmp/candidate.nan1" || { echo "candidate checkpoint was not written"; exit 1; }
if grep -a -q 'N16_GATE_UNIQUE_CORPUS_MARKER_7F31' "$tmp/candidate.nan1"; then echo "candidate checkpoint retained raw corpus text"; exit 1; fi
grep -qx '00000001' "$tmp/out" || { echo "candidate bigram count missing"; cat "$tmp/out"; exit 1; }
grep -qx '0B86B768' "$tmp/out" || { echo "deterministic trainer schedule digest mismatch"; cat "$tmp/out"; exit 1; }
# --peek emits: PASS line, three stats, one bigram count, then the first
# three corpus words (81920:3), then the schedule audit digest. The candidate
# exporter may omit the input region entirely, so its marker-absence test is
# NOT evidence that NaN16 scrubbed the source bytes from live guest memory.
if ! awk 'NR >= 6 && NR <= 8 { if ($0 != "00000000") bad=1; seen++ }
          END { if (bad || seen != 3) exit 1 }' "$tmp/out"; then
  echo "native NaN16 corpus input remained in guest memory after training"
  cat "$tmp/out"
  exit 1
fi
# NaN16 predictor: "AB" is the deterministic lowest-byte tied A-context
# completion in this corpus; unseen byte 255 must back off to the unigram,
# while previous byte 256 must fail before reading any table entry.
test "$(sed -n '10p' "$tmp/out")" = '00000042' || {
  echo "native A -> B completion failed"; cat "$tmp/out"; exit 1;
}
test "$(sed -n '11p' "$tmp/out")" = '00000000' || {
  echo "seen-context completion did not use the bigram"; cat "$tmp/out"; exit 1;
}
test "$(sed -n '13p' "$tmp/out")" = '00000001' || {
  echo "unseen-context unigram backoff failed"; cat "$tmp/out"; exit 1;
}
test "$(sed -n '15p' "$tmp/out")" = '00000003' || {
  echo "out-of-range completion context was accepted"; cat "$tmp/out"; exit 1;
}
# Prove the model/data layout under an input bigger than the old 16 KiB
# overlap boundary. All 700 records must survive and every native AB bigram
# must accumulate; neither buffer writes nor corpus scrubbing may erase them.
printf 'N16TXT/1\n' > "$tmp/long-corpus.txt"
i=0
while [ "$i" -lt 700 ]; do
  printf 'AB repeated context data 0123456789.\n' >> "$tmp/long-corpus.txt"
  i=$((i + 1))
done
if ! aarch64/android/nan_cli --nannet-train "$tmp/long-corpus.txt" --serial \
    --peek 8449:1,33090:1,81920:3 > "$tmp/long.out"; then
  cat "$tmp/long.out"
  echo "large native trainer corpus invocation failed"
  exit 1
fi
grep -qx 'N16 TRAIN PASS' "$tmp/long.out" || { cat "$tmp/long.out"; exit 1; }
test "$(sed -n '2p' "$tmp/long.out")" = '000002BC' || {
  echo "record accounting failed above former 16 KiB overlap"; cat "$tmp/long.out"; exit 1;
}
test "$(sed -n '3p' "$tmp/long.out")" = '000002BC' || {
  echo "native bigram counts were corrupted by corpus input"; cat "$tmp/long.out"; exit 1;
}
if ! awk 'NR >= 4 && NR <= 6 { if ($0 != "00000000") bad=1; seen++ }
          END { if (bad || seen != 3) exit 1 }' "$tmp/long.out"; then
  echo "large corpus source was retained in the NaN16 guest"
  cat "$tmp/long.out"
  exit 1
fi
if ! aarch64/android/nan_cli --nannet-train --serial > "$tmp/sample.out"; then cat "$tmp/sample.out"; echo "sample invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/sample.out" || { cat "$tmp/sample.out"; exit 1; }
sh tools/nannet-train.sh > "$tmp/launcher.out"
grep -qx 'N16 TRAIN PASS' "$tmp/launcher.out" || { cat "$tmp/launcher.out"; exit 1; }
printf 'N16TXT/1\ncaf\303\251\nemoji \360\237\214\215\n' > "$tmp/utf8.txt"
if ! aarch64/android/nan_cli --nannet-train "$tmp/utf8.txt" --serial > "$tmp/utf8.out"; then cat "$tmp/utf8.out"; echo "UTF-8 invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/utf8.out" || { cat "$tmp/utf8.out"; exit 1; }
printf 'N16TXT/1\r\nCRLF record\r\n' > "$tmp/crlf.txt"
aarch64/android/nan_cli --nannet-train "$tmp/crlf.txt" --serial > "$tmp/crlf.out"
grep -qx 'N16 TRAIN PASS' "$tmp/crlf.out" || { cat "$tmp/crlf.out"; exit 1; }
printf 'N16TXT/1\nstray\rCR\n' > "$tmp/lone-cr.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/lone-cr.txt" --serial > "$tmp/lone-cr.out"; then echo "lone CR unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/lone-cr.out" || { cat "$tmp/lone-cr.out"; exit 1; }
printf 'CRLF body record one.\r\nCRLF body record two.\r\n' > "$tmp/crlf-body.txt"
if ! aarch64/android/nan_cli --nannet-train "$tmp/crlf-body.txt" --serial --peek 8449:1 > "$tmp/crlf-body.out"; then cat "$tmp/crlf-body.out"; echo "CRLF body invocation failed"; exit 1; fi
grep -qx 'N16 TRAIN PASS' "$tmp/crlf-body.out" || { cat "$tmp/crlf-body.out"; exit 1; }
grep -qx '00000002' "$tmp/crlf-body.out" || { echo "CRLF body record count mismatch"; cat "$tmp/crlf-body.out"; exit 1; }
printf 'N16TXT/1\nbare\rreturn\n' > "$tmp/bare-cr.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/bare-cr.txt" --serial > "$tmp/bare-cr.out"; then echo "bare CR unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/bare-cr.out" || { cat "$tmp/bare-cr.out"; exit 1; }
printf 'N16TXT/1\nbad \300\257\n' > "$tmp/invalid.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/invalid.txt" --serial --candidate-out "$tmp/rejected.nan1" > "$tmp/invalid.out"; then echo "invalid UTF-8 unexpectedly accepted"; exit 1; fi
test ! -e "$tmp/rejected.nan1" || { echo "rejected corpus exported a candidate"; exit 1; }
grep -qx 'N16 TRAIN REJECT' "$tmp/invalid.out" || { cat "$tmp/invalid.out"; exit 1; }
printf 'N16TXT/1\ncontrol \302\200\n' > "$tmp/control.txt"
if aarch64/android/nan_cli --nannet-train "$tmp/control.txt" --serial > "$tmp/control.out"; then echo "C1 control unexpectedly accepted"; exit 1; fi
grep -qx 'N16 TRAIN REJECT' "$tmp/control.out" || { cat "$tmp/control.out"; exit 1; }
echo "N16 corpus trainer gate: PASS"

# The deterministic scheduler is a separate NaN16 guest kernel. Its rotated
# epoch order is a full permutation, and invalid corpus/draw bounds are rejected.
awk -f tools/nmk.awk -v CMD=emit src/training/n16_schedule.nas > "$tmp/n16_schedule.nan"
if ! aarch64/android/nan_cli --img "$tmp/n16_schedule.nan" --serial > "$tmp/schedule.out"; then
  cat "$tmp/schedule.out"
  echo "deterministic scheduler invocation failed"
  exit 1
fi
grep -qx 'N16 SCHED PASS' "$tmp/schedule.out" || { cat "$tmp/schedule.out"; exit 1; }
