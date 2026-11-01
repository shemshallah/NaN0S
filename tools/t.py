#!/usr/bin/env python3
# SCAFFOLD test driver (not NaN/0S): boot image in v86, send keys, print the text screen.
# usage: t.py img secs "1.5:m,2.5:1,@4" ; key names: single chars, esc, enter, space, bs
import sys,subprocess,os
SC=dict(zip("1234567890",range(2,12)));SC.update({c:v for c,v in zip("qwertyuiop",range(0x10,0x1A))})
SC.update({c:v for c,v in zip("asdfghjkl",range(0x1E,0x27))});SC.update({c:v for c,v in zip("zxcvbnm",range(0x2C,0x33))})
SC.update(esc=1,enter=0x1C,space=0x39,bs=0x0E)
img,secs,plan=sys.argv[1],sys.argv[2],sys.argv[3] if len(sys.argv)>3 else ""
out="/tmp/tt"
for f in os.listdir("/tmp"):
    if f.startswith("tt") and f.endswith(".bin"): os.remove("/tmp/"+f)
pl=[]
for it in plan.split(","):
    if not it: continue
    if it[0]=="@": pl.append(it)
    else:
        t,k=it.split(":"); pl.append("%s:%02x"%(t,SC[k]))
h=os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","x86","harness")
subprocess.run(["node","cap.mjs",os.path.abspath(img),secs,out,",".join(pl)],cwd=h,check=True,capture_output=True,timeout=int(float(secs))+60)
for f in sorted(os.listdir("/tmp")):
    if f.startswith("tt") and f.endswith(".bin"):
        d=open("/tmp/"+f,"rb").read();m,c,r=d[0],d[1],d[2];b=d[3:]
        print("=== %s mode %d %dx%d"%(f,m,c,r))
        for y in range(r):
            print(''.join((chr(b[(y*c+x)*2]) if 32<=b[(y*c+x)*2]<127 else ('#' if b[(y*c+x)*2]>=127 else ' ')) for x in range(c)).rstrip())
