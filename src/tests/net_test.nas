JMP @main
; ---------------- code ----------------
JMP @main
.include "../net/defs.nas"
.include "../net/bytes.nas"
.include "../net/crc32.nas"
.include "../net/hex.nas"
.include "../net/b64.nas"
.include "../net/base32.nas"
.include "../net/xor.nas"
.include "../net/chunk.nas"
.include "../net/fnv.nas"
.include "../net/vec.nas"

main:
  MOVI r13,1
  MOVI r1,@crc32_tab
  CALL @crc32_mktab        ; build the CRC table (needs r13 = 1)

  ; --- CRC-32 known answer over "123456789" ---
  MOVI r1,@crc32_tab
  MOVI r2,0xFFFF
  MOVHI r2,0xFFFF          ; state = 0xFFFFFFFF
  MOVI r3,@crc_v
  SHL r3,r3,2
  MOVI r4,9
  CALL @crc32_update       ; r2 = state
  CALL @crc32_fin          ; r2 = ~state
  LA r3,0xCBF43926
  CMP r2,r3
  JMP[NE] @fail

  ; --- FNV-1a32 known answer over "foobar" ---
  MOVI r1,@fnv_v
  SHL r1,r1,2
  MOVI r2,6
  CALL @fnv32              ; r3 = hash
  LA r4,0xBF9CF968
  CMP r3,r4
  JMP[NE] @fail

  ; --- u64 tag-swap audit (spec 8): class 6 <-> 9, payload reverses ---
  MOVI r2,@audit_w
  LA r4,0xA1B2C3D4
  MOVI r1,6
  STW r4,r2,r1             ; word = class 6, payload 0xA1B2C3D4
  BSWAPM r2,0
  LDN r3,r2,0
  MOVI r5,9
  CMP r3,r5
  JMP[NE] @fail            ; class must be rot2(6) = 9
  LD r3,r2,0
  LA r5,0xD4C3B2A1
  CMP r3,r5
  JMP[NE] @fail            ; payload bytes reversed
  BSWAPM r2,0
  LDN r3,r2,0
  MOVI r5,6
  CMP r3,r5
  JMP[NE] @fail            ; class back to 6
  LD r3,r2,0
  LA r5,0xA1B2C3D4
  CMP r3,r5
  JMP[NE] @fail            ; payload restored

  ; --- byte-lane roundtrip: wrbe16 then rdbe16 of 0x1234 ---
  MOVI r1,@lane_v
  SHL r1,r1,2
  MOVI r2,0x1234
  CALL @wrbe16
  CALL @rdbe16             ; r2 == 0x1234 expected (r1 preserved by both)
  MOVI r3,0x1234
  CMP r2,r3
  JMP[NE] @fail

  ; --- the vector table (22 vectors) ---
  MOVI r1,@vtb
  CALL @vec_run            ; r5 pass, r6 fail
  CMP r6,r0
  JMP[NE] @fail

pass:
  MOVI r8,@s_pass
  SHL r8,r8,2
  CALL @vr_pstr
  HALT
fail:
  MOVI r8,@s_fail
  SHL r8,r8,2
  CALL @vr_pstr
  HALT
; ---------------- data (labels own their lines - nasm0 rule) -------------
; vector names
n_hxe1:
  .str "hxEN hello"
n_hxe2:
  .str "hxEN empty"
n_hxe3:
  .str "hxEN cap9"
n_hxd1:
  .str "hxD 012"
n_hxd2:
  .str "hxD odd"
n_hxd3:
  .str "hxD cap2"
n_b4e1:
  .str "b64E hello"
n_b4d1:
  .str "b64D hello"
n_b4e2:
  .str "b64E empty"
n_b4d2:
  .str "b64D $"
n_b4e3:
  .str "b64E a"
n_b4d3:
  .str "b64D cap4"
n_b3e1:
  .str "b32E a"
n_b3d1:
  .str "b32D ME"
n_b3d2:
  .str "b32D i1"
n_b3e2:
  .str "b32E empty"
n_xo1:
  .str "xor AB K3"
n_xo2:
  .str "xor back"
n_xo3:
  .str "xor klen0"
n_ch1:
  .str "chunk N3"
n_ch2:
  .str "chunk N300"
n_ch3:
  .str "chunk cap5"

; inputs
v_hello:
  .str "hello"
v_empty:
  .str ""
v_hexin:
  .str "303132"
v_hexodd:
  .str "30313"
v_b64in:
  .str "aGVsbG8"
v_b64bad:
  .str "$GVs"
v_a:
  .str "a"
v_b32in:
  .str "ME======"
v_b32bad:
  .str "ME1====="
v_ab:
  .str "AB"
v_key:
  .str "K3"
v_xback:
  .word 0x00007B0A       ; xor("AB", "K3") raw bytes 0A 7B
v_abcdef:
  .str "abcdef"
v_out:
  .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; expected outputs
v_hexout:
  .str "68656c6c6f"        ; hex("hello")
v_b64out:
  .str "aGVsbG8"           ; b64url("hello")
v_yq:
  .str "YQ"                ; b64url("a")
v_b32out:
  .str "ME======"          ; b32("a")
v_012:
  .str "012"               ; hexdec("303132")
v_about:
  .str "AB"                ; xor self-inverse
v_xexp:
  .word 0x00007B0A         ; xor("AB","K3") bytes 0A 7B
v_chexp:
  .word 0x63626103, 0x66656403  ; chunk("abcdef",3)

; known-answer sources
crc_v:
  .str "123456789"
fnv_v:
  .str "foobar"

; scratch
audit_w:
  .word 0
lane_v:
  .word 0

s_pass:
  .str "NET PASS"
s_fail:
  .str "NET FAIL"

; ---------------- vector table (stride 10, fn==0 sentinel) ----------------
vtb:
; hex encode
.word @he_enc, @n_hxe1, @v_hello, @v_out, 5, 32, 10, 0, 0, @v_hexout
.word @he_enc, @n_hxe2, @v_empty, @v_out, 0, 32, 0, 0, 0, @v_empty
.word @he_enc, @n_hxe3, @v_hello, @v_out, 5, 9, 0xFFF8000A, 0, 0, 0
; hex decode
.word @he_dec, @n_hxd1, @v_hexin, @v_out, 6, 32, 3, 0, 0, @v_012
.word @he_dec, @n_hxd2, @v_hexodd, @v_out, 5, 32, 0xFFF60000, 0, 0, 0
.word @he_dec, @n_hxd3, @v_hexin, @v_out, 6, 2, 0xFFF80003, 0, 0, 0
; base64url
.word @be_enc, @n_b4e1, @v_hello, @v_out, 5, 32, 7, 0, 0, @v_b64out
.word @be_dec, @n_b4d1, @v_b64in, @v_out, 7, 32, 5, 0, 0, @v_hello
.word @be_enc, @n_b4e2, @v_empty, @v_out, 0, 32, 0, 0, 0, @v_empty
.word @be_dec, @n_b4d2, @v_b64bad, @v_out, 4, 32, 0xFFF60000, 0, 0, 0
.word @be_enc, @n_b4e3, @v_a, @v_out, 1, 32, 2, 0, 0, @v_yq
.word @be_dec, @n_b4d3, @v_b64in, @v_out, 7, 4, 0xFFF80005, 0, 0, 0
; base32
.word @e32, @n_b3e1, @v_a, @v_out, 1, 32, 8, 0, 0, @v_b32out
.word @d32, @n_b3d1, @v_b32in, @v_out, 8, 32, 1, 0, 0, @v_a
.word @d32, @n_b3d2, @v_b32bad, @v_out, 8, 32, 0xFFF60000, 0, 0, 0
.word @e32, @n_b3e2, @v_empty, @v_out, 0, 32, 0, 0, 0, @v_empty
; xor chain (k1 = key word idx raw, k2 = klen)
.word @xor_ec, @n_xo1, @v_ab, @v_out, 2, 32, 2, @v_key, 2, @v_xexp
.word @xor_ec, @n_xo2, @v_xback, @v_out, 2, 32, 2, @v_key, 2, @v_about
.word @xor_ec, @n_xo3, @v_ab, @v_out, 2, 32, 0xFFFD0000, 0, 0, 0
; chunk split (k1 = N)
.word @chunk, @n_ch1, @v_abcdef, @v_out, 6, 32, 8, 3, 0, @v_chexp
.word @chunk, @n_ch2, @v_abcdef, @v_out, 6, 32, 0xFFFD0000, 300, 0, 0
.word @chunk, @n_ch3, @v_abcdef, @v_out, 6, 5, 0xFFF80008, 3, 0, 0
.word 0

