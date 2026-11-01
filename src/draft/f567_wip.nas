; ====================== r26: TEXT HELPERS, SETTINGS (F5), NaNNet (F6), UTILITIES (F7) ======================
; All pure NaN16. Text goes through NaNGlyph (fb_text7 / fb_char7); strings are 4 chars per word, so a CPUID register IS a string word.
; Scratch above the window buffers (0x40000..0x4FFFF): IDBUF 0x50000 (256 words), ATAT 0x50200 (4 slots x 16), PCIT 0x50300 (entries x 4).
.equ PCIMAX 12
.equ MODE_TMO 10000
.equ C_CY 11
.equ C_GRN 10
.equ C_DIM 8
; tx_org r1=id : tx_x = X+8, tx_y = Y+22 (text origin of the window body)
tx_org:
SHL r1,r1,5
MOVI r2,#WT
ADD r1,r1,r2
LD r2,r1,#W_X
MOVI r3,8
ADD r2,r2,r3
ST r2,r0,@tx_x
LD r2,r1,#W_Y
MOVI r3,22
ADD r2,r2,r3
ST r2,r0,@tx_y
RET
tx_x:
.word 0
tx_y:
.word 0
; tx_s r1=xoff r2=row r3=string r4=colour
tx_s:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@tx_x
ADD r1,r1,r5
MOVI r5,13
MUL r2,r2,r5
LD r5,r0,@tx_y
ADD r2,r2,r5
CALL @fb_text7
SUB r14,r14,r13
LD r15,r14,0
RET
; tx_c r1=xoff r2=row r3=ascii r4=colour
tx_c:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@tx_x
ADD r1,r1,r5
MOVI r5,13
MUL r2,r2,r5
LD r5,r0,@tx_y
ADD r2,r2,r5
CALL @fb_char7
SUB r14,r14,r13
LD r15,r14,0
RET
; tx_h r1=xoff r2=row r3=value r4=ndigits r5=colour (hex)
tx_h:
ST r15,r14,0
ADD r14,r14,r13
LD r6,r0,@tx_x
ADD r1,r1,r6
MOVI r6,13
MUL r2,r2,r6
LD r6,r0,@tx_y
ADD r2,r2,r6
CALL @wm_puthex
SUB r14,r14,r13
LD r15,r14,0
RET
; tx_d r1=xoff r2=row r3=value r4=colour (decimal, left aligned; leaves the end x in td2_x)
tx_d:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@tx_x
ADD r1,r1,r5
ST r1,r0,@td2_x
MOVI r5,13
MUL r2,r2,r5
LD r5,r0,@tx_y
ADD r2,r2,r5
ST r2,r0,@td2_y
ST r4,r0,@td2_c
MOVI r5,10
MOVI r6,0
td2_div:
MODU r7,r3,r5
DIVU r3,r3,r5
MOVI r8,@td2_b
ADD r8,r8,r6
ST r7,r8,0
ADD r6,r6,r13
CMP r3,r0
JMP[NE] @td2_div
ST r6,r0,@td2_n
td2_out:
LD r6,r0,@td2_n
CMP r6,r0
JMP[EQ] @td2_done
SUB r6,r6,r13
ST r6,r0,@td2_n
MOVI r8,@td2_b
ADD r8,r8,r6
LD r3,r8,0
MOVI r5,48
ADD r3,r3,r5
LD r1,r0,@td2_x
LD r2,r0,@td2_y
LD r4,r0,@td2_c
CALL @fb_char7
LD r1,r0,@td2_x
MOVI r5,8
ADD r1,r1,r5
ST r1,r0,@td2_x
JMP @td2_out
td2_done:
SUB r14,r14,r13
LD r15,r14,0
RET
td2_x:
.word 0
td2_y:
.word 0
td2_c:
.word 0
td2_n:
.word 0
td2_b:
.word 0,0,0,0,0,0,0,0,0,0,0,0
; tx_end -> r1 = x offset just after the last tx_d number
tx_end:
LD r1,r0,@td2_x
LD r2,r0,@tx_x
SUB r1,r1,r2
RET
; tx_wh r1=xoff r2=row r3=w r4=h r5=colour of w r6=colour of h : "W x H"
tx_wh:
ST r15,r14,0
ADD r14,r14,r13
ST r2,r0,@wh_r
ST r4,r0,@wh_h
ST r6,r0,@wh_ch
ADD r4,r5,r0
ST r5,r0,@wh_cw
CALL @tx_d
CALL @tx_end
ST r1,r0,@wh_x
MOVI r2,8
ADD r1,r1,r2
LD r2,r0,@wh_r
MOVI r3,120
MOVI r4,#C_DIM
CALL @tx_c
LD r1,r0,@wh_x
MOVI r2,24
ADD r1,r1,r2
LD r2,r0,@wh_r
LD r3,r0,@wh_h
LD r4,r0,@wh_ch
CALL @tx_d
SUB r14,r14,r13
LD r15,r14,0
RET
wh_r:
.word 0
wh_h:
.word 0
wh_cw:
.word 0
wh_ch:
.word 0
wh_x:
.word 0
; gui_single r1=kind : raise the live window of that kind, or open one centred below the bar
gui_single:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@gs_k
MOVI r2,0
gs_l:
MOVI r3,#MAXW
CMP r2,r3
JMP[GE] @gs_new
SHL r4,r2,5
MOVI r5,#WT
ADD r4,r4,r5
LD r5,r4,#W_ALIVE
CMP r5,r0
JMP[EQ] @gs_n
LD r5,r4,#W_KIND
LD r6,r0,@gs_k
CMP r5,r6
JMP[EQ] @gs_have
gs_n:
ADD r2,r2,r13
JMP @gs_l
gs_have:
ADD r1,r2,r0
CALL @wm_raise
JMP @gs_ret
gs_new:
LD r1,r0,@gs_k
SHL r4,r1,2
MOVI r5,@kdef
ADD r4,r4,r5
LD r5,r4,0
LD r6,r0,@fb_w
MOVI r2,0
CMP r6,r5
JMP[LE] @gs_go
SUB r2,r6,r5
SHR r2,r2,1
gs_go:
MOVI r3,40
CALL @gui_open_at
gs_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
gs_k:
.word 0
; ====================== SETTINGS (kind 4) ======================
; A0 selected row (0 x86, 1 Galaxy A32 5G, 2 RISC-V disabled, 3 custom)  A1 custom W  A2 custom H  A3 custom field (0 W, 1 H)  A5 message code
; A mode change arms a 10 s TICK countdown: ENTER keeps, ESC (or the timeout) reverts to the previous mode. While armed g_onkey routes every key to st_pendkey.
st_init:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@st_wid
CALL @wm_wbase
MOVI r2,800
ST r2,r1,#W_A1
MOVI r2,600
ST r2,r1,#W_A2
SUB r14,r14,r13
LD r15,r14,0
RET
st_wid:
.word 0
st_pend:
.word 0
st_t0:
.word 0
st_ow:
.word 0
st_oh:
.word 0
st_sec:
.word 0
st_items:
.word @s_i0,1024,768,15
.word @s_i1,720,1600,15
.word @s_i2,0,0,8
.word @s_i3,0,0,15
st_msgs:
.word @s_e,@s_m1,@s_m2,@s_m3,@s_m4,@s_m5
t_set:
.str "SETTINGS"
s_st0:
.str "DISPLAY MODE"
s_cur:
.str "CURRENT"
s_i0:
.str "X86 PC"
s_i1:
.str "GALAXY A32 5G"
s_i2:
.str "RISC-V"
s_i3:
.str "CUSTOM"
s_dis:
.str "DISABLED"
s_e:
.str ""
s_m1:
.str "RISC-V IS NOT AVAILABLE"
s_m2:
.str "OUT OF RANGE: W 320-1920 (X8) H 200-1600 W*H<=2M"
s_m3:
.str "MODE KEPT"
s_m4:
.str "REVERTED TO THE PREVIOUS MODE"
s_m5:
.str "THAT MODE IS ALREADY ACTIVE"
s_sh1:
.str "UP/DOWN SELECT   ENTER APPLY"
s_sh2:
.str "CUSTOM: LEFT/RIGHT FIELD  0-9  BKSP"
s_keep:
.str "KEEP THIS MODE?  ENTER = KEEP   ESC = REVERT"
s_secs:
.str " SEC UNTIL AUTOMATIC REVERT"
; st_draw r1=id
st_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@sd_id
CALL @g_clr
LD r1,r0,@sd_id
CALL @tx_org
LD r1,r0,@sd_id
CALL @wm_wbase
ST r1,r0,@sd_wb
MOVI r1,0
MOVI r2,0
MOVI r3,@s_st0
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,1
MOVI r3,@s_cur
MOVI r4,#C_CY
CALL @tx_s
MOVI r1,72
MOVI r2,1
LD r3,r0,@fb_w
LD r4,r0,@fb_h
MOVI r5,#C_TXT
MOVI r6,#C_TXT
CALL @tx_wh
ST r0,r0,@sd_i
sd_l:
LD r1,r0,@sd_i
MOVI r2,4
CMP r1,r2
JMP[GE] @sd_after
SHL r5,r1,2
MOVI r6,@st_items
ADD r5,r5,r6
ST r5,r0,@sd_p
LD r6,r5,3
LD r3,r0,@sd_wb
LD r4,r3,#W_A0
CMP r1,r4
JMP[NE] @sd_nsel
MOVI r6,#C_YEL
MOVI r1,0
LD r2,r0,@sd_i
MOVI r3,3
ADD r2,r2,r3
MOVI r3,62
MOVI r4,#C_YEL
ST r6,r0,@sd_col
CALL @tx_c
LD r6,r0,@sd_col
sd_nsel:
ST r6,r0,@sd_col
LD r5,r0,@sd_p
LD r3,r5,0
MOVI r1,16
LD r2,r0,@sd_i
MOVI r5,3
ADD r2,r2,r5
LD r4,r0,@sd_col
CALL @tx_s
LD r1,r0,@sd_i
MOVI r2,3
CMP r1,r2
JMP[EQ] @sd_cust
MOVI r2,2
CMP r1,r2
JMP[EQ] @sd_dis
LD r5,r0,@sd_p
LD r3,r5,1
LD r4,r5,2
MOVI r1,136
LD r2,r0,@sd_i
MOVI r6,3
ADD r2,r2,r6
LD r5,r0,@sd_col
ADD r6,r5,r0
CALL @tx_wh
JMP @sd_next
sd_dis:
MOVI r1,136
LD r2,r0,@sd_i
MOVI r6,3
ADD r2,r2,r6
MOVI r3,@s_dis
LD r4,r0,@sd_col
CALL @tx_s
JMP @sd_next
sd_cust:
LD r5,r0,@sd_wb
LD r3,r5,#W_A1
LD r4,r5,#W_A2
LD r6,r5,#W_A3
MOVI r8,15
MOVI r9,15
CMP r6,r0
MOVI[EQ] r8,14
CMP r6,r13
MOVI[EQ] r9,14
MOVI r1,136
LD r2,r0,@sd_i
MOVI r6,3
ADD r2,r2,r6
ADD r5,r8,r0
ADD r6,r9,r0
CALL @tx_wh
sd_next:
LD r1,r0,@sd_i
ADD r1,r1,r13
ST r1,r0,@sd_i
JMP @sd_l
sd_after:
LD r5,r0,@sd_wb
LD r6,r5,#W_A5
MOVI r7,@st_msgs
ADD r7,r7,r6
LD r3,r7,0
MOVI r1,0
MOVI r2,8
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,10
MOVI r3,@s_sh1
MOVI r4,#C_DIM
CALL @tx_s
MOVI r1,0
MOVI r2,11
MOVI r3,@s_sh2
MOVI r4,#C_DIM
CALL @tx_s
LD r5,r0,@st_pend
CMP r5,r0
JMP[EQ] @sd_done
MOVI r1,0
MOVI r2,13
MOVI r3,@s_keep
MOVI r4,#C_YEL
CALL @tx_s
TICK r5
LD r6,r0,@st_t0
SUB r5,r5,r6
MOVI r6,1000
DIVU r5,r5,r6
MOVI r6,10
MOVI r3,0
CMP r5,r6
JMP[GE] @sd_z
SUB r3,r6,r5
sd_z:
MOVI r1,0
MOVI r2,14
MOVI r4,#C_GRN
CALL @tx_d
CALL @tx_end
MOVI r2,14
MOVI r3,@s_secs
MOVI r4,#C_GRN
CALL @tx_s
sd_done:
SUB r14,r14,r13
LD r15,r14,0
RET
sd_id:
.word 0
sd_wb:
.word 0
sd_i:
.word 0
sd_p:
.word 0
sd_col:
.word 0
; st_key r1=id r3=key
st_key:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@sk_id
ST r3,r0,@sk_k
CALL @wm_wbase
ST r1,r0,@sk_wb
ST r0,r1,#W_A5
LD r3,r0,@sk_k
LD r4,r1,#W_A0
MOVI r5,0x110
CMP r3,r5
JMP[EQ] @sk_up
MOVI r5,0x111
CMP r3,r5
JMP[EQ] @sk_dn
MOVI r5,13
CMP r3,r5
JMP[EQ] @sk_apply
MOVI r5,3
CMP r4,r5
JMP[NE] @sk_draw
MOVI r5,0x112
CMP r3,r5
JMP[EQ] @sk_f0
MOVI r5,0x113
CMP r3,r5
JMP[EQ] @sk_f1
MOVI r5,8
CMP r3,r5
JMP[EQ] @sk_bs
MOVI r5,48
CMP r3,r5
JMP[LT] @sk_draw
MOVI r5,57
CMP r3,r5
JMP[GT] @sk_draw
MOVI r5,48
SUB r3,r3,r5
LD r6,r1,#W_A3
ADD r7,r1,r6
LD r8,r7,#W_A1
MOVI r9,10
MUL r8,r8,r9
ADD r8,r8,r3
MOVI r9,9999
CMP r8,r9
JMP[GT] @sk_draw
ST r8,r7,#W_A1
JMP @sk_draw
sk_bs:
LD r6,r1,#W_A3
ADD r7,r1,r6
LD r8,r7,#W_A1
MOVI r9,10
DIVU r8,r8,r9
ST r8,r7,#W_A1
JMP @sk_draw
sk_f0:
ST r0,r1,#W_A3
JMP @sk_draw
sk_f1:
ST r13,r1,#W_A3
JMP @sk_draw
sk_up:
CMP r4,r0
JMP[EQ] @sk_draw
SUB r4,r4,r13
ST r4,r1,#W_A0
JMP @sk_draw
sk_dn:
MOVI r5,3
CMP r4,r5
JMP[GE] @sk_draw
ADD r4,r4,r13
ST r4,r1,#W_A0
JMP @sk_draw
sk_apply:
CALL @st_do
sk_draw:
LD r1,r0,@sk_id
CALL @st_draw
SUB r14,r14,r13
LD r15,r14,0
RET
sk_id:
.word 0
sk_k:
.word 0
sk_wb:
.word 0
; st_do : apply the selected row (A5 gets a message when nothing is applied)
st_do:
ST r15,r14,0
ADD r14,r14,r13
LD r1,r0,@sk_wb
LD r4,r1,#W_A0
MOVI r5,2
CMP r4,r5
JMP[EQ] @sdo_rv
MOVI r5,3
CMP r4,r5
JMP[EQ] @sdo_cu
SHL r4,r4,2
MOVI r5,@st_items
ADD r4,r4,r5
LD r2,r4,1
LD r3,r4,2
JMP @sdo_go
sdo_cu:
LD r2,r1,#W_A1
LD r3,r1,#W_A2
MOVI r5,0xFFF8
BOOL.8 r2,r2,r5
MOVI r5,320
CMP r2,r5
JMP[LT] @sdo_bad
MOVI r5,1920
CMP r2,r5
JMP[GT] @sdo_bad
MOVI r5,200
CMP r3,r5
JMP[LT] @sdo_bad
MOVI r5,1600
CMP r3,r5
JMP[GT] @sdo_bad
MUL r5,r2,r3
MOVI r6,0x8480
MOVHI r6,0x1E
CMP r5,r6
JMP[GT] @sdo_bad
ST r2,r1,#W_A1
sdo_go:
LD r5,r0,@fb_w
CMP r2,r5
JMP[NE] @sdo_diff
LD r5,r0,@fb_h
CMP r3,r5
JMP[EQ] @sdo_same
sdo_diff:
CALL @st_apply
JMP @sdo_ret
sdo_same:
MOVI r5,5
JMP @sdo_msg
sdo_bad:
MOVI r5,2
JMP @sdo_msg
sdo_rv:
MOVI r5,1
sdo_msg:
ST r5,r1,#W_A5
sdo_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; st_apply r2=w r3=h : remember the current mode, arm the countdown, switch
st_apply:
ST r15,r14,0
ADD r14,r14,r13
LD r5,r0,@fb_w
ST r5,r0,@st_ow
LD r5,r0,@fb_h
ST r5,r0,@st_oh
ST r13,r0,@st_pend
ST r0,r0,@st_sec
TICK r5
ST r5,r0,@st_t0
SHL r1,r2,16
ADD r1,r1,r3
CALL @st_mode
SUB r14,r14,r13
LD r15,r14,0
RET
; st_mode r1 = w<<16|h : switch the display, re-fit every window, reseed the lattice, redraw
st_mode:
ST r15,r14,0
ADD r14,r14,r13
CALL @fb_init_mode
CALL @st_refit
ST r0,r0,@ls_w
ST r13,r0,@wm_redraw
SUB r14,r14,r13
LD r15,r14,0
RET
; st_refit : un-enlarge, then clamp every live window into the new screen
st_refit:
MOVI r1,0
srf_l:
MOVI r2,#MAXW
CMP r1,r2
RET[GE]
SHL r2,r1,5
MOVI r3,#WT
ADD r2,r2,r3
LD r3,r2,#W_ALIVE
CMP r3,r0
JMP[EQ] @srf_n
LD r3,r2,#W_FLAGS
CMP r3,r0
JMP[EQ] @srf_c
LD r3,r2,#W_SX
ST r3,r2,#W_X
LD r3,r2,#W_SY
ST r3,r2,#W_Y
LD r3,r2,#W_SW
ST r3,r2,#W_W
LD r3,r2,#W_SH
ST r3,r2,#W_H
ST r0,r2,#W_FLAGS
srf_c:
LD r4,r2,#W_W
LD r5,r0,@fb_w
CMP r4,r5
JMP[LE] @srf_w
ADD r4,r5,r0
ST r4,r2,#W_W
srf_w:
LD r6,r2,#W_H
LD r5,r0,@fb_h
MOVI r7,#TOPH
SUB r5,r5,r7
CMP r6,r5
JMP[LE] @srf_h
ADD r6,r5,r0
ST r6,r2,#W_H
srf_h:
LD r3,r2,#W_X
ADD r7,r3,r4
LD r5,r0,@fb_w
CMP r7,r5
JMP[LE] @srf_x
SUB r3,r5,r4
ST r3,r2,#W_X
srf_x:
LD r3,r2,#W_Y
ADD r7,r3,r6
LD r5,r0,@fb_h
CMP r7,r5
JMP[LE] @srf_y
SUB r3,r5,r6
srf_y:
MOVI r7,#TOPH
CMP r3,r7
JMP[GE] @srf_s
ADD r3,r7,r0
srf_s:
ST r3,r2,#W_Y
srf_n:
ADD r1,r1,r13
JMP @srf_l
; st_revert : back to the remembered mode
st_revert:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,@st_pend
LD r2,r0,@st_ow
LD r3,r0,@st_oh
SHL r1,r2,16
ADD r1,r1,r3
CALL @st_mode
SUB r14,r14,r13
LD r15,r14,0
RET
; st_pendkey r1=key : while the countdown runs ENTER keeps and ESC reverts; every other key is ignored
st_pendkey:
ST r15,r14,0
ADD r14,r14,r13
MOVI r2,13
CMP r1,r2
JMP[EQ] @pk_keep
MOVI r2,27
CMP r1,r2
JMP[EQ] @pk_rev
JMP @pk_ret
pk_keep:
ST r0,r0,@st_pend
MOVI r5,3
JMP @pk_msg
pk_rev:
CALL @st_revert
MOVI r5,4
pk_msg:
LD r1,r0,@st_wid
CALL @wm_wbase
ST r5,r1,#W_A5
ST r13,r0,@wm_redraw
pk_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
; st_tick r1=id : countdown; revert at 10 s, redraw the banner once per second
st_tick:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@stt_id
LD r2,r0,@st_pend
CMP r2,r0
JMP[EQ] @stt_ret
TICK r2
LD r3,r0,@st_t0
SUB r2,r2,r3
MOVI r3,#MODE_TMO
CMP r2,r3
JMP[LT] @stt_wait
CALL @st_revert
LD r1,r0,@st_wid
CALL @wm_wbase
MOVI r2,4
ST r2,r1,#W_A5
JMP @stt_ret
stt_wait:
MOVI r3,1000
DIVU r2,r2,r3
LD r3,r0,@st_sec
CMP r2,r3
JMP[EQ] @stt_ret
ST r2,r0,@st_sec
LD r1,r0,@stt_id
CALL @wm_covered
CMP r1,r0
JMP[NE] @stt_full
LD r1,r0,@stt_id
CALL @st_draw
JMP @stt_ret
stt_full:
ST r13,r0,@wm_redraw
stt_ret:
SUB r14,r14,r13
LD r15,r14,0
RET
stt_id:
.word 0
; ====================== NaNNet (kind 5): connection UI, no NIC driver yet ======================
; A0 selected row (0 connect, 1 address mode, 2 DNS mode)  A1 0 DHCP / 1 STATIC  A2 0 AUTO / 1 MANUAL  A3 link (0 idle, 1 probing, 2 no driver, 3 no adapter)  A4 probe start (TICK)
nn_init:
ST r15,r14,0
ADD r14,r14,r13
CALL @pci_scan
CALL @pci_nic
SUB r14,r14,r13
LD r15,r14,0
RET
nn_nic:
.word 0
t_net:
.str "NaNNet"
s_n0:
.str "NaNNet  NETWORK CONTROL  (DRIVER PENDING)"
s_n1:
.str "ADAPTER"
s_n2:
.str "STATUS"
s_n3:
.str "NONE ON PCI BUS 0"
s_n4:
.str "CONNECT"
s_n5:
.str "ADDRESS"
s_n6:
.str "DNS"
s_n7:
.str "HOST"
s_n8:
.str "NAN0S"
s_nh:
.str "UP/DOWN SELECT   ENTER OR LEFT/RIGHT CHANGE"
s_dhcp:
.str "DHCP"
s_stat:
.str "STATIC"
s_auto:
.str "AUTO"
s_man:
.str "MANUAL"
s_l0:
.str "DISCONNECTED"
s_l1:
.str "PROBING"
s_l2:
.str "ADAPTER FOUND, NO DRIVER YET (STUB)"
s_l3:
.str "NO ADAPTER FOUND"
s_io:
.str "IO"
nn_ls:
.word @s_l0,@s_l1,@s_l2,@s_l3
; nn_draw r1=id
nn_draw:
ST r15,r14,0
ADD r14,r14,r13
ST r1,r0,@nd_id
CALL @g_clr
LD r1,r0,@nd_id
CALL @tx_org
LD r1,r0,@nd_id
CALL @wm_wbase
ST r1,r0,@nd_wb
MOVI r1,0
MOVI r2,0
MOVI r3,@s_n0
MOVI r4,#C_YEL
CALL @tx_s
MOVI r1,0
MOVI r2,2
MOVI r3,@s_n1
MOVI r4,#C_CY
CALL @tx_s
LD r5,r0,@nn_nic
CMP r5,r0
JMP[NE] @nd_have
MOVI r1,72
MOVI r2,2
MOVI r3,@s_n3
MOVI r4,#C_DIM
CALL @tx_s
JMP @nd_stat
nd_have:
LD r3,r5,1
SHR r3,r3,16
MOVI r1,72
MOVI r2,2
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
MOVI r1,104
MOVI r2,2
MOVI r3,58
MOVI r4,#C_DIM
CALL @tx_c
LD r5,r0,@nn_nic
LD r3,r5,1
MOVI r6,0xFFFF
BOOL.8 r3,r3,r6
MOVI r1,112
MOVI r2,2
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
MOVI r1,168
MOVI r2,2
MOVI r3,@s_io
MOVI r4,#C_CY
CALL @tx_s
LD r5,r0,@nn_nic
LD r3,r5,3
MOVI r6,0xFFFC
BOOL.8 r3,r3,r6
MOVI r1,192
MOVI r2,2
MOVI r4,4
MOVI r5,#C_TXT
CALL @tx_h
nd_stat:
MOVI r1,0
MOVI r2,3
MOVI r3,@s_n2
MOVI r4,#C_CY
CALL @tx_s
LD r5,r0,@nd_wb
LD r6,r5,#W_A3
MOVI r7,@nn_ls
ADD r7,r7,r6
LD r3,r7,0
MOVI r1,72
MOVI r2,3
MOVI r4,#C_TXT
MOVI r8,2
CMP r6,r8
JMP[LT] @nd_sc
MOVI r4,#C_YEL
nd_sc:
CALL @tx_s
LD r5,r0,@nd_wb
LD r6,r5,#W_A3
CMP r6,r13
JMP[NE] @nd_rows
LD r5,r0,@nd_wb
LD r6,r5,#W_A4
TICK r7
SUB r7,r7,r6
MOVI r6,250
DIVU r7,r7,r6
MOVI r6,3
BOOL.8 r7,r7,r6
ADD r7,r7,r13
ST r7,r0,@nd_dots
ST r0,r0,@nd_i
nd_dl:
LD r1,r0,@nd_i
LD r2,r0,@nd_dots
CMP r1,r2
JMP[GE] @nd_rows
MOVI r2,8
MUL r1,r1,r2
MOVI r2,128
ADD r1,r1,r2
MOVI r2,3
MOVI r3,46
MOVI r4,#C_TXT
CALL @tx_c
LD r1,r0,@nd_i
ADD r1,r1,r13
ST r1,r0,@nd_i
JMP @nd_dl
nd_rows:
ST r0,r0,@nd_i
nd_rl:
LD r1,r0,@nd_i
MOVI r2,3
CMP r1,r2
JMP[GE] @nd_host
LD r5,r0,@nd_wb
LD r6,r5,#W_A0
MOVI r4,#C_TXT
CMP r1,r6
JMP[NE] @nd_nsel
MOVI r4,#C_YEL
ST r4,r0,@nd_col
MOVI r1,0
LD r2,r0,@nd_i
MOVI r3,5
ADD r2,r2,r3
MOVI r3,62
CALL @tx_c
LD r4,r0,@nd_col
LD r1,r0,@nd_i
nd_nsel:
ST r4,r0,@nd_col
; >>> TRUNCATED HERE (r25e). NOT ASSEMBLED, NOT TESTED, NOT IN ANY CARTRIDGE. Still to write: NaNNet rows/key/tick, Utilities (CPUID, TSC, ATA IDENTIFY, PCI), g_onkey F5-F7 hooks + st_pend capture, kdef/kt rows for kinds 4-6, terminal s/n/u commands, relative g_bar + short hint.
