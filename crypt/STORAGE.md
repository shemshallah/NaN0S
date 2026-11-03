# NSPV storage volumes

Status: host format/verify/read/write + guest NSPV sector decrypt implemented.
The guest decrypt cart passes on the C-core disk fd and x86 QEMU IDE.
Encrypted boot and a chunked guest file/mount tool are pending.

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
sh crypt/storage_decrypt_gate.sh  # guest sector decrypt on C-core fd + QEMU IDE
sh crypt/storage_gate.sh   # NSPV probe on C-core disk fd + x86 QEMU IDE
```

## Storage backends

- **x86 virtual HDD:** QEMU `-drive format=raw,if=ide,file=vol.img`. The guest
  ATA PIO path reads sector 0; `storage_gate.sh` PASS.
- **x86 real HDD:** the same ATA primary-master path. Write the prepared volume
  image to the drive (destructive; verify the device first). The guest probe
  does not depend on QEMU.
- **Android emulated:** the bundled `disk.nanfs`, or any SAF file, is attached
  as a file descriptor (`NanNative.attachDiskFd`); the C core exposes it as the
  ATA primary master. The C-core leg of `storage_gate.sh` uses this path.
- **Android real:** use the SAF picker (`Disk`) to attach any file/content
  provider descriptor. Raw block devices are not available to a normal app
  without root; "any storage" means any file/fd the picker can provide.
- **Plug and play:** the guest reads sector 0 and checks the NSPV magic. An
  unformatted/plain volume prints `NSPV NO`; an NSPV volume prints `NSPV OK`.
  Format/unlock is done with the host tool until the guest port lands.

## Current limits

1. The guest decrypts one NSPV sector today (`crypt/guest/nspv_decrypt.nan`),
   not a chunked multi-sector mount; the next port iterates the volume.
   raw-NaN16 port. The 512-byte capsule round-trip itself is gated privately.
2. Encrypted **boot** is not implemented: bootloader/NaNFS decryption, operator
   or TPM key release, rollback-counter enforcement and key zeroization are
   pending.
3. Key management is caller-supplied; no key slot, escrow or revocation yet.
4. Real HDD write is destructive; use a disposable drive or a verified image.
5. NSP-7/NSP-8 are experimental; do not protect real data yet.

## Security notes

- The header is authenticated only through every data-sector AD; a volume with
  no data sectors should be rejected.
- Tag-table tamper is detected by the data tags; a missing tag is a failure.
- The host tool is a reference; the product path must be raw NaN16.
