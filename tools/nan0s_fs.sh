#!/bin/sh
# nan0s_fs - sparse NSPV disk-image / raw-device manager.
#
# Defaults: image  $HOME/nan0s_fs/nan0s_fs.img
#           key    $HOME/nan0s_fs/nan0s_fs.key
#           size   1G (sparse; only used sectors allocate blocks)
#
# Commands:
#   make [size] [image]      create a sparse lazy volume if absent
#   check [image]           boot check (creates the default image if absent)
#   boot [--verify]         check only; --verify checks every used sector
#   format [image|device] [size] [--device]
#                           overwrite/create a volume (destructive)
#   grow [size] [image]     grow capacity, re-sealing only the used prefix
#   mkfs [image]            write the nan0s_fs superblock/directory
#   put <local> <name> [image]        store a file
#   get <name> <out> [image]          extract a file
#   ls [image]                        list files
#   rm <name> [image]                 remove a directory entry
#   checkfs [image]                   verify the nan0s_fs layer
#   info [image]            header/capacity/used information
#   link [image] [target]   copy for Android testing; default shared Download
#
# The image is an NSPV suite-1 volume. The tag table is reserved for the full
# capacity at creation; writes grow `used` in place, so the file is sparse and
# does not need to be rebuilt for every new sector. To change capacity, create
# a new image with the desired size.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
DIR="${NAN0S_FS_DIR:-$HOME/nan0s_fs}"
IMG="${NAN0S_FS_IMAGE:-$DIR/nan0s_fs.img}"
KEYF="${NAN0S_FS_KEY:-$DIR/nan0s_fs.key}"
SIZE="${NAN0S_FS_SIZE:-1G}"

ensure_key() {
  [ -f "$KEYF" ] && return 0
  mkdir -p "$DIR"
  (umask 077
   tmp="$KEYF.tmp.$$"
   node -e '
     const c=require("crypto");
     console.log("KEY="+c.randomBytes(32).toString("hex").toUpperCase());
     console.log("NON="+c.randomBytes(16).toString("hex").toUpperCase());
   ' > "$tmp"
   mv "$tmp" "$KEYF")
}

read_key() {
  ensure_key
  KEY=$(sed -n 's/^KEY=//p' "$KEYF" | head -1)
  NON=$(sed -n 's/^NON=//p' "$KEYF" | head -1)
  [ ${#KEY} -eq 64 ] && [ ${#NON} -eq 32 ] || {
    echo "nan0s_fs: bad key file $KEYF" >&2; exit 1; }
}

make_image() {
  size="$1"; image="$2"
  mkdir -p "$(dirname "$image")"
  if [ -e "$image" ]; then
    echo "nan0s_fs: exists, checking $image"
    check_image "$image"
    return 0
  fi
  read_key
  node crypt/volume.cjs create 1 "$image" "$KEY" "$NON" "$size" --lazy
  crypt/nan0s_fs mkfs "$image" "$KEY"
}

check_image() {
  image="$1"; verify="${2:-0}"
  if [ ! -e "$image" ]; then
    echo "nan0s_fs: missing $image" >&2
    return 1
  fi
  if [ "$verify" = "1" ]; then
    read_key
    if [ -b "$image" ]; then
      sectors=$(( $(blockdev --getsize64 "$image") / 512 ))
      node crypt/volume.cjs check "$image" "$KEY" --sectors "$sectors" --verify
    else
      node crypt/volume.cjs check "$image" "$KEY" --verify
      crypt/nan0s_fs check "$image" "$KEY"
    fi
  elif [ -b "$image" ]; then
    sectors=$(( $(blockdev --getsize64 "$image") / 512 ))
    node crypt/volume.cjs check "$image" --sectors "$sectors"
  else
    node crypt/volume.cjs check "$image"
  fi
}

format_target() {
  target="$1"; size="$2"; device="$3"
  if [ "$device" = "1" ] || [ -b "$target" ]; then
    [ -w "$target" ] || { echo "nan0s_fs: not writable: $target" >&2; exit 1; }
    read_key
    [ -n "$size" ] || size=$(blockdev --getsize64 "$target" 2>/dev/null || true)
    [ -n "$size" ] || { echo "nan0s_fs: size required for raw device" >&2; exit 1; }
    node crypt/volume.cjs create 1 "$target" "$KEY" "$NON" "$size" --device
    return 0
  fi
  read_key
  node crypt/volume.cjs create 1 "$target" "$KEY" "$NON" "$size" --lazy
}

link_image() {
  image="$1"; target="${2:-}"
  if [ -z "$target" ]; then
    if [ -d "$HOME/storage/downloads" ]; then target="$HOME/storage/downloads"
    elif [ -d /sdcard/Download ]; then target=/sdcard/Download
    else echo "nan0s_fs: no shared Download directory; use: $0 link $image /path" >&2; return 1; fi
  fi
  mkdir -p "$target"
  cp --sparse=always "$image" "$target/nan0s_fs.img"
  cp "$KEYF" "$target/nan0s_fs.key" 2>/dev/null || true
  echo "LINKED $target/nan0s_fs.img"
  echo "Use the Android Disk picker on that file. The key copy is for host-side testing only."
}

cmd="${1:-check}"; shift || true
case "$cmd" in
  make)
    make_image "${1:-$SIZE}" "${2:-$IMG}" ;;
  check)
    image="${1:-$IMG}"
    if [ ! -e "$image" ]; then make_image "$SIZE" "$image"; else check_image "$image"; fi ;;
  boot)
    verify=0; [ "${1:-}" = "--verify" ] && verify=1
    check_image "$IMG" "$verify" ;;
  format)
    target="${1:-$IMG}"; size="${2:-$SIZE}"; device=0
    [ "${3:-}" = "--device" ] && device=1
    format_target "$target" "$size" "$device" ;;
  grow)
    size="${1:-2G}"; image="${2:-$IMG}"
    read_key
    node crypt/volume.cjs grow "$image" "$KEY" "$size"
    if crypt/nan0s_fs check "$image" "$KEY" >/dev/null 2>&1; then
      crypt/nan0s_fs resize "$image" "$KEY"
    fi ;;
  mkfs)
    image="${1:-$IMG}"; read_key; crypt/nan0s_fs mkfs "$image" "$KEY" ;;
  put)
    local="${1:-}"; name="${2:-}"; image="${3:-$IMG}"
    [ -n "$local" ] && [ -n "$name" ] || { echo "usage: $0 put <local> <name> [image]" >&2; exit 2; }
    read_key; crypt/nan0s_fs put "$image" "$KEY" "$local" "$name" ;;
  get)
    name="${1:-}"; out="${2:-}"; image="${3:-$IMG}"
    [ -n "$name" ] && [ -n "$out" ] || { echo "usage: $0 get <name> <out> [image]" >&2; exit 2; }
    read_key; crypt/nan0s_fs get "$image" "$KEY" "$name" "$out" ;;
  ls)
    image="${1:-$IMG}"; read_key; crypt/nan0s_fs ls "$image" "$KEY" ;;
  rm)
    name="${1:-}"; image="${2:-$IMG}"
    [ -n "$name" ] || { echo "usage: $0 rm <name> [image]" >&2; exit 2; }
    read_key; crypt/nan0s_fs rm "$image" "$KEY" "$name" ;;
  checkfs)
    image="${1:-$IMG}"; read_key; crypt/nan0s_fs check "$image" "$KEY" ;;
  info)
    target="${1:-$IMG}"
    if [ -b "$target" ]; then
      sectors=$(( $(blockdev --getsize64 "$target") / 512 ))
      node crypt/volume.cjs info "$target" --sectors "$sectors"
    else
      node crypt/volume.cjs info "$target"
    fi ;;
  link)
    read_key
    link_image "${1:-$IMG}" "${2:-}" ;;
  *)
    echo "usage: $0 make|check|boot|format|grow|mkfs|put|get|ls|rm|checkfs|info|link [args]" >&2; exit 2 ;;
esac
