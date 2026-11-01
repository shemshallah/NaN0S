#!/usr/bin/env python3
# SCAFFOLD test: trap behaviour of native core vs model (empty guest gate trap, bad ops, gate trap mid-program, HALT).
import sys,os,subprocess,tempfile
sys.path.insert(0,os.path.dirname(__file__))
import nan16sim
nat=sys.argv[1]; bad=0
def case(name,setup):
    global bad
    s=nan16sim.Sim(b'',nwords=1<<20,isa=1); setup(s); img=bytes(s.mem[:8*40])
    with tempfile.NamedTemporaryFile(delete=False) as f: f.write(img); p=f.name
    s.run(1000); r=subprocess.run([nat,p],capture_output=True); os.unlink(p)
    so=''.join(s.out).encode('latin-1'); ok=(r.stdout==so); bad+=not ok
    print('%-22s %s model=%r native=%r'%(name,'ok  ' if ok else 'FAIL',so,r.stdout))
case('empty guest',lambda s:None)
for op in (0x38,0x0E,0x1C,0x1F,0x40,0xFE): case('bad op %02X'%op,lambda s,op=op:s.setw(0,15,op<<24))
case('hole op skipped by pred',lambda s:(s.setw(0,0,0x01000001),s.setw(1,15,0x0E<<24),s.setw(2,15,0xFF<<24)))
def g(s): s.setw(0,15,0x0F<<24); s.mem[8*1+6]=0; s.mem[8*1+7]=0   # word 1 has an illegal near head
case('gate trap word 1',g)
case('big pc trap hex',lambda s:(s.setw(0,15,0x0B<<24|0),))
case('halt',lambda s:s.setw(0,15,0xFF<<24))
sys.exit(1 if bad else 0)
