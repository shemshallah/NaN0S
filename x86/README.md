# x86

Bare-metal 32-bit x86: a 512-byte boot sector, a ~5.8 KB native kernel, and the NaN16 guest on top.

```
boot/      boot0.nan, kboot0.xa      boot sector
native/    kan16.xa, nan16_x86.nan   the kernel (source + gold bytes); nan16.s, boot.s = retired reference
build/     nan0s.img, base.img       1,474,560-byte floppy image + scaffold input for nasm0 proofs
tools/     mkall.sh, qgate.sh, ...   run from the repo root
harness/   v86 JS harness (retired)  scaffold/  boot0.s, nanvm0.s
```

```sh
sh x86/tools/mkall.sh          # build x86/build/nan0s.img
sh x86/tools/qgate.sh          # headless boot gate (needs qemu-system-i386)
qemu-system-i386 -m 32 -drive format=raw,if=floppy,file=x86/build/nan0s.img
```
