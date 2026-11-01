; crc32.nas - CRC-32/ISO-HDLC (poly 0xEDB88320 reflected). Used by the
; frame/pcap/eth-FCS faces of the spec (0x0D01 PCAP_FILE headers and the
; image CRC of section 6 use this exact word).
; crc = 0xFFFFFFFF at start, complemented at the end (RFC 1952 face).
;
; Table: 256 words pre-filled with zero data below; crc32_mktab fills it.
; Word address aligns NO offset; entry i lives at word (tab + i); ST/LD
; default-class words hold the value in the 32-bit payload.
;
; crc32_mktab: r1 = table word base (r1 kept); fills 256 words; leaf.
; crc32_update: r1 = tab, r2 = state, r3 = buf byte addr, r4 = len -> r2.
; crc32_fin:    r2 in/out, complements the state; leaf.
; Preserves r9..r12; uses r1..r8 only (per src/net/defs.nas ABI).
.equ CRC_POLY_LO 0x8320
.equ CRC_POLY_HI 0xEDB8

crc32_tab:                       ; 256 words of table space (must stay)
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; Once per boot: builds the table in 256*8 rounds ~ 4k sim steps.
crc32_mktab:                     ; r1 = table base
  ST r15,r0,@cmk_ret
  ADD r2,r1,r0                   ; entry ptr = base
  ADDI r3,r1,256                 ; sentinel ptr = base + 256
  MOVI r6,#CRC_POLY_LO
  MOVHI r6,#CRC_POLY_HI           ; r6 = 0xEDB88320
cmk_e:
  CMP r2,r3
  JMP[GE] @cmk_done
  SUB r5,r2,r1                   ; t = ptr - base = entry index i
  MOVI r7,8
  ST r7,r0,@cmk_cnt               ; rounds counter = 8
cmk_r:
  LD r7,r0,@cmk_cnt
  CMP r7,r0
  JMP[EQ] @cmk_w
  MOVI r8,1
  BOOL.8 r8,r5,r8                ; bit = t & 1
  SHR r5,r5,1                    ; t >>= 1
  SUB r7,r0,r8                   ; mask = 0 - bit (all ones iff bit set)
  BOOL.8 r8,r7,r6                ; r8 = poly & mask
  BOOL.6 r5,r5,r8                ; t ^= (poly & mask)
  LD r7,r0,@cmk_cnt
  SUB r7,r7,r13
  ST r7,r0,@cmk_cnt
  JMP @cmk_r
cmk_w:
  ST r5,r2,0                     ; tab[i] = t
  ADDI r2,r2,1
  JMP @cmk_e
cmk_done:
  LD r15,r0,@cmk_ret
  RET
cmk_ret:
.word 0
cmk_cnt:
.word 0

; step the CRC over one byte at a time (hot loop, 9 instrs/byte)
crc32_update:                    ; r1 = tab, r2 = state, r3 = buf, r4 = len
  MOVI r5,255
crc_l:
  CMP r4,r0
  JMP[EQ] @crc_ret
  LDB r6,r3,0                    ; byte
  BOOL.6 r6,r2,r6                ; idx = crc ^ byte
  BOOL.8 r6,r6,r5                ; idx &= 255
  ADD r7,r1,r6                   ; word ptr = tab + idx
  LD r8,r7,0                     ; t = tab[idx]
  SHR r2,r2,8                    ; crc >>= 8
  BOOL.6 r2,r2,r8                ; crc ^= t
  ADDI r3,r3,1
  SUB r4,r4,r13
  JMP @crc_l
crc_ret:
  RET

; final complement (leaf)
crc32_fin:                       ; r2 in/out
  MOVI r3,0xFFFF
  MOVHI r3,0xFFFF
  BOOL.6 r2,r2,r3
  RET
