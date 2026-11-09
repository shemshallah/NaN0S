# Micro-transformer plan in the one NaNVM

Status: **primitives implemented; full model/BPTT not claimed**. This is the
point-by-point path for self-modifying micro-transformers over the same NaN16
machine and 8 MiB register.

## P0 — ISA primitives (done)

- [x] `FEXP` (0x46), `FTANH` (0x47), `FLOG` (0x48) in the portable C core.
- [x] Same ops in the raw-NaN N16I guest interpreter.
- [x] Same mnemonics in the raw assembler (`tools/nmk.awk`).
- [x] Differential native/N16I gate passes (`tools/ngate_n16i.sh`).
- [x] One ISA document (`spec/NANVM_SPEC.md`), no VM2/VM3 fork.
- Existing `MUL/DIV/FADD/FSUB/FMUL/FDIV/FSQRT/FCMP/CVTIF/CVTFI`, byte/block
  moves and flat memory are the rest of the micro-transformer arithmetic.
- [x] Raw two-token forward primitive: `src/tests/micro_block.nas`
  (identity QKV, `FEXP` softmax, context mix, `FTANH` MLP).

## P1 — QKV/MLP block

- [ ] d=8 Q, K, V projection matrices in the guest heap; 2 heads of d=4.
- [ ] Causal mask and 8-step context.
- [ ] Residual + layer norm using FADD/FMUL/FSQRT/FDIV.
- [ ] MLP d=8 -> 16 -> 8 with FTANH.
- [ ] Weight/activation storage contract in the 8 MiB chart extension.
- [ ] Native/N16I parity on fixed vectors.

## P2 — BPTT

- [ ] Forward activation tape for T=8 frames in the guest heap.
- [ ] Backward Q/K/V, attention-softmax, MLP and layer-norm kernels.
- [ ] Gradient accumulation in fixed-point Q16.16 with bounded saturation.
- [ ] Gradient clipping and one optimizer step.
- [ ] Finite-difference check on scalar weights.
- [ ] Loss must decrease on a tiny copy/next-byte task; no fluency claim.

## P3 — Triad and field voting

- [ ] Per-head local loss/credit from its micro-transformer.
- [ ] 3-head local votes (2/3) and credit persistence.
- [ ] 85-triad promotion; adaptive membership only after local evidence.
- [ ] Field vote (43/85) gates global parameter/update proposals.
- [ ] Both trihead layers aggregate as one field vote against the global
  modification; 2/3 trihead and field thresholds are explicit.
- [ ] Store triad pairings as data leaves in the mirrored hypermatrix rows.

## P4 — Hypermatrix temporal frames

- [ ] Step one micro-transformer frame forward/back through the 32,640-row
  hypermatrix (not a separate model).
- [ ] Store forward/inverse frame activations and triad credits in mapped rows.
- [ ] Replay a frame sequence after restart byte-for-byte.

## P5 — Self-modification

- [ ] Each head proposes its own QKV/MLP delta.
- [ ] Local loss/credit votes; triad 2/3; field 43/85.
- [ ] Bounded update, persistent weights, rollback on failed global score.
- [ ] Frequent free self-modification bounded by a write budget and ledger.

## P6 — Evaluation

- [ ] Tiny source-disjoint next-byte task.
- [ ] Matched non-self-modifying micro-transformer control.
- [ ] Full QKV/MLP vs no-QKV/no-MLP/no-hypermatrix ablations.
- [ ] Report failures and ties; no open-domain fluency claim.

## Hard constraints

- One NaNVM, one ISA document; no forked VM2/VM3.
- Native core, N16I and assembler are updated together.
- HERMES consumes the pinned NaN0S snapshot; it does not fork the VM.
- The canonical 8 MiB chart remains the only persistent field.
- No host-only Python/PyTorch path is counted as the native result.
