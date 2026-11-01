#!/usr/bin/env python3
# SCAFFOLD: differential test. Same image run natively and under n16i.nas on the Python NaN16 model (isa=1).
import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
root=os.path.join(os.path.dirname(__file__),'..')
def build(src,nw=16384):
    lines,lab=nanchk.emit(src)
    s=nan16sim.Sim(b'',nwords=nw,isa=1)
    for i,l in enumerate(lines):
        n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    return s,lab
def run(src,mode,gsel,badhead=False,maxsteps=400000000):
    s,lab=build(src)
    s.setw(lab['mode'],10,mode); s.setw(lab['gsel'],10,gsel)
    if badhead:
        o=lab['gbad']*8; s.mem[o+6]=0; s.mem[o+7]=0
    s.run(maxsteps); return s,lab
if __name__=='__main__':
    src=os.path.join(root,'src/tests/n16i_test.nas'); bad=0
    for name,gsel,bh in (('suite',0,False),('gate trap',1,True),('bad-op trap',2,False)):
        a,lab=run(src,0,gsel,bh); b,_=run(src,1,gsel,bh)
        oa=''.join(a.out); ob=''.join(b.out); ok=(oa==ob) and a.halted and b.halted
        gs=b.payload(lab['res_steps'])
        print('%-12s native steps %8d | interp host steps %10d | guest steps reported %8d | out %5d chars | %s'%(name,a.steps,b.steps,gs,len(oa),'MATCH' if ok else 'MISMATCH'))
        if not ok:
            bad+=1; print('--native--\n'+oa[:600]+'\n--interp--\n'+ob[:600])
        if gsel==0: print('   tail:',repr(oa[-40:]))
        else: print('   out:',repr(oa))
        if gs!=a.steps-4 and gsel==0: print('   (note: guest step count %d vs native total %d, driver overhead expected)'%(gs,a.steps))
    ns=os.path.join(root,'src/tests/n16i_nest.nas'); outs=[]
    for m in (0,1,2):
        s,lab=build(ns); s.setw(lab['mode'],10,m); s.run(2*10**9); outs.append(''.join(s.out))
        print('nest depth %d: host steps %10d | %s'%(m,s.steps,'halted' if s.halted else 'RUNNING'))
    ok=outs[0]==outs[1]==outs[2] and 'sum of squares' in outs[0]
    print('nested outputs identical (native / 1 level / 2 levels):',ok); print(outs[2],end='')
    bad+= (not ok)
    print('RESULT','PASS' if not bad else 'FAIL'); sys.exit(bad)
