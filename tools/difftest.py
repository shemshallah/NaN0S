#!/usr/bin/env python3
# SCAFFOLD test driver (not NaN/0S): differential test of the native core (x86/native/nan16.s) against tools/nan16sim.py.
# usage: difftest.py NATIVE_BIN PROG.nas [steps] [keybytes]   -> prints MATCH or the first difference
import sys,os,subprocess,tempfile
sys.path.insert(0,os.path.dirname(__file__))
import nanchk,nan16sim
nat,prog=sys.argv[1],sys.argv[2]; steps=int(sys.argv[3]) if len(sys.argv)>3 else 300000
keys=bytes(int(k,0) for k in sys.argv[4].split(',')) if len(sys.argv)>4 else b''
L,_=nanchk.emit(prog)
s=nan16sim.Sim(b'',nwords=1<<20,isa=1,keys=list(keys))
for i,l in enumerate(L):
    n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
img=bytes(s.mem[:8*len(L)])
with tempfile.NamedTemporaryFile(suffix='.bin',delete=False) as f: f.write(img); path=f.name
s.run(steps)
r=subprocess.run([nat,path,str(steps)],input=keys,capture_output=True,timeout=600); os.unlink(path)
so=''.join(s.out).encode('latin-1'); sv=b''.join((c&0xFFFF).to_bytes(2,'little') for c in s.vga)
ok_o=(r.stdout==so); ok_v=(r.stderr==sv)
print('%s words=%d steps=%d out=%s vga=%s trap=%s'%(os.path.basename(prog),len(L),s.steps,'ok' if ok_o else 'DIFF','ok' if ok_v else 'DIFF',s.trap))
if not ok_o: print(' sim',so[:80],'\n nat',r.stdout[:80])
if not ok_v:
    i=next(i for i in range(min(len(sv),len(r.stderr))) if sv[i]!=r.stderr[i]) if sv!=r.stderr else 0; print(' vga first diff byte',i,len(r.stderr))
sys.exit(0 if ok_o and ok_v else 1)
