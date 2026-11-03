; NANNET M1 test: config apply, listings, route lookup, rollback, restore-on-
; failure, link up/down, address del/add. Expected serial transcript is gated
; by tools/netcfg_gate.sh; final line is NANNET PASS.
main:
MOVI r13,1
; apply the system config
MOVI r1,@cfg
SHL r1,r1,2
CALL @nn_cfg_apply
CMP r3,r0
JMP[NE] @fail
; state transcript
CALL @nn_link_list
CALL @nn_addr_list
CALL @nn_route_list
CALL @nn_dns_list
CALL @nn_status
; longest-prefix lookup: default route matches anything
MOVI r1,0x1234
CALL @nn_route_lookup
CMP r3,r0
JMP[NE] @fail
MOVI r8,0x0A01
CMP r1,r8
JMP[NE] @fail
MOVI r8,1
CMP r2,r8
JMP[NE] @fail
; driver 9 loaded by the config
MOVI r1,9
CALL @nn_drv_find
CMP r5,r0
JMP[EQ] @fail
LD r8,r5,2
MOVI r9,1
CMP r8,r9
JMP[NE] @fail
; rollback restores the pre-apply generation
CALL @nn_cfg_rollback
CALL @nn_link_list
CALL @nn_addr_list
CALL @nn_route_list
CALL @nn_dns_list
CALL @nn_status
MOVI r1,9
CALL @nn_drv_find
LD r8,r5,2
CMP r8,r0
JMP[NE] @fail
; apply again, then a bad config must restore the good state
MOVI r1,@cfg
SHL r1,r1,2
CALL @nn_cfg_apply
CMP r3,r0
JMP[NE] @fail
MOVI r1,@badcfg
SHL r1,r1,2
CALL @nn_cfg_apply
MOVI r8,1
CMP r3,r8
JMP[NE] @fail
MOVI r1,2
CALL @nn_if_find
CMP r5,r0
JMP[EQ] @fail
LD r8,r5,3
CMP r8,r0
JMP[NE] @fail
CALL @nn_addr_list
CALL @nn_status
; link down / up
MOVI r1,1
CALL @nn_link_down
CALL @nn_link_list
MOVI r1,1
CALL @nn_link_up
; address del / add
MOVI r1,1
MOVI r2,0x0A00
CALL @nn_addr_del
CALL @nn_addr_list
MOVI r1,1
MOVI r2,0x0A00
MOVI r3,16
CALL @nn_addr_add
CALL @nn_addr_list
; PASS
MOVI r1,78
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,13
PUTC r1
MOVI r1,10
PUTC r1
HALT
fail:
MOVI r1,78
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,13
PUTC r1
MOVI r1,10
PUTC r1
HALT
cfg:
.str "# system.nancfg\nlink 0 1\nlink 1 1\naddr 1 0x0A00 16\nroute 0x0000 0 0x0A01 1 1\ndns 0x0A01\ndriver 9 1\ndriver 10 1\n"
badcfg:
.str "link 2 1\nbogus 9\n"

.include "nannet.nas"
