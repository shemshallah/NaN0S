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
JMP @a2_chk
res_nwin:
.word 0
res_kind0:
.word 0
res_alive0:
.word 0
; ---- self-check: exactly one window, terminal kind, and alive (A2's actual assertions;
; res_steps is filled by the outer driver AFTER n16i_run, so the guest cannot read it here) ----
a2_chk:
MOVI r2,1
LD r1,r0,@res_nwin
CMP r1,r2
JMP[NE] @a2_fail
LD r1,r0,@res_kind0
CMP r1,r0
JMP[NE] @a2_fail
LD r1,r0,@res_alive0
CMP r1,r2
JMP[NE] @a2_fail
MOVI r1,65
PUTC r1
MOVI r1,50
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
MOVI r1,10
PUTC r1
HALT
a2_fail:
MOVI r1,65
PUTC r1
MOVI r1,50
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
MOVI r1,10
PUTC r1
HALT
.include "../exhibits/gui_cart.nas"
