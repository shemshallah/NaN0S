#!/usr/bin/env python3
# SCAFFOLD: render a VGA text dump (cap.mjs) to PNG using the museum's
# homebrew 3x5 font at 3x scale. Not part of the runtime.
import sys, zlib, struct, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_fb_lib import FONT5

PAL = [(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),
       (170,85,0),(170,170,170),(85,85,85),(85,85,255),(85,255,85),
       (85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]

def glyph(ch):
    return FONT5.get(ch, ["00000"]*7)

def chunk(t, b):
    return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t+b)&0xffffffff)

def main():
    d = open(sys.argv[1],'rb').read()
    mode, cols, rows = d[0], d[1], d[2]
    body = d[3:]
    S = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    GAP = max(1, S//2)
    CW, CH = 5*S+GAP, 7*S+GAP
    W, H = cols*CW, rows*CH
    pix = bytearray(W*H*3)
    for i in range(cols*rows):
        if 2*i+1 >= len(body): break
        ch, at = body[2*i], body[2*i+1]
        fg = PAL[at & 15]; bg = PAL[(at >> 4) & 7]
        x0, y0 = (i % cols)*CW, (i // cols)*CH
        for yy in range(CH):
            for xx in range(CW):
                o = ((y0+yy)*W + x0+xx)*3
                pix[o:o+3] = bytes(bg)
        g = glyph(chr(ch) if 32 <= ch < 127 else ' ')
        for ry, rowbits in enumerate(g):
            for cx, bit in enumerate(rowbits):
                if bit == '1':
                    for sy in range(S):
                        for sx in range(S):
                            o = ((y0+ry*S+sy)*W + x0+cx*S+sx)*3
                            pix[o:o+3] = bytes(fg)
    raw = b''.join(b'\x00'+bytes(pix[y*W*3:(y+1)*W*3]) for y in range(H))
    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(raw, 9))
    png += chunk(b'IEND', b'')
    open(sys.argv[2],'wb').write(png)
    print(sys.argv[2], W, 'x', H, 'mode', mode, cols, 'x', rows)

if __name__ == '__main__':
    main()
