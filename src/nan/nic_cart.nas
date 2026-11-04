; nic_cart.nas - RTL8139 PCI bring-up probe (I/O BAR, MAC).
; PCI config byte offsets: command=4, BAR0=16.
.org 8192
main:
MOVI r13,1
ST r15,r0,@nc_ret
CALL @nic_probe
LD r15,r0,@nc_ret
RET

pci_rd:
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
pci_wr:
SHL r4,r1,8
BOOL.14 r4,r4,r2
MOVI r5,0
MOVHI r5,0x8000
BOOL.14 r4,r4,r5
MOVI r5,0xCF8
OUTL r4,r5
MOVI r5,0xCFC
OUTL r3,r5
RET

nic_probe:
ST r15,r0,@np_ret
MOVI r10,0
nfl:
MOVI r2,32
CMP r10,r2
JMP[GE] @nnone
ADDI r1,r10,0
SHL r1,r1,3
MOVI r2,0
CALL @pci_rd
MOVI r3,0xFFFF
BOOL.8 r4,r1,r3
MOVI r3,0x10EC
CMP r4,r3
JMP[NE] @nfn
SHR r1,r1,16
MOVI r3,0x8139
CMP r1,r3
JMP[EQ] @nfound
nfn:
ADDI r10,r10,1
JMP @nfl
nfound:
; Enable I/O space + bus mastering (command register, offset 4).
ADDI r1,r10,0
SHL r1,r1,3
MOVI r2,4
CALL @pci_rd
MOVI r3,5
BOOL.14 r1,r1,r3
ADDI r3,r1,0
ADDI r1,r10,0
SHL r1,r1,3
MOVI r2,4
CALL @pci_wr
; BAR0 is byte offset 16 (0x10).
ADDI r1,r10,0
SHL r1,r1,3
MOVI r2,16
CALL @pci_rd
MOVI r3,0xFFFC
BOOL.8 r1,r1,r3
ST r1,r0,@nc_base
CMP r1,r0
JMP[EQ] @nnone
MOVI r1,@t_nic
CALL @sputs
MOVI r1,0x10EC
CALL @puthex4
MOVI r1,32
PUTC r1
MOVI r1,0x8139
CALL @puthex4
MOVI r1,@t_base
CALL @sputs
LD r1,r0,@nc_base
CALL @puthex4
MOVI r1,32
PUTC r1
MOVI r8,0
nmac:
MOVI r9,6
CMP r8,r9
JMP[GE] @ndone
LD r6,r0,@nc_base
ADD r7,r6,r8
INB r1,r7
CALL @puthex2
ADDI r8,r8,1
MOVI r1,58
PUTC r1
JMP @nmac
ndone:
; RTL8139 reset and enable RX/TX, then read media status.
LD r6,r0,@nc_base
MOVI r5,0x37
ADD r5,r6,r5
MOVI r2,0x10
OUTB r2,r5
MOVI r8,10000
nrst:
INB r1,r5
MOVI r3,16
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[EQ] @nrst_d
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @nrst
nrst_d:
MOVI r2,0x0C
OUTB r2,r5
MOVI r5,0x58
ADD r5,r6,r5
INW r1,r5
ST r1,r0,@nc_msr
MOVI r1,32
PUTC r1
MOVI r1,@t_reset
CALL @sputs
LD r1,r0,@nc_msr
CALL @puthex4
MOVI r1,10
PUTC r1
; build a 60-byte Ethernet ARP request in the raw DMA window
MOVI r9,0xF000
MOVI r1,255
STB r1,r9,0
MOVI r1,255
STB r1,r9,1
MOVI r1,255
STB r1,r9,2
MOVI r1,255
STB r1,r9,3
MOVI r1,255
STB r1,r9,4
MOVI r1,255
STB r1,r9,5
MOVI r1,82
STB r1,r9,6
MOVI r1,84
STB r1,r9,7
MOVI r1,0
STB r1,r9,8
MOVI r1,18
STB r1,r9,9
MOVI r1,52
STB r1,r9,10
MOVI r1,86
STB r1,r9,11
MOVI r1,8
STB r1,r9,12
MOVI r1,6
STB r1,r9,13
MOVI r1,0
STB r1,r9,14
MOVI r1,1
STB r1,r9,15
MOVI r1,8
STB r1,r9,16
MOVI r1,0
STB r1,r9,17
MOVI r1,6
STB r1,r9,18
MOVI r1,4
STB r1,r9,19
MOVI r1,0
STB r1,r9,20
MOVI r1,1
STB r1,r9,21
MOVI r1,82
STB r1,r9,22
MOVI r1,84
STB r1,r9,23
MOVI r1,0
STB r1,r9,24
MOVI r1,18
STB r1,r9,25
MOVI r1,52
STB r1,r9,26
MOVI r1,86
STB r1,r9,27
MOVI r1,10
STB r1,r9,28
MOVI r1,0
STB r1,r9,29
MOVI r1,2
STB r1,r9,30
MOVI r1,15
STB r1,r9,31
MOVI r1,0
STB r1,r9,32
MOVI r1,0
STB r1,r9,33
MOVI r1,0
STB r1,r9,34
MOVI r1,0
STB r1,r9,35
MOVI r1,0
STB r1,r9,36
MOVI r1,0
STB r1,r9,37
MOVI r1,10
STB r1,r9,38
MOVI r1,0
STB r1,r9,39
MOVI r1,2
STB r1,r9,40
MOVI r1,2
STB r1,r9,41
MOVI r1,0
STB r1,r9,42
MOVI r1,0
STB r1,r9,43
MOVI r1,0
STB r1,r9,44
MOVI r1,0
STB r1,r9,45
MOVI r1,0
STB r1,r9,46
MOVI r1,0
STB r1,r9,47
MOVI r1,0
STB r1,r9,48
MOVI r1,0
STB r1,r9,49
MOVI r1,0
STB r1,r9,50
MOVI r1,0
STB r1,r9,51
MOVI r1,0
STB r1,r9,52
MOVI r1,0
STB r1,r9,53
MOVI r1,0
STB r1,r9,54
MOVI r1,0
STB r1,r9,55
MOVI r1,0
STB r1,r9,56
MOVI r1,0
STB r1,r9,57
MOVI r1,0
STB r1,r9,58
MOVI r1,0
STB r1,r9,59
; TXAD0 = raw physical 0x01000000
MOVI r5,0x20
ADD r5,r6,r5
MOVI r1,0
MOVHI r1,0x0100
OUTL r1,r5
; TCR = 0x03000700
MOVI r5,0x40
ADD r5,r6,r5
MOVI r1,0x0700
MOVHI r1,0x0300
OUTL r1,r5
; TSD0 = 60 bytes
MOVI r5,0x10
ADD r5,r6,r5
MOVI r2,60
OUTL r2,r5
MOVI r8,60000
nictx:
INW r1,r5
MOVI r3,0x8000
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @nictx_ok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @nictx
MOVI r1,@t_txno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
nictx_ok:
MOVI r1,@t_txok
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
nnone:
MOVI r1,@t_none
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET

sputs:
SHL r1,r1,2
spl:
LDB r2,r1,0
CMP r2,r0
JMP[EQ] @spd
PUTC r2
ADDI r1,r1,1
JMP @spl
spd:
RET
puthex4:
ST r15,r0,@ph4_ret
ADDI r9,r1,0
SHR r2,r9,12
MOVI r3,15
BOOL.8 r1,r2,r3
CALL @phx
SHR r2,r9,8
MOVI r3,15
BOOL.8 r1,r2,r3
CALL @phx
SHR r2,r9,4
MOVI r3,15
BOOL.8 r1,r2,r3
CALL @phx
MOVI r3,15
BOOL.8 r1,r9,r3
CALL @phx
LD r15,r0,@ph4_ret
RET
puthex2:
ST r15,r0,@ph2_ret
ADDI r9,r1,0
SHR r2,r9,4
MOVI r3,15
BOOL.8 r1,r2,r3
CALL @phx
MOVI r3,15
BOOL.8 r1,r9,r3
CALL @phx
LD r15,r0,@ph2_ret
RET
phx:
MOVI r2,10
CMP r1,r2
JMP[LT] @phxd
ADDI r1,r1,55
PUTC r1
RET
phxd:
ADDI r1,r1,48
PUTC r1
RET
t_nic:
.str "NIC "
t_base:
.str " BASE "
t_none:
.str "NIC NONE"
t_reset:
.str "RESET "
t_txok:
.str "TX OK"
t_txno:
.str "TX FAIL"
nc_ret:
.word 0
np_ret:
.word 0
nc_base:
.word 0
nc_msr:
.word 0
ph4_ret:
.word 0
ph2_ret:
.word 0
