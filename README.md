<div align="center">

<img src="assets/github/nan0s-banner.svg" alt="NaN/0S" width="100%"/>

<br/>

![](https://img.shields.io/badge/-7ff8-0b0b1a?style=flat-square&labelColor=0b0b1a&color=8f9bff)
![](https://img.shields.io/badge/-%E2%96%88%E2%96%88%E2%96%88%E2%96%88-ff2bd6?style=flat-square)
![](https://img.shields.io/badge/-%E2%88%85-39ff14?style=flat-square)
![](https://img.shields.io/badge/-NaN%20!%3D%20NaN-00f0ff?style=flat-square)

*there is a number that isn't one.*
*there is an operation that isn't allowed.*
*you have been asked to put them together.*

<img src="assets/github/nan0s-rule.svg" alt="" width="100%"/>

</div>

<br/>

## `> sighting`

<div align="center">

<iframe src="https://shemshallah.github.io/NaN0S/?live=1" title="NaN/0S live (v86)" width="960" height="600"
        style="border:1px solid #23234a;border-radius:6px;max-width:100%" loading="lazy"></iframe>

<a href="https://shemshallah.github.io/NaN0S/?live=1"><img src="assets/nan0s-desktop.png" alt="NaN/0S desktop — click the screenshot to boot LIVE in your browser" width="100%"/></a>

**Click the screenshot to boot LIVE in your browser!**

<sub>the real guest floppy, executed in <a href="https://github.com/copy/v86">v86</a> (x86 → WebAssembly) — no install, no host OS underneath.</sub>
<sub>[open full screen ↗](https://shemshallah.github.io/NaN0S/?live=1) · click the screen, then <b>1–9</b> for the exhibits · <b>ESC</b> back.</sub>
<sub>GitHub's README sanitizer strips &lt;iframe&gt;, so on github.com you see the still above; in renderers that allow frames the live machine runs inline.</sub>
<sub>source <code>docs/</code> · image <code>docs/nan0s.img</code> (= <code>build/nan0s.img</code>) · host a fork: Settings → Pages → branch <code>main</code> / <code>docs</code></sub>

</div>

<details>
<summary><sub>▓ raw text render (no JS, no SVG, no mercy)</sub></summary>

```
 ███╗   ██╗ █████╗ ███╗   ██╗      ╱    ██████╗  ███████╗
 ████╗  ██║██╔══██╗████╗  ██║     ╱    ██╔═████╗ ██╔════╝
 ██╔██╗ ██║███████║██╔██╗ ██║    ╱     ██║██╔██║ ███████╗
 ██║╚██╗██║██╔══██║██║╚██╗██║   ╱      ████╔╝██║ ╚════██║
 ██║ ╚████║██║  ██║██║ ╚████║  ╱       ╚██████╔╝ ███████║
 ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╱         ╚═════╝  ╚══════╝
```

</details>

<div align="center"><img src="assets/github/nan0s-rule.svg" alt="" width="100%"/></div>

## `> manifest`

```diff
+ 1
+ 2
+ 3
- 4
- ·
- ·
! 4095
```

```
ff 00 00 00 00 08 f8 7f
```

Read it backwards. Then read it as nothing.

<div align="center"><img src="assets/github/nan0s-rule.svg" alt="" width="100%"/></div>

## `> intercepted`

> *"bits 8–34 are reserved and must be zero."*
>
> *"undefined opcodes must trap."*
>
> *"do not use floating-point arithmetic."*

Three sentences. One entire worldview. We will not elaborate.

<div align="center"><img src="assets/github/nan0s-rule.svg" alt="" width="100%"/></div>

## `> signal`

Thirteen words fell out of the build. Each one is a quiet NaN. None of them is an error.

```
7ff8002000000043
7ff8005800000030
7ff8006800000035
7ff800400000004e
7ff8005000000034
7ff800280000004b
7ff8006000000039
7ff8004800000020
7ff800100000004e
7ff800080000004b
7ff800380000004f
7ff800180000004f
7ff8003000000020
```

- no checksum
- no key
- the order is in the machine
- the message is in the rest

First to decode it, open an issue titled with what it says. We will neither confirm nor deny. We will *notice*.

<div align="center"><img src="assets/github/nan0s-rule.svg" alt="" width="100%"/></div>

## `> pieces on the table`

| | |
|:-:|---|
| 🟣 | `██████████` |
| 🟢 | `x != x` |
| 🔵 | `███ ██ ████` |
| 🟡 | a thing that reads itself |
| 🟠 | a thing that refuses to |
| 🔴 | `[ ]` ← *eventually* |
| ⚫ | the quiet part |

<div align="center"><img src="assets/github/nan0s-rule.svg" alt="" width="100%"/></div>

## `> floor plan`

```
x86/       the first body.  boot sector, kernel, the floppy image
aarch64/   the second.      an A64 core, and the Android app
riscv/     the third.       a smoke test and a promise
src/       what runs on all of them: NaN16, in NaN16
spec/      the reasoning
docs/      status, and the map of where everything went
```

<div align="center"><img src="assets/github/nan0s-rule.svg" alt="" width="100%"/></div>

## `> door`

```sh
git clone https://github.com/shemshallah/nan0s
# the door is painted on.
cd nan0s
sh x86/tools/mkall.sh     # it opens anyway. rebuilds the image, byte for byte.
qemu-system-i386 -m 32 -drive format=raw,if=floppy,file=x86/build/nan0s.img
```

phone? `aarch64/android/` builds an APK (`gradle :app:assembleDebug`) or a plain
terminal runner (`make`). start at `aarch64/android/docs/HANDOFF.md`.

the long form lives in [`docs/STATUS.md`](docs/STATUS.md) · the old-path map in [`docs/LAYOUT.md`](docs/LAYOUT.md).

⭐ if you understood any of this.
⭐⭐ if you didn't, and it bothered you.

<br/>

<div align="center">

`7ff8 ····`

**`NaN ≠ NaN`**

<sub>divide by nothing. get everything.</sub>

</div>
