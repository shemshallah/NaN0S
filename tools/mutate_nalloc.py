#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): mutation test. Plants 9 single-edit bugs into a COPY of nalloc.nas and requires nalloc_test.nas to stop at FAIL for each.
import sys,os,shutil,re
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import nanchk, nan16sim
def run(path):
    L,lab=nanchk.emit(path)
    s=nan16sim.Sim(b'',nwords=1<<20)
    for i,l in enumerate(L):
        n,p=nanchk.unword(l.split(';')[0].strip()); s.setw(i,n,p)
    s.run(20000000)
    return ''.join(s.out).strip().splitlines()[-1], s.steps, len(L)
src=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','src','prog')+'/'
print('clean:',run(src+'nalloc_test.nas'))
orig=open(src+'nalloc.nas').read()
muts={
 'no-next-coalesce':("ADD r5,r5,r7\nnf_prev:","nf_prev:"),
 'no-prev-coalesce':("SUB r2,r2,r7\nADD r5,r5,r7\nnf_wr:","nf_wr:"),
 'split-threshold':("MOVI r9,3\nCMP r8,r9\nJMP[LT] @na_all","MOVI r9,4\nCMP r8,r9\nJMP[LT] @na_all"),
 'rover-not-reset-in-free':("ST r2,r0,#NV_ROVER\nnf_done:","nf_done:"),
 'rover-not-advanced-on-split':("ST r6,r0,#NV_ROVER\nADD r1,r2,r13\nRET\nna_all:","ADD r1,r2,r13\nRET\nna_all:"),
 'no-wrap-in-next':("na_next:\nADD r2,r2,r7\nCMP r2,r3\nJMP[LT] @na_nw\nBOOL.12 r2,r4,r4\nna_nw:","na_next:\nADD r2,r2,r7\nna_nw:"),
 'foot-off-by-one':("ADD r6,r2,r1\nSUB r7,r6,r13\nST r9,r7,0","ADD r6,r2,r1\nST r9,r6,0"),
 'double-free-undetected':("CMP r6,r0\nJMP[EQ] @nf_bad\nSHR r5,r5,1","SHR r5,r5,1"),
 'min-size-2':("MOVI r2,3\nCMP r1,r2\nMOVI[LT] r1,3","MOVI r2,2\nCMP r1,r2\nMOVI[LT] r1,2"),
}
bad=0
for k,(a,b) in muts.items():
    assert a in orig,k
    d='/tmp/mut_'+k; os.makedirs(d,exist_ok=True)
    shutil.copy(src+'nalloc_test.nas',d); open(d+'/nalloc.nas','w').write(orig.replace(a,b,1))
    r=run(d+'/nalloc_test.nas'); caught='PASS' not in r[0]
    bad+=not caught
    print('%-28s %s  %s'%(k,'CAUGHT' if caught else 'MISSED',r[0][:60]))
print('missed',bad)
