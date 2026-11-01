# Repository layout

```
README.md            front door
TODO.md              running work log (historical paths inside; see the map below)
assets/              README art: nan0s-desktop.png, github/nan0s-banner.svg, github/nan0s-rule.svg
docs/                STATUS.md (the long technical README), LAYOUT.md (this file)
spec/                design notes and plans
logs/                recorded evidence from past rounds
screencaps/          screenshots
src/                 NaN16 guest code. Architecture-neutral: runs on every native core.
  lib/ exhibits/ museum/ net/ prog/ tests/ tools/ translate/ vm/ puzzle/ nan/ draft/
tools/               host-side dev tools shared by every architecture
                     (mkimg.awk, nmk.awk, carts.txt, the python scaffolds)
x86/                 boot/ native/ build/ tools/ harness/ scaffold/
aarch64/             native/ tools/ draft/ android/
riscv/               draft/  (not implemented yet)
.github/workflows/   android.yml (CI for aarch64/android)
```

Everything is run from the repository root, e.g. `sh x86/tools/mkall.sh`.

## Old path -> new path

TODO.md, spec/ and logs/ are history and still use the old names. Translate with this table.

| old | new |
|---|---|
| `src/boot/*` | `x86/boot/*` |
| `src/native/kan16.xa`, `nan16_x86.nan`, `nan16.s`, `boot.s`, `r22_verified/` | `x86/native/...` |
| `src/native/kan16_a64.xa64` | `aarch64/native/kan16_a64.xa64` |
| `build/nan0s.img`, `build/base.img` | `x86/build/...` |
| `tools/mkall.sh`, `qgate.sh`, `build.sh`, `native_check.sh`, `capture_r21.sh` | `x86/tools/...` |
| `tools/harness/` (v86 test harness) | `x86/harness/` |
| `tools/scaffold/` | `x86/scaffold/` |
| `tools/a64.awk`, `tools/a64_run.sh` | `aarch64/tools/...` |
| `src/draft/a64_smoke.hex` | `aarch64/draft/a64_smoke.hex` |
| `src/draft/rv64_smoke.hex` | `riscv/draft/rv64_smoke.hex` |
| `android/` | `aarch64/android/` |
| `android/.github/workflows/android.yml` | `.github/workflows/android.yml` |
| `README.md` (technical) | `docs/STATUS.md` |

Everything else did not move. No source or data file was edited in the move: only scripts, build
config and docs had paths rewritten. `sh x86/tools/mkall.sh` rebuilds `x86/build/nan0s.img` byte-identical
to the pre-move image.

## Left out on purpose

* `android/.git` and `tools/.git` (two nested repositories; git cannot track a repo inside a repo).
* `tools/harness/node_modules` (run `npm install` in `x86/harness/` if you need the v86 harness) and `__pycache__`.
