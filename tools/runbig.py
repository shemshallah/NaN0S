#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): run a .nas program in the Python model of the flat 1M-word NaN memory (no native VM exists yet). Prints guest output.
# usage: runbig.py PROG.nas [--isa1] [--steps N]   (--isa1 enables NaNVM1 ops 0x20-0x37)
import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
a=sys.argv[1:]; L,lab=nanchk.emit(a[0])
s=nan16sim.Sim(b'',nwords=1<<20,isa=1 if '--isa1' in a else 0)
for i,l in enumerate(L):
    n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
s.run(int(a[a.index('--steps')+1]) if '--steps' in a else 200000000)
print('words',len(L),'steps',s.steps,'halted',s.halted,'trap',s.trap); print(''.join(s.out))
