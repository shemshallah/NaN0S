#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): mnemonic -> NNNN_PPPPPPPP_FFFF hex words, and decode-check of the hex back to mnemonics.
# usage: nanchk.py emit src.nas out.nan | check out.nan | image out.nan img
import sys,re,struct
OPS=dict(BOOL=0,MOVI=1,MOVHI=2,ADD=3,SUB=4,SHL=5,SHR=6,CMP=7,LD=8,ST=9,JMP=10,CALL=11,RET=12,JMPR=13,NOP=15,VPOKE=16,VPEEK=17,KEY=18,TICK=19,BSWAPM=20,PUTC=21,STW=22,LDN=23,DISPQ=24,DISPSET=25,KEYQ=26,BEEP=27,MUL=32,MULH=33,MULHU=34,DIV=35,MOD=36,DIVU=37,MODU=38,SAR=39,CMPS=40,ADDI=41,LDB=42,STB=43,CALLR=44,BCOPY=45,BFILL=46,FADD=48,FSUB=49,FMUL=50,FDIV=51,FSQRT=52,FCMP=53,CVTIF=54,CVTFI=55,JMPF=56,CALLF=57,FBINFO=58,VSYNC=59,FBCOPY=60,FBFILL=61,OUTB=62,INB=63,INW=64,OUTW=65,OUTSW=66,OUTL=67,CPUID=68,RDTSC=69,HALT=255)
FORM=dict(BOOL='dab',ADD='dab',SUB='dab',STW='dab',MOVI='di',MOVHI='di',SHL='dai',SHR='dai',LD='dai',ST='dai',LDN='dai',CMP='ab',JMP='i',CALL='i',RET='',NOP='',HALT='',JMPR='a',KEY='d',DISPQ='d',DISPSET='d',KEYQ='d',BEEP='d',TICK='d',PUTC='d',VPOKE='da',VPEEK='da',BSWAPM='ai',MUL='dab',MULH='dab',MULHU='dab',DIV='dab',MOD='dab',DIVU='dab',MODU='dab',SAR='dai',CMPS='ab',ADDI='dai',LDB='dai',STB='dai',CALLR='a',BCOPY='dab',BFILL='dab',FADD='dab',FSUB='dab',FMUL='dab',FDIV='dab',FSQRT='da',FCMP='ab',CVTIF='da',CVTFI='da',JMPF='j',CALLF='j',FBINFO='d',VSYNC='',FBCOPY='dab',FBFILL='dab',OUTB='da',INB='da',INW='da',OUTW='da',OUTSW='dab',OUTL='da',CPUID='dab',RDTSC='da')
PRED=dict(ALWAYS=15,NEVER=0,EQ=4,NE=3,LT=2,GE=5,GT=1,LE=6)
NEAR=[0x7FF1,0xFFF1,0x7FF8,0xFFF8]; FAR=[0xF17F,0xF1FF,0xF87F,0xF8FF]
def word(n,p): return "%04X_%08X_%04X"%(NEAR[n>>2],p&0xFFFFFFFF,FAR[n&3])
def unword(s):
    a,p,f=s.split('_'); a=int(a,16);f=int(f,16);p=int(p,16)
    return NEAR.index(a)<<2|FAR.index(f),p
def dis(n,p):
    op,d,a,imm=p>>24,(p>>20)&15,(p>>16)&15,p&0xFFFF
    nm=[k for k,v in OPS.items() if v==op][0]
    if nm=='BOOL': return "BOOL.%d r%d,r%d,r%d"%(n,d,a,imm&15)
    pr=[k for k,v in PRED.items() if v==n]; pr='[%s]'%(pr[0] if pr else 'n%d'%n) if n!=15 else ''
    f=FORM[nm]; parts={'d':'r%d'%d,'a':'r%d'%a,'b':'r%d'%(imm&15),'i':str(imm),'j':str(p&0xFFFFFF)}
    if nm=='CMP': parts['b']='r%d'%(imm&15)
    ops=[parts[c] for c in f]
    if nm in('STW','MUL','MULH','MULHU','DIV','MOD','DIVU','MODU','BCOPY','BFILL','FADD','FSUB','FMUL','FDIV'): ops=['r%d'%d,'r%d'%a,'r%d'%(imm&15)]
    return nm+pr+(' '+','.join(ops) if ops else '')
import os
def readsrc(path):
    out=[]
    for raw in open(path):
        t=raw.split(';')[0].strip()
        if t.startswith('.include'):
            out+=readsrc(os.path.join(os.path.dirname(path),re.search(r'"(.*)"',t).group(1)))
        else: out.append(raw)
    return out
def ev(x,lab,EQU):
    """expression: terms joined by + or -; term = number | @label | #EQU"""
    import re as _re
    tot=0
    for sign,term in _re.findall(r'([+-]?)\s*([^+-]+)',x.replace(' ','')):
        t=term.strip()
        v=lab[t[1:]] if t[0]=='@' else EQU[t[1:]] if t[0]=='#' else int(t,0)
        tot+= -v if sign=='-' else v
    return tot
def emit(src):
    lines=[];lab={};items=[];EQU={}
    for raw in readsrc(src):
        t=raw.split(';')[0].strip()
        if not t: continue
        m=re.match(r'(\w+):$',t)
        if m: lab[m.group(1)]=len(items);continue
        if t.startswith('.equ'):
            _,k,v=t.split(None,2); EQU[k]=int(v.split()[0],0); continue
        if t.startswith('.org'):
            tgt=int(t.split()[1],0); assert tgt>=len(items),'.org backwards at %d'%len(items)
            while len(items)<tgt: items.append(('data',0,'pad'))
            continue
        if t.startswith('.str'):
            s=re.search(r'"(.*)"',t).group(1).encode().decode('unicode_escape').encode('latin1')+b'\0'
            s+=b'\0'*(-len(s)%4)
            for i in range(0,len(s),4): items.append(('data',struct.unpack('<I',s[i:i+4])[0],'str %r'%s[i:i+4]))
            continue
        if t.startswith('.word'):
            for w in [x.strip() for x in t[5:].split(',') if x.strip()]: items.append(('data',('EXPR',w),'word'))
            continue
        ml=re.match(r'LA(?:\[(\w+)\])?\s+r(\d+)\s*,\s*(.+)$',t)
        if ml:
            pn=PRED[ml.group(1)] if ml.group(1) else 15
            items.append(('la',int(ml.group(2)),ml.group(3).strip(),0,pn)); items.append(('la',int(ml.group(2)),ml.group(3).strip(),1,pn)); continue
        items.append(('ins',t))
    out=[]
    for it in items:
        if it[0]=='la':
            v=ev(it[2],lab,EQU)&0xFFFFFFFF; p=(OPS['MOVHI']<<24|it[1]<<20|(v>>16)) if it[3] else (OPS['MOVI']<<24|it[1]<<20|(v&0xFFFF))
            out.append((it[4],p,dis(it[4],p)));continue
        if it[0]=='data':
            v=ev(it[1][1],lab,EQU) if isinstance(it[1],tuple) else it[1]
            out.append((10,v&0xFFFFFFFF,it[2]));continue
        t=it[1];m=re.match(r'(\w+)(?:\.(\d+)|\[(\w+)\])?\s*(.*)$',t);nm,bn,pr,rest=m.groups()
        n=int(bn) if bn else PRED[pr] if pr else 15
        args=[x.strip() for x in rest.split(',')] if rest else []
        def num(x): return ev(x,lab,EQU)
        d=a=imm=0
        for c,x in zip(FORM[nm],args):
            if c=='d': d=int(x[1:])
            elif c=='a': a=int(x[1:])
            elif c=='b': imm=int(x[1:])
            elif c=='j': tj=num(x)&0xFFFFFF; d=tj>>20; a=(tj>>16)&15; imm=tj&0xFFFF
            else: imm=num(x)
        if nm=='MOVI' and imm>0xFFFF: raise SystemExit('MOVI immediate %d does not fit 16 bits (use LA): %s'%(imm,t))
        if nm=='CMP': pass
        p=OPS[nm]<<24|d<<20|a<<16|(imm&0xFFFF)
        out.append((n,p,dis(n,p)))
    return [word(n,p)+"   ; %03d %s"%(i,c) for i,(n,p,c) in enumerate(out)],lab
def check(f):
    bad=0
    for l in open(f):
        if l.startswith(';') or not l.strip(): continue
        h,c=l.split(';');i,txt=c.strip().split(' ',1);n,p=unword(h.strip())
        if txt.startswith('str') or txt=='word': continue
        if dis(n,p).replace(' ','')!=txt.replace(' ','').replace('BOOL.','BOOL.'): bad+=1;print("MISMATCH",i,dis(n,p),'<>',txt)
    print("check: %d mismatches"%bad); return bad
if __name__=='__main__':
    c=sys.argv[1]
    if c=='emit':
        L,lab=emit(sys.argv[2]);open(sys.argv[3],'w').write("; NaN16 guest program, generated by scaffold from mnemonics; word index in comments\n"+'\n'.join(L)+'\n');print(len(L),'words',lab)
    elif c=='check': sys.exit(1 if check(sys.argv[2]) else 0)
    elif c=='image':
        g=b''
        for l in open(sys.argv[2]):
            if l.startswith(';') or not l.strip(): continue
            n,p=unword(l.split(';')[0].strip());a,pp,f=l.split(';')[0].strip().split('_')
            g+=struct.pack('<HIH'[0:0] or '<QQ'[0:0] or '<H',int(f,16))+struct.pack('<I',int(pp,16))+struct.pack('<H',int(a,16))
        img=bytearray(open(sys.argv[4] if len(sys.argv)>4 else 'base.img','rb').read()); assert len(g)<=65536,'guest > 8192 words'; img[4*512:4*512+len(g)]=g
        open(sys.argv[3],'wb').write(img);print(len(g)//8,'words in image')
