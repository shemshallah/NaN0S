# riscv

Not implemented yet. This directory holds the placeholder and the plan.

```
draft/rv64_smoke.hex     first smoke-test bytes
```

Plan and boot contract (qemu `-M virt -bios none`, M-mode, load at 0x80000000): `spec/ARCH_ADAPTERS.md`.
The portable NaN16 self-test any new native core must pass: `src/tests/a64_test.nas`.
