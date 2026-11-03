; NANNET M2 gate: WiFi fixture backend, state transitions, config verbs.
main:
MOVI r13,1
; scan while wlan0 is down -> EPERM 7
MOVI r1,2
CALL @nn_wifi_scan
MOVI r8,7
CMP r3,r8
JMP[NE] @fail
; link up, scan -> 3 networks, state 2
MOVI r1,2
CALL @nn_link_up
MOVI r1,2
CALL @nn_wifi_scan
CMP r3,r0
JMP[NE] @fail
MOVI r8,3
CMP r1,r8
JMP[NE] @fail
CALL @nn_link_list
CALL @nn_wifi_list
; join index 9 -> EINVAL 1
MOVI r1,2
MOVI r2,9
CALL @nn_wifi_join
MOVI r8,1
CMP r3,r8
JMP[NE] @fail
; join index 1 (Cafe, rssi 42) -> state 4
MOVI r1,2
MOVI r2,1
CALL @nn_wifi_join
CMP r3,r0
JMP[NE] @fail
MOVI r8,42
CMP r2,r8
JMP[NE] @fail
CALL @nn_link_list
CALL @nn_wifi_list
; leave -> state 1, joined ssid cleared
MOVI r1,2
CALL @nn_wifi_leave
CALL @nn_link_list
CALL @nn_wifi_list
; join without a scan -> EPROTO 5
MOVI r1,2
MOVI r2,0
CALL @nn_wifi_join
MOVI r8,5
CMP r3,r8
JMP[NE] @fail
; scan on a wired interface -> EINVAL 1
MOVI r1,1
CALL @nn_wifi_scan
MOVI r8,1
CMP r3,r8
JMP[NE] @fail
; config: up, scan, join index 1
MOVI r1,@cfg
SHL r1,r1,2
CALL @nn_cfg_apply
CMP r3,r0
JMP[NE] @fail
CALL @nn_link_list
CALL @nn_wifi_list
; rollback restores the pre-apply state (up, not joined)
CALL @nn_cfg_rollback
CALL @nn_link_list
CALL @nn_wifi_list
; PASS
MOVI r1,87
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,73
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
MOVI r1,87
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,73
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
.str "link 2 1\nwscan 2\nwjoin 2 1\n"

.include "nannet.nas"
