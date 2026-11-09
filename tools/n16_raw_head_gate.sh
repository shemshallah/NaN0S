#!/bin/sh
# Host transport regression only. Head validity/learning remain native NaN16.
set -eu
cd "$(dirname "$0")/.."
make -C aarch64/android tests/test_core
aarch64/android/tests/test_core
# Class-preserving raw transport is distinct from the guest-instruction gate.
sh tools/n16_head_runtime_gate.sh
