#!/usr/bin/env python3
# SCAFFOLD (host test bench, not NaN/0S): assemble a cart with nanchk, run it in nan16sim, write a PNG of the framebuffer.
# usage: guitest.py cart.nas out.png [max_steps] [keys comma sep, 'tN' = run N more steps]
import sys,os,zlib,struct
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
PAL=[(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,170,170),(85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]
def png(fb,path,sc=2):
    W,H=320,200
    rows=[]
    for y in range(H):
        row=b''.join(bytes(PAL[fb[y*W+x]&15])*sc for x in range(W))
        rows+= [b'\x00'+row]*sc
    raw=b''.join(rows)
    def ch(t,b): return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b)&0xffffffff)
    open(path,'wb').write(b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',W*sc,H*sc,8,2,0,0,0))+ch(b'IDAT',zlib.compress(raw,9))+ch(b'IEND',b''))
def build(src):
    L=nanchk.emit(src)[0]
    s=nan16sim.Sim(b'',nwords=1<<15,isa=1)
    for i,l in enumerate(L):
        n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    s.pc=8192
    return s,len(L)
def build2(src):
    r=nanchk.emit(src); L=r[0]; lab=r[1] if isinstance(r[1],dict) else {}
    s,n=build(src); return s,n,lab
def idle(s,lab,limit=20000000):
    a=lab.get('g_tick'); t=s.steps+limit
    # run until the main loop reaches the no-key branch with an empty key queue
    while not s.halted and s.steps<t:
        s.step()
        if s.pc==a and not s.keys: break
if __name__=='__main__':
    src,out=sys.argv[1],sys.argv[2]
    plan=sys.argv[3].split(',') if len(sys.argv)>3 and sys.argv[3] else []
    s,n,lab=build2(src); print('words',n,'labels',len(lab))
    idle(s,lab)
    for it in plan:
        if it.startswith('t'):
            tgt=s.steps+int(it[1:])
            while not s.halted and s.steps<tgt: s.step()
            idle(s,lab)
        elif it.startswith('s'):   # string of ascii keys, \n=13
            for ch in it[1:].replace('_',' '): s.keys.append(13 if ch=='~' else ord(ch))
            idle(s,lab)
        else:
            s.keys.append(int(it,0)); idle(s,lab)
    print('steps',s.steps,'halted',s.halted,'trap',s.trap,'pc',s.pc,'out',''.join(s.out)[:80])
    png(s.fb,out)
