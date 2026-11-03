# crypt — public encryption suite

Status: reference implementation, usable on the host for files. The product
(NaN16) port and encrypted-system boot are pending. Experimental; do not
protect real data yet.

Internal guest milestone: 512-byte capsule round-trip PASS in raw NaN16
(64 words, 10-word AD, tag/tamper). The public guest NSPF1 tool and
encrypted boot are pending.

Separate from NANNET (network manager) and NANNETSUITE (toolkit). This suite is
the encryption product: capsule AEAD, file/volume container, suite selection.

## Suites

| id | suite | status | use |
|---|---|---|---|
| 1 | NSP-7 capsule AEAD | ready (reference + guest gated) | files, capsules |
| 2 | NSP-8 capsule AEAD | reference (16-round QST) | files, capsules |
| 3 | X25519 + Ed25519 | planned | KEM/signature handshake |
| 4 | ML-KEM-768 + ML-DSA-44 | planned | PQ hybrid |
| 5 | SLH-DSA | planned | optional signature |

Suites 3/4/5 are **not implemented**; the tool refuses them. ML-KEM is absent
from the tree today; Ed25519/ML-DSA/SLH-DSA are specification targets only.

## File usage

```
sh crypt/nspfile seal <1|2> <in> <out> <keyhex> <noncehex>
sh crypt/nspfile open <in> <out> <keyhex>
```

- key: 32 bytes = 64 hex chars
- nonce: 16 bytes = 32 hex chars
- output is the NSPF1 container: authenticated header plus 512-byte chunks
- tampering, truncation, wrong keys, and planned suites are refused

Full container details: `FORMAT.md`.

Storage volumes: NSPV1 sector format, host `nspvol`, and the
NSPV guest sector decrypt cart and the ATA/fd probe for x86 HDD and Android
storage are in `STORAGE.md`.
Full container details: `FORMAT.md`.

## Host reference

`crypt/reference/nsp.cjs` contains the NSP-7/NSP-8 capsule AEAD and the NSPF1
file container. It is a **host reference**, not the product; the product port
must be raw NaN16/0xNaN.

```
node crypt/reference/nsp.cjs selftest   # CAP7-1/2, CAP8-1/2, tamper, PASS
crypt/gate.sh                           # KATs + file tests
```

## System volume

A raw volume image can be sealed as a file today. Encrypted **boot** is not
implemented: the bootloader/NaNFS path, operator/TPM key policy, rollback
counter and key zeroization are the next milestone. See `FORMAT.md` §System.

## Security notes

- NSP-7/NSP-8 are experimental constructions; no external review claim.
- The file container authenticates header, chunk index and length as AD; it
  uses per-chunk nonces derived from the file nonce and index.
- Key management is caller-supplied; the CLI does not generate, store or wipe
  keys.
- Suites 3/4/5 stay planned until their primitives, KATs and audits land.
