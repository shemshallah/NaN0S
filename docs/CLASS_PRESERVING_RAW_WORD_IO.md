# Class-preserving NaN16 raw bank transport (C-core host boundary)

The existing `nan_write_bytes`/`nan_read_bytes` methods are **byte-corpus
payload** transport: four host bytes become one NaN16 payload, with a newly
created qNaN face. They are not safe for the native `NH_WORDS` persistent
head bank. That bank depends on both near/far NaN class faces (sNaN/qNaN
× sign), payload, generation and slot-validity checks. Losing the NaN faces
during import silently destroys class-sensitive learning state.

Two new C-core **transport-only** functions provide exact raw 8-byte NaN16
word copying:
```c
int nan_write_words_raw(nan_vm *vm, uint32_t first_guest_word,
                        const uint8_t *raw_words, size_t word_count);
int nan_read_words_raw(const nan_vm *vm, uint32_t first_guest_word,
                       uint8_t *output, size_t word_count);
```

They are not NaN16 math or head-storage implementations. They cannot
select a generation, compute a checksum, decide a head, or promote a rule;
only native `nh_open/nh_put/nh_get` and `nhr_attach/nhr_observe` do that.
The raw transport validates each extent against the 4M-word VM allocation,
with no modulo wraparound and no partial write on denial. The data length
uses **words**, each exactly **8 raw bytes**. Big-endian hosts fail closed
until an explicit serialized-endianness adapter is implemented.

The 8 MiB HERMES chart exposes the native bank at byte offset
`0x640000`, length `67,838 × 8 = 542,704 bytes`. The VM can remap these
exact bytes into its reserved guest bank word base `0x4000` (16,384),
using the raw API; it must not use `nan_write_bytes` with address units
mistakenly multiplied by four. Class bits survive transport exactly.
The guest stage registers remain outside that reserved span.

`aarch64/android/tests/test_core.c` exercises all four class-face types,
byte-for-byte bulk 542,704-byte copy, 4M-word boundary and overflow denial,
null bounds, and the chart-relative guest offset `0xC8000`. The native
runtime test separately exercises generation selection and learned
observation. Neither test alone is a live authenticated HERMES/NaNROUTER
mount or a language-learning quality measure.

Next integration contract: pin native guest/library digests; acquire the
current router lease and chart-root/generation fence; import raw bank bytes;
call guest `nh_open/nhr_attach`; execute one bounded observation; export
raw words, verify expected native generation and SHA256 change; journal
and checkpoint atomically under the caller's authorized policy. No
host-language emulation of the native checksum is permitted.
