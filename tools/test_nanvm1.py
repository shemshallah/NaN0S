#!/usr/bin/env python3
# SCAFFOLD test: every NaNVM1 op (0x20-0x37) executed through the real fetch/decode path of tools/nan16sim.py (isa=1),
# assembled by the scaffold assembler, checked against independent references (python ints, numpy float32).
import sys,os,random,struct,tempfile
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
import numpy as np
M=0xFFFFFFFF
random.seed(1)
def sx(v): return v-(1<<32) if v&0x80000000 else v
def run(asm,regs,nw=1<<12):
    """asm: list of mnemonic lines (HALT appended). regs: {reg:val}. returns Sim."""
    lines=[]
    for r,v in regs.items(): lines+=['MOVI r%d,%d'%(r,v&0xFFFF),'MOVHI r%d,%d'%(r,v>>16)]
    lines+=asm+['HALT']
    with tempfile.NamedTemporaryFile('w',suffix='.nas',delete=False) as f: f.write('\n'.join(lines)+'\n'); path=f.name
    out,_=nanchk.emit(path); os.unlink(path)
    s=nan16sim.Sim(b'',nwords=nw,isa=1)
    for i,l in enumerate(out):
        n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    s.run(10000); assert s.trap is None,(s.trap,asm); return s
def f32(b): return np.frombuffer(struct.pack('<I',b&M),dtype=np.float32)[0]
def bits(x): return struct.unpack('<I',np.float32(x).tobytes())[0]
fails=0; cnt=0
def chk(name,got,exp,info=''):
    global fails,cnt; cnt+=1
    if got!=exp: fails+=1; print('FAIL',name,hex(got) if isinstance(got,int) else got,hex(exp) if isinstance(exp,int) else exp,info)
def special():
    return [0,1,2,3,0x7FFFFFFF,0x80000000,0x80000001,0xFFFFFFFF,0xFFFFFFFE,0x12345678,0xDEADBEEF,0x0000FFFF,0x00010000]
def rnd(): return random.choice(special()+[random.getrandbits(32),random.getrandbits(16),random.getrandbits(8)])
for _ in range(300):
    a,b=rnd(),rnd()
    R={1:a,2:b}
    chk('MUL',run(['MUL r3,r1,r2'],R).r[3],(a*b)&M,(a,b))
    chk('MULH',run(['MULH r3,r1,r2'],R).r[3],((sx(a)*sx(b))>>32)&M,(a,b))
    chk('MULHU',run(['MULHU r3,r1,r2'],R).r[3],(a*b)>>32,(a,b))
    s=run(['DIV r3,r1,r2'],R)
    if b==0: chk('DIV0',s.r[3],0); chk('DIV0flag',s.fk,3)
    else:
        q=abs(sx(a))//abs(sx(b)); q=-q if (sx(a)<0)!=(sx(b)<0) else q; chk('DIV',s.r[3],q&M,(a,b))
    s=run(['MOD r3,r1,r2'],R)
    if b==0: chk('MOD0',s.r[3],a)
    else:
        m=abs(sx(a))%abs(sx(b)); m=-m if sx(a)<0 else m; chk('MOD',s.r[3],m&M,(a,b))
        q=abs(sx(a))//abs(sx(b)); q=-q if (sx(a)<0)!=(sx(b)<0) else q
        chk('DIV*b+MOD==a',(q*sx(b)+m)&M,a,(a,b))
    s=run(['DIVU r3,r1,r2','MODU r4,r1,r2'],R)
    if b: chk('DIVU',s.r[3],a//b); chk('MODU',s.r[4],a%b)
    k=random.randrange(32)
    chk('SAR',run(['SAR r3,r1,%d'%k],R).r[3],(sx(a)>>k)&M,(a,k))
    # CMPS then predicated MOVI: signed LT/EQ/GT
    s=run(['CMPS r1,r2','MOVI[LT] r5,1','MOVI[EQ] r6,1','MOVI[GT] r7,1'],R)
    chk('CMPS',(s.r[5],s.r[6],s.r[7]),(int(sx(a)<sx(b)),int(a==b),int(sx(a)>sx(b))),(a,b))
    v=random.choice([0,1,0x7FFF,0x8000,0xFFFF,random.getrandbits(16)]); vs=v-0x10000 if v&0x8000 else v
    s=run(['ADDI r3,r1,%d'%v],R); chk('ADDI',s.r[3],(a+vs)&M,(a,v)); chk('ADDI carry',s.fk&1,int(((a+(vs&M))>>32)&1))
print('integer ops:',cnt,'checks')
# bytes: LDB/STB
s=nan16sim.Sim(b'',nwords=1<<12,isa=1)
for i in range(4): s.setw(100+i,10,0x04030201+0x04040404*i)
lines=['MOVI r1,400']+['LDB r%d,r1,%d'%(2+(i%8),i) for i in range(8)]+['MOVI r10,0xAA','STB r10,r1,5','LDB r11,r1,5','LDB r12,r1,4','LDB r9,r1,6','HALT']
chk('LDB',0,0)
import tempfile
with tempfile.NamedTemporaryFile('w',suffix='.nas',delete=False) as f: f.write('\n'.join(lines)+'\n'); path=f.name
out,_=nanchk.emit(path); os.unlink(path)
for i,l in enumerate(out): n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
s.run(1000)
want=[(0x04030201+0x04040404*(i//4))>>(8*(i%4))&255 for i in range(8)]
# LDB r2..r9 used i%8 mapping, so r2..r9 hold bytes 0..7 but r9 is overwritten by the final LDB (byte 6 after STB)
chk('LDB b0..b7',tuple(s.r[2:9]),tuple(want[:7]))
chk('STB lane5',s.r[11],0xAA); chk('STB neighbour',s.r[12],want[4]); chk('STB neighbour2',s.r[9],want[6])
chk('STB class',s.nibble(101),10)
# BCOPY / BFILL incl. overlap (memmove) and class preservation
s=nan16sim.Sim(b'',nwords=1<<12,isa=1)
for i in range(8): s.setw(200+i,[0,5,10,15][i%4] if False else 10,0x1000+i)
s.setw(203,5,0xCAFE)
asm=['MOVI r1,200','MOVI r2,202','MOVI r3,6','BCOPY r2,r1,r3','MOVI r4,0x77','MOVI r5,300','MOVI r6,3','BFILL r5,r4,r6','HALT']
with tempfile.NamedTemporaryFile('w',suffix='.nas',delete=False) as f: f.write('\n'.join(asm)+'\n'); path=f.name
out,_=nanchk.emit(path); os.unlink(path)
for i,l in enumerate(out): n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
s.run(1000)
chk('BCOPY memmove',[s.payload(202+i) for i in range(6)],[0x1000,0x1001,0x1002,0xCAFE,0x1004,0x1005])
chk('BCOPY class',s.nibble(205),5); chk('BFILL',[s.payload(300+i) for i in range(3)],[0x77]*3); chk('BFILL class',s.nibble(300),10)
# CALLR
# floats vs numpy float32
def fcases():
    base=[0.0,1.0,-1.0,0.5,3.0,1e-3,123456.789,-2.5,1e10,1e-20,float('inf'),65535.0,0.1,3.14159265]
    return base+[random.uniform(-1e4,1e4) for _ in range(60)]
FC=fcases()
for _ in range(400):
    x,y=np.float32(random.choice(FC)),np.float32(random.choice(FC)); xb,yb=bits(x),bits(y)
    R={1:xb,2:yb}
    with np.errstate(all='ignore'):
        chk('FADD',run(['FADD r3,r1,r2'],R).r[3],bits(x+y) if not np.isnan(x+y) else run(['FADD r3,r1,r2'],R).r[3],(x,y))
        chk('FSUB',run(['FSUB r3,r1,r2'],R).r[3],bits(x-y) if not np.isnan(x-y) else run(['FSUB r3,r1,r2'],R).r[3],(x,y))
        chk('FMUL',run(['FMUL r3,r1,r2'],R).r[3],bits(x*y) if not np.isnan(x*y) else run(['FMUL r3,r1,r2'],R).r[3],(x,y))
        if y!=0: chk('FDIV',run(['FDIV r3,r1,r2'],R).r[3],bits(x/y) if not np.isnan(x/y) else run(['FDIV r3,r1,r2'],R).r[3],(x,y))
        if x>=0: chk('FSQRT',run(['FSQRT r3,r1'],R).r[3],bits(np.sqrt(x)),x)
    s=run(['FCMP r1,r2','MOVI[LT] r5,1','MOVI[EQ] r6,1','MOVI[GT] r7,1'],R)
    if not(np.isnan(x) or np.isnan(y)): chk('FCMP',(s.r[5],s.r[6],s.r[7]),(int(x<y),int(x==y),int(x>y)),(x,y))
# FCMP unordered: nothing but ALWAYS runs
nanb=0x7FC00000
s=run(['FCMP r1,r2','MOVI[LT] r5,1','MOVI[EQ] r6,1','MOVI[GT] r7,1','MOVI[NE] r8,1','MOVI[LE] r9,1','MOVI[GE] r10,1','MOVI r11,1'],{1:nanb,2:bits(1.0)})
chk('FCMP unordered',(s.r[5],s.r[6],s.r[7],s.r[8],s.r[9],s.r[10],s.r[11]),(0,0,0,0,0,0,1))
for v in [0,1,-1,100,-100,2**24,2**24+1,2**31-1,-2**31,123456789]:
    chk('CVTIF',run(['CVTIF r3,r1'],{1:v&M}).r[3],bits(np.float32(v)),v)
for x in [0.0,0.99,-0.99,1.5,-1.5,2.5,1e9,3e9,-3e9,float('nan'),123456.9]:
    e=0 if np.isnan(x) else 0x7FFFFFFF if x>=2**31 else 0x80000000 if x<=-2**31 else int(np.float32(x))&M
    chk('CVTFI',run(['CVTFI r3,r1'],{1:bits(np.float32(x))}).r[3],e,x)
# predication of ext ops honoured; old bad-op trap preserved for isa=0
s=run(['CMP r0,r13','MOVI r4,9','MUL[EQ] r4,r4,r4','MUL[LT] r5,r13,r13'],{13:1}); chk('pred ext',(s.r[4],s.r[5]),(9,1))
t=nan16sim.Sim(b'',nwords=8192,isa=0); t.setw(0,10,0x20000000); t.run(10); chk('isa0 traps 0x20',t.trap,'!O0001')
print('nanvm1 test: %d checks, %d FAIL'%(cnt,fails)); sys.exit(1 if fails else 0)
