# Two-Stage Allocation Image and the Gigabyte Store

## The problem

The release must not be a multi-gigabyte download. The running system must
still be able to own gigabytes of storage, large files, and large numbers of
files. A single floppy-sized image cannot hold the museum forever.

## The rule

Ship two small things:

1. `nan0s.img` is the loader image: boot sector, native kernel, Stage-1
   formatter/loader, and the seal verifier. It is small enough to inspect.
2. `work.img` is the current work image: the museum shell and every cartridge.
   It is the image that contains all of the work. It is also small.

On first boot, Stage 1 creates the allocation image `store.nan`. The allocation
image is sparse. It is not shipped, not uploaded, and not downloaded. It is a
local artifact. Stage 1 writes `work.img` into block 0 of `store.nan`, seals it,
and jumps to it. On later boots, Stage 1 finds the header, verifies the seal, and
loads `work.img` from `store.nan` without reformatting.

## Why sparse

A sparse file has holes. A hole reads as zero and costs no host blocks until it
is written. A 64 GiB `store.nan` can exist on a phone while only the first few
megabytes are physically present. The allocator image owns the address space;
the host owns only the blocks that were actually touched.

On real hardware the same idea is a raw partition or a dedicated block device
with a NaNFS superblock. The device may be 64 GiB. The used-block bitmap and the
extent tree say which blocks are real. A freshly formatted device has one small
superblock and one small work image, not 64 GiB of zeros.

## On-disk layout

```
offset 0x0000  NANFS superblock (4 KiB)
  magic "NANFS01\0"
  version, block size (4 KiB), total blocks (u64), free blocks (u64)
  root inode, work-image inode, seal A/B/C
  generation, mount count, last mount time
offset 0x1000  block bitmap (one bit per 4 KiB block)
offset ...     inode table (64-byte records)
offset ...     extent tree (64-bit block numbers, 32-bit lengths)
offset ...     data extents
```

The work image is stored as an inode with extents. The first extent begins at a
fixed block so Stage 1 can find it without a full filesystem mount. The seal is
the same dual-face FNV-1a/32 triplet used by the museum cartridges, plus a
future keyed MAC.

## Stage 1 boot flow

1. BIOS loads `nan0s.img`.
2. Kernel starts. Stage 1 scans block devices in a fixed order: ATA primary
   master, ATA primary slave, AHCI port 0, NVMe namespace 1, then a RAM disk.
3. Read the first 4 KiB. If `NANFS01` is present and the work seal verifies,
   load the work image and jump.
4. If the magic is absent, format the selected device: write the superblock,
   zero the bitmap, create the work inode, copy `work.img` from the release
   medium (second floppy, USB, or a built-in payload) into extents, seal, fsync.
5. If the device cannot be formatted, fall back to a RAM disk and print a
   loud warning. The machine still boots; the work is not persisted.

## Block and file scale

- 64-bit block numbers. 4 KiB blocks. A 64 GiB device is 16,777,216 blocks.
- Extents, not block lists, for large files.
- A content-addressed store for museum assets: key = BLAKE3-like hash (future),
  value = extent list. Duplicate ROMs and text are stored once.
- Streaming reads and writes: a file is a sequence of extents; the block cache
  is a fixed window. A 10 GiB file never has to fit in RAM.
- Large numbers of files: inode table and directory entries are extents too.
  The directory is a B-tree keyed by name hash. The museum can hold millions of
  small files without a linear scan.
- Journal: write-ahead log of metadata blocks, checksummed. A crash leaves a
  replayable tail, not a corrupted tree.
- Trim/discard: pass through to the host so deleted extents become holes again.

## GPU and VRAM

The same allocation model applies to device memory. A `GPU` region is an
extent list over a PCIe BAR. The kernel exposes BAR mapping and DMA windows;
the NaN16 driver owns the command queue and the VRAM allocator. A future
`GPUALLOC`, `GPUCOPY`, `GPUSUBMIT` op is the only native boundary. Doom and
Quake use the same framebuffer API as the museum.

## v86 prototype

`tools/mkalloc.py` creates a sparse `build/store.nan` with a valid superblock
and copies `build/nan0s.img` into the first work extent. The harness attaches
it as `hda`. Stage 1 reads it through ATA PIO. The release zip contains
`nan0s.img` and `work.img`; `store.nan` is generated on the user's machine.

## Test gates

- `python3 tools/mkalloc.py --size 64G build/store.nan` creates a sparse file
  whose apparent size is 64 GiB and whose disk usage is tiny.
- Stage 1 formats an absent device, writes the work image, verifies the seal,
  and boots it.
- Stage 1 refuses a corrupted work extent with the correct seal status.
- A 1 GiB test file streams through a 1 MiB block cache with constant RAM.
- 100,000 small files create and enumerate without a linear directory scan.
- The image is never larger than the small release pair. The allocation image
  is never uploaded.

## Honest limit

A sparse file is a host filesystem feature. On a host that does not support
holes, the same logical image is still sparse at the NaNFS level: unwritten
blocks are not allocated, even if the host preallocates the container. The
release never contains the container.
