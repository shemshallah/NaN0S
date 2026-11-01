; NaN/0S MUSEUM - round 18. Exhibit cartridge system.

.org 0
JMP @sh_cold

; Vector table (words 1-31)
.org 1
v_puts:
NOP
v_hex:
NOP
v_dec:
NOP
v_cls:
NOP
v_key:
NOP
v_keyq:
NOP
v_tick:
NOP
v_putc:
NOP
v_bcopy:
NOP
v_seal_verify:
NOP
v_seal_show:
NOP
v_scroll:
NOP
v_13:
NOP
v_14:
NOP
v_15:
NOP
v_16:
NOP
v_17:
NOP
v_18:
NOP
v_19:
NOP
v_20:
NOP
v_21:
NOP
v_22:
NOP
v_23:
NOP
v_24:
NOP
v_25:
NOP
v_26:
NOP
v_27:
NOP
v_28:
NOP
v_29:
NOP
v_30:
NOP
v_31:
NOP

.org 32
.include "../lib/libvec.nas"

.org 512
sh_cold:
MOVI r1,78
PUTC r1
MOVI r1,97
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,47
PUTC r1
MOVI r1,48
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,50
PUTC r1
MOVI r1,54
PUTC r1
MOVI r1,74
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,68
PUTC r1
MOVI r1,89
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,77
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,78
PUTC r1
MOVI r1,85
PUTC r1
MOVI r1,61
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,13
PUTC r1
MOVI r1,10
PUTC r1
.include "shell.nas"
