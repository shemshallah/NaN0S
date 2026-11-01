; Host driver: runs the gui_cart.nas single-terminal-boot check (A2) as GUEST code under n16i.nas
; (the raw-NaN interpreter), per spec/TOOL01_PLAN.md - nan16sim.py here is only the outer box
; executing n16i.nas's own NaN16 words; it is not directly interpreting gui_cart.nas.
JMP @drv
.include "../tools/n16i.nas"
drv:
MOVI r13,1
MOVI r1,@boot_test
MOVI r2,0
MOVI r3,0
MOVHI r3,8      ; mask = 0x7FFFF (2^19-1): covers code + WT/ZO/STK (0x58000-0x59000) and PCIT (0x50300)
SUB r3,r3,r13
CALL @n16i_run
ST r1,r0,@res_steps
HALT
res_steps:
.word 0
boot_test:
MOVI r13,1
MOVI r14,#STKL
MOVHI r14,#STKH
CALL @wm_init
MOVI r1,0
CALL @gui_open_new
LD r1,r0,@wm_zn
ST r1,r0,@res_nwin
MOVI r2,#WTL
MOVHI r2,#WTH
LD r3,r2,#W_KIND
ST r3,r0,@res_kind0
LD r3,r2,#W_ALIVE
ST r3,r0,@res_alive0
HALT
res_nwin:
.word 0
res_kind0:
.word 0
res_alive0:
.word 0
.include "../exhibits/gui_cart.nas"
