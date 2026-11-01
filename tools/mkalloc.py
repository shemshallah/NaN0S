#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): create the sparse allocation image described in
# spec/IMAGE_SCALE_PLAN.md. The runtime Stage-1 loader will read this later.
# It writes a small NANFS superblock and copies the work image into the first
# work extent. The file is sparse: apparent size can be 64 GiB, disk usage is
# only the superblock + work image.
import sys, os, struct, time

MAGIC = b'NANFS01\0'
BLOCK = 4096

def size(s):
    s = s.strip().upper()
    mul = 1
    if s.endswith('K'): mul, s = 1024, s[:-1]
    elif s.endswith('M'): mul, s = 1024**2, s[:-1]
    elif s.endswith('G'): mul, s = 1024**3, s[:-1]
    elif s.endswith('T'): mul, s = 1024**4, s[:-1]
    return int(s, 0) * mul

def fnv(data):
    h = 0x811C9DC5
    for b in data:
        h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF
    return h

def main():
    av = sys.argv[1:]
    def opt(name, default):
        return av[av.index(name)+1] if name in av else default
    total = size(opt('--size', '64G'))
    work = opt('--work', 'x86/build/nan0s.img')
    out = opt('--out', 'store.nan')
    data = open(work, 'rb').read()
    if total < BLOCK + len(data):
        raise SystemExit('allocation image smaller than work image')
    sb = bytearray(BLOCK)
    sb[0:8] = MAGIC
    struct.pack_into('<I', sb, 8, 1)              # version
    struct.pack_into('<I', sb, 12, BLOCK)         # block size
    struct.pack_into('<Q', sb, 16, total // BLOCK) # total blocks
    struct.pack_into('<Q', sb, 24, (BLOCK + len(data) + BLOCK - 1) // BLOCK)
    struct.pack_into('<Q', sb, 32, BLOCK)         # first work extent offset
    struct.pack_into('<Q', sb, 40, len(data))     # work length
    struct.pack_into('<I', sb, 48, fnv(data))     # seal A
    struct.pack_into('<I', sb, 52, fnv(bytes(data[i] for i in range(len(data)-1, -1, -1)))) # seal B (reverse)
    struct.pack_into('<I', sb, 56, 0)             # seal C (class channel, future)
    struct.pack_into('<Q', sb, 64, int(time.time()))
    with open(out, 'wb') as f:
        f.write(sb)
        f.write(data)
        f.truncate(total)
    st = os.stat(out)
    print('allocation image', out)
    print('apparent bytes', st.st_size)
    print('allocated bytes (sparse)', st.st_blocks * 512)
    print('work image bytes', len(data))
    print('total blocks', total // BLOCK, 'used blocks', (BLOCK + len(data) + BLOCK - 1)//BLOCK)
    print('seal A %08x seal B %08x' % (fnv(data), fnv(bytes(data[i] for i in range(len(data)-1, -1, -1)))))

if __name__ == '__main__':
    main()
