# Self-Hosting and the Native Boundary

## The directive

Move the system to NaN as completely as possible. The native core is the
absolute minimum needed to execute a NaN word and touch raw hardware. The disk
driver, filesystem, builder, loader, shell, museum, and tools are NaN16.

## The chain

```
S0  boot sector             native, 512 B, hand-checkable
S1  native core             x86 or AArch64, minimum
S2  nasm0                   NaN16 assembler, self-hosting
S3  nbuild                  NaN16 builder: manifest -> cartridges -> image
S4  nanfs                   NaN16 disk driver + filesystem + allocator
S5  work image              shell + museum + all cartridges
S6  host test bench         scaffold only, outside the machine
```

S0+S1 are the trust base. S2..S5 are NaN. S6 is not part of the machine.

## Native core contract

S1 provides only:

- fetch a 64-bit word from guest memory,
- decode near/far faces and gate,
- execute the NaN16 opcode,
- trap (`!G`, `!O`),
- read/write guest memory,
- read the clock,
- read the keyboard ring,
- write text cells and framebuffer bytes,
- byte and word port I/O (`INB/OUTB/INW/OUTW`) so the NaN16 drivers own the
  device protocols,
- halt.

No ATA logic, no filesystem, no allocator, no shell, no builder, no font, no
VGA mode table in S1. Those are NaN.

## Disk driver: ATA PIO in NaN16

`src/lib/ata.nas` implements:

- `ata_wait_bsy`: poll status port 0x1F7 bit 7.
- `ata_wait_drq`: poll bit 3.
- `ata_identify`: command 0xEC, read 256 words, verify signature.
- `ata_read28`: LBA28, one sector, read 256 words to a guest buffer.
- `ata_write28`: LBA28, one sector, write 256 words.
- `ata_read48` / `ata_write48`: LBA48 for the gigabyte store.
- `ata_flush`: command 0xE7.

The driver uses only `INW`/`OUTW`/`INB`/`OUTB`. The NaN16 code owns the ATA
register sequence, the polling, the LBA arithmetic, and the error handling.

## Filesystem: NaNFS

`src/lib/nanfs.nas`:

- 4 KiB blocks, 64-bit block numbers.
- superblock: magic, version, block size, total blocks, free blocks, root
  inode, work inode, seal triplet.
- block bitmap.
- inode table: 64-byte records.
- extents: 64-bit block, 32-bit length.
- directory B-tree keyed by name hash.
- write-ahead journal for metadata.
- content-addressed store for large assets.
- block cache: fixed window, streaming reads and writes.

## Builder: nbuild

`src/prog/nbuild.nas`:

1. Read the manifest (cartridge source pointers, store hints).
2. For each cartridge, call nasm0's `run` with pass 1 and pass 2.
3. Check `V_ERR`, `V_MIRR`, and the emitted word count.
4. Compute the dual-face seal:
   - A: FNV-1a/32 over near payloads,
   - B: FNV-1a/32 over far payloads,
   - C: rotate/XOR over class nibbles.
5. Write the cartridge payload to the store.
6. Write the 16-word TOC entry.
7. Flush through ATA.
8. Optionally write a new `work.img` / `store.nan`.

The first milestone is a RAM-only nbuild: assemble one cartridge, seal it,
place it in a RAM store, and run it from the shell. The second milestone writes
the store to ATA. The third milestone builds the whole image.

## Boot flow

1. S0 loads S1.
2. S1 loads the work image from the boot medium or from NaNFS.
3. The shell starts. `nbuild` and `nanfs` are available as tools.
4. If NaNFS is absent, the shell can format the allocation device and write
   the work image. The allocation image is sparse and local; it is never
   shipped.
5. The work image contains the shell, museum, cartridges, sources, and tools.

## AArch64

The same S1 contract, written in AArch64 assembly. The boot path is UEFI or a
bare-metal Pi stub; the NaN image is identical. `nasm2` is the AArch64 emitter
written in NaN16, with the same source language as nasm1. The AArch64 emulator
is a NaN16 interpreter, so the museum can run A64 programs inside the NaN
machine.

## Nested NaNs

Metadata and builder records use nested NaN pairs:

```
outer A payload = inner near head || inner payload low
outer B payload = inner payload high || inner far head
```

The pair is written in opposite byte orders. The decoder reconstructs the inner
word, checks the inner gate, and rejects a mismatch. Nested words carry TOC
metadata, seal records, and builder manifests.

## Double endianness rules

- Every stored word is written in both faces.
- The gate checks both faces before execution.
- The seal checks near payload, far payload, and class channel.
- TOC, n16de, and nested records vote across faces.
- The disassembler shows both faces.
- The compiler emits both faces; the decompiler reads either and reports the
  other.

## Milestones

1. `INW`/`OUTW` guest ops + `ata_identify` + `ata_read28` test in v86.
2. `ata_write28` round-trip test on a scratch sector.
3. `nbuild` RAM-only: assemble one cartridge with nasm0 and run it.
4. `nbuild` + `ata_write28`: write the cartridge to a raw sector, read it back.
5. NaNFS format/mount/read/write.
6. Shell command `BUILD` / `FORMAT` / `MOUNT`.
7. Build the whole work image from source inside the machine.
8. AArch64 core and `nasm2`.

## Gates

- ATA identify returns the v86 disk signature.
- Read sector 0 matches the host image bytes.
- Write/read round-trip on a scratch sector.
- nbuild assembles the toy cartridge and its seal verifies.
- NaNFS format/mount/read/write survives a reboot.
- The work image built in-guest is byte-identical to the host-built image.
- The native core size and instruction count are published.
