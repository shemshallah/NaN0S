import sys,json,subprocess,os
# SCAFFOLD - reference only (host test bench, not NaN/0S).
sys.path.insert(0,'tools')
import nanchk,nan16sim
prog,img=sys.argv[1],sys.argv[2]; steps=int(sys.argv[3]) if len(sys.argv)>3 else 10**7
L,_=nanchk.emit(prog); s=nan16sim.Sim(b'',nwords=1<<20,isa=1)
for i,l in enumerate(L): n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
s.run(steps); want=''.join(s.out)
r=subprocess.run(['node','boot.mjs',img,sys.argv[4] if len(sys.argv)>4 else '12'],cwd=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','x86','harness'),capture_output=True,text=True)
got=json.loads(r.stdout.split('SERIAL: ',1)[1].split('\n',1)[0])
print('model out == v86 bare-metal serial:',want==got,len(want),len(got)); 
if want!=got: print(repr(want[-120:]),'\n',repr(got[-120:]))
else: print(repr(got[-90:]))
