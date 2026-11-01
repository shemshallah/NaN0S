#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): run nasm1.nas (the NaN16 x86 emitter) over an .xa source in the Python model.
# usage: nasm1run.py SRC.xa [OUT.bin] [--steps N] [--nasm1 FILE] [--quiet]
# stdout protocol from the guest: one status line ('Y' or 'N') + newline, then the emitted bytes (PUTC 0..255).
import sys,os,struct
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
root=os.path.join(os.path.dirname(__file__),'..')
SRC=0x20000

def minify(path):
    out=[]
    for raw in open(path,encoding='latin-1'):
        s=raw.rstrip('\r\n'); q=False; cut=len(s)
        for i,c in enumerate(s):
            if c=='"': q=not q
            if c==';' and not q: cut=i; break
        s=s[:cut].strip()
        if s: out.append(s)
    return ('\n'.join(out)+'\n').encode('latin-1')

def build(srcpath,progpath=None):
    prog=progpath or os.path.join(root,'src/prog/nasm1.nas')
    L,lab=nanchk.emit(prog)
    s=nan16sim.Sim(b'',nwords=1<<20,isa=1)
    for i,l in enumerate(L):
        n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    text=minify(srcpath)+b'\0'
    text+=b'\0'*(-len(text)%4)
    for i in range(0,len(text),4):
        s.setw(SRC+i//4,10,struct.unpack('<I',text[i:i+4])[0])
    return s,len(L),len(text)

if __name__=='__main__':
    av=sys.argv[1:]
    a=[x for i,x in enumerate(av) if not x.startswith('--') and not (i>0 and av[i-1] in('--steps','--nasm1'))]
    src=a[0]; outpath=a[1] if len(a)>1 else None
    steps=int(av[av.index('--steps')+1]) if '--steps' in av else 120000000
    s,nw,nt=build(src,av[av.index('--nasm1')+1] if '--nasm1' in av else None)
    s.run(steps)
    raw=bytes(ord(c)&255 for c in s.out)
    nl=raw.find(b'\n')
    if nl<0:
        print('NO STATUS LINE (trap=%r halted=%r steps=%d bytes=%d)'%(s.trap,s.halted,s.steps,len(raw)))
        sys.exit(2)
    status=raw[:nl]; data=raw[nl+1:]
    if '--quiet' not in av:
        print('status %r  bytes %d  words %d  src %d  steps %d  halted %r  trap %r'%(
            status.decode('latin-1'),len(data),nw,nt,s.steps,s.halted,s.trap))
    if outpath:
        open(outpath,'wb').write(data)
    sys.exit(0 if status==b'Y' else 1)
