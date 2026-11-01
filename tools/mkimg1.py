#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): bootable floppy image with boot+kernel assembled by nasm1 (NaN16 x86 emitter).
# usage: mkimg1.py BOOT.xa KERNEL.xa GUEST.nas OUT.img
import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim,nasm1run

def load_guest(path):
    if path.endswith('.nan'):
        out=[]
        for line in open(path):
            t=line.split(';')[0].strip()
            if t: out.append(t)
        return out
    return nanchk.emit(path)[0]

def asm_xa(path,steps=120000000):
    s,nw,nt=nasm1run.build(path)
    s.run(steps)
    raw=bytes(ord(c)&255 for c in s.out)
    nl=raw.find(b'\n')
    status=raw[:nl]; data=raw[nl+1:]
    if status!=b'Y':
        raise SystemExit('nasm1 error in %s (status %r)'%(path,status))
    return data

def main():
    boot_xa,ker_xa,guest_nas,out=sys.argv[1:5]
    carts=[a.split(':',1)[1] and a.split(':',1) for a in sys.argv[6:]] if len(sys.argv)>6 and sys.argv[5]=='--cart' else []
    boot=asm_xa(boot_xa); ker=asm_xa(ker_xa)
    assert len(boot)==512,len(boot)
    assert len(ker)<=8192,len(ker)
    L=load_guest(guest_nas)
    s=nan16sim.Sim(b'',nwords=1<<16,isa=1)
    for i,l in enumerate(L):
        n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    top=6400
    for k,(st,cf) in enumerate(carts):   # --cart STORE:file.nas : assembled at .org SLOT(4096), payload placed at STORE; TOC entry k (base 1024+16k): +4 start, +5 len, +8 FNV-1a/32 seal of payload words
        C=load_guest(cf); pay=C[8192:]; st=(top if st=='auto' else int(st,0)); assert st+len(pay)<=65536,'cartridge too big for store (image carries 65536 guest words)'; top=st+len(pay)
        for i,l in enumerate(pay):
            n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(st+i,n,p)
        M=0xFFFFFFFF; h=0x811C9DC5; h2=0x811C9DC5; cc=0
        def bsw(x): return int.from_bytes(x.to_bytes(4,'little'),'big')
        for i,l in enumerate(pay):
            n_,p_=nanchk.unword(l.split(';')[0].strip())
            h=((h^p_)*0x01000193)&M; h2=((h2^bsw(p_))*0x01000193)&M; cc=(((cc<<4)|(cc>>28))&M)^n_
        tb=4608+16*k; s.setw(tb+4,0,st); s.setw(tb+5,0,len(pay)); s.setw(tb+8,0,h); s.setw(tb+10,0,h2); s.setw(tb+11,0,cc)
        if k==0 and os.environ.get('NAN_FLIP'):   # test hooks: flip payload bit NAN_BIT of cart word NAN_FLIP AFTER sealing
            w=int(os.environ['NAN_FLIP']); bit=int(os.environ.get('NAN_BIT','0')); n=nanchk.unword(pay[w].split(';')[0].strip())[0]; s.setw(st+w,n,s.payload(st+w)^(1<<bit)); print('FLIPPED cart word',w,'bit',bit)
        if k==0 and os.environ.get('NAN_HEADFLIP'): w=int(os.environ['NAN_HEADFLIP']); s.mem[(st+w)*8+6]^=1; print('FLIPPED head bit of cart word',w)
        if k==0 and os.environ.get('NAN_SEALBIT'): s.setw(tb+8,0,h^(1<<int(os.environ['NAN_SEALBIT']))); print('FLIPPED seal bit',os.environ['NAN_SEALBIT'])
        L=L+[None]*max(0,top-len(L)); print('cart',cf,'store',st,'len',len(pay),'seal A %08x B %08x C %08x'%(h,h2,cc))
    L=L+[None]*max(0,4096-len(L)); g=bytes(s.mem[:8*len(L)]); assert len(g)<=524288,len(g)
    img=boot+ker.ljust(8192,b'\0')+g.ljust(524288,b'\0')
    img=img.ljust(1474560,b'\0')
    open(out,'wb').write(img)
    print('image',out,'boot',len(boot),'kernel',len(ker),'guest',len(L),'words')
main()
