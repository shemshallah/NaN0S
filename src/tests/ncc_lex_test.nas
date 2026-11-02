; ncc - the NaN C compiler. M0: LEXER.
; Written in raw NaN16 only. This test cart streams an embedded C source and
; prints one line per token so the token stream can be compared EXACTLY:
;   K VVVVVVVV LL @LLLL
;   K   01 EOF | 02 INT | 03 IDENT | 04 STRING | 05 CHAR | 06 PUNCT | 07 ERR | 08 KEYWORD
;   V   INT value, otherwise FNV-1a/32 of the token bytes; KEYWORD = keyword id
;   LL  token length in bytes;  LLLL 1-based source line at token start (hex)
; C rules implemented here: // and /* */ comments, escapes in string/char
; literals, decimal/octal/hex integers, identifier charset, C89 keywords by hash,
; and LONGEST-MATCH punctuators (<<= >>= << >> <= >= == != && || ++ -- -> += -= *=
; /= %= &= |= ^= and the single-char set). Invalid bytes become ERR(07) tokens.
; Tracked M0 corners (documented, not silent): a leading-0 number followed by 8/9
; lexes as octal '0' then a new number (C would diagnose a bad octal); raw newline
; inside a literal is an ERR with the words scanned so far. Everything else is
; exact.
.org 0
JMP @lxmain

; ---------------------------------------------------------------- main loop
lxmain:
MOVI r13,1
LA r1,@src
ST r1,r0,@lx_wp
ST r0,r0,@lx_bi
MOVI r1,1
ST r1,r0,@lx_line
tok_loop:
CALL @skip_ws
CALL @lx_peek
CMP r1,r0
JMP[EQ] @tok_eof
ST r1,r0,@c0
CALL @digit10          ; r1 = digit or 255 (source char still unconsumed)
MOVI r2,255
CMP r1,r2
JMP[NE] @tok_num
LD r1,r0,@c0
CALL @ident0
CMP r1,r0
JMP[NE] @tok_ident
LD r1,r0,@c0
MOVI r2,34
CMP r1,r2
JMP[EQ] @tok_str
MOVI r2,39
CMP r1,r2
JMP[EQ] @tok_chr
JMP @tok_punct
tok_num:
CALL @scan_num
JMP @tok_loop
tok_ident:
CALL @scan_ident
JMP @tok_loop
tok_str:
MOVI r10,34
MOVI r11,4
CALL @scan_q
JMP @tok_loop
tok_chr:
MOVI r10,39
MOVI r11,5
CALL @scan_q
JMP @tok_loop
tok_punct:
CALL @scan_punct
JMP @tok_loop
tok_eof:
LD r1,r0,@lx_line
ST r1,r0,@lx_tline
MOVI r1,1
ST r1,r0,@lx_kind
MOVI r1,0
ST r1,r0,@lx_tv
MOVI r1,0
ST r1,r0,@lx_tl
CALL @emit_tok
HALT

; ---------------------------------------------------------------- cursor
; lx_peek -> r1 = current byte (0 = end); does not advance
lx_peek:
LD r2,r0,@lx_wp
LD r1,r2,0
LD r3,r0,@lx_bi
lpk_l:
CMP r3,r0
JMP[EQ] @lpk_d
SHR r1,r1,8
SUB r3,r3,r13
JMP @lpk_l
lpk_d:
MOVI r2,255
BOOL.8 r1,r1,r2
RET
; lx_adv: advance one byte, wrapping every 4 into the next word
lx_adv:
LD r2,r0,@lx_bi
ADD r2,r2,r13
MOVI r3,4
CMP r2,r3
JMP[LT] @lad_s
MOVI r2,0
LD r3,r0,@lx_wp
ADD r3,r3,r13
ST r3,r0,@lx_wp
lad_s:
ST r2,r0,@lx_bi
RET
; lx_get -> r1 = byte, advances, counts newlines into lx_line
lx_get:
ST r15,r0,@lgt_ret
CALL @lx_peek
ST r1,r0,@lx_ch
CALL @lx_adv
LD r1,r0,@lx_ch
MOVI r2,10
CMP r1,r2
JMP[NE] @lgt_d
LD r2,r0,@lx_line
ADD r2,r2,r13
ST r2,r0,@lx_line
lgt_d:
LD r1,r0,@lx_ch
LD r15,r0,@lgt_ret
RET
; peekn: r10 = lookahead offset (0..3) -> r1 = byte, cursor unchanged
peekn:
ST r15,r0,@pkn_ret
LD r2,r0,@lx_wp
ST r2,r0,@pkn_w
LD r2,r0,@lx_bi
ST r2,r0,@pkn_b
pkn_l:
CMP r10,r0
JMP[EQ] @pkn_d
CALL @lx_adv
SUB r10,r10,r13
JMP @pkn_l
pkn_d:
CALL @lx_peek
ST r1,r0,@pkn_c
LD r2,r0,@pkn_w
ST r2,r0,@lx_wp
LD r2,r0,@pkn_b
ST r2,r0,@lx_bi
LD r1,r0,@pkn_c
LD r15,r0,@pkn_ret
RET

; ---------------------------------------------------------------- char classes
; digit10: r1 = char -> 0..9 or 255
digit10:
MOVI r2,48
CMP r1,r2
JMP[LT] @d10_no
MOVI r2,58
CMP r1,r2
JMP[GE] @d10_no
ADDI r1,r1,-48
RET
d10_no:
MOVI r1,255
RET
; hexval: r1 = char -> 0..15 or 255
hexval:
MOVI r2,48
CMP r1,r2
JMP[LT] @hx_no
MOVI r2,58
CMP r1,r2
JMP[LT] @hx_dec
MOVI r2,65
CMP r1,r2
JMP[LT] @hx_no
MOVI r2,71
CMP r1,r2
JMP[LT] @hx_uc
MOVI r2,97
CMP r1,r2
JMP[LT] @hx_no
MOVI r2,103
CMP r1,r2
JMP[LT] @hx_lc
JMP @hx_no
hx_dec:
ADDI r1,r1,-48
RET
hx_uc:
ADDI r1,r1,-55
RET
hx_lc:
ADDI r1,r1,-87
RET
hx_no:
MOVI r1,255
RET
; digitv: r1 = char, r2 = base (8/10/16) -> value or 255
digitv:
MOVI r3,16
CMP r2,r3
JMP[EQ] @dv_hex
MOVI r3,8
CMP r2,r3
JMP[EQ] @dv_oct
JMP @digit10
dv_hex:
JMP @hexval
dv_oct:
MOVI r3,48
CMP r1,r3
JMP[LT] @dv_no
MOVI r3,56
CMP r1,r3
JMP[GE] @dv_no
ADDI r1,r1,-48
RET
dv_no:
MOVI r1,255
RET
; ident0: r1 = char -> 1 if [A-Za-z_]
ident0:
MOVI r2,95
CMP r1,r2
JMP[NE] @i0_a
MOVI r1,1
RET
i0_a:
MOVI r2,65
CMP r1,r2
JMP[LT] @i0_b
MOVI r2,91
CMP r1,r2
JMP[LT] @i0_y
i0_b:
MOVI r2,97
CMP r1,r2
JMP[LT] @i0_n
MOVI r2,123
CMP r1,r2
JMP[LT] @i0_y
i0_n:
MOVI r1,0
RET
i0_y:
MOVI r1,1
RET
; identc: r1 = char -> 1 if identifier continue [A-Za-z0-9_]
identc:
ST r15,r0,@ic_ret
ST r1,r0,@ic_c
CALL @ident0
CMP r1,r0
JMP[NE] @ic_y
LD r1,r0,@ic_c
CALL @digit10
MOVI r2,255
CMP r1,r2
JMP[NE] @ic_y
MOVI r1,0
LD r15,r0,@ic_ret
RET
ic_y:
MOVI r1,1
LD r15,r0,@ic_ret
RET
; hashc: r1 = byte -> lx_hash = (lx_hash ^ byte) * FNV prime (mod 2^32)
hashc:
LD r2,r0,@lx_hash
BOOL.6 r2,r2,r1
LD r3,r0,@k_fnvp
MUL r2,r2,r3
ST r2,r0,@lx_hash
RET

; ---------------------------------------------------------------- keywords
; kw_lookup: r1 = identifier hash -> r1 = keyword id, or 0
kw_lookup:
LA r3,@kw_tab
kw_l:
LD r2,r3,0
CMP r2,r0
JMP[EQ] @kw_none
CMP r2,r1
JMP[EQ] @kw_hit
MOVI r4,2
ADD r3,r3,r4
JMP @kw_l
kw_hit:
LD r1,r3,1
RET
kw_none:
MOVI r1,0
RET

; ---------------------------------------------------------------- comments + space
skip_ws:
ST r15,r0,@sw_ret
sw_l:
CALL @lx_peek
CMP r1,r0
JMP[EQ] @sw_d
MOVI r2,32
CMP r1,r2
JMP[EQ] @sw_c
MOVI r2,9
CMP r1,r2
JMP[EQ] @sw_c
MOVI r2,10
CMP r1,r2
JMP[EQ] @sw_c
MOVI r2,13
CMP r1,r2
JMP[EQ] @sw_c
JMP @sw_cm
sw_c:
CALL @lx_get
JMP @sw_l
sw_cm:
MOVI r2,47
CMP r1,r2
JMP[NE] @sw_d
MOVI r10,1
CALL @peekn
MOVI r2,47
CMP r1,r2
JMP[EQ] @sw_lc
MOVI r2,42
CMP r1,r2
JMP[EQ] @sw_bc
JMP @sw_d
sw_lc:
CALL @lx_get
CALL @lx_get
sw_lc_l:
CALL @lx_peek
CMP r1,r0
JMP[EQ] @sw_d
MOVI r2,10
CMP r1,r2
JMP[EQ] @sw_lc_n
CALL @lx_get
JMP @sw_lc_l
sw_lc_n:
CALL @lx_get
JMP @sw_l
sw_bc:
CALL @lx_get
CALL @lx_get
sw_bc_l:
CALL @lx_peek
CMP r1,r0
JMP[EQ] @sw_d
MOVI r2,42
CMP r1,r2
JMP[NE] @sw_bc_g
MOVI r10,1
CALL @peekn
MOVI r2,47
CMP r1,r2
JMP[EQ] @sw_bc_e
sw_bc_g:
CALL @lx_get
JMP @sw_bc_l
sw_bc_e:
CALL @lx_get
CALL @lx_get
JMP @sw_l
sw_d:
LD r15,r0,@sw_ret
RET

; ---------------------------------------------------------------- integers
; decimal 1-9..., octal 0..., hex 0x... ; value accumulated mod 2^32
scan_num:
ST r15,r0,@sn_ret
LD r1,r0,@lx_line
ST r1,r0,@lx_tline
CALL @lx_get
MOVI r1,1
ST r1,r0,@lx_tl
MOVI r1,0
ST r1,r0,@lx_val
MOVI r1,10
ST r1,r0,@lx_base
LD r1,r0,@lx_ch
MOVI r2,48
CMP r1,r2
JMP[NE] @sn_first
; leading zero
MOVI r10,0
CALL @peekn
MOVI r2,120
CMP r1,r2
JMP[EQ] @sn_hex
MOVI r2,88
CMP r1,r2
JMP[EQ] @sn_hex
MOVI r2,48
CMP r1,r2
JMP[LT] @sn_fin
MOVI r2,56
CMP r1,r2
JMP[GE] @sn_fin
MOVI r1,8
ST r1,r0,@lx_base
JMP @sn_loop
sn_hex:
CALL @lx_get
LD r1,r0,@lx_tl
ADD r1,r1,r13
ST r1,r0,@lx_tl
MOVI r1,16
ST r1,r0,@lx_base
JMP @sn_loop
sn_first:
SUB r1,r1,r2
ST r1,r0,@lx_val
sn_loop:
CALL @lx_peek
LD r2,r0,@lx_base
CALL @digitv
MOVI r2,255
CMP r1,r2
JMP[EQ] @sn_fin
LD r3,r0,@lx_val
LD r4,r0,@lx_base
MUL r3,r3,r4
ADD r3,r3,r1
ST r3,r0,@lx_val
LD r3,r0,@lx_tl
ADD r3,r3,r13
ST r3,r0,@lx_tl
CALL @lx_get
JMP @sn_loop
sn_fin:
MOVI r1,2
ST r1,r0,@lx_kind
LD r1,r0,@lx_val
ST r1,r0,@lx_tv
CALL @emit_tok
LD r15,r0,@sn_ret
RET

; ---------------------------------------------------------------- identifiers / keywords
scan_ident:
ST r15,r0,@si_ret
LD r1,r0,@lx_line
ST r1,r0,@lx_tline
LD r1,r0,@k_fnv0
ST r1,r0,@lx_hash
MOVI r1,0
ST r1,r0,@lx_tl
si_l:
CALL @lx_peek
CALL @identc
CMP r1,r0
JMP[EQ] @si_fin
CALL @lx_get
LD r1,r0,@lx_ch
CALL @hashc
LD r1,r0,@lx_tl
ADD r1,r1,r13
ST r1,r0,@lx_tl
JMP @si_l
si_fin:
LD r1,r0,@lx_hash
CALL @kw_lookup
CMP r1,r0
JMP[EQ] @si_id
ST r1,r0,@lx_tv
MOVI r1,8
ST r1,r0,@lx_kind
JMP @si_emit
si_id:
MOVI r1,3
ST r1,r0,@lx_kind
LD r1,r0,@lx_hash
ST r1,r0,@lx_tv
si_emit:
CALL @emit_tok
LD r15,r0,@si_ret
RET

; ---------------------------------------------------------------- string / char literals
; scan_q: r10 = delimiter byte, r11 = token kind; content hash skips the quotes,
; escapes are kept raw (backslash + next byte) in hash and length.
scan_q:
ST r15,r0,@sq_ret
ST r10,r0,@lx_qd
ST r11,r0,@lx_qk
LD r1,r0,@lx_line
ST r1,r0,@lx_tline
LD r1,r0,@k_fnv0
ST r1,r0,@lx_hash
MOVI r1,0
ST r1,r0,@lx_tl
CALL @lx_get
sq_l:
CALL @lx_peek
CMP r1,r0
JMP[EQ] @sq_err
MOVI r2,10
CMP r1,r2
JMP[EQ] @sq_err
LD r2,r0,@lx_qd
CMP r1,r2
JMP[EQ] @sq_fin
MOVI r2,92
CMP r1,r2
JMP[EQ] @sq_esc
CALL @lx_get
LD r1,r0,@lx_ch
CALL @hashc
LD r1,r0,@lx_tl
ADD r1,r1,r13
ST r1,r0,@lx_tl
JMP @sq_l
sq_esc:
CALL @lx_get
LD r1,r0,@lx_ch
CALL @hashc
LD r1,r0,@lx_tl
ADD r1,r1,r13
ST r1,r0,@lx_tl
CALL @lx_peek
CMP r1,r0
JMP[EQ] @sq_err
MOVI r2,10
CMP r1,r2
JMP[EQ] @sq_err
CALL @lx_get
LD r1,r0,@lx_ch
CALL @hashc
LD r1,r0,@lx_tl
ADD r1,r1,r13
ST r1,r0,@lx_tl
JMP @sq_l
sq_fin:
CALL @lx_get
LD r1,r0,@lx_qk
ST r1,r0,@lx_kind
LD r1,r0,@lx_hash
ST r1,r0,@lx_tv
CALL @emit_tok
LD r15,r0,@sq_ret
RET
sq_err:
MOVI r1,7
ST r1,r0,@lx_kind
LD r1,r0,@k_ffff
ST r1,r0,@lx_tv
CALL @emit_tok
LD r15,r0,@sq_ret
RET

; ---------------------------------------------------------------- punctuators (longest match)
scan_punct:
ST r15,r0,@sp_ret
LD r1,r0,@lx_line
ST r1,r0,@lx_tline
MOVI r10,0
CALL @peekn
ST r1,r0,@p0
MOVI r10,1
CALL @peekn
ST r1,r0,@p1
MOVI r10,2
CALL @peekn
ST r1,r0,@p2
MOVI r1,1
ST r1,r0,@sp_len
LD r1,r0,@p0
MOVI r2,61
CMP r1,r2
JMP[EQ] @sp_eq
MOVI r2,33
CMP r1,r2
JMP[EQ] @sp_eq
MOVI r2,60
CMP r1,r2
JMP[EQ] @sp_ltgt
MOVI r2,62
CMP r1,r2
JMP[EQ] @sp_ltgt
MOVI r2,38
CMP r1,r2
JMP[EQ] @sp_amp
MOVI r2,124
CMP r1,r2
JMP[EQ] @sp_bar
MOVI r2,43
CMP r1,r2
JMP[EQ] @sp_plus
MOVI r2,45
CMP r1,r2
JMP[EQ] @sp_minus
MOVI r2,42
CMP r1,r2
JMP[EQ] @sp_muldiv
MOVI r2,47
CMP r1,r2
JMP[EQ] @sp_muldiv
MOVI r2,37
CMP r1,r2
JMP[EQ] @sp_muldiv
MOVI r2,94
CMP r1,r2
JMP[EQ] @sp_muldiv
JMP @sp_single
sp_eq:
LD r2,r0,@p1
MOVI r3,61
CMP r2,r3
JMP[NE] @sp_go
MOVI r1,2
ST r1,r0,@sp_len
JMP @sp_go
sp_ltgt:
LD r1,r0,@p0
LD r2,r0,@p1
CMP r1,r2
JMP[NE] @sp_ltgt2
LD r2,r0,@p2
MOVI r3,61
CMP r2,r3
JMP[NE] @sp_ll2
MOVI r1,3
ST r1,r0,@sp_len
JMP @sp_go
sp_ll2:
MOVI r1,2
ST r1,r0,@sp_len
JMP @sp_go
sp_ltgt2:
MOVI r3,61
CMP r2,r3
JMP[NE] @sp_go
MOVI r1,2
ST r1,r0,@sp_len
JMP @sp_go
sp_amp:
LD r2,r0,@p1
MOVI r3,38
CMP r2,r3
JMP[EQ] @sp_two
MOVI r3,61
CMP r2,r3
JMP[EQ] @sp_two
JMP @sp_go
sp_bar:
LD r2,r0,@p1
MOVI r3,124
CMP r2,r3
JMP[EQ] @sp_two
MOVI r3,61
CMP r2,r3
JMP[EQ] @sp_two
JMP @sp_go
sp_plus:
LD r2,r0,@p1
MOVI r3,43
CMP r2,r3
JMP[EQ] @sp_two
MOVI r3,61
CMP r2,r3
JMP[EQ] @sp_two
JMP @sp_go
sp_minus:
LD r2,r0,@p1
MOVI r3,45
CMP r2,r3
JMP[EQ] @sp_two
MOVI r3,61
CMP r2,r3
JMP[EQ] @sp_two
MOVI r3,62
CMP r2,r3
JMP[EQ] @sp_two
JMP @sp_go
sp_muldiv:
LD r2,r0,@p1
MOVI r3,61
CMP r2,r3
JMP[NE] @sp_go
sp_two:
MOVI r1,2
ST r1,r0,@sp_len
JMP @sp_go
sp_single:
LD r1,r0,@p0
MOVI r2,126
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,63
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,58
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,59
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,44
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,46
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,40
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,41
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,91
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,93
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,123
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,125
CMP r1,r2
JMP[EQ] @sp_go
MOVI r2,35
CMP r1,r2
JMP[EQ] @sp_go
JMP @sp_err
sp_go:
LD r1,r0,@k_fnv0
ST r1,r0,@lx_hash
LD r1,r0,@p0
CALL @hashc
LD r1,r0,@sp_len
MOVI r2,2
CMP r1,r2
JMP[LT] @sp_h1
LD r1,r0,@p1
CALL @hashc
LD r1,r0,@sp_len
MOVI r2,3
CMP r1,r2
JMP[LT] @sp_h1
LD r1,r0,@p2
CALL @hashc
sp_h1:
LD r1,r0,@sp_len
ST r1,r0,@lx_tl
LD r1,r0,@lx_hash
ST r1,r0,@lx_tv
MOVI r1,6
ST r1,r0,@lx_kind
LD r1,r0,@sp_len
ST r1,r0,@sp_n
sp_c:
LD r1,r0,@sp_n
CMP r1,r0
JMP[EQ] @sp_emit
CALL @lx_get
LD r1,r0,@sp_n
SUB r1,r1,r13
ST r1,r0,@sp_n
JMP @sp_c
sp_emit:
CALL @emit_tok
LD r15,r0,@sp_ret
RET
sp_err:
MOVI r1,7
ST r1,r0,@lx_kind
LD r1,r0,@p0
ST r1,r0,@lx_tv
MOVI r1,1
ST r1,r0,@lx_tl
CALL @lx_get
CALL @emit_tok
LD r15,r0,@sp_ret
RET

; ---------------------------------------------------------------- output
; emit_tok: prints lx_kind, lx_tv, lx_tl, lx_tline as "K VVVVVVVV LL @LLLL\n"
emit_tok:
ST r15,r0,@et_ret
LD r5,r0,@lx_kind
CALL @puthex2
MOVI r1,32
PUTC r1
LD r5,r0,@lx_tv
CALL @puthex8
MOVI r1,32
PUTC r1
LD r5,r0,@lx_tl
CALL @puthex2
MOVI r1,32
PUTC r1
MOVI r1,64
PUTC r1
LD r5,r0,@lx_tline
CALL @puthex4
MOVI r1,10
PUTC r1
LD r15,r0,@et_ret
RET
puthex2:
MOVI r6,2
SHL r5,r5,24
JMP @puthexn
puthex4:
MOVI r6,4
SHL r5,r5,16
JMP @puthexn
puthex8:
MOVI r6,8
puthexn:
ST r15,r0,@phn_ret
phn_l:
SHR r1,r5,28
CALL @puthex1
SHL r5,r5,4
SUB r6,r6,r13
CMP r6,r0
JMP[NE] @phn_l
LD r15,r0,@phn_ret
RET
puthex1:
MOVI r2,10
CMP r1,r2
JMP[LT] @phx_d
ADDI r1,r1,55
PUTC r1
RET
phx_d:
ADDI r1,r1,48
PUTC r1
RET

; ---------------------------------------------------------------- data
lx_wp:
.word 0
lx_bi:
.word 0
lx_line:
.word 0
lx_ch:
.word 0
lx_val:
.word 0
lx_base:
.word 0
lx_tl:
.word 0
lx_hash:
.word 0
lx_kind:
.word 0
lx_tv:
.word 0
lx_tline:
.word 0
lx_qd:
.word 0
lx_qk:
.word 0
c0:
.word 0
p0:
.word 0
p1:
.word 0
p2:
.word 0
sp_len:
.word 0
sp_n:
.word 0
k_fnv0:
.word 0x811C9DC5
k_fnvp:
.word 0x01000193
k_ffff:
.word 0xFFFFFFFF
et_ret:
.word 0
lgt_ret:
.word 0
pkn_ret:
.word 0
pkn_w:
.word 0
pkn_b:
.word 0
pkn_c:
.word 0
sw_ret:
.word 0
sn_ret:
.word 0
si_ret:
.word 0
sq_ret:
.word 0
sp_ret:
.word 0
phn_ret:
.word 0
ic_ret:
.word 0
ic_c:
.word 0
; C89 keyword table: hash, id (id order documented in TODO/A7)
kw_tab:
.word 0x923FA396, 1
.word 0xC9648178, 2
.word 0x9B2538B1, 3
.word 0xA84C031D, 4
.word 0x664FD1D4, 5
.word 0xB1727E44, 6
.word 0x933B5BDE, 7
.word 0x621CD814, 8
.word 0xA0EB0F08, 9
.word 0xBDBF5BF0, 10
.word 0x816CB000, 11
.word 0x9087DDB7, 12
.word 0xA6C45D85, 13
.word 0xACF38390, 14
.word 0xF5A30FE6, 15
.word 0x39386E06, 16
.word 0x95E97E5E, 17
.word 0xC2ECDF53, 18
.word 0x2D6871C0, 19
.word 0x85EE37BF, 20
.word 0xBA226BD5, 21
.word 0xB5712015, 22
.word 0x6EE13AFD, 23
.word 0xD290C23B, 24
.word 0x92C2BE20, 25
.word 0x93E05F71, 26
.word 0x221EDE24, 27
.word 0xDBDED6F4, 28
.word 0x0C547726, 29
.word 0x48B5725F, 30
.word 0x94E1036D, 31
.word 0x0DC628CE, 32
.word 0
src:
.str "/* ncc M0 lexer */\nint add(int a, int b) { return a + b; }\n// numbers, keywords, operators\nint main(void)\n{\n  int x = 010, y = 31, z = 0x1f;\n  char c = 'A', d = '\\n';\n  const char *s = \"a\\tb\\\"c\";\n  if (x << 2 >= y && z != 0) x += z <<= 1;\n  x = x-- + (y ? 3 : 4);\n  return add(x, y) * 2 / 1 % 3;\n}\n"
