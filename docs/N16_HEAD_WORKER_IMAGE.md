# Native 255-head word-preserving guest worker

`src/nannet/n16_head_worker.nas` wraps the existing `n16_head_store.nas`
and `n16_head_runtime.nas` as a **single host-callable NaN16 image**. The
worker has no alternate Python/C learning engine, no NANNET merge and no
independent universe. Its external entry labels are exported by
`tools/nmk.awk -v CMD=emit -v LABELS=/secure/path/labels` and are to be
pinned by digest beside the guest image and VM library before attaching.

The transport must copy the HERMES chart's 67,838 raw words to guest
word index `0x4000` using a *class-preserving* 8-byte-word API. The
corpus-byte interface `nan_write_bytes` is NOT suitable. Allocate
128-word scratch at `0x1000` and 128-word readback at `0x2000`, both
disjoint from the bank and guest program.

Initial bank bootstrap has two cases: a completely zero region may be
formatted **once by native `nh_format`**, and an existing region must
pass **native `nh_open`** with no implicit reformat. Host may import,
export and hash bytes, but slot selection, checksum, class nibble and
revision remain native `nh_* / nhr_*` work.

The test gate assembles the complete worker, validates all required labels,
and actually starts the guest VM. It tests the *worker image contract*,
not a live chart attachment or language-learning gain. Separate native
`n16_head_runtime_test.nas` covers observed counter revisions and
fault recovery.

A full end-to-end attachment still requires an authenticated, single-use
NaNROUTER lease, stable HERMES parent/generation fence and verified
guest-output receipt. Do not accept the presence of this file or a
checksum as proof of those missing barriers.
