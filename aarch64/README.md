# aarch64 / Android

```
native/    kan16_a64.xa64    hand-written A64 core for qemu -M virt (raw blob entered at 0x40080000)
tools/     a64.awk           minimal A64 assembler (gawk)
           a64_run.sh        assemble core + guest, run on qemu-system-aarch64, print the UART
draft/     a64_smoke.hex
android/   the phone port: C core + JNI + Kotlin app, bundled nan0s.img
```

```sh
sh aarch64/tools/a64_run.sh GUEST.nan        # needs qemu-system-aarch64
cd aarch64/android && make test              # core self-tests
cd aarch64/android && gradle :app:assembleDebug
```

Android details: `android/docs/HANDOFF.md`, `android/docs/DESIGN.md`. CI: `.github/workflows/android.yml`.
