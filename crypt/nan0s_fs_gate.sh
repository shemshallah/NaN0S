#!/bin/sh
# nan0s_fs file-layer gate: mkfs/put/get/ls/rm/check on a sparse NSPV volume,
# then the guest boot marker (fs=1) on the C-core fd and x86 IDE.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/nan0sfslayer.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
command -v node >/dev/null 2>&1 || { echo "nan0s_fs gate: node missing"; exit 77; }
KEY=A6FBC7641D3FBB665A3D4D4313F10C3D546CCCD54959EB0825079FE4A376C9B7
NON=A6FBC7641D3FBB665A3D4D4313F10C3D
node crypt/volume.cjs create 1 "$T/fs.img" "$KEY" "$NON" 64M --lazy >/dev/null
crypt/nan0s_fs mkfs "$T/fs.img" "$KEY" >/dev/null
printf 'hello nan0s_fs\n' > "$T/hello"
crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/hello" hello.txt | grep -q '^PUT hello.txt '
crypt/nan0s_fs ls "$T/fs.img" "$KEY" | grep -q '^hello.txt 2 1 '
crypt/nan0s_fs get "$T/fs.img" "$KEY" hello.txt "$T/out"
cmp "$T/hello" "$T/out"
for i in $(seq 1 11); do
  printf 'file %02d\n' "$i" > "$T/f$i"
  crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/f$i" "f$i.txt" >/dev/null
done
[ "$(crypt/nan0s_fs ls "$T/fs.img" "$KEY" | wc -l | tr -d ' ')" = "12" ]
crypt/nan0s_fs check "$T/fs.img" "$KEY" | grep -q '^FS OK files=12 '
crypt/nan0s_fs get "$T/fs.img" "$KEY" f6.txt "$T/f6.out"
cmp "$T/f6" "$T/f6.out"
crypt/nan0s_fs rm "$T/fs.img" "$KEY" hello.txt >/dev/null
crypt/nan0s_fs rm "$T/fs.img" "$KEY" f6.txt >/dev/null
crypt/nan0s_fs rm "$T/fs.img" "$KEY" f11.txt >/dev/null
crypt/nan0s_fs check "$T/fs.img" "$KEY" | grep -q '^FS OK files=9 '
[ "$(crypt/nan0s_fs ls "$T/fs.img" "$KEY" | wc -l | tr -d ' ')" = "9" ]
crypt/nan0s_fs df "$T/fs.img" "$KEY" | grep -q '^DF .* files=9$'
crypt/nan0s_fs put "$T/fs.img" "$KEY" "$T/f1" reuse.txt >/dev/null
crypt/nan0s_fs check "$T/fs.img" "$KEY" | grep -q '^FS OK files=10 '
crypt/nan0s_fs get "$T/fs.img" "$KEY" reuse.txt "$T/reuse.out"
cmp "$T/f1" "$T/reuse.out"
crypt/nan0s_fs rm "$T/fs.img" "$KEY" reuse.txt >/dev/null
crypt/nan0s_fs check "$T/fs.img" "$KEY" | grep -q '^FS OK files=9 '
crypt/nan0s_fs mv "$T/fs.img" "$KEY" f2.txt renamed.txt >/dev/null
crypt/nan0s_fs get "$T/fs.img" "$KEY" renamed.txt "$T/renamed.out"
cmp "$T/f2" "$T/renamed.out"
crypt/nan0s_fs compact "$T/fs.img" "$KEY" | grep -q '^COMPACT files=9$'
crypt/nan0s_fs check "$T/fs.img" "$KEY" | grep -q '^FS OK files=9 next=19 '
crypt/nan0s_fs get "$T/fs.img" "$KEY" renamed.txt "$T/renamed2.out"
cmp "$T/f2" "$T/renamed2.out"

awk -f tools/nmk.awk -v CMD=emit crypt/guest/nan0s_fs_check.nas > "$T/check.nan"
aarch64/android/nan_cli --img "$T/check.nan" --disk "$T/fs.img" \
  --steps 5000000 --serial > "$T/c.out" 2>/dev/null
grep -q '^NAN0S_FS OK cap=' "$T/c.out" || {
  echo "nan0s_fs gate: FAIL (C-core header check)"; tail -4 "$T/c.out"; exit 1; }
grep -q ' fs=00000001$' "$T/c.out" || {
  echo "nan0s_fs gate: FAIL (C-core fs marker)"; tail -4 "$T/c.out"; exit 1; }

if command -v qemu-system-i386 >/dev/null 2>&1; then
  BOOT_SRC="$PWD/crypt/guest/.nan0s_fs_check_boot.nas"
  trap 'rm -f "$BOOT_SRC"; rm -rf "$T"' EXIT
  sed 's/^\.org 0$/.org 8192/' crypt/guest/nan0s_fs_check.nas > "$BOOT_SRC"
  awk -f tools/nmk.awk -v CMD=emit "$BOOT_SRC" > "$T/check_boot.nan"
  printf 'boot:%s\n' "$T/check_boot.nan" > "$T/carts.txt"
  gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
    -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" 2>/dev/null
  cat "$T/b.bin" "$T/g.bin" > "$T/boot.img"
  truncate -s 1474560 "$T/boot.img" 2>/dev/null || \
    dd if=/dev/zero bs=1 count=$((1474560 - $(wc -c < "$T/boot.img"))) >> "$T/boot.img"
  timeout 30 qemu-system-i386 -m 32 \
    -drive format=raw,if=floppy,file="$T/boot.img" \
    -drive format=raw,if=ide,file="$T/fs.img" \
    -display none -serial "file:$T/q.out" -no-reboot >/dev/null 2>&1 || true
  grep -q ' fs=00000001$' "$T/q.out" || {
    echo "nan0s_fs gate: FAIL (x86 fs marker)"; tail -6 "$T/q.out"; exit 1; }
  echo "nan0s_fs gate: PASS (12 files, rename, free-extent reuse, compact, guest fs marker on C-core fd + x86 IDE)"
else
  echo "nan0s_fs gate: PASS (12 files, rename, free-extent reuse, compact, guest fs marker on C-core fd; QEMU skipped)"
fi
