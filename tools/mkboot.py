#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): build a bootable floppy image: boot sector + bare-metal nan16 kernel (8 KB) + guest words (60 KB).
# usage: mkboot.py GUEST.nas OUT.img
import sys,os,subprocess
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
root=os.path.join(os.path.dirname(__file__),'..'); N=os.path.join(root,'x86/native')
def sh(c): subprocess.run(c,shell=True,check=True)
sh('as --32 -o /tmp/b.o %s/boot.s && ld -m elf_i386 -Ttext=0x7c00 --oformat binary -o /tmp/boot.bin /tmp/b.o'%N)
sh('as --32 --defsym BARE=1 -o /tmp/k.o %s/nan16.s && ld -m elf_i386 -Ttext=0x10000 --oformat binary -o /tmp/kernel.bin /tmp/k.o'%N)
boot=open('/tmp/boot.bin','rb').read(); ker=open('/tmp/kernel.bin','rb').read()
assert len(boot)==512 and len(ker)<=8192,(len(boot),len(ker))
L,_=nanchk.emit(sys.argv[1]); s=nan16sim.Sim(b'',nwords=1<<14,isa=1)
for i,l in enumerate(L): n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
g=bytes(s.mem[:8*len(L)]); assert len(g)<=61440,len(g)
img=boot+ker.ljust(8192,b'\0')+g.ljust(61440,b'\0'); img=img.ljust(1474560,b'\0')
open(sys.argv[2],'wb').write(img); print('image',sys.argv[2],'kernel',len(ker),'bytes, guest',len(L),'words')
