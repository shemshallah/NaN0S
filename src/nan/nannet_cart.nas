; NANNET service cart (slot-less). System network manager console.
; ABI: r0=0, r13=1; text vectors V_PUTS/V_HEX/V_DEC/V_CLS/V_KEY.
.equ V_PUTS 1
.equ V_HEX 2
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.org 8192
JMP @svc_entry
.include "../nannet/nannet.nas"
svc_entry:
ST r15,r0,@svc_ret
MOVI r13,1
CALL @nn_tables_reset
svc_redraw:
CALL #V_CLS
MOVI r1,@sv_title
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sv_sub
MOVI r2,80
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sv_l_links
MOVI r2,160
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sv_l0
MOVI r2,240
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,0
MOVI r2,256
MOVI r3,0x0E00
CALL @svc_link_state
MOVI r1,@sv_l1
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,1
MOVI r2,336
MOVI r3,0x0E00
CALL @svc_link_state
MOVI r1,@sv_l2
MOVI r2,400
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,2
MOVI r2,416
MOVI r3,0x0E00
CALL @svc_link_state
MOVI r1,@sv_l3
MOVI r2,480
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,3
MOVI r2,496
MOVI r3,0x0E00
CALL @svc_link_state
MOVI r1,@sv_l_counts
MOVI r2,640
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL @svc_counts
MOVI r1,@sv_l_wifi
MOVI r2,800
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sv_wl0
MOVI r2,880
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,2
MOVI r2,892
MOVI r3,0x0E00
CALL @svc_link_state
MOVI r1,@sv_l_scan
MOVI r2,1040
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL @svc_scan_list
MOVI r1,@sv_foot
MOVI r2,1760
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @svc_exit
MOVI r4,49
CMP r1,r4
JMP[EQ] @svc_t01
MOVI r4,50
CMP r1,r4
JMP[EQ] @svc_t02
MOVI r4,51
CMP r1,r4
JMP[EQ] @svc_t03
MOVI r4,52
CMP r1,r4
JMP[EQ] @svc_t04
MOVI r4,83
CMP r1,r4
JMP[EQ] @svc_scan
MOVI r4,115
CMP r1,r4
JMP[EQ] @svc_scan
MOVI r4,74
CMP r1,r4
JMP[EQ] @svc_join
MOVI r4,106
CMP r1,r4
JMP[EQ] @svc_join
MOVI r4,76
CMP r1,r4
JMP[EQ] @svc_leave
MOVI r4,108
CMP r1,r4
JMP[EQ] @svc_leave
MOVI r4,82
CMP r1,r4
JMP[EQ] @svc_rb
MOVI r4,114
CMP r1,r4
JMP[EQ] @svc_rb
JMP @svc_redraw
svc_t01:
MOVI r1,0
JMP @svc_toggle
svc_t02:
MOVI r1,1
JMP @svc_toggle
svc_t03:
MOVI r1,2
JMP @svc_toggle
svc_t04:
MOVI r1,3
svc_toggle:
MOVI r4,@nn_ifs
MOVI r2,8
MUL r2,r1,r2
ADD r4,r4,r2
LD r3,r4,3
CMP r3,r0
JMP[NE] @svc_set0
MOVI r2,1
JMP @svc_set
svc_set0:
MOVI r2,0
svc_set:
CALL @nn_link_set
JMP @svc_redraw
svc_scan:
MOVI r1,2
CALL @nn_wifi_scan
JMP @svc_redraw
svc_join:
MOVI r1,2
MOVI r2,0
CALL @nn_wifi_join
JMP @svc_redraw
svc_leave:
MOVI r1,2
CALL @nn_wifi_leave
JMP @svc_redraw
svc_rb:
CALL @nn_cfg_rollback
JMP @svc_redraw
svc_exit:
LD r15,r0,@svc_ret
RET
svc_ret:
.word 0
; r1 = 0-based link index, r2 = target cell, r3 = attr<<8
svc_link_state:
ST r15,r0,@vls_ret
ST r1,r0,@vls_id
ST r2,r0,@vls_cell
ST r3,r0,@vls_attr
MOVI r4,@nn_ifs
MOVI r5,8
MUL r5,r1,r5
ADD r4,r4,r5
LD r1,r4,3
MOVI r4,@nn_state_tab
ADD r4,r4,r1
LD r1,r4,0
LD r2,r0,@vls_cell
LD r3,r0,@vls_attr
CALL #V_PUTS
LD r15,r0,@vls_ret
RET
vls_ret:
.word 0
vls_id:
.word 0
vls_cell:
.word 0
vls_attr:
.word 0
; counts row: up / addresses / routes / dns
svc_counts:
ST r15,r0,@vc_ret
MOVI r4,@nn_ifs
MOVI r5,4
MOVI r6,0
svc_cl:
CMP r5,r0
JMP[EQ] @svc_clp
LD r7,r4,3
CMP r7,r0
JMP[EQ] @svc_cn
ADDI r6,r6,1
svc_cn:
ADDI r4,r4,8
SUB r5,r5,r13
JMP @svc_cl
svc_clp:
ST r6,r0,@vc_a
MOVI r1,@sv_c_up
MOVI r2,720
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r2,726
MOVI r3,0x0E00
LD r1,r0,@vc_a
CALL #V_DEC
MOVI r4,@nn_addr
MOVI r5,6
MOVI r6,0
svc_cl2:
CMP r5,r0
JMP[EQ] @svc_cl2p
LD r7,r4,4
CMP r7,r0
JMP[EQ] @svc_cl2n
ADDI r6,r6,1
svc_cl2n:
ADDI r4,r4,5
SUB r5,r5,r13
JMP @svc_cl2
svc_cl2p:
ST r6,r0,@vc_n
MOVI r1,@sv_c_addr
MOVI r2,735
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r2,744
MOVI r3,0x0E00
LD r1,r0,@vc_n
CALL #V_DEC
MOVI r4,@nn_route
MOVI r5,8
MOVI r6,0
svc_cl3:
CMP r5,r0
JMP[EQ] @svc_cl3p
LD r7,r4,5
CMP r7,r0
JMP[EQ] @svc_cl3n
ADDI r6,r6,1
svc_cl3n:
ADDI r4,r4,6
SUB r5,r5,r13
JMP @svc_cl3
svc_cl3p:
ST r6,r0,@vc_n
MOVI r1,@sv_c_route
MOVI r2,752
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r2,761
MOVI r3,0x0E00
LD r1,r0,@vc_n
CALL #V_DEC
MOVI r4,@nn_dns
MOVI r5,2
MOVI r6,0
svc_cl4:
CMP r5,r0
JMP[EQ] @svc_cl4p
LD r7,r4,1
CMP r7,r0
JMP[EQ] @svc_cl4n
ADDI r6,r6,1
svc_cl4n:
ADDI r4,r4,2
SUB r5,r5,r13
JMP @svc_cl4
svc_cl4p:
ST r6,r0,@vc_n
MOVI r1,@sv_c_dns
MOVI r2,770
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r2,777
MOVI r3,0x0E00
LD r1,r0,@vc_n
CALL #V_DEC
LD r15,r0,@vc_ret
RET
vc_ret:
.word 0
vc_n:
.word 0
vc_a:
.word 0
; static three-entry Wi-Fi scan fixture with RSSI from the control plane
svc_scan_list:
ST r15,r0,@ssl_ret
MOVI r1,@sv_s0
MOVI r2,1120
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r4,@nn_scan_tab
LD r1,r4,1
MOVI r2,1138
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sv_s1
MOVI r2,1200
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r4,@nn_scan_tab
ADDI r4,r4,2
LD r1,r4,1
MOVI r2,1218
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sv_s2
MOVI r2,1280
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r4,@nn_scan_tab
ADDI r4,r4,4
LD r1,r4,1
MOVI r2,1298
MOVI r3,0x0E00
CALL #V_DEC
LD r15,r0,@ssl_ret
RET
ssl_ret:
.word 0
sv_title:
.str " NaN/0S  NANNET SERVICE"
sv_sub:
.str " system control plane"
sv_l_links:
.str "LINK"
sv_l0:
.str "0 LO     loop"
sv_l1:
.str "1 ETH0    wired"
sv_l2:
.str "2 WLAN0   wifi"
sv_l3:
.str "3 SEAM0   seam"
sv_l_counts:
.str "COUNTS"
sv_l_wifi:
.str "WLAN0"
sv_l_scan:
.str "SCAN"
sv_c_up:
.str "UP "
sv_c_addr:
.str "ADDR "
sv_c_route:
.str "ROUTE "
sv_c_dns:
.str "DNS "
sv_wl0:
.str "wlan0"
sv_s0:
.str "0 HomeNet   RSSI "
sv_s1:
.str "1 Cafe      RSSI "
sv_s2:
.str "2 Lab       RSSI "
sv_foot:
.str "1-4 link  S scan  J join  L leave  R rollback  ESC"
