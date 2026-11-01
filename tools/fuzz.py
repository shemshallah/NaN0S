#!/usr/bin/env python3
# SCAFFOLD test (not NaN/0S): op-vector fuzz of the native core vs the Python model. Registers r3..r10 and flag probes are printed via PUTC.
# usage: fuzz.py NATIVE_BIN [count]
import sys,os,random,subprocess,tempfile,struct
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
nat=sys.argv[1]; N=int(sys.argv[2]) if len(sys.argv)>2 else 400
random.seed(7)
SP=[0,1,2,3,0x7FFFFFFF,0x80000000,0x80000001,0xFFFFFFFF,0xFFFFFFFE,0x12345678,0xDEADBEEF,0xFFFF,0x10000,0x7F800000,0xFF800000,0x7FC00000,0xFFC00000,0x7F800001,0x3F800000,0xBF800000,0x80000000,0x4F000000,0xCF000000,0x4EFFFFFF,0x00000001,0x7FC00123]
def rnd(): return random.choice(SP+[random.getrandbits(32),random.getrandbits(16),random.getrandbits(8),struct.unpack('<I',struct.pack('<f',random.uniform(-1e4,1e4)))[0]])
OPS3=['ADD','SUB','MUL','MULH','MULHU','DIV','MOD','DIVU','MODU','FADD','FSUB','FMUL','FDIV']+['BOOL.%d'%i for i in range(16)]
OPS2=['SHL','SHR','SAR','ADDI']; OPS1=['FSQRT','CVTIF','CVTFI']; CMPS=['CMP','CMPS','FCMP']
def prog(op,a,b):
    L=[]
    for r,v in ((1,a),(2,b)): L+=['MOVI r%d,%d'%(r,v&0xFFFF),'MOVHI r%d,%d'%(r,v>>16)]
    base=op.split('.')[0]
    if op in OPS3: L.append('%s r3,r1,r2'%op)
    elif op in OPS2: L.append('%s r3,r1,%d'%(op,b&0x1F if op!='ADDI' else b&0xFFFF))
    elif op in OPS1: L.append('%s r3,r1'%op)
    else: L.append('%s r1,r2'%op)
    for i,pn in enumerate(['LT','EQ','GT','NE','LE','GE']): L.append('MOVI[%s] r%d,%d'%(pn,5+i,1+i))
    L+=['MOVI r4,77','MOVI[ALWAYS] r11,5']
    for r in (3,5,6,7,8,9,10,11):
        for k in range(4): L+=['SHR r12,r%d,%d'%(r,8*k),'PUTC r12']
    L.append('HALT'); return L
fails=0; cnt=0
allops=OPS3+OPS2+OPS1+CMPS
for it in range(N):
    op=allops[it%len(allops)]; a,b=rnd(),rnd()
    with tempfile.NamedTemporaryFile('w',suffix='.nas',delete=False) as f: f.write('\n'.join(prog(op,a,b))+'\n'); pth=f.name
    L,_=nanchk.emit(pth)
    s=nan16sim.Sim(b'',nwords=1<<20,isa=1)
    for i,l in enumerate(L): n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    img=bytes(s.mem[:8*len(L)]); open(pth,'wb').write(img)
    s.run(100000)
    r=subprocess.run([nat,pth],capture_output=True,timeout=20); os.unlink(pth)
    cnt+=1; so=''.join(s.out).encode('latin-1')
    if so!=r.stdout:
        fails+=1
        if fails<=12: print('FAIL',op,hex(a),hex(b),'\n sim',so.hex(),'\n nat',r.stdout.hex(), s.trap)
print('fuzz: %d vectors, %d FAIL'%(cnt,fails)); sys.exit(1 if fails else 0)
