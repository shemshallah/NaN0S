; nfix_test.nas - r29h: nasm0 FIXPOINT gate, entirely in the guest, source read from a NaNFS disk (ATA PIO), no scaffold at run time.
; gen0 = this image built by the one-time host seed (tools/nmk.awk). Its own source (flattened, tools/nflat.awk) sits on the disk
; (tools/nmkfs.sh, nan_cli --disk). Stage 1 (native): pristine-copy own words, load source via ata_read28 + nanfs_read, assemble it
; with nasm0 (2 passes) and require OUT == own words (payload AND class nibble) -> gen1 == gen0. Stage 2: copy gen1 (the GUEST-emitted
; words, not gen0) into a window, run it under src/tools/n16i.nas with mode=1 (source pre-placed); gen1 assembles the same source and
; checks itself against ITS pristine copy -> gen2 == gen1. Prints F1 PASS, F2 PASS, FIX PASS.
JMP @nf_main
.include "../tools/n16i.nas"
.include "../prog/nasm0.nas"
.include "../lib/ata.nas"
.include "../lib/nanfs.nas"
.equ NSTK 24576
.equ NTMP 28672
.equ NVB 0x10000
.equ NPRIS 0x20000
.equ NSRC 0x40000
.equ NOUT 0x80000
.equ NLAB 0xA0000
.equ NGB 0x100000
.equ NGM 0xFFFFF
.equ VM_MODE 6300
.equ VM_RES 6301
.equ VM_SRCN 6302
.equ VM_I 6303
.equ VM_SECS 6304
.equ VM_B 6305
.equ VM_D 6306
.equ VM_STEPS 6307
.equ VM_FB 6308
nf_main:
MOVI r13,1
MOVI r14,#NSTK
LA r1,#NPRIS
MOVI r2,0
MOVI r3,@nf_end
BCOPY r1,r2,r3
LD r1,r0,#VM_MODE
CMP r1,r0
JMP[NE] @nf_have
CALL @nf_load
nf_have:
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
CALL @nf_cmp
ST r6,r0,#VM_STEPS
LD r1,r0,#V_ERR
CMP r1,r0
ADD[NE] r6,r6,r13
MOVI r1,@nf_sF
CALL @nf_puts
LD r1,r0,#VM_MODE
MOVI r2,49
ADD r2,r2,r1
PUTC r2
CMP r6,r0
JMP[NE] @nf_bad
MOVI r1,@nf_sP
CALL @nf_puts
LD r1,r0,#V_IDX
CALL @nf_hex
MOVI r1,10
PUTC r1
LD r1,r0,#VM_MODE
CMP r1,r0
JMP[NE] @nf_g2
; ---- stage 2: gen1 = the words nasm0 just emitted, run under n16i
LA r4,#NGB
ADD r1,r4,r0
LD r2,r0,#V_OUTB
MOVI r3,@nf_end
BCOPY r1,r2,r3
LA r5,#NSRC
ST r5,r4,#V_SRCB
LA r5,#NOUT
ST r5,r4,#V_OUTB
LA r5,#NLAB
ST r5,r4,#V_LABB
LA r1,#NSRC
ADD r1,r1,r4
LA r2,#NSRC
LD r3,r0,#VM_SRCN
BCOPY r1,r2,r3
MOVI r5,1
ST r5,r4,#VM_MODE
ST r0,r4,#VM_RES
MOVI r1,0
ADD r2,r4,r0
LA r3,#NGM
CALL @n16i_run
MOVI r13,1
MOVI r14,#NSTK
ST r1,r0,#VM_STEPS
LA r4,#NGB
LD r5,r4,#VM_RES
MOVI r6,1
CMP r5,r6
JMP[NE] @nf_xf
LD r1,r0,#VM_STEPS
MOVI r2,8
CMP r1,r2
JMP[LT] @nf_xf
MOVI r1,@nf_sFIX
CALL @nf_puts
MOVI r1,@nf_sP
CALL @nf_puts
LD r1,r0,#VM_STEPS
CALL @nf_hex
MOVI r1,10
PUTC r1
HALT
nf_xf:
MOVI r1,@nf_sFIX
CALL @nf_puts
MOVI r1,@nf_sX
CALL @nf_puts
MOVI r1,10
PUTC r1
HALT
nf_g2:
MOVI r1,1
ST r1,r0,#VM_RES
HALT
nf_bad:
MOVI r1,@nf_sX
CALL @nf_puts
LD r1,r0,#V_FIRST
CALL @nf_hex
MOVI r1,32
PUTC r1
LD r1,r0,#V_IDX
CALL @nf_hex
MOVI r1,10
PUTC r1
LD r9,r0,#V_FIRST
LD r2,r0,#V_OUTB
ADD r2,r2,r9
LD r1,r2,0
CALL @nf_hex
MOVI r1,32
PUTC r1
LDN r1,r2,0
CALL @nf_hex
MOVI r1,32
PUTC r1
LA r2,#NPRIS
ADD r2,r2,r9
LD r1,r2,0
CALL @nf_hex
MOVI r1,32
PUTC r1
LDN r1,r2,0
CALL @nf_hex
MOVI r1,10
PUTC r1
HALT
; ---- compare OUT with the pristine copy: payload AND class nibble; r6 = mismatches (+1 if word count != nf_end)
nf_cmp:
ST r15,r14,0
ADD r14,r14,r13
MOVI r5,0
MOVI r6,0
MOVI r7,@nf_end
LD r10,r0,#V_OUTB
LA r11,#NPRIS
nc1:
CMP r5,r7
JMP[GE] @ncx
ADD r2,r10,r5
LD r3,r2,0
LDN r8,r2,0
ADD r2,r11,r5
LD r4,r2,0
LDN r9,r2,0
CMP r3,r4
JMP[NE] @ncb
CMP r8,r9
JMP[EQ] @nco
ncb:
ADD r6,r6,r13
CMP r6,r13
ST[EQ] r5,r0,#V_FIRST
nco:
ADD r5,r5,r13
JMP @nc1
ncx:
LD r2,r0,#V_IDX
CMP r2,r7
ADD[NE] r6,r6,r13
SUB r14,r14,r13
LD r15,r14,0
RET
; ---- load: NaNFS volume (2 blocks per ATA sector, each 32-bit word = two LE u16) -> NVB, then file blocks -> NSRC via nanfs_read
nf_load:
ST r15,r14,0
ADD r14,r14,r13
ST r0,r0,#VM_I
nl_s:
LD r1,r0,#VM_I
MOVI r2,#NTMP
CALL @ata_read28
LD r1,r0,#VM_I
SHL r6,r1,7
LA r7,#NVB
ADD r6,r6,r7
MOVI r5,0
MOVI r8,#NTMP
nl_u:
LD r1,r8,0
LD r2,r8,1
SHL r2,r2,16
BOOL.14 r1,r1,r2
ST r1,r6,0
ADD r6,r6,r13
ADD r8,r8,r13
ADD r8,r8,r13
ADD r5,r5,r13
MOVI r4,128
CMP r5,r4
JMP[LT] @nl_u
LD r1,r0,#VM_I
CMP r1,r0
JMP[NE] @nl_n
LA r2,#NVB
LD r3,r2,0
LA r4,#NF_MAGIC
CMP r3,r4
JMP[NE] @nl_bad
LD r3,r2,1
SHR r3,r3,1
ST r3,r0,#VM_SECS
nl_n:
LD r1,r0,#VM_I
ADD r1,r1,r13
ST r1,r0,#VM_I
LD r2,r0,#VM_SECS
CMP r1,r2
JMP[LT] @nl_s
LA r1,#NVB
LD r2,r1,4
ST r2,r0,#VM_SRCN
LA r1,#NSRC
ST r1,r0,#V_SRCB
ST r1,r0,#VM_D
LA r1,#NOUT
ST r1,r0,#V_OUTB
LA r1,#NLAB
ST r1,r0,#V_LABB
LA r1,#NVB
LD r5,r1,3
ST r5,r0,#VM_FB
ST r5,r0,#VM_B
nl_b:
LD r5,r0,#VM_B
LD r4,r0,#VM_FB
SUB r2,r5,r4
SHL r2,r2,6
LD r1,r0,#VM_SRCN
CMP r2,r1
JMP[GE] @nl_e
LA r1,#NVB
ADD r2,r5,r0
LD r3,r0,#VM_D
CALL @nanfs_read
LD r5,r0,#VM_B
ADD r5,r5,r13
ST r5,r0,#VM_B
LD r3,r0,#VM_D
MOVI r4,64
ADD r3,r3,r4
ST r3,r0,#VM_D
JMP @nl_b
nl_e:
SUB r14,r14,r13
LD r15,r14,0
RET
nl_bad:
MOVI r1,@nf_sN
CALL @nf_puts
HALT
; ---- console helpers (4 chars per word, LE, NUL-terminated)
nf_puts:
MOVI r4,255
nfp:
LD r2,r1,0
MOVI r3,4
nfq:
BOOL.8 r5,r2,r4
CMP r5,r0
RET[EQ]
PUTC r5
SHR r2,r2,8
SUB r3,r3,r13
JMP[NE] @nfq
ADD r1,r1,r13
JMP @nfp
nf_hex:
MOVI r3,8
MOVI r4,10
MOVI r7,7
nfh:
SHR r2,r1,28
SHL r1,r1,4
MOVI r6,48
ADD r6,r6,r2
CMP r2,r4
ADD[GE] r6,r6,r7
PUTC r6
SUB r3,r3,r13
JMP[NE] @nfh
RET
nf_sF:
.str "F"
nf_sP:
.str " PASS words="
nf_sX:
.str " FAIL first="
nf_sFIX:
.str "FIX"
nf_sN:
.str "NFS BAD\n"
nf_end:
