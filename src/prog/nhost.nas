; nhost - NaN/0S self-hosting assembler CLI, written in NaN16 (r29g). Replaces nanchk.py / tools/nmk.awk.
; Host contract (the ONLY outside-the-machine part): nan_cli --img nhost.nan --disk BUNDLE --serial > OUT.nan
; BUNDLE is plain text: first line ";@MAIN path", then every source file as ";@FILE path" + its text. NUL padded (disk sectors).
; Machine does: ATA PIO read -> directory -> .include expansion (relative paths, .. and . normalised) -> nasm0 pass 1+2
; -> prints NNNN_PPPPPPPP_FFFF words, then a last line ";END words=.. labels=.. err=.. mirror=.. pre=..".
; Byte-addressed text (LDB/STB); the packed 4-chars/word source nasm0 wants is just the same bytes.
; Conventions as nasm0: r0=0 r13=1 r14=SP(grows up) r15=link; helpers clobber r1..r9, r10..r12 survive.
.org 0
JMP @main
.include "nasm0.nas"
.equ P_DATA 0x1F0
.equ P_COUNT 0x1F2
.equ P_LBA0 0x1F3
.equ P_LBA1 0x1F4
.equ P_LBA2 0x1F5
.equ P_DRIVE 0x1F6
.equ P_CMD 0x1F7
.equ P_STAT 0x1F7
.equ B_BUN 0x80000
.equ B_SRC 0x280000
.equ W_SRC 0xA0000
.equ W_OUT 0x120000
.equ W_LAB 0x220000
.equ DIRB 16384
.equ PB1 32768
.equ PB2 33792
.equ H_ND 6300
.equ H_OP 6301
.equ H_PERR 6302
.equ H_LS 6303
.equ H_LE 6304
.equ H_NB 6305
.equ H_T 6306
.equ H_T2 6307
; ---------------------------------------------------------------- main
main:
MOVI r13,1
MOVI r14,#STACK
CALL @h_load
CALL @h_mkdir
CALL @h_pre
LA r1,#W_SRC
ST r1,r0,#V_SRCB
LA r1,#W_OUT
ST r1,r0,#V_OUTB
LA r1,#W_LAB
ST r1,r0,#V_LABB
ST r0,r0,#V_EXPB
ST r0,r0,#V_EXPCB
ST r0,r0,#V_ERR
ST r0,r0,#V_MIRR
ST r0,r0,#V_NLAB
LD r2,r0,#V_LABB
ST r0,r2,0
MOVI r2,1
ST r2,r0,#V_PASS
CALL @run
MOVI r2,2
ST r2,r0,#V_PASS
CALL @run
CALL @h_dump
MOVI r1,59
PUTC r1
MOVI r1,@s_end
CALL @h_puts
LD r1,r0,#V_IDX
CALL @h_hex8
MOVI r1,@s_lab
CALL @h_puts
LD r1,r0,#V_NLAB
CALL @h_hex8
MOVI r1,@s_err
CALL @h_puts
LD r1,r0,#V_ERR
CALL @h_hex8
MOVI r1,@s_mir
CALL @h_puts
LD r1,r0,#V_MIRR
CALL @h_hex8
MOVI r1,@s_pre
CALL @h_puts
LD r1,r0,#H_PERR
CALL @h_hex8
MOVI r1,10
PUTC r1
HALT
h_nodisk:
MOVI r1,59
PUTC r1
MOVI r1,@s_nod
CALL @h_puts
MOVI r1,10
PUTC r1
HALT
; ---------------------------------------------------------------- h_load: ATA PIO LBA28 sectors -> bytes at B_BUN until a sector holds a NUL
h_load:
ST r15,r14,0
ADD r14,r14,r13
LA r10,#B_BUN
MOVI r11,0
hl_sec:
MOVI r1,#P_DRIVE
MOVI r2,0xE0
OUTB r2,r1
MOVI r1,#P_COUNT
MOVI r2,1
OUTB r2,r1
MOVI r1,#P_LBA0
MOVI r3,255
BOOL.8 r2,r11,r3
OUTB r2,r1
MOVI r1,#P_LBA1
SHR r2,r11,8
BOOL.8 r2,r2,r3
OUTB r2,r1
MOVI r1,#P_LBA2
SHR r2,r11,16
BOOL.8 r2,r2,r3
OUTB r2,r1
MOVI r1,#P_CMD
MOVI r2,0x20
OUTB r2,r1
hl_wait:
MOVI r1,#P_STAT
INB r2,r1
MOVI r3,255
CMP r2,r3
JMP[EQ] @h_nodisk
MOVI r3,0x88
BOOL.8 r4,r2,r3
MOVI r5,8
CMP r4,r5
JMP[NE] @hl_wait
MOVI r1,#P_DATA
MOVI r12,256
MOVI r9,0
hl_w:
INW r2,r1
MOVI r3,255
BOOL.8 r4,r2,r3
SHR r5,r2,8
STB r4,r10,0
STB r5,r10,1
ADDI r10,r10,2
CMP r4,r0
MOVI[EQ] r9,1
CMP r5,r0
MOVI[EQ] r9,1
SUB r12,r12,r13
JMP[NE] @hl_w
ADD r11,r11,r13
CMP r9,r0
JMP[NE] @hl_done
MOVI r2,4095
CMP r11,r2
JMP[LT] @hl_sec
hl_done:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---------------------------------------------------------------- tiny helpers
; h_eol: r1 = byte addr -> r1 = addr of the next LF or NUL (clobbers r2,r3)
h_eol:
LDB r2,r1,0
CMP r2,r0
RET[EQ]
MOVI r3,10
CMP r2,r3
RET[EQ]
ADDI r1,r1,1
JMP @h_eol
; h_match: r1 = text byte addr, r2 = pattern byte addr, r3 = len -> r1 = 1 if equal else 0 (clobbers r2..r5)
h_match:
LDB r4,r1,0
LDB r5,r2,0
CMP r4,r5
JMP[NE] @hmt_no
ADDI r1,r1,1
ADDI r2,r2,1
SUB r3,r3,r13
JMP[NE] @h_match
MOVI r1,1
RET
hmt_no:
MOVI r1,0
RET
; h_put: r1 = char -> appended to the expanded source at H_OP (clobbers r4)
h_put:
LD r4,r0,#H_OP
STB r1,r4,0
ADDI r4,r4,1
ST r4,r0,#H_OP
RET
; h_puts: r1 = word addr of a packed NUL-terminated string -> serial (clobbers r1..r5)
h_puts:
LD r2,r1,0
MOVI r3,4
hp_c:
MOVI r4,255
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @hp_c
ADDI r1,r1,1
JMP @h_puts
; h_hex8 / h_hex4: r1 = value -> 8 / 4 upper-case hex digits on serial (clobbers r1,r3..r5)
h_hex4:
SHL r1,r1,16
MOVI r3,4
JMP @hh_l
h_hex8:
MOVI r3,8
hh_l:
SHR r4,r1,28
SHL r1,r1,4
MOVI r5,10
CMP r4,r5
JMP[LT] @hh_n
ADDI r4,r4,7
hh_n:
ADDI r4,r4,48
PUTC r4
SUB r3,r3,r13
JMP[NE] @hh_l
RET
; ---------------------------------------------------------------- h_mkdir: directory of ";@FILE path" markers
; entry (5 words at DIRB+5i): hash(path), start byte, end byte, path start byte, path length
h_mkdir:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,#H_ND
LA r10,#B_BUN
MOVI r11,0
hm_l:
LDB r1,r10,0
CMP r1,r0
JMP[EQ] @hm_fin
ADD r1,r10,r0
CALL @h_eol
ADD r12,r1,r0
ADD r1,r10,r0
MOVI r2,@m_file
SHL r2,r2,2
MOVI r3,7
CALL @h_match
CMP r1,r0
JMP[EQ] @hm_next
CMP r11,r0
JMP[EQ] @hm_new
ST r10,r11,2
hm_new:
LD r2,r0,#H_ND
MOVI r3,5
MUL r3,r2,r3
MOVI r4,#DIRB
ADD r11,r3,r4
ADD r2,r2,r13
ST r2,r0,#H_ND
ADDI r5,r10,7
ST r5,r11,3
SUB r6,r12,r5
ST r6,r11,4
ADDI r7,r12,1
ST r7,r11,1
ST r0,r11,2
MOVI r8,5381
hm_h:
CMP r5,r12
JMP[GE] @hm_hd
LDB r1,r5,0
SHL r2,r8,5
ADD r8,r2,r8
ADD r8,r8,r1
ADDI r5,r5,1
JMP @hm_h
hm_hd:
ST r8,r11,0
hm_next:
ADDI r10,r12,1
JMP @hm_l
hm_fin:
CMP r11,r0
JMP[EQ] @hm_x
ST r10,r11,2
hm_x:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---------------------------------------------------------------- h_resolve: r1 = including entry (0 = none), r2/r3 = name [start,end) bytes
; -> r1 = directory entry or 0. Path = dir(cur) + name, then "x/../" and "./" removed, hashed, matched on hash + length.
h_resolve:
ST r15,r14,0
ST r10,r14,1
ST r11,r14,2
ST r12,r14,3
ADDI r14,r14,4
MOVI r11,0
CMP r1,r0
JMP[EQ] @hr_name
LD r4,r1,3
LD r5,r1,4
ADD r6,r4,r5
hr_b:
CMP r6,r4
JMP[LE] @hr_name
SUB r7,r6,r13
LDB r8,r7,0
MOVI r9,47
CMP r8,r9
JMP[EQ] @hr_f
ADD r6,r7,r0
JMP @hr_b
hr_f:
MOVI r9,#PB1
hr_c:
CMP r4,r6
JMP[GE] @hr_name
LDB r8,r4,0
ADD r7,r9,r11
STB r8,r7,0
ADDI r4,r4,1
ADDI r11,r11,1
JMP @hr_c
hr_name:
MOVI r9,#PB1
hr_n:
CMP r2,r3
JMP[GE] @hr_norm
LDB r8,r2,0
ADD r7,r9,r11
STB r8,r7,0
ADDI r2,r2,1
ADDI r11,r11,1
JMP @hr_n
hr_norm:
MOVI r10,0
MOVI r12,0
hn_l:
CMP r10,r11
JMP[GE] @hn_end
MOVI r9,#PB1
ADD r5,r10,r0
hn_e:
CMP r5,r11
JMP[GE] @hn_ee
ADD r6,r9,r5
LDB r7,r6,0
MOVI r8,47
CMP r7,r8
JMP[EQ] @hn_ee
ADDI r5,r5,1
JMP @hn_e
hn_ee:
SUB r6,r5,r10
CMP r6,r0
JMP[EQ] @hn_skip
MOVI r7,1
CMP r6,r7
JMP[NE] @hn_two
ADD r8,r9,r10
LDB r8,r8,0
MOVI r7,46
CMP r8,r7
JMP[EQ] @hn_skip
JMP @hn_copy
hn_two:
MOVI r7,2
CMP r6,r7
JMP[NE] @hn_copy
ADD r8,r9,r10
LDB r1,r8,0
LDB r2,r8,1
MOVI r7,46
CMP r1,r7
JMP[NE] @hn_copy
CMP r2,r7
JMP[NE] @hn_copy
CMP r12,r0
JMP[EQ] @hn_skip
SUB r12,r12,r13
hn_pop:
CMP r12,r0
JMP[EQ] @hn_skip
MOVI r7,#PB2
ADD r7,r7,r12
SUB r7,r7,r13
LDB r8,r7,0
MOVI r7,47
CMP r8,r7
JMP[EQ] @hn_skip
SUB r12,r12,r13
JMP @hn_pop
hn_copy:
CMP r10,r5
JMP[GE] @hn_slash
ADD r6,r9,r10
LDB r8,r6,0
MOVI r7,#PB2
ADD r7,r7,r12
STB r8,r7,0
ADDI r10,r10,1
ADDI r12,r12,1
JMP @hn_copy
hn_slash:
MOVI r7,#PB2
ADD r7,r7,r12
MOVI r8,47
STB r8,r7,0
ADDI r12,r12,1
hn_skip:
ADDI r10,r5,1
JMP @hn_l
hn_end:
CMP r12,r0
JMP[EQ] @hn_look
MOVI r7,#PB2
ADD r7,r7,r12
SUB r7,r7,r13
LDB r8,r7,0
MOVI r9,47
CMP r8,r9
JMP[NE] @hn_look
SUB r12,r12,r13
hn_look:
MOVI r8,5381
MOVI r5,0
MOVI r9,#PB2
hn_hh:
CMP r5,r12
JMP[GE] @hn_hd
ADD r6,r9,r5
LDB r1,r6,0
SHL r2,r8,5
ADD r8,r2,r8
ADD r8,r8,r1
ADDI r5,r5,1
JMP @hn_hh
hn_hd:
MOVI r5,#DIRB
LD r6,r0,#H_ND
hn_s:
CMP r6,r0
JMP[EQ] @hn_none
LD r7,r5,0
CMP r7,r8
JMP[NE] @hn_nx
LD r7,r5,4
CMP r7,r12
JMP[NE] @hn_nx
ADD r1,r5,r0
JMP @hr_ret
hn_nx:
ADDI r5,r5,5
SUB r6,r6,r13
JMP @hn_s
hn_none:
MOVI r1,0
hr_ret:
SUB r14,r14,r13
SUB r14,r14,r13
SUB r14,r14,r13
SUB r14,r14,r13
LD r15,r14,0
LD r10,r14,1
LD r11,r14,2
LD r12,r14,3
RET
; ---------------------------------------------------------------- h_pre: expand the MAIN file (or the first file) into the packed source
h_pre:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,#H_PERR
LA r1,#B_SRC
ST r1,r0,#H_OP
LA r1,#B_BUN
MOVI r2,@m_main
SHL r2,r2,2
MOVI r3,7
CALL @h_match
CMP r1,r0
JMP[EQ] @hp_first
LA r1,#B_BUN
CALL @h_eol
ADD r3,r1,r0
LA r2,#B_BUN
ADDI r2,r2,7
MOVI r1,0
CALL @h_resolve
CMP r1,r0
JMP[NE] @hp_go
LD r2,r0,#H_PERR
ADD r2,r2,r13
ST r2,r0,#H_PERR
JMP @hp_x
hp_first:
MOVI r1,#DIRB
hp_go:
CALL @h_expand
hp_x:
SUB r14,r14,r13
LD r15,r14,0
RET
; ---------------------------------------------------------------- h_expand: r1 = entry. Copies its lines (comments stripped, quote/escape aware); .include lines recurse.
h_expand:
ST r15,r14,0
ST r10,r14,1
ST r11,r14,2
ST r12,r14,3
ADDI r14,r14,4
LD r10,r1,1
LD r11,r1,2
ADD r12,r1,r0
hx_l:
CMP r10,r11
JMP[GE] @hx_d
ST r10,r0,#H_LS
ADD r1,r10,r0
CALL @h_eol
ST r1,r0,#H_LE
ADDI r10,r1,1
LD r2,r0,#H_LS
hx_b:
LDB r3,r2,0
MOVI r4,32
CMP r3,r4
JMP[EQ] @hx_bs
MOVI r4,9
CMP r3,r4
JMP[NE] @hx_t
hx_bs:
ADDI r2,r2,1
JMP @hx_b
hx_t:
ST r2,r0,#H_NB
ADD r1,r2,r0
MOVI r2,@m_inc
SHL r2,r2,2
MOVI r3,8
CALL @h_match
CMP r1,r0
JMP[EQ] @hx_cp
LD r2,r0,#H_NB
ADDI r2,r2,8
LD r4,r0,#H_LE
MOVI r5,34
hx_q1:
CMP r2,r4
JMP[GE] @hx_err
LDB r3,r2,0
CMP r3,r5
JMP[EQ] @hx_q2
ADDI r2,r2,1
JMP @hx_q1
hx_q2:
ADDI r2,r2,1
ADD r3,r2,r0
hx_q3:
CMP r3,r4
JMP[GE] @hx_err
LDB r6,r3,0
CMP r6,r5
JMP[EQ] @hx_q4
ADDI r3,r3,1
JMP @hx_q3
hx_q4:
ADD r1,r12,r0
CALL @h_resolve
CMP r1,r0
JMP[EQ] @hx_err
CALL @h_expand
JMP @hx_l
hx_err:
LD r2,r0,#H_PERR
ADD r2,r2,r13
ST r2,r0,#H_PERR
JMP @hx_l
hx_cp:
LD r2,r0,#H_LS
LD r3,r0,#H_LE
CALL @h_copyline
JMP @hx_l
hx_d:
SUB r14,r14,r13
SUB r14,r14,r13
SUB r14,r14,r13
SUB r14,r14,r13
LD r15,r14,0
LD r10,r14,1
LD r11,r14,2
LD r12,r14,3
RET
; h_copyline: r2 = line start, r3 = line end (bytes) -> appended without its comment, plus LF
h_copyline:
ST r15,r14,0
ADD r14,r14,r13
MOVI r6,0
hc_l:
CMP r2,r3
JMP[GE] @hc_nl
LDB r1,r2,0
ADDI r2,r2,1
CMP r6,r0
JMP[NE] @hc_q
MOVI r4,59
CMP r1,r4
JMP[EQ] @hc_nl
MOVI r4,34
CMP r1,r4
JMP[NE] @hc_p
MOVI r6,1
JMP @hc_p
hc_q:
MOVI r4,34
CMP r1,r4
JMP[NE] @hc_q2
MOVI r6,0
JMP @hc_p
hc_q2:
MOVI r4,92
CMP r1,r4
JMP[NE] @hc_p
CALL @h_put
CMP r2,r3
JMP[GE] @hc_nl
LDB r1,r2,0
ADDI r2,r2,1
hc_p:
CALL @h_put
JMP @hc_l
hc_nl:
MOVI r1,10
CALL @h_put
SUB r14,r14,r13
LD r15,r14,0
RET
; ---------------------------------------------------------------- h_dump: every emitted word as NEAR_PAYLOAD_FAR (OPS.md text form)
h_dump:
ST r15,r14,0
ST r10,r14,1
ST r11,r14,2
ST r12,r14,3
ADDI r14,r14,4
MOVI r10,0
LD r11,r0,#V_IDX
LA r12,#W_OUT
hd_l:
CMP r10,r11
JMP[GE] @hd_d
ADD r5,r12,r10
LDN r6,r5,0
LD r7,r5,0
ST r7,r0,#H_T
ST r6,r0,#H_T2
SHR r8,r6,2
MOVI r9,@t_near
ADD r9,r9,r8
LD r1,r9,0
CALL @h_hex4
MOVI r1,95
PUTC r1
LD r1,r0,#H_T
CALL @h_hex8
MOVI r1,95
PUTC r1
LD r6,r0,#H_T2
MOVI r2,3
BOOL.8 r6,r6,r2
MOVI r9,@t_far
ADD r9,r9,r6
LD r1,r9,0
CALL @h_hex4
MOVI r1,10
PUTC r1
ADDI r10,r10,1
JMP @hd_l
hd_d:
SUB r14,r14,r13
SUB r14,r14,r13
SUB r14,r14,r13
SUB r14,r14,r13
LD r15,r14,0
LD r10,r14,1
LD r11,r14,2
LD r12,r14,3
RET
; ---------------------------------------------------------------- data (no ';' inside .str: the host assemblers cut at ';')
m_file:
.word 0x4946403B,0x0020454C
m_main:
.word 0x414D403B,0x00204E49
m_inc:
.word 0x636E692E,0x65646C75
t_near:
.word 0x7FF1,0xFFF1,0x7FF8,0xFFF8
t_far:
.word 0xF17F,0xF1FF,0xF87F,0xF8FF
s_end:
.str "END words="
s_lab:
.str " labels="
s_err:
.str " err="
s_mir:
.str " mirror="
s_pre:
.str " pre="
s_nod:
.str "NODISK"
