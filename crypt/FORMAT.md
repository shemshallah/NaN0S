# NSPF1 file/volume container

Status: reference implementation. Product (raw NaN16) port pending.

## Header (7 x 64-bit words, little-endian)

```
0 magic         0x4E53504631 ("NSPF1")
1 version/suite (1 << 16) | suite
2 chunk_words   64 (512 bytes)
3 total_bytes
4 chunk_count   max(1, ceil(total_bytes / 512))
5 nonce0
6 nonce1
```

## Chunk

```
len_words (64-bit)
ciphertext[0..len_words)
tag[0..6)                 384-bit
```

No trailing bytes are accepted. The chunk count must be exact.

## Authentication

Per chunk, AD = header words || chunk index || len_words || chunk_bytes.
The chunk nonce is the 128-bit file nonce plus the chunk index. The tag
authenticates ciphertext, header, index and length.

Failure cases:

- header tamper -> every chunk tag fails;
- chunk reorder -> index in AD fails;
- length tamper -> AD and tag fail;
- truncation/extra bytes -> count/trailing check fails;
- wrong key -> tag fails;
- empty file -> one zero-length chunk with a valid tag.

## Suite mapping

- suite 1: NSP-7 capsule `seal`/`open` (ready, guest-gated);
- suite 2: NSP-8 capsule `seal8`/`open8` (reference, 16-round QST);
- suites 3/4/5: refused until implemented.

Internal guest milestone: 512-byte capsule round-trip PASS (64 words,
10-word AD, tag/tamper); chunked container and encrypted boot pending.

## System volume (planned)

1. Reserve the header/chunk map at a fixed volume offset.
2. Derive/release the file key from the operator key or TPM/host binding; never
   store plaintext key material.
3. Add a monotonic rollback counter to the header; check at open.
4. Bootloader/NaNFS reads and decrypts chunks into RAM; zeroize keys on exit.
5. Implement the same container in raw NaN16 (guest) and gate it before
   claiming encrypted boot.

## Non-claims

NSP-7/NSP-8 are experimental. The guest does not yet encrypt files or boot an
encrypted system. ML-KEM/Ed25519/ML-DSA/SLH-DSA are not implemented.
