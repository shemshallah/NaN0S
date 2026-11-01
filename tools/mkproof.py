#!/usr/bin/env python3
# SCAFFOLD (M4): build a nasm0 proof image and run it in the Python model of NaNVM0.
# usage: mkproof.py TARGET.nas [OUT.img] [--run] [--steps N]
# The guest gets: nasm0 + harness at word 0, minified source (4 chars/word) at SRC, the scaffold's own output as EXP/EXPC.
import sys,os,re,struct
sys.path.insert(0,os.path.dirname(__file__))
import nanchk, nan16sim
root=os.path.join(os.path.dirname(__file__),'..')
V_EXPN,V_SRCB,V_OUTB,V_LABB,V_EXPB,V_EXPCB=6290,6293,6294,6295,6296,6297
SMALL=dict(nw=8192,SRC=2048,EXP=5120,EXPC=6144,OUT=6400,LAB=7424)   # NaNVM0-sized
BIG=dict(nw=1<<20,SRC=0x40000,EXP=0x60000,EXPC=0x70000,OUT=0x80000,LAB=0xA0000)   # flat 1M-word NaN memory (8 MB), buffers far above 64K
def minify(path):
    out=[]
    for raw in nanchk.readsrc(path):
        s=raw.rstrip('\r\n'); q=False; cut=len(s)
        for i,c in enumerate(s):
            if c=='"': q=not q
            if c==';' and not q: cut=i; break
        s=s[:cut].strip()
        if s: out.append(s)
    return ('\n'.join(out)+'\n').encode()
def parse(lines):
    r=[]
    for l in lines:
        h=l.split(';')[0].strip(); r.append(nanchk.unword(h))
    return r
def build(target,L=SMALL):
    SRC,EXP,EXPC,OUT,LAB=L['SRC'],L['EXP'],L['EXPC'],L['OUT'],L['LAB']
    harn=parse(nanchk.emit(os.path.join(root,'src/prog/nasm0_proof.nas'))[0])
    exp=parse(nanchk.emit(target)[0])
    text=minify(target)+b'\0'; text+=b'\0'*(-len(text)%4)
    srcw=[struct.unpack('<I',text[i:i+4])[0] for i in range(0,len(text),4)]
    assert len(harn)<6272, 'nasm0+harness is %d words, must be < 6272 (VARS)'%len(harn)
    assert SRC+len(srcw)<=EXP, 'source %d words too big'%len(srcw)
    assert len(exp)<=EXPC-EXP
    W={}
    for i,(n,p) in enumerate(harn): W[i]=(n,p)
    for i,w in enumerate(srcw): W[SRC+i]=(10,w)
    for i,(n,p) in enumerate(exp): W[EXP+i]=(10,p)
    for j in range((len(exp)+7)//8):
        v=0
        for k in range(8):
            if 8*j+k<len(exp): v|=exp[8*j+k][0]<<(4*k)
        W[EXPC+j]=(10,v)
    W[V_EXPN]=(10,len(exp))
    for k,v in ((V_SRCB,SRC),(V_OUTB,OUT),(V_LABB,LAB),(V_EXPB,EXP),(V_EXPCB,EXPC)): W[k]=(10,v)
    assert harn and max(W)<L['nw']
    return W,len(harn),len(srcw),len(exp)
def memory(W,nw=8192):
    s=nan16sim.Sim(b'',nwords=nw)
    for i,(n,p) in W.items(): s.setw(i,n,p)
    return bytes(s.mem)
if __name__=='__main__':
    av=sys.argv[1:]
    a=[x for i,x in enumerate(av) if not x.startswith('--') and not (i>0 and av[i-1]=='--steps')]
    big='--big' in sys.argv; L=BIG if big else SMALL
    target=a[0]; W,nh,ns,ne=build(target,L)
    print('harness+nasm0 = %d words (limit %d) | source %d words | expected %d words'%(nh,6272,ns,ne))
    mem=memory(W,L['nw'])
    if len(a)>1:
        assert not big,'image output is for the 8192-word NaNVM0 layout'
        base=bytearray(open(os.path.join(root,'x86/build/base.img'),'rb').read()); base[4*512:4*512+65536]=mem; open(a[1],'wb').write(base); print('image',a[1])
    if '--run' in sys.argv:
        steps=int(sys.argv[sys.argv.index('--steps')+1]) if '--steps' in sys.argv else 200000000
        s=nan16sim.Sim(mem,nwords=L['nw']); s.run(steps)
        print('steps',s.steps,'halted',s.halted,'trap',s.trap); print(''.join(s.out))
def gen2(target):
    """M7b: run gen0 (scaffold-built seed), harvest the words the GUEST emitted at OUT, make THEM the code of gen1, run again."""
    W,nh,ns,ne=build(target); s=nan16sim.Sim(memory(W)); s.run(200000000)
    out=''.join(s.out); assert 'PASS' in out,'gen0 failed: '+out
    G={}
    for i in range(ne): G[i]=(s.nibble(6400+i),s.payload(6400+i))
    W1=dict(W)
    for i in range(nh): W1[i]=G[i]
    s1=nan16sim.Sim(memory(W1)); s1.run(200000000); o1=''.join(s1.out)
    same=all(s1.nibble(6400+i)==s.nibble(6400+i) and s1.payload(6400+i)==s.payload(6400+i) for i in range(ne))
    print('gen0 steps',s.steps,'| gen1 (guest-built code) steps',s1.steps,'|',o1.strip().splitlines()[-1],'| gen1 output == gen0 output:',same)
if __name__=='__main__' and '--gen2' in sys.argv: gen2([x for x in sys.argv[1:] if not x.startswith('--')][0])
