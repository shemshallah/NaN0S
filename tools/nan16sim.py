#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): byte-accurate Python model of NaNVM0 for fast debugging.
# Mirrors x86/scaffold/nanvm0.s: 8-byte words, both-face gate, predication via flags, STW/ST/LDN/BSWAPM.
# NaNVM1 draft in the model: Sim(..., nwords=2**k) gives a flat k-bit word space; LD/ST/STW/BSWAPM take 32-bit register addresses, pc is 32-bit when nwords>65536 (JMPR/RET reach everywhere; JMP/CALL imm stay 16-bit).
# usage: nan16sim.py image.img [max_steps] [keys]   (guest words read from sector 4 of the image)
import sys,struct,math
M=0xFFFFFFFF
def sx(v): return v-(1<<32) if v&0x80000000 else v
def f32(bits): return struct.unpack('<f',struct.pack('<I',bits&M))[0]
def b32(x):
    try: return struct.unpack('<I',struct.pack('<f',x))[0]
    except OverflowError: return 0xFF800000 if x<0 else 0x7F800000
HEADS=[0x7FF1,0xFFF1,0x7FF8,0xFFF8]
def hc(h):
    if (h&0x7FF0)!=0x7FF0: return None
    l=h&15
    if l not in (1,8): return None
    return ((l>>3)&1)*2|(h>>15)
class Trap(Exception): pass
class Sim:
    def __init__(s,words_bytes,keys=(),nwords=8192,isa=0):
        s.isa=isa; s.maxop=0x43 if isa>=1 else 0x1F   # isa=1: NaNVM1 ops 0x20-0x37 (spec/NANVM1_SPEC.md); isa=0: frozen NaN16 v0.1
        assert nwords&(nwords-1)==0
        s.nw=nwords; s.mask=nwords-1; s.pcm=0xFFFF if nwords<=65536 else 0xFFFFFFFF
        s.mem=bytearray(8*nwords); s.mem[:len(words_bytes)]=words_bytes[:8*nwords]
        s.r=[0]*16; s.pc=0; s.fk=0; s.steps=0; s.halted=False; s.out=[]; s.keys=list(keys)
        s.vga=[0]*2000; s.fb=bytearray(64000); s.vmode=0; s.trap=None
    def word(s,i): return bytes(s.mem[(i&s.mask)*8:(i&s.mask)*8+8])
    def nibble(s,i):
        b=s.word(i); cn=hc(b[6]|b[7]<<8); cf=hc(b[0]<<8|b[1])
        return None if cn is None or cf is None else cn<<2|cf
    def payload(s,i): return struct.unpack('<I',s.word(i)[2:6])[0]
    def setw(s,i,n,p):
        o=(i&s.mask)*8; m=s.mem
        m[o+2:o+6]=struct.pack('<I',p&M)
        h=HEADS[n&3]; m[o]=h>>8; m[o+1]=h&255
        h=HEADS[n>>2&3]; m[o+6]=h&255; m[o+7]=h>>8
    def step(s):
        pc=s.pc&s.mask; s.pc=(pc+1)&s.pcm; s.steps+=1
        n=s.nibble(pc)
        if n is None: s.trap='!G%04X'%s.pc; s.halted=True; s.out.append(s.trap); return
        p=s.payload(pc); op=p>>24
        if op==0xFF: s.halted=True; return
        if op>s.maxop: s.trap='!O%04X'%s.pc; s.halted=True; s.out.append(s.trap); return
        if op!=0 and not (n>>s.fk)&1: return
        d=(p>>20)&15; a=(p>>16)&15; imm=p&0xFFFF; r=s.r; b=r[imm&15]
        def fl(z,l): s.fk=2*int(z)+int(l)
        if op==0:
            x=r[a]; y=b; res=0
            if n&1: res|=~(x|y)
            if n&2: res|=~x&y
            if n&4: res|=~y&x
            if n&8: res|=x&y
            res&=M; r[d]=res; fl(res==0,0)
        elif op==1: r[d]=imm
        elif op==2: r[d]=(r[d]&0xFFFF)|imm<<16
        elif op==3: t=r[a]+b; r[d]=t&M; fl((t&M)==0,t>M)
        elif op==4: t=r[a]-b; r[d]=t&M; fl((t&M)==0,t<0)
        elif op==5: t=(r[a]<<(imm&31))&M; r[d]=t; fl(t==0,0)
        elif op==6: t=r[a]>>(imm&31); r[d]=t; fl(t==0,0)
        elif op==7: fl(r[a]==b,r[a]<b)
        elif op==8: r[d]=s.payload((r[a]+imm)&s.mask)
        elif op==9: s.setw((r[a]+imm)&s.mask,10,r[d])
        elif op==10: s.pc=imm
        elif op==11: r[15]=s.pc; s.pc=imm
        elif op==12: s.pc=r[15]&s.pcm
        elif op==13: s.pc=r[a]&s.pcm
        elif op==15: pass
        elif op==16:
            if s.vmode:
                if r[a]<64000: s.fb[r[a]]=r[d]&255
            elif r[a]<2000: s.vga[r[a]]=r[d]&0xFFFF
        elif op==17:
            if s.vmode:
                if r[a]<64000: r[d]=s.fb[r[a]]
            elif r[a]<2000: r[d]=s.vga[r[a]]
        elif op==18: r[d]=s.keys.pop(0) if s.keys else 0
        elif op==19: r[d]=s.steps//1000
        elif op==20:
            o=((r[a]+imm)&s.mask)*8; s.mem[o:o+8]=s.mem[o:o+8][::-1]
        elif op==21: s.out.append(chr(r[d]&255))
        elif op==22: s.setw(r[a],b&15,r[d])
        elif op==23:
            nn=s.nibble((r[a]+imm)&s.mask); r[d]=M if nn is None else nn
        elif op==24: r[d]=(0x13<<16|200<<8) if s.vmode else (3<<16|25<<8|80)
        elif op==25:
            if (r[d]&255)==0x13: s.vmode=1; s.fb=bytearray(64000)
            else: s.vmode=0; s.vga=[0]*2000
        elif op==26: r[d]=s.keys.pop(0) if s.keys else 0
        elif op==27: pass
        elif op>=0x20: s.ext(op,n,d,a,imm,b)
        else: s.trap='!O%04X'%s.pc; s.halted=True; s.out.append(s.trap)
    def ext(s,op,n,d,a,imm,b):
        """NaNVM1 ops. Float = IEEE-754 binary32 carried in the 32-bit payload; results rounded to binary32 (double rounding is exact for + - * / sqrt)."""
        r=s.r; M_=M
        def fl(z,l): s.fk=2*int(z)+int(l)
        x=r[a]
        if op==0x20: t=(x*b)&M_; r[d]=t; fl(t==0,0)                          # MUL    low 32
        elif op==0x21: t=((sx(x)*sx(b))>>32)&M_; r[d]=t; fl(t==0,0)          # MULH   signed high 32
        elif op==0x22: t=((x*b)>>32)&M_; r[d]=t; fl(t==0,0)                  # MULHU  unsigned high 32
        elif op==0x23:                                                       # DIV    signed, truncating; /0 -> 0 and flags (1,1)
            if b==0: r[d]=0; s.fk=3
            else:
                q=abs(sx(x))//abs(sx(b)); q=-q if (sx(x)<0)!=(sx(b)<0) else q; t=q&M_; r[d]=t; fl(t==0,0)
        elif op==0x24:                                                       # MOD    signed, sign of dividend; %0 -> x
            if b==0: r[d]=x; s.fk=3
            else:
                m=abs(sx(x))%abs(sx(b)); m=-m if sx(x)<0 else m; t=m&M_; r[d]=t; fl(t==0,0)
        elif op==0x25:                                                       # DIVU
            if b==0: r[d]=0; s.fk=3
            else: t=x//b; r[d]=t; fl(t==0,0)
        elif op==0x26:                                                       # MODU
            if b==0: r[d]=x; s.fk=3
            else: t=x%b; r[d]=t; fl(t==0,0)
        elif op==0x27: t=(sx(x)>>(imm&31))&M_; r[d]=t; fl(t==0,0)           # SAR
        elif op==0x28: fl(x==b,sx(x)<sx(b))                                  # CMPS   signed compare
        elif op==0x29:                                                       # ADDI   d = a + sext(imm16); L=carry
            v=imm-0x10000 if imm&0x8000 else imm; t=x+(v&M_); r[d]=t&M_; fl((t&M_)==0,t>M_)
        elif op==0x2A:                                                       # LDB    d = byte at byte address r[a]+imm (4 bytes per word, little end first)
            ba=(x+imm)&M_; w=s.payload((ba>>2)&s.mask); r[d]=(w>>(8*(ba&3)))&255
        elif op==0x2B:                                                       # STB    byte store, word class becomes +q/+q
            ba=(x+imm)&M_; i=(ba>>2)&s.mask; sh=8*(ba&3); w=s.payload(i)
            s.setw(i,10,(w&~(255<<sh)&M_)|((r[d]&255)<<sh))
        elif op==0x2C: r[15]=s.pc; s.pc=x&s.pcm                              # CALLR
        elif op==0x2D:                                                       # BCOPY  mem[r[d]..+r[b]) = mem[r[a]..+r[b]) words, memmove semantics, classes preserved
            cnt=b; src=x&s.mask; dst=r[d]&s.mask
            if cnt:
                blk=bytes(s.mem[min(src,s.nw)*8:min(src+cnt,s.nw)*8]) if src+cnt<=s.nw else b''.join(s.word(src+k) for k in range(cnt))
                if dst+cnt<=s.nw: s.mem[dst*8:(dst+cnt)*8]=blk
                else:
                    for k in range(cnt): s.mem[((dst+k)&s.mask)*8:((dst+k)&s.mask)*8+8]=blk[8*k:8*k+8]
        elif op==0x2E:                                                       # BFILL  mem[r[d]..+r[b]) = +q/+q words with payload r[a]
            for k in range(b): s.setw((r[d]+k)&s.mask,10,x)
        elif op==0x2F: pass                                                  # reserved (BXOR/hash lanes)
        elif op==0x30: r[d]=b32(f32(x)+f32(b)); s.fk=0                        # FADD
        elif op==0x31: r[d]=b32(f32(x)-f32(b)); s.fk=0                        # FSUB
        elif op==0x32: r[d]=b32(f32(x)*f32(b)); s.fk=0                        # FMUL
        elif op==0x33:                                                       # FDIV   x/0 -> +-inf by IEEE
            fa,fb=f32(x),f32(b)
            if fb==0.0: r[d]=0x7FC00000 if fa==0.0 or fa!=fa else (0x7F800000 if (fa>0)==(math.copysign(1,fb)>0) else 0xFF800000)
            else: r[d]=b32(fa/fb)
            s.fk=0
        elif op==0x34:                                                       # FSQRT  d = sqrt(a); negative -> qNaN
            fa=f32(x); r[d]=b32(math.sqrt(fa)) if fa>=0 else 0x7FC00000; s.fk=0
        elif op==0x35:                                                       # FCMP   Z=eq L=lt ; unordered (NaN) -> (Z,L)=(1,1): only ALWAYS ops run
            fa,fb=f32(x),f32(b)
            if fa!=fa or fb!=fb: s.fk=3
            else: fl(fa==fb,fa<fb)
        elif op==0x36: r[d]=b32(float(sx(x))); s.fk=0                         # CVTIF  int32 -> f32 (round to nearest even)
        elif op==0x38: s.pc=((d<<20)|(a<<16)|imm)&s.pcm                      # JMPF   24-bit absolute target in d:a:imm16
        elif op==0x39: s.r[15]=s.pc; s.pc=((d<<20)|(a<<16)|imm)&s.pcm       # CALLF  r15=pc, then JMPF
        elif op==0x3A: r[d]=(320<<16|200) if s.vmode else (80<<16|25)        # FBINFO
        elif op==0x3B: pass                                                   # VSYNC (model: no-op)
        elif op==0x3C:                                                        # FBCOPY d,a,b: bytes, dst r[a], src r[b], count r[d]
            n_=r[d]&0xFFFFFFFF
            dst=r[a]; src=b
            for i in range(0,n_):
                if dst+i<64000 and src+i<64000: s.fb[dst+i]=s.fb[src+i]
        elif op==0x3D:                                                        # FBFILL d,a,b: count r[d], start r[a], colour r[b]
            n_=r[d]&0xFFFFFFFF; a0=r[a]; col=b&255
            for i in range(n_):
                if a0+i<64000: s.fb[a0+i]=col
        elif op==0x3E: pass                                                   # OUTB (model: no hardware)
        elif op==0x3F: r[d]=0                                                 # INB  (model: no hardware)
        elif op==0x40: r[d]=0                                                 # INW  (model: no hardware)
        elif op==0x41: pass                                                   # OUTW (model: no hardware)
        elif op==0x42: pass                                                   # OUTSW (model: no hardware)
        elif op==0x43: pass                                                   # OUTL (model: no hardware)
        elif op==0x37:                                                       # CVTFI  f32 -> int32, truncate toward zero, saturating; NaN -> 0
            fa=f32(x)
            if fa!=fa: t=0
            elif fa>=2147483648.0: t=0x7FFFFFFF
            elif fa<=-2147483648.0: t=0x80000000
            else: t=int(fa)&M_
            r[d]=t; fl(t==0,0)
    def run(s,maxsteps=10**7):
        while not s.halted and s.steps<maxsteps: s.step()
        return s
    def screen(s,cols=80,rows=25):
        return '\n'.join(''.join(chr(c&255) if 32<=(c&255)<127 else ' ' for c in s.vga[y*cols:(y+1)*cols]).rstrip() for y in range(rows))
def load_image(path):
    d=open(path,'rb').read(); return d[4*512:4*512+65536]
if __name__=='__main__':
    sim=Sim(load_image(sys.argv[1]),keys=[int(k,0) for k in sys.argv[3].split(',')] if len(sys.argv)>3 else ())
    sim.run(int(sys.argv[2]) if len(sys.argv)>2 else 10**7)
    print('steps',sim.steps,'halted',sim.halted,'trap',sim.trap); print(''.join(sim.out)); print(sim.screen())
