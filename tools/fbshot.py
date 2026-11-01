#!/usr/bin/env python3
# SCAFFOLD: render a 320x200 palette-index framebuffer dump (capfb.mjs) to PNG.
# Palette index 15 is white, 0 is black; other indices use a simple VGA palette.
import sys, zlib, struct
PAL = [(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),
       (170,85,0),(170,170,170),(85,85,85),(85,85,255),(85,255,85),
       (85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]
def chunk(t,b):
    return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b)&0xffffffff)
d=open(sys.argv[1],'rb').read(); W,H=320,200
pix=bytearray(W*H*3)
for i,v in enumerate(d[:W*H]):
    pix[i*3:i*3+3]=bytes(PAL[v&15])
raw=b''.join(b'\x00'+bytes(pix[y*W*3:(y+1)*W*3]) for y in range(H))
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',W,H,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b'')
open(sys.argv[2],'wb').write(png); print(sys.argv[2],W,'x',H)
