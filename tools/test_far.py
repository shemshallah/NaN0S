#!/usr/bin/env python3
# SCAFFOLD - reference only (host test bench, not NaN/0S).
# v32: model check of JMPF/CALLF + 4M-word memory. usage: python3 tools/test_far.py
import sys,os; sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
L,_=nanchk.emit(os.path.join(os.path.dirname(__file__),'..','src/tests/far_test.nas'))
s=nan16sim.Sim(b'',nwords=1<<22,isa=1)
for i,l in enumerate(L):
    n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
s.run(10000)
out=''.join(c if isinstance(c,str) else '?' for c in s.out)
print('out',repr(out),'halted',s.halted,'trap',getattr(s,'trap',None),'steps',s.steps)
sys.exit(0 if out=='FKMN' else 1)
