#!/bin/sh
# gdiff.sh IMG KEY STEPS WAIT -> compares the graphics screen (qemu `screendump` PPM) with nan_cli --dump-ppm. Uses a deterministic step clock for the C side.
IMG=$1; KEY=$2; STEPS=${3:-80000000}; WAIT=${4:-5}; D=$(mktemp -d); cd "$(dirname "$0")/.."
{ sleep $WAIT; for k in $(echo "$KEY" | tr ',' ' '); do case $k in ESC) q=esc;; ENTER) q=ret;; '~') q=shift-grave_accent;; *) q=$k;; esac; echo "sendkey $q"; sleep 3; done
  echo "screendump $D/q.ppm"; sleep 1; echo quit; } | qemu-system-i386 -m 32 -fda "$IMG" -display none -serial null -monitor stdio >/dev/null 2>&1
./nan_cli --img "$IMG" --steps "$STEPS" --keys "$KEY" --dump-ppm $D/c.ppm 2>&1 | tail -1
python3 - "$D/q.ppm" "$D/c.ppm" <<'P'
import sys
def rd(p):
    b=open(p,'rb').read(); t=b.split(None,4); w,h=int(t[1]),int(t[2]); off=len(b)-w*h*3; return w,h,b[off:]
try:
    qw,qh,q=rd(sys.argv[1]); cw,ch,c=rd(sys.argv[2])
except Exception as e: print("read fail",e); sys.exit(1)
print("qemu %dx%d  core %dx%d"%(qw,qh,cw,ch))
if (qw,qh)==(cw*2,ch*2):
    q=b"".join(q[((y*2)*qw+x*2)*3:((y*2)*qw+x*2)*3+3] for y in range(ch) for x in range(cw)); qw,qh=cw,ch
if (qw,qh)!=(cw,ch): print("SIZE DIFFER"); sys.exit(1)
import os
if os.environ.get("KEEP"):
    for n,d in (("q",q),("c",c)): open(os.environ["KEEP"]+"/"+n+".ppm","wb").write(b"P6\n%d %d\n255\n"%(qw,qh)+d)
n=sum(1 for i in range(0,len(q),3) if q[i:i+3]!=c[i:i+3]); print("pixels differing: %d of %d"%(n,qw*qh))
P
rm -rf $D
