; SETTINGS cart (slot 9). NANNET Manager, Driver Manager, Codec Manager.
; ABI: r0=0, r13=1; shell text vectors V_PUTS/V_DEC/V_CLS/V_KEY.
.equ V_PUTS 1
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.org 8192
JMP @sg_entry
.include "../nannet/nannet.nas"
.include "../lib/timing.nas"
sg_entry:
ST r15,r0,@sg_ret
MOVI r13,1
CALL @nn_tables_reset
sg_menu:
CALL #V_CLS
MOVI r1,@sg_title
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu1
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu2
MOVI r2,480
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu3
MOVI r2,640
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu4
MOVI r2,800
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu5
MOVI r2,960
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu6
MOVI r2,1120
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu7
MOVI r2,1280
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_menu8
MOVI r2,1440
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_exit
MOVI r4,49
CMP r1,r4
JMP[EQ] @sg_net
MOVI r4,50
CMP r1,r4
JMP[EQ] @sg_drv
MOVI r4,51
CMP r1,r4
JMP[EQ] @sg_codec
MOVI r4,52
CMP r1,r4
JMP[EQ] @sg_storage
MOVI r4,53
CMP r1,r4
JMP[EQ] @sg_nic
MOVI r4,54
CMP r1,r4
JMP[EQ] @sg_tim
MOVI r4,55
CMP r1,r4
JMP[EQ] @sg_cpu
JMP @sg_menu
sg_svc:
CALL #V_CLS
MOVI r1,@sg_svc_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc1
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc2
MOVI r2,480
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc3
MOVI r2,640
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc4
MOVI r2,800
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc5
MOVI r2,960
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc6
MOVI r2,1120
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_svc_bl
MOVI r2,1280
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_svc_bits
MOVI r2,1520
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_svc_f
MOVI r2,1600
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_net
MOVI r4,49
CMP r1,r4
JMP[LT] @sg_svc
MOVI r4,54
CMP r1,r4
JMP[GT] @sg_svc
MOVI r4,49
SUB r1,r1,r4
MOVI r2,@sg_svc_masks
ADD r2,r2,r1
LD r2,r2,0
LD r1,r0,@sg_svc_bits
BOOL.6 r1,r1,r2
ST r1,r0,@sg_svc_bits
JMP @sg_svc
sg_tim:
CALL #V_CLS
MOVI r1,@sg_tim_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_tim_l0
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
TICK r1
MOVI r2,400
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_tim_l1
MOVI r2,480
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL @tm_ping_get
ST r1,r0,@sg_num
LD r1,r0,@sg_num
MOVI r2,560
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_tim_l2
MOVI r2,640
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_num
MOVI r2,720
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_tim_l3
MOVI r2,800
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_num
MOVI r2,880
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_tim_l4
MOVI r2,1040
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,1000
MOVI r2,2
CALL @tm_rate
MOVI r2,1120
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_tim_f
MOVI r2,1280
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_menu
JMP @sg_tim
sg_cpu:
CALL #V_CLS
MOVI r1,@sg_cpu_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_cpu_l
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL @tm_cpu_mhz
MOVI r2,400
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@sg_cpu_f
MOVI r2,960
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_menu
JMP @sg_cpu
sg_storage:
MOVI r1,4800
MOVI r2,10
ST r2,r1,0
JMP @sg_exit
sg_nic:
CALL #V_CLS
MOVI r1,@sg_nic_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL @sg_nic_probe
CMP r1,r0
JMP[EQ] @sg_nic_no
MOVI r1,@sg_nic_y
JMP @sg_nic_pr
sg_nic_no:
MOVI r1,@sg_nic_n
sg_nic_pr:
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_nic_f
MOVI r2,960
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_menu
JMP @sg_nic
sg_nic_probe:
ST r15,r0,@sg_nic_ret
MOVI r10,0
sg_nic_l:
MOVI r2,32
CMP r10,r2
JMP[GE] @sg_nic_none
ADDI r1,r10,0
SHL r1,r1,3
MOVI r2,0
CALL @sg_pci_rd
MOVI r3,0xFFFF
BOOL.8 r4,r1,r3
MOVI r3,0x10EC
CMP r4,r3
JMP[NE] @sg_nic_next
SHR r1,r1,16
MOVI r3,0x8139
CMP r1,r3
JMP[EQ] @sg_nic_yes
sg_nic_next:
ADDI r10,r10,1
JMP @sg_nic_l
sg_nic_yes:
MOVI r1,1
LD r15,r0,@sg_nic_ret
RET
sg_nic_none:
MOVI r1,0
LD r15,r0,@sg_nic_ret
RET
sg_pci_rd:
SHL r3,r1,8
BOOL.14 r3,r3,r2
MOVI r4,0
MOVHI r4,0x8000
BOOL.14 r3,r3,r4
MOVI r5,0xCF8
OUTL r3,r5
MOVI r5,0xCFC
INW r6,r5
MOVI r5,0xCFE
INW r7,r5
SHL r7,r7,16
BOOL.14 r1,r6,r7
RET
sg_exit:
LD r15,r0,@sg_ret
RET
sg_ret:
.word 0
sg_nic_ret:
.word 0

; ---- NANNET manager ------------------------------------------------------
sg_net:
CALL #V_CLS
MOVI r1,@sg_net_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@nn_ifs
MOVI r2,4
MOVI r3,8
MOVI r4,3
CALL @sg_count
MOVI r2,320
ST r1,r0,@sg_num
MOVI r1,@sg_links
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_num
MOVI r2,400
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@nn_addr
MOVI r2,6
MOVI r3,5
MOVI r4,4
CALL @sg_count
ST r1,r0,@sg_num
MOVI r1,@sg_addrs
MOVI r2,480
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_num
MOVI r2,560
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@nn_route
MOVI r2,8
MOVI r3,6
MOVI r4,5
CALL @sg_count
ST r1,r0,@sg_num
MOVI r1,@sg_routes
MOVI r2,640
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_num
MOVI r2,720
MOVI r3,0x0E00
CALL #V_DEC
MOVI r1,@nn_dns
MOVI r2,2
MOVI r3,2
MOVI r4,1
CALL @sg_count
MOVI r2,880
ST r1,r0,@sg_num
MOVI r1,@sg_dns
MOVI r2,800
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r1,r0,@sg_num
MOVI r2,880
MOVI r3,0x0E00
CALL #V_DEC
CALL @sg_nic_probe
CMP r1,r0
JMP[EQ] @sg_net_nonic
MOVI r1,@sg_net_nic_y
JMP @sg_net_nic_p
sg_net_nonic:
MOVI r1,@sg_net_nic_n
sg_net_nic_p:
MOVI r2,960
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_net_ctrl
MOVI r2,1120
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_menu
MOVI r4,49
CMP r1,r4
JMP[EQ] @sg_lo_up
MOVI r4,50
CMP r1,r4
JMP[EQ] @sg_lo_dn
MOVI r4,51
CMP r1,r4
JMP[EQ] @sg_et_up
MOVI r4,52
CMP r1,r4
JMP[EQ] @sg_et_dn
MOVI r4,115
CMP r1,r4
JMP[EQ] @sg_svc
JMP @sg_net
sg_lo_up:
MOVI r1,0
CALL @nn_link_up
JMP @sg_net
sg_lo_dn:
MOVI r1,0
CALL @nn_link_down
JMP @sg_net
sg_et_up:
MOVI r1,1
CALL @nn_link_up
JMP @sg_net
sg_et_dn:
MOVI r1,1
CALL @nn_link_down
JMP @sg_net
sg_count:
MOVI r5,0
sg_c_l:
CMP r2,r0
JMP[EQ] @sg_c_d
ADD r6,r1,r4
LD r6,r6,0
CMP r6,r0
JMP[EQ] @sg_c_s
ADDI r5,r5,1
sg_c_s:
ADD r1,r1,r3
SUB r2,r2,r13
JMP @sg_c_l
sg_c_d:
ADD r1,r5,r0
RET

; ---- driver manager ------------------------------------------------------
sg_drv:
CALL #V_CLS
MOVI r1,@sg_drv_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_drv_h
MOVI r2,80
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@nn_drv_reg
ST r1,r0,@sg_rec
MOVI r1,13
ST r1,r0,@sg_n
MOVI r1,160
ST r1,r0,@sg_off
sg_d_l:
LD r1,r0,@sg_n
CMP r1,r0
JMP[EQ] @sg_d_done
LD r7,r0,@sg_rec
LD r1,r7,0
ST r1,r0,@sg_id
LD r2,r0,@sg_off
MOVI r3,0x0F00
CALL #V_DEC
LD r7,r0,@sg_rec
LD r1,r7,1
LD r2,r0,@sg_off
ADDI r2,r2,8
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LD r7,r0,@sg_rec
LD r1,r7,2
LD r2,r0,@sg_off
ADDI r2,r2,60
MOVI r3,0x0E00
CALL #V_DEC
LD r1,r0,@sg_rec
ADDI r1,r1,3
ST r1,r0,@sg_rec
LD r1,r0,@sg_n
SUB r1,r1,r13
ST r1,r0,@sg_n
LD r1,r0,@sg_off
ADDI r1,r1,80
ST r1,r0,@sg_off
JMP @sg_d_l
sg_d_done:
MOVI r1,@sg_drv_ctrl
MOVI r2,1200
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_menu
MOVI r4,49
CMP r1,r4
JMP[LT] @sg_drv
MOVI r4,57
CMP r1,r4
JMP[GT] @sg_drv
MOVI r4,48
SUB r1,r1,r4
ST r1,r0,@sg_id
CALL @nn_drv_find
CMP r5,r0
JMP[EQ] @sg_drv
LD r6,r5,2
MOVI r2,1
CMP r6,r0
JMP[EQ] @sg_d_set
MOVI r2,0
sg_d_set:
LD r1,r0,@sg_id
CALL @nn_drv_set
JMP @sg_drv

; ---- codec manager -------------------------------------------------------
sg_codec:
CALL #V_CLS
MOVI r1,@sg_cod_t
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_cod_b
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@sg_cod_f
MOVI r2,1120
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
CALL #V_KEY
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @sg_menu
JMP @sg_codec

sg_title:
.str " SETTINGS"
sg_tim_t:
.str " TIMING"
sg_tim_l0:
.str "TICK MS"
sg_tim_l1:
.str "PING COUNT"
sg_tim_l2:
.str "PING AVG MS"
sg_tim_l3:
.str "PING MAX MS"
sg_tim_l4:
.str "SAMPLE RATE 1000 BYTES/2MS"
sg_tim_f:
.str "ESC BACK"
sg_cpu_t:
.str " CPU TIMING"
sg_cpu_l:
.str "CPU MHZ"
sg_cpu_f:
.str "ESC BACK"
sg_svc_t:
.str " SERVICE MANAGER"
sg_svc1:
.str "[1] TELNET 23  TCP PENDING"
sg_svc2:
.str "[2] QOTD 17    UDP PENDING"
sg_svc3:
.str "[3] FINGER 79  TCP PENDING"
sg_svc4:
.str "[4] GOPHER 70  TCP PENDING"
sg_svc5:
.str "[5] HTTP 80    TCP PENDING"
sg_svc6:
.str "[6] HTTPS 443  TLS PENDING"
sg_svc_bl:
.str "ENABLED BITS "
sg_svc_f:
.str "1-6 TOGGLE   ESC BACK"
sg_nic_t:
.str " NIC STATUS"
sg_nic_y:
.str " RTL8139 FOUND"
sg_nic_n:
.str " NO RTL8139 ON PCI BUS 0"
sg_nic_f:
.str " ESC BACK"
sg_menu1:
.str "[1] NANNET MANAGER"
sg_menu2:
.str "[2] DRIVER MANAGER"
sg_menu3:
.str "[3] CODEC MANAGER"
sg_menu4:
.str "[4] STORAGE (nsh)"
sg_menu5:
.str "[5] NIC STATUS"
sg_menu6:
.str "[6] TIMING"
sg_menu7:
.str "[7] CPU TIMING"
sg_menu8:
.str "ESC BACK"
sg_net_t:
.str " NANNET MANAGER"
sg_net_nic_y:
.str "NIC RTL8139 LIVE"
sg_net_nic_n:
.str "NIC NONE"
sg_links:
.str "LINKS "
sg_addrs:
.str "ADDRS "
sg_routes:
.str "ROUTES "
sg_dns:
.str "DNS "
sg_net_ctrl:
.str "1-4 LINK  S SERVICES  ESC BACK"
sg_num:
.word 0
sg_tim_bits:
.word 0
sg_svc_bits:
.word 0
sg_svc_masks:
.word 1,2,4,8,16,32
sg_drv_t:
.str " DRIVER MANAGER"
sg_drv_h:
.str "ID NAME LOAD"
sg_drv_ctrl:
.str "1-9 TOGGLE DRIVER   ESC BACK"
sg_cod_t:
.str " CODEC MANAGER"
sg_cod_b:
.str "NSP-7   STORAGE   READY\nNSP-8   STORAGE   REFERENCE\nNSPF1   FILE      READY\nNSPV1   VOLUME    READY\nBASE64  TEXT      READY\nHEX     TEXT      READY"
sg_cod_f:
.str "ESC BACK"
sg_rec:
.word 0
sg_n:
.word 0
sg_off:
.word 0
sg_id:
.word 0
