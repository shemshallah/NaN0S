# HANDOFF (r5, 1 Nov 2026) - work in progress, for the next Claude

## Goal
Run nan0s on Android: (a) APK built by GitHub Actions, (b) Termux with nan_cli (no APK needed).
The bundled image app/src/main/assets/nan0s.img is the r28d build, so nothing else has to be downloaded for the app itself.

## Verified in the sandbox this round (no Android SDK available there)
- Kotlin: ALL files under app/src/main/java type-check with kotlinc 2.0.21 against android.jar (API 33): zero errors.
- C core + JNI compile warning-free with clang (zig cc, -Wall -Wextra) for x86_64, aarch64, armv7.
- `make test`: 866 checks, 0 failures; `make asan`: same under ASan/UBSan.
- Host JNI test (host-test/HostTest.kt over the real .so): HOST TEST PASS.

## NOT verified (do these first)
1. Gradle / AGP 8.5.2 / CMake / AAPT / manifest never ran. Push the tree to GitHub, open the `android` Actions run, fix what it reports. Artifact: app-debug.apk.
2. No gradle wrapper in the tree. Workflow uses setup-gradle 8.9 and plain `gradle`. For Android Studio add one: `gradle wrapper --gradle-version 8.9`.
3. Nothing has run on a real phone: AudioTrack beeper, soft keyboard (TYPE_NULL), text glyphs (box/block chars use the device font; draw 0xB0-0xDF procedurally if they look wrong), key row layout.
4. DONE: merged as aarch64/android/; the workflow is at the repo root (.github/workflows/android.yml) and runs with working-directory aarch64/android.

## Remaining work (priority order)
- Fix whatever the first Actions run reports.
- Disk fd leak: MainActivity uses pfd.detachFd() and never closes it. Keep the ParcelFileDescriptor, pass pfd.fd, close after vm.detachDisk() and in onDestroy.
- tools/nan_cli.c is missing --tty, --save/--load, --trace, --ports, --selftest (APIs exist; see TODO.md item 5). --tty matters: it is the no-APK way to test on a phone in Termux.
- Procedural CP437 box/block glyphs in NanView (0xB0-0xDF).
- Fuzz widening and qemu gates (TODO.md items 2-4) need gawk + qemu-system-i386, which the sandbox lacked.
- Update docs/DESIGN.md "Files (planned)" to match reality.

## What the user needs to download
- To get the APK: nothing locally. Create a GitHub repo, push this folder, download the apk artifact from the Actions run, install on the phone (allow "install unknown apps").
- To build locally: Android Studio Koala (2024.1.1) or newer (brings the SDK, NDK, CMake 3.22.1, JDK 17).
- Termux path (no APK): `pkg install clang make`, then `make` and `./nan_cli --img app/src/main/assets/nan0s.img --dump-text --keys "1" --steps 5000000`. For an interactive screen, nan_cli needs --tty (not written yet).
- Optional for the oracle tests on a PC: gawk, xxd, qemu-system-i386.
