; NaN/0S shell (round 18) - exhibit cartridge loader.
; Entry: word 0 JMPs here (shell_entry at word 512).
; r0=0, r13=1, r14=SP, r15=link.

.equ SLOT 8192
.equ TOC_BASE 22000
.equ STR_BASE 2048
.equ BABY_STORE 3072

shell_entry:
MOVI r13,1
; ---- 1. Fill jump-vector table ----
; v_puts -> lib_vputs
MOVI r1,@lib_vputs
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_puts
MOVI r3,15
STW r1,r2,r3

; v_hex -> lib_vhex
MOVI r1,@lib_vhex
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_hex
MOVI r3,15
STW r1,r2,r3

; v_dec -> lib_vdec
MOVI r1,@lib_vdec
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_dec
MOVI r3,15
STW r1,r2,r3

; v_cls -> lib_vcls
MOVI r1,@lib_vcls
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_cls
MOVI r3,15
STW r1,r2,r3

; v_key -> lib_key
MOVI r1,@lib_key
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_key
MOVI r3,15
STW r1,r2,r3

; v_keyq -> lib_keyq
MOVI r1,@lib_keyq
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_keyq
MOVI r3,15
STW r1,r2,r3

; v_tick -> lib_tick
MOVI r1,@lib_tick
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_tick
MOVI r3,15
STW r1,r2,r3

; v_putc -> lib_putc
MOVI r1,@lib_putc
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_putc
MOVI r3,15
STW r1,r2,r3

; v_bcopy -> lib_bcopy
MOVI r1,@lib_bcopy
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_bcopy
MOVI r3,15
STW r1,r2,r3

; v_seal_verify -> lib_seal_verify
MOVI r1,@lib_seal_verify
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_seal_verify
MOVI r3,15
STW r1,r2,r3

; v_seal_show -> lib_seal_show
MOVI r1,@lib_seal_show
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_seal_show
MOVI r3,15
STW r1,r2,r3

; v_scroll -> lib_vscroll (general 80x25 text scroll)
MOVI r1,@lib_vscroll
MOVI r8,10
SHL r8,r8,24
BOOL.14 r1,r1,r8
MOVI r2,@v_scroll
MOVI r3,15
STW r1,r2,r3

; ---- cold boot: run the system cart (GUI desktop) when the builder declared one;
; its entry opens a single CLI window (A2). ESC/q there returns to this menu.
; boot_rec is separate from the exhibit TOC, so slots stay free for exhibits.
LA r10,@boot_rec
LD r1,r10,0
CMP r1,r0
JMP[EQ] @sh_redraw
JMP @sh_run

; ---- 2. Clear screen and display menu ----
sh_redraw:
CALL @v_cls

sh_menu:
MOVI r1,@sh_banner
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL @v_puts

; ---- count visible entries, derive pages, clamp page ----
MOVI r10,#TOC_BASE
MOVI r8,0
shc_loop:
LD r1,r10,0
CMP r1,r0
JMP[EQ] @shc_done
LD r1,r10,7
MOVI r4,1
BOOL.8 r1,r1,r4
CMP r1,r0
JMP[NE] @shc_next
ADDI r8,r8,1
shc_next:
MOVI r4,16
ADD r10,r10,r4
JMP @shc_loop
shc_done:
ADDI r1,r8,8
MOVI r2,9
DIVU r1,r1,r2
CMP r1,r0
JMP[NE] @shc_pages
MOVI r1,1
shc_pages:
ST r1,r0,@sh_pages
LD r1,r0,@sh_page
LD r2,r0,@sh_pages
CMP r1,r2
JMP[LT] @shc_clamped
SUB r2,r2,r13
ST r2,r0,@sh_page
shc_clamped:
LD r1,r0,@sh_page
MOVI r2,9
MUL r1,r1,r2
ST r1,r0,@sh_pstart
ADDI r1,r1,9
ST r1,r0,@sh_pend

; ---- TOC-driven page: entry = 16 words (see TOC layout below); ends at id 0 ----
MOVI r10,#TOC_BASE
MOVI r11,324
ST r0,r0,@sh_visidx
shm_loop:
LD r1,r10,0
CMP r1,r0
JMP[EQ] @shm_done
LD r2,r10,7
MOVI r4,1
BOOL.8 r2,r2,r4
CMP r2,r0
JMP[NE] @shm_hidden
LD r2,r0,@sh_pstart
LD r9,r0,@sh_visidx
CMP r9,r2
JMP[LT] @shm_skip
LD r2,r0,@sh_pend
LD r9,r0,@sh_visidx
CMP r9,r2
JMP[GE] @shm_done
LD r2,r0,@sh_pstart
LD r9,r0,@sh_visidx
SUB r1,r9,r2
ADDI r1,r1,1
MOVI r4,0x0F5B
VPOKE r4,r11
ADD r2,r11,r13
MOVI r3,0x0F00
CALL @v_dec
MOVI r4,0x0F5D
ADD r2,r11,r13
ADD r2,r2,r13
VPOKE r4,r2
LD r1,r10,1
MOVI r2,5
ADD r2,r2,r11
MOVI r3,0x0E00
CALL @v_dec
LD r1,r10,3
MOVI r2,10
ADD r2,r2,r11
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL @v_puts
LD r4,r10,6
LD r1,r4,@sh_btab
MOVI r2,90
ADD r2,r2,r11
MOVI r3,0x0B00
MOVI r5,0
MOVI r6,0
CALL @v_puts
MOVI r4,160
ADD r11,r11,r4
LD r1,r0,@sh_visidx
ADDI r1,r1,1
ST r1,r0,@sh_visidx
JMP @shm_next
shm_skip:
LD r1,r0,@sh_visidx
ADDI r1,r1,1
ST r1,r0,@sh_visidx
shm_hidden:
shm_next:
MOVI r4,16
ADD r10,r10,r4
JMP @shm_loop
shm_done:
MOVI r1,@sh_more
MOVI r2,1760
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL @v_puts
LD r1,r0,@sh_page
ADDI r1,r1,1
MOVI r2,1816
MOVI r3,0x0800
CALL @v_dec

MOVI r1,@sh_foot
MOVI r2,1840
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL @v_puts

; ---- 3. Wait for key ----
sh_key:
CALL @v_key
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,115
CMP r1,r4
JMP[EQ] @sh_sys
MOVI r4,0x7E
CMP r1,r4
JMP[EQ] @sh_curator
MOVI r4,27
CMP r1,r4
JMP[EQ] @sh_redraw
MOVI r4,93
CMP r1,r4
JMP[EQ] @sh_pgnext
MOVI r4,91
CMP r1,r4
JMP[EQ] @sh_pgprev
MOVI r4,48
CMP r1,r4
JMP[LT] @sh_key
MOVI r4,57
CMP r1,r4
JMP[GT] @sh_key
MOVI r4,48
SUB r1,r1,r4
SUB r1,r1,r13
LD r2,r0,@sh_page
MOVI r3,9
MUL r2,r2,r3
ADD r1,r1,r2
ST r1,r0,@sh_target
MOVI r10,#TOC_BASE
MOVI r8,0
shk_find:
LD r2,r10,0
CMP r2,r0
JMP[EQ] @sh_key
LD r3,r10,7
MOVI r4,1
BOOL.8 r3,r3,r4
CMP r3,r0
JMP[NE] @shk_skip
LD r3,r0,@sh_target
CMP r8,r3
JMP[EQ] @sh_run
ADDI r8,r8,1
shk_skip:
MOVI r4,16
ADD r10,r10,r4
JMP @shk_find
sh_pgnext:
LD r1,r0,@sh_page
LD r2,r0,@sh_pages
ADDI r3,r1,1
CMP r3,r2
JMP[GE] @sh_key
ST r3,r0,@sh_page
JMP @sh_redraw
sh_pgprev:
LD r1,r0,@sh_page
CMP r1,r0
JMP[EQ] @sh_key
SUB r1,r1,r13
ST r1,r0,@sh_page
JMP @sh_redraw

; ---- load + seal-check + run the cartridge whose TOC entry is at r10 ----
sh_run:
LD r1,r10,4
LD r2,r10,5
CALL @v_seal_verify
BOOL.12 r12,r1,r1
BOOL.12 r11,r2,r2
CMP r12,r13
JMP[EQ] @sh_seal_ok
MOVI r1,@sh_bad
MOVI r2,1600
MOVI r3,0x0C00
MOVI r5,0
MOVI r6,0
CALL @v_puts
LD r1,r12,@sh_rtab
MOVI r2,1680
MOVI r3,0x0E00
MOVI r5,0
MOVI r6,0
CALL @v_puts
CMP r12,r0
JMP[EQ] @sh_key
BOOL.12 r1,r11,r11
MOVI r2,1760
MOVI r3,0x0E00
CALL @v_dec
JMP @sh_key
sh_seal_ok:
MOVI r1,8192
LD r2,r10,4
LD r3,r10,5
CALL @v_bcopy
CALL 8192
; public program request: a desktop program can ask the shell to load a hidden slot
LA r10,@nsh_req
LD r1,r10,0
CMP r1,r0
JMP[EQ] @sh_after_prog
ST r0,r10,0
CALL @v_cls
MOVI r10,#TOC_BASE
shsr_find:
LD r2,r10,0
CMP r2,r0
JMP[EQ] @sh_after_prog
CMP r2,r1
JMP[EQ] @sh_run
MOVI r4,16
ADD r10,r10,r4
JMP @shsr_find
sh_after_prog:
MOVI r13,1
JMP @sh_redraw

sh_curator:
CALL @cu_entry
JMP @sh_redraw
sh_sys:
CALL @sys_menu
JMP @sh_redraw

; ---- Curator Console: raw guest words, read-only. Secret key: ~ ----
cu_entry:
ST r15,r0,@cu_ret
MOVI r1,0
ST r1,r0,@cu_base
cu_redraw:
CALL @v_cls
MOVI r10,0
cu_row:
MOVI r4,24
CMP r10,r4
JMP[GE] @cu_key
LD r1,r0,@cu_base
MOVI r4,4
MUL r4,r10,r4
ADD r1,r1,r4
MOVI r2,80
MUL r2,r10,r2
MOVI r3,0x0E00
CALL @v_hex
MOVI r11,0
cu_word:
MOVI r4,4
CMP r11,r4
JMP[GE] @cu_next
LD r1,r0,@cu_base
MOVI r4,4
MUL r4,r10,r4
ADD r1,r1,r4
ADD r1,r1,r11
LD r1,r1,0
MOVI r2,10
MOVI r4,9
MUL r4,r11,r4
ADD r2,r2,r4
MOVI r4,80
MUL r4,r10,r4
ADD r2,r2,r4
MOVI r3,0x0F00
CALL @v_hex
ADD r11,r11,r13
JMP @cu_word
cu_next:
ADD r10,r10,r13
JMP @cu_row
cu_key:
MOVI r1,@cu_foot
MOVI r2,1920
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL @v_puts
CALL @v_key
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @cu_exit
MOVI r4,0x80
CMP r1,r4
JMP[EQ] @cu_up
MOVI r4,0x81
CMP r1,r4
JMP[EQ] @cu_down
MOVI r4,0x82
CMP r1,r4
JMP[EQ] @cu_pgup
MOVI r4,0x83
CMP r1,r4
JMP[EQ] @cu_pgdn
JMP @cu_key
cu_up:
LD r1,r0,@cu_base
CMP r1,r0
JMP[EQ] @cu_key
SUB r1,r1,r13
ST r1,r0,@cu_base
JMP @cu_redraw
cu_down:
LD r1,r0,@cu_base
ADD r1,r1,r13
MOVI r2,32672
CMP r1,r2
JMP[LE] @cu_down_ok
ADD r1,r2,r0
cu_down_ok:
ST r1,r0,@cu_base
JMP @cu_redraw
cu_pgup:
LD r1,r0,@cu_base
MOVI r2,96
CMP r1,r2
JMP[LT] @cu_pgup0
SUB r1,r1,r2
JMP @cu_pgup_ok
cu_pgup0:
MOVI r1,0
cu_pgup_ok:
ST r1,r0,@cu_base
JMP @cu_redraw
cu_pgdn:
LD r1,r0,@cu_base
MOVI r2,96
ADD r1,r1,r2
MOVI r2,32672
CMP r1,r2
JMP[LE] @cu_pgdn_ok
ADD r1,r2,r0
cu_pgdn_ok:
ST r1,r0,@cu_base
JMP @cu_redraw
cu_exit:
LD r15,r0,@cu_ret
RET
cu_ret:
.word 0
cu_base:
.word 0
cu_title:
.str " CURATOR CONSOLE - RAW GUEST WORDS - 8 HEX ADDRESS + 4 PAYLOADS"
cu_foot:
.str "CURATOR CONSOLE  UP/DOWN word  LEFT/RIGHT page  ESC shell  key ~"

; ---- Data ----
sh_banner:
.str " NaN/0S  MUSEUM OF COMPUTING  (exhibit cartridges)  v40          "
sh_more:
.str " PAGE "
sh_btab:
.word @sh_b0
.word @sh_b1
.word @sh_b2
sh_b0:
.str "EXACT: original program/data bit-for-bit"
sh_b1:
.str "RE-CREATION: same behaviour, rewritten"
sh_b2:
.str "INSPIRED: in the spirit of the original"
sh_rtab:
.word @sh_r0
.word @sh_r0
.word @sh_r2
.word @sh_r3
sh_r0:
.str "seal differs: near payload / far-face payload / class-nibble channel"
sh_r2:
.str "illegal head (gate fails) at cartridge word:"
sh_r3:
.str "mirror law broken (BSWAPM face != software swap) at cartridge word:"
sh_bad:
.str "SEAL MISMATCH - cartridge REFUSED (not loaded, not run)"
sh_foot:
.str "ring 0, no host OS. 1-9 run item; [ ] page; ESC redraw. NaN/0S v40\n"

; ---- System menu: settings, NaNNet, disk, memory, CPU ----
sys_menu:
  ST r15,r0,@sm_ret
  CALL @v_cls
  MOVI r1,@sm_title
  MOVI r2,0
  MOVI r3,0x1F00
  MOVI r5,0
  MOVI r6,0
  CALL @v_puts
  MOVI r1,@sm_body
  MOVI r2,160
  MOVI r3,0x0F00
  MOVI r5,0
  MOVI r6,0
  CALL @v_puts
  MOVI r1,@sm_foot
  MOVI r2,1840
  MOVI r3,0x0800
  MOVI r5,0
  MOVI r6,0
  CALL @v_puts
sm_key:
  CALL @v_key
  MOVI r4,255
  BOOL.8 r1,r1,r4
  MOVI r4,27
  CMP r1,r4
  JMP[EQ] @sm_exit
  MOVI r4,49
  CMP r1,r4
  JMP[EQ] @sm_settings
  MOVI r4,50
  CMP r1,r4
  JMP[EQ] @sm_net
  JMP @sm_key
sm_settings:
  MOVI r1,@st_title
  MOVI r2,@st_body
  CALL @sys_show
  JMP @sys_menu
sm_net:
  LA r10,@service_rec
  LD r1,r10,0
  CMP r1,r0
  JMP[NE] @sh_run
  MOVI r1,@net_title
  MOVI r2,@net_body
  CALL @sys_show
  JMP @sys_menu
sm_disk:
  MOVI r1,@disk_title
  MOVI r2,@disk_body
  CALL @sys_show
  JMP @sys_menu
sm_mem:
  MOVI r1,@mem_title
  MOVI r2,@mem_body
  CALL @sys_show
  JMP @sys_menu
sm_cpu:
  MOVI r1,@cpu_title
  MOVI r2,@cpu_body
  CALL @sys_show
  JMP @sys_menu
sm_exit:
  LD r15,r0,@sm_ret
  RET
sm_ret:
.word 0

sys_show:
  ST r15,r0,@ss_ret
  ST r2,r0,@ss_body
  CALL @v_cls
  MOVI r2,0
  MOVI r3,0x1F00
  MOVI r5,0
  MOVI r6,0
  CALL @v_puts
  LD r1,r0,@ss_body
  MOVI r2,160
  MOVI r3,0x0F00
  MOVI r5,0
  MOVI r6,0
  CALL @v_puts
  MOVI r1,@sys_foot
  MOVI r2,1840
  MOVI r3,0x0800
  MOVI r5,0
  MOVI r6,0
  CALL @v_puts
  CALL @v_key
  LD r15,r0,@ss_ret
  RET
ss_ret:
.word 0
ss_body:
.word 0

; Catalog: 16 words per entry, BUILT by tools/mkimg.awk from tools/carts.txt:
; [0] catalog id (0 = end of list) | [1] year | [2] hall | [3] title_ptr |
; [4] store addr | [5] len words | [6] badge (0 EXACT 1 RE-CREATION 2 INSPIRED) |
; [7] flags (bit0 hidden) | [8] seal A | [9] meta_ptr | [10] seal B | [11] seal C |
; [12-15] reserved. Titles live at 23600 (16 words each); the catalog is paged
; by the shell. Order and wording are edited in carts.txt only.
.equ TOC_BASE 22000
.equ BOOT_BASE 4784
.equ SERVICE_BASE 4816
.org 4784
boot_rec:
; system cart record (the GUI desktop), same 16-word shape. [0]=0 -> boot to menu.
; NOT an exhibit slot: slot 9 is the Settings cart.
.org 4800
nsh_req:
.word 0
.org 4816
service_rec:
; slot-less service cart record (SYSTEM menu [2]), same 16-word shape.
.org 4864
sh_page:
.word 0
sh_pages:
.word 1
sh_pstart:
.word 0
sh_pend:
.word 9
sh_target:
.word 0
sh_visidx:
.word 0
.org 5376
sm_title:
.str " NaN/0S  SYSTEM"
sm_body:
.str " [1] SETTINGS\n [2] NANNET SERVICE\n [3] DISK UTILITY\n [4] MEMORY UTILITY\n [5] CPU / ARCHITECTURE\n\n ESC returns to the museum."
sm_foot:
.str "NaN/0S SYSTEM  1-2 open  ESC main menu"
sys_foot:
.str "NaN/0S  any key returns to the system menu"
st_title:
.str " NaN/0S  SETTINGS"
st_body:
.str " VISUAL MODES\n 80x25 text is current.\n 320x200 pixel is live for Sierpinski and Paradox.\n 1024x768 GUI is planned, VBE driver not yet.\n AArch64 phone, x86, and RISC-V layouts are planned.\n\n CONFIRMATION RULE\n A future visual mode change will show a 10 second countdown\n and revert to the previous mode if no key is pressed."
net_title:
.str " NaN/0S  NANNET"
net_body:
.str " CONNECT\n No NIC driver yet. No link.\n SETTINGS\n Node NaN-0001, transport serial/ATA, no network stack.\n Plan: NaN16 IPv4/UDP loopback over COM1, then a PCIe NIC\n driver with DMA and a NaNNet settings page."
disk_title:
.str " NaN/0S  DISK UTILITY"
disk_body:
.str " ATA primary master: read PASS (sector 0 = NAN0).\n ATA PIO write: C-core PASS (16-bit OUTW); QEMU/real pending.\n NaNFS RAM: format/alloc/write/read PASS.\n Image: 1.44 MB, guest 32,768 words.\n Next: QEMU/real write validation, then NaNFS on disk."
mem_title:
.str " NaN/0S  MEMORY UTILITY"
mem_body:
.str " Guest image: 65,536 words (512 KB).\n Runtime G window: 8 MB at 0x200000.\n nalloc heap and MEMQ/E820 discovery are planned.\n Current exhibits use fixed buffers below the store.\n Store: 3,072..14,516 words."
cpu_title:
.str " NaN/0S  CPU / ARCHITECTURE"
cpu_body:
.str " Native core: x86, 5,800 bytes.\n Guest ISA: NaN16 double-endian, 16 truth-table classes.\n Clock: PIT TICK, 1,000 Hz class.\n AArch64 and RISC-V native cores: planned.\n Android root detection: host-only, not bare metal."



; ---- paged cartridge catalog area (builder writes 16-word entries at 22000) ----
.org 22000
toc:
