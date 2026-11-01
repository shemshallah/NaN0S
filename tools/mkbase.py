#!/usr/bin/env python3
# SCAFFOLD: base floppy = boot sector + NaNVM0 (sector 2..3); guest words are added by nanchk.py image.
b=open('x86/scaffold/boot0.bin','rb').read(); v=open('x86/scaffold/nanvm0.bin','rb').read()
assert len(v)<=1536
img=bytearray(1474560); img[0:len(b)]=b; img[510]=0x55; img[511]=0xAA; img[512:512+len(v)]=v
open('x86/build/base.img','wb').write(img)
hexl=lambda d,h:[h]+[' '.join('%02x'%x for x in d[i:i+16])+'   ; +%04x'%i for i in range(0,len(d),16)]
open('src/vm/nanvm0.nan','w').write('\n'.join(hexl(v,'; NaNVM0 native boundary (NaN16 + DISPQ/DISPSET); bytes from x86/scaffold/nanvm0.s, objdump-verified'))+'\n')
