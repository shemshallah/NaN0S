#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): hand-computed encoding tests for nasm1 (the NaN16 x86 emitter).
import sys,os
sys.path.insert(0,os.path.dirname(__file__))
import nasm1run
T=os.environ.get('TMPDIR','/data/data/com.termux/files/usr/tmp/opencode')
def asm(src,steps=4000000):
    p=os.path.join(T,'n1t.xa')
    open(p,'w').write(src)
    s,nw,nt=nasm1run.build(p)
    s.run(steps)
    raw=bytes(ord(c)&255 for c in s.out)
    nl=raw.find(b'\n')
    if nl<0: return None,'trap %r'%s.trap
    if raw[:nl]!=b'Y': return None,'status N'
    return raw[nl+1:],None
CASES=[
 (".code32\nMOV $0x12345678,%EAX", "b878563412"),
 (".code32\nMOV $1,%AL", "b001"),
 (".code16\nMOV $1,%AX", "b80100"),
 (".code32\nMOV $1,%AX", "66b80100"),
 (".code32\nMOV %EAX,%EBX", "89c3"),
 (".code32\nMOV %EBX,%EAX", "89d8"),
 (".code32\nMOV [0x1234],%EAX", "a134120000"),
 (".code32\nMOV %EAX,[0x1234]", "a334120000"),
 (".code32\nMOV [0x1234],%EBX", "8b1d34120000"),
 (".code32\nMOV %EBX,[0x1234]", "891d34120000"),
 (".code32\nMOV [0x1234],%AX", "66a134120000"),
 (".code32\nMOV [EBX],%EAX", "8b03"),
 (".code32\nMOV %EAX,[EBX]", "8903"),
 (".code32\nMOV [EBX+4],%EAX", "8b4304"),
 (".code32\nMOV [EBX+0x1234],%EAX", "8b8334120000"),
 (".code32\nMOV [EBX+ECX*4],%EAX", "8b048b"),
 (".code32\nMOV [EBX+ECX*4+8],%EAX", "8b448b08"),
 (".code32\nMOV [ECX*4+0x1000],%EAX", "8b048d00100000"),
 (".code32\nADD $1,%EAX", "83c001"),
 (".code32\nADD $0x12345678,%EAX", "0578563412"),
 (".code32\nADD $0x12345678,%EBX", "81c378563412"),
 (".code32\nCMP $1,%AL", "3c01"),
 (".code32\nCMP $1,%BL", "80fb01"),
 (".code32\nTEST %EAX,%EAX", "85c0"),
 (".code32\nTEST $1,%AL", "a801"),
 (".code32\nTEST $1,%EAX", "a901000000"),
 (".code32\nINC %EAX", "40"),
 (".code32\nDEC %EBX", "4b"),
 (".code32\nINC %AL", "fec0"),
 (".code32\nDEC %AL", "fec8"),
 (".code32\nDECL [EBX]", "ff0b"),
 (".code32\nINCL [EBX]", "ff03"),
 (".code32\nDECB [EBX]", "fe0b"),
 (".code32\nSHL $1,%EAX", "d1e0"),
 (".code32\nSHL $4,%EAX", "c1e004"),
 (".code32\nSHL %CL,%EAX", "d3e0"),
 (".code32\nNEG %EAX", "f7d8"),
 (".code32\nNOT %EAX", "f7d0"),
 (".code32\nMUL %EBX", "f7e3"),
 (".code32\nIMUL %EBX", "f7eb"),
 (".code32\nIMUL %EDX,%EBX", "0fafda"),
 (".code32\nIMUL $10,%EAX", "6bc00a"),
 (".code32\nIDIV %EBX", "f7fb"),
 (".code32\nDIV %EBX", "f7f3"),
 (".code32\nLEA [EBX+ECX*4+8],%EAX", "8d448b08"),
 (".code32\nPUSH %EAX", "50"),
 (".code32\nPOP %EBX", "5b"),
 (".code32\nSETZ %AL", "0f94c0"),
 (".code32\nSETC %CL", "0f92c1"),
 (".code32\nMOVZX %AL,%EAX", "0fb6c0"),
 (".code32\nMOVSX %AL,%EAX", "0fbec0"),
 (".code32\nMOVSX %AX,%EAX", "0fbfc0"),
 (".code32\nMOVZX %AX,%EAX", "0fb7c0"),
 (".code32\nMOVD %EAX,%XMM0", "660f6ec0"),
 (".code32\nMOVD %XMM0,%EAX", "660f7ec0"),
 (".code32\nADDSS %XMM1,%XMM0", "f30f58c1"),
 (".code32\nSUBSS %XMM1,%XMM0", "f30f5cc1"),
 (".code32\nXORPS %XMM1,%XMM1", "0f57c9"),
 (".code32\nUCOMISS %XMM1,%XMM0", "0f2ec1"),
 (".code32\nCVTSI2SS %ECX,%XMM0", "f30f2ac1"),
 (".code32\nCVTTSS2SI %XMM0,%EBX", "f30f2cd8"),
 (".code32\nSHRD $16,%EDX,%EAX", "0facd010"),
 (".code32\nBT %EBX,%ECX", "0fa3d9"),
 (".code32\nBSWAP %EAX", "0fc8"),
 (".code32\nLGDT [0x1234]", "0f011534120000"),
 (".code32\nINT $0x13", "cd13"),
 (".code32\nIN $0x60,%AL", "e460"),
 (".code32\nOUT %AL,$0x60", "e660"),
 (".code32\nIN %DX,%AL", "ec"),
 (".code32\nOUT %AL,%DX", "ee"),
 (".code32\nREPSTOSD", "f3ab"),
 (".code32\nREPMOVSD", "f3a5"),
 (".code32\nCLI\nSTI\nCLD\nSTD\nHLT\nRET\nNOP\nCLC\nSTC\nCLTD", "fafbfcfdf4c390f8f999"),
 (".code16\nLJMP $8,@pm\npm:\n  HLT", "ea05000800f4"),
 (".code32\nJMP @L\nNOP\nNOP\nL:\n  HLT", "eb029090f4"),
 (".code32\nCALL @L\nL:\n  HLT", "e800000000f4"),
 (".code32\nJZ @L\nNOP\nL:\n  HLT", "740190f4"),
 (".code32\nMOV %DS,%AX", "8cd8"),
 (".code32\nMOV %AX,%DS", "8ed8"),
 (".code32\nL: HLT", "f4"),
 (".code16\nMOV %DL,[drive]\ndrive: .byte 0", "8816040000"),
 (".code32\nMOV %CR0,%EAX", "0f20c0"),
 (".code32\nMOV %EAX,%CR0", "0f22c0"),
]
fail=0
for i,(src,exp) in enumerate(CASES):
    got,err=asm(src)
    e=bytes.fromhex(exp.replace(' ',''))
    if got!=e:
        fail+=1
        print('FAIL %02d %-40r got %s want %s %s'%(i,src.replace('\n','; '),got.hex() if got else None,exp,err or ''))
print('%d/%d passed'%(len(CASES)-fail,len(CASES)))
sys.exit(1 if fail else 0)
