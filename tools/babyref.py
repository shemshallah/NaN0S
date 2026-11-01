#!/usr/bin/env python3
# SCAFFOLD reference model of the Manchester Baby (SSEM) used only to verify the program words before porting to NaN16.
# Words are 32-bit; bits 0-4 operand line S, bits 13-15 function F: 0 JMP,1 JRP,2 LDN,3 STO,4/5 SUB,6 CMP,7 STP. CI is incremented BEFORE fetch.
M=0xFFFFFFFF
def neg(x): return (-x)&M
def ins(f,s): return (f<<13)|s
def program(N):
    st=[0]*32
    L=dict(one=21,negN=22,d=23,nd=24,t=25,tmp=26,jchk=27,jin=28,jnext=29)
    code=[ # line, F, S
     (1,2,L['nd']),(2,4,L['one']),(3,3,L['d']),(4,2,L['d']),(5,3,L['nd']),(6,2,L['negN']),(7,3,L['t']),
     (8,2,L['t']),(9,4,L['nd']),(10,3,L['tmp']),(11,2,L['tmp']),(12,3,L['t']),(13,2,L['t']),(14,6,0),
     (15,0,L['jchk']),(16,0,L['jin']),(17,4,L['one']),(18,6,0),(19,0,L['jnext']),(20,7,0)]
    for ln,f,s in code: st[ln]=ins(f,s)
    st[L['one']]=1; st[L['negN']]=neg(N); st[L['d']]=N; st[L['nd']]=neg(N)
    st[L['jchk']]=16; st[L['jin']]=7; st[L['jnext']]=0
    return st,L
def run(st,maxsteps=10**9):
    A=0;CI=0;n=0
    while n<maxsteps:
        CI=(CI+1)&M; w=st[CI&31]; S=w&31; F=(w>>13)&7; n+=1
        if F==0: CI=st[S]
        elif F==1: CI=(CI+st[S])&M
        elif F==2: A=neg(st[S])
        elif F==3: st[S]=A
        elif F in(4,5): A=(A-st[S])&M
        elif F==6:
            if A>>31: CI=(CI+1)&M
        else: return st,n
    return st,n
if __name__=='__main__':
    for N in (12,100,1024,2**12,2**18):
        st,L=program(N); st,n=run(st); print(N,'-> highest proper factor',st[L['d']],'in',n,'Baby instructions')
