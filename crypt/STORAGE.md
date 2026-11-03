# NSPV storage volumes

Status: host format/verify/read/write + guest NSPV all-sector decrypt implemented.
The guest decrypt cart passes on the C-core disk fd and x86 QEMU IDE for every
data sector of the test volume (16 sectors). A chunked guest file/mount tool and
encrypted boot are pending.

## NSPV1 sector format

Sector size 512 bytes. Header is sector 0, 16 little-endian 64-bit words:

```
0  magic          0x4E53505631 ("NSPV1")
1  version/suite  (1 << 16) | suite
2  sector_size    512
3  data_lba
4  data_sectors
5  tag_lba        1
6  tag_sectors    ceil(data_sectors / 10)
7  nonce0
8  nonce1
9  key_id
10 rollback
11..15            reserved zero
```

- Tag table starts at sector 1: 10 tags per sector, 48 bytes each.
- Data starts at `data_lba` (after the tag table); each sector is 512 bytes.
- AD = header words 0..10 || sector index.
- Nonce = file nonce + sector index.
- Each data sector is one capsule message: 64 x 64-bit words -> ciphertext
  (512 B) + 384-bit tag (48 B).
- Any header/tag/data tamper fails the sector tag; wrong key fails; grouped
  tags are not reorderable because the index is in AD.

## Host tool

```
crypt/nspvol format <1|2> <image> <keyhex> <noncehex> <sectors>
crypt/nspvol verify <image> <keyhex>
crypt/nspvol info   <image>
crypt/nspvol read   <image> <keyhex> <lba> <out>
crypt/nspvol write  <image> <keyhex> <lba> <in>
```

Key 32 bytes (64 hex); nonce 16 bytes (32 hex). `read` returns a full 512-byte
sector (padded); `write` pads a short input.

Gates:

```
sh crypt/volume_gate.sh    # suites 1/2, write/read, header/tag/data tamper, wrong key
sh crypt/storage_gate.sh   # NSPV probe on C-core disk fd + x86 QEMU IDE
sh crypt/storage_decrypt_gate.sh  # guest all-sector decrypt on C-core fd + QEMU IDE
sh crypt/storage_boot_gate.sh     # sparse 1 GiB: header + populated prefix, C-core + x86 IDE
```

The decrypt cart (`crypt/guest/nspv_decrypt.nan`) walks `data_sectors` for a
full volume and stops at `used_sectors` for a lazy one. It selects the tag slot
(`lba % 10` in the tag table), derives `nonce + lba`, decrypts the sector
capsule, verifies the tag, and checks the plaintext pattern. It prints
`VOL PASS <count>`; the boot variant is `nspv_decrypt_boot.nan`. A zero tag is
an unallocated sparse hole and is skipped, while `used` remains the high-water
mark. A 1 GiB image with only sector 2 populated prints `VOL PASS 00000003`
(used=3, sectors 0/1 holes).

The boot check cart (`crypt/guest/nan0s_fs_check.nas`) reads sector 0 only and
prints `NAN0S_FS OK cap=<hex> used=<hex> suite=<hex> lazy=<bit>`; it does not
walk a 1 GiB image just to boot.

## Sparse, arbitrary-size images

An NSPV image can be created at any size without allocating the whole file.
The tag table is reserved for the full capacity at creation and
`data_lba` stays fixed; header word 11 is `used_sectors` and word 12 is a flags
word (bit 0 = lazy). Capacity is capped at the 32-bit sector count (~2 TiB);
Android **Fs** accepts 0.0625–64 GiB. Writes seal a sector and advance `used`, so the sparse file
grows only where data/tags are written. `grow` rebuilds a larger image and
re-seals only the populated prefix, so capacity can increase without touching
unused holes; a shrink is accepted only down to `used`.

Default test image, kept under the Termux home:

```
~/nan0s_fs/nan0s_fs.img   1 GiB sparse NSPV suite-1 image
~/nan0s_fs/nan0s_fs.key   KEY=<64 hex> / NON=<32 hex>, mode 0600

tools/nan0s_fs.sh make 1G     # volume + nan0s_fs mkfs
tools/nan0s_fs.sh check          # boot check; creates the image if absent
tools/nan0s_fs.sh boot --verify  # header + every used sector; non-zero if invalid
tools/nan0s_fs.sh grow 2G        # grow capacity, re-sealing used sectors
tools/nan0s_fs.sh info
tools/nan0s_fs.sh format /dev/block/... 1G --device   # raw device, if writable
tools/nan0s_fs.sh link           # copy image+key to shared Download for SAF
```

Termux:Boot install:

```
mkdir -p ~/.termux/boot
ln -sf "$PWD/tools/nan0s_fs_boot.sh" ~/.termux/boot/nan0s_fs
```

The one-sector write path is:

```
KEY=$(sed -n 's/^KEY=//p' ~/nan0s_fs/nan0s_fs.key)
crypt/nspvol write ~/nan0s_fs/nan0s_fs.img "$KEY" 0 file.bin
crypt/nspvol info  ~/nan0s_fs/nan0s_fs.img   # USED advances
```

Android: the **Fs** button prompts for a size (default 1 GiB) and creates `filesDir/nan0s_fs.img` and
`nan0s_fs.key`, attaches it immediately, and the next boot prefers it when its
header is valid. **Reset** removes it and returns to `disk.nanfs`. The **Disk**
button can still open a host-linked image from shared storage.

## nan0s_fs file layer

`crypt/nan0s_fs` is a flat, encrypted file layer over logical NSPV data blocks:

- block 0 = superblock (`NAN0FS1`, capacity, next free, file count, first/last)
- each file has one `NDIR1` directory block in a chained list, carrying its
  name, payload start, sector count, byte size and flags
- payload blocks are contiguous; file count is limited only by volume capacity
- the superblock holds up to 58 free extents; `rm` returns directory/payload
  runs and `put` uses first-fit reuse, coalescing adjacent extents
- every block is sealed by NSPV; unused blocks stay sparse holes
- header word 13 carries the unauthenticated `NAN0FS1` marker, word 15 the
  file count; the guest boot cart prints `fs=00000001`

Commands (image + key):

```
crypt/nan0s_fs mkfs  image keyhex
crypt/nan0s_fs put   image keyhex local name
crypt/nan0s_fs get   image keyhex name out
crypt/nan0s_fs ls    image keyhex
crypt/nan0s_fs rm    image keyhex name
crypt/nan0s_fs mv    image keyhex old new
crypt/nan0s_fs df    image keyhex
crypt/nan0s_fs compact image keyhex   # defragment and collapse free extents
crypt/nan0s_fs check image keyhex
crypt/nan0s_fs resize image keyhex    # after volume grow
```

Shortcuts through the default image:

```
tools/nan0s_fs.sh mkfs
tools/nan0s_fs.sh put note.txt note.txt
tools/nan0s_fs.sh ls
tools/nan0s_fs.sh get note.txt /tmp/note.txt
tools/nan0s_fs.sh mv note.txt renamed.txt
tools/nan0s_fs.sh df
tools/nan0s_fs.sh rm renamed.txt
tools/nan0s_fs.sh compact
tools/nan0s_fs.sh checkfs
tools/nan0s_fs.sh boot --verify
```

`boot --verify` verifies every nonzero tag **and** the `nan0s_fs` superblock,
directory chain, extents, free list and file count. `grow` preserves the file
layer and resizes its superblock capacity. `rm` releases extents to the
superblock free list; `put` reuses the first fitting run. `compact` rewrites the
live files into a fresh sparse image, collapsing fragmentation or a full free
list. The Android **Fs** image is an NSPV volume without the encrypted file
layer yet (`fs=00000000`); create a file layer on the host and open that image
through **Disk**, or add the guest-side mkfs next.

Limits: arbitrary file count up to volume capacity, at most 58 free extents in
the superblock (compact when exhausted), flat namespace (no directories), and
the guest can boot/check the filesystem marker but does not mount files yet.

## Storage backends

- **x86 virtual HDD:** QEMU `-drive format=raw,if=ide,file=vol.img`. The guest
  ATA PIO path reads every data sector; `storage_decrypt_gate.sh` PASS.
- **x86 real HDD:** the same ATA primary-master path. Write the prepared volume
  image to the drive (destructive; verify the device first). The guest decrypt
  does not depend on QEMU.
- **Android emulated:** the bundled `disk.nanfs`, the local **Fs** sparse
  `nan0s_fs.img`, or any SAF file is attached as a file descriptor
  (`NanNative.attachDiskFd`); the C core exposes it as the ATA primary master.
  The C-core legs of `storage_decrypt_gate.sh` and `storage_boot_gate.sh` use
  this path.
- **Android real:** use the SAF picker (`Disk`) to attach any file/content
  provider descriptor. Raw block devices are not available to a normal app
  without root; "any storage" means any file/fd the picker can provide.
- **Plug and play:** the guest reads sector 0 and checks the NSPV magic. An
  unformatted/plain volume prints `NSPV NO`; an NSPV volume prints `NSPV OK`.
  The decrypt cart then walks populated sectors, skipping zero-tag holes. Format/rekey is done with the
  host tool; the guest unlock/mount layer is the next port.

## Current limits

1. The guest decrypts the populated prefix of a full or lazy volume
   (`nspv_decrypt.nan`) and skips zero-tag holes, but has no guest file/mount
   layer; each sector is verified and then discarded. A 1 GiB lazy image boots
   through the header check (`nan0s_fs_check.nas`). The host file layer exists in
   `crypt/nan0s_fs`; the next port adds the guest directory/extent reader and a
   sector cache.
2. Encrypted **boot** is not implemented: bootloader/NaNFS decryption, operator
   or TPM key release, rollback-counter enforcement and key zeroization are
   pending.
3. Key management is caller-supplied; the host/Android test paths keep a
   plaintext `nan0s_fs.key` (mode 0600). No key slot, escrow or revocation yet.
4. Real HDD write is destructive; use a disposable drive or a verified image.
5. NSP-7/NSP-8 are experimental; do not protect real data yet.

## Security notes

- The header is authenticated only through every data-sector AD; a lazy image
  with `used=0` is therefore a capacity/geometry check, not an authentication
  check. Full verification covers every non-zero-tag sector below `used`.
- A zero tag is an unallocated sparse hole and is skipped; a corrupted non-zero tag fails.
- Unwritten sectors are holes: they are neither allocated nor authenticated and
  must never be exposed as valid plaintext.
- The host tool is a reference; the product path must be raw NaN16.
