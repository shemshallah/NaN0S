#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): mutation sweep of the cartridge seal v2. Builds an image per mutant (hooks in mkimg1.py), boots it in v86, presses key 1, and requires
# "SEAL MISMATCH" on screen for every mutant and NONE for the control. usage: TMPDIR=/tmp python3 tools/sweep_seal.py [par=5]
import subprocess,os,sys,itertools,concurrent.futures as cf
R=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def run(m):
    name,env=m; img=f"/tmp/sweep_{name}.img"
    e=dict(os.environ,TMPDIR='/tmp',**env)
    subprocess.run(['python3',f'{R}/tools/mkimg1.py',f'{R}/x86/boot/kboot0.xa',f'{R}/x86/native/kan16.xa',f'{R}/src/museum/museum.nas',img,'--cart',f'3072:{R}/src/exhibits/baby_cart.nas'],env=e,capture_output=True,check=True)
    o=subprocess.run(['node','boot.mjs',img,'10','5:02'],cwd=f'{R}/x86/harness',capture_output=True,text=True,timeout=120).stdout
    os.remove(img); return name,('SEAL MISMATCH' in o),('MANCHESTER' in o)
M=[('control',{})]
for w in (0,1,100,306,611,612):
    for b in (0,15,31): M.append((f'pay_w{w}_b{b}',dict(NAN_FLIP=str(w),NAN_BIT=str(b))))
for w in (0,300,612): M.append((f'head_w{w}',dict(NAN_HEADFLIP=str(w))))
for b in (0,16,31): M.append((f'sealbit_{b}',dict(NAN_SEALBIT=str(b))))
par=int(sys.argv[1]) if len(sys.argv)>1 else 5
bad=0
with cf.ThreadPoolExecutor(par) as ex:
    for name,refused,ran in ex.map(run,M):
        ok=(not refused and ran) if name=='control' else (refused and not ran)
        bad+=not ok; print(('PASS' if ok else 'FAIL'),name,'refused' if refused else 'loaded',flush=True)
print('MUTANTS',len(M)-1,'FAILS',bad)
