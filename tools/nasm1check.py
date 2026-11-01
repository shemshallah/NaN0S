#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): verify nasm1 (the NaN16 x86 emitter) against the gold bytes + encoding suite.
import sys,os,subprocess
sys.path.insert(0,os.path.dirname(__file__))
import nasm1run
root=os.path.join(os.path.dirname(__file__),'..')

def gold():
    toks=[]
    for line in open(os.path.join(root,'x86/native/nan16_x86.nan')):
        toks += line.split(';')[0].split()
    return bytes(int(t,16) for t in toks)

def asm(path,steps=120000000):
    s,nw,nt=nasm1run.build(path)
    s.run(steps)
    raw=bytes(ord(c)&255 for c in s.out)
    nl=raw.find(b'\n')
    st,data=raw[:nl],raw[nl+1:]
    assert st==b'Y',(path,st)
    return data

def main():
    g=gold()
    boot=asm(os.path.join(root,'x86/boot/kboot0.xa'))
    ker=asm(os.path.join(root,'x86/native/kan16.xa'))
    ok=True
    print('gold: %d bytes (boot 512 + kernel %d)'%(len(g),len(g)-512))
    print('boot  : %d bytes  %s'%(len(boot),'IDENTICAL' if boot==g[:512] else 'DIFF'))
    ok = ok and boot==g[:512]
    print('kernel: %d bytes  %s'%(len(ker),'IDENTICAL' if ker==g[512:] else 'DIFF'))
    ok = ok and ker==g[512:]
    r=subprocess.run([sys.executable,os.path.join(root,'tools/nasm1_tests.py')])
    ok = ok and r.returncode==0
    print('RESULT:', 'PASS' if ok else 'FAIL')
    sys.exit(0 if ok else 1)
main()
