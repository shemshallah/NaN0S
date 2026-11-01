#!/usr/bin/env python3
# SCAFFOLD: run the nasm0 in-guest assembler proof (flat 1M layout) on the NATIVE core; compare with the logged model output.
# usage: proofnat.py NATIVE_BIN TARGET.nas LOGFILE
import sys,os,subprocess,tempfile,time
sys.path.insert(0,os.path.dirname(__file__))
import mkproof
nat,target,log=sys.argv[1:4]
W,nh,ns,ne=mkproof.build(target,mkproof.BIG); mem=mkproof.memory(W,mkproof.BIG['nw'])
with tempfile.NamedTemporaryFile(delete=False) as f: f.write(mem); p=f.name
t=time.time(); r=subprocess.run([nat,p],capture_output=True,timeout=900); os.unlink(p)
out=r.stdout.decode('latin-1'); ref=open(log).read()
want=[l for l in ref.splitlines() if 'PASS' in l or 'FAIL' in l or l.startswith('!')]
got=[l for l in out.splitlines() if 'PASS' in l or 'FAIL' in l or l.startswith('!')]
print(os.path.basename(target),'native %.2fs'%(time.time()-t),'| native:',got,'| logged:',want,'| MATCH' if got==want and got else '| CHECK')
