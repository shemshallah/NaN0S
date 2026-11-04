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
MOVI r1,10
PUTC r1
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
; Locally administered MAC: 02:4E:41:4E:30:53 ("NAN0S").
MOVI r5,0x00
ADD r5,r6,r5
MOVI r2,0x02
OUTB r2,r5
MOVI r5,0x01
ADD r5,r6,r5
MOVI r2,0x4E
OUTB r2,r5
MOVI r5,0x02
ADD r5,r6,r5
MOVI r2,0x41
OUTB r2,r5
MOVI r5,0x03
ADD r5,r6,r5
MOVI r2,0x4E
OUTB r2,r5
MOVI r5,0x04
ADD r5,r6,r5
MOVI r2,0x30
OUTB r2,r5
MOVI r5,0x05
ADD r5,r6,r5
MOVI r2,0x53
OUTB r2,r5
MOVI r1,@t_mac
CALL @sputs
MOVI r1,0x024E
CALL @puthex4
MOVI r1,0x414E
CALL @puthex4
MOVI r1,0x3053
CALL @puthex4
MOVI r1,10
PUTC r1
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
; RX ring physical 0x01000000; TX frame lives at raw +0x800.
MOVI r5,0x30
ADD r5,r6,r5
MOVI r1,0
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x44
ADD r5,r6,r5
MOVI r1,0xF00F
OUTL r1,r5
MOVI r5,0x38
ADD r5,r6,r5
MOVI r2,0
OUTB r2,r5
; build a 60-byte Ethernet ARP request in the raw DMA window
MOVI r9,0xF800
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
MOVI r1,2
STB r1,r9,6
MOVI r1,78
STB r1,r9,7
MOVI r1,65
STB r1,r9,8
MOVI r1,78
STB r1,r9,9
MOVI r1,48
STB r1,r9,10
MOVI r1,83
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
MOVI r1,2
STB r1,r9,22
MOVI r1,78
STB r1,r9,23
MOVI r1,65
STB r1,r9,24
MOVI r1,78
STB r1,r9,25
MOVI r1,48
STB r1,r9,26
MOVI r1,83
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
MOVI r1,76
STB r1,r9,42
MOVI r1,79
STB r1,r9,43
MOVI r1,32
STB r1,r9,44
MOVI r1,70
STB r1,r9,45
MOVI r1,82
STB r1,r9,46
MOVI r1,79
STB r1,r9,47
MOVI r1,77
STB r1,r9,48
MOVI r1,32
STB r1,r9,49
MOVI r1,78
STB r1,r9,50
MOVI r1,65
STB r1,r9,51
MOVI r1,78
STB r1,r9,52
MOVI r1,48
STB r1,r9,53
MOVI r1,83
STB r1,r9,54
MOVI r1,32
STB r1,r9,55
MOVI r1,49
STB r1,r9,56
MOVI r1,57
STB r1,r9,57
MOVI r1,54
STB r1,r9,58
MOVI r1,57
STB r1,r9,59
; TXAD0 = raw physical 0x01000000
MOVI r5,0x20
ADD r5,r6,r5
MOVI r1,0x0800
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
; Wait for RTL8139 ROK. The first 4 KB of the RX ring maps to F000.
MOVI r5,0x3E
ADD r5,r6,r5
MOVI r8,60000
nicrx:
INW r1,r5
MOVI r3,1
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @nicrx_ok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @nicrx
MOVI r1,@t_rxno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
nicrx_ok:
MOVI r7,0xF000
LDB r1,r7,0
MOVI r3,1
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[EQ] @nicrx_bad
; RX header is 4 bytes; Ethernet frame starts at raw+4.
LDB r1,r7,16
MOVI r3,8
CMP r1,r3
JMP[NE] @nicrx_plain
LDB r1,r7,17
MOVI r3,6
CMP r1,r3
JMP[NE] @nicrx_plain
; ARP opcode reply = 2 at frame+20 -> raw+24.
LDB r1,r7,25
MOVI r3,2
CMP r1,r3
JMP[NE] @nicrx_plain
MOVI r1,@t_arp
CALL @sputs
MOVI r8,32
narp:
MOVI r9,36
CMP r8,r9
JMP[GE] @narp_d
LDB r1,r7,0
ADD r1,r1,r8
; LDB has no register address; reload via a second base.
MOVI r6,0xF000
ADD r6,r6,r8
LDB r1,r6,0
CALL @puthex2
ADDI r8,r8,1
JMP @narp
narp_d:
MOVI r1,10
PUTC r1
MOVI r1,@t_pad
CALL @sputs
MOVI r1,10
PUTC r1
; Reset and reinitialize the RX ring before the next protocol step.
LD r6,r0,@nc_base
MOVI r5,0x37
ADD r5,r6,r5
MOVI r2,0x10
OUTB r2,r5
MOVI r8,10000
pingrst:
INB r1,r5
MOVI r3,16
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[EQ] @pingrst_d
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @pingrst
pingrst_d:
MOVI r2,0x0C
OUTB r2,r5
MOVI r5,0x30
ADD r5,r6,r5
MOVI r1,0
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x44
ADD r5,r6,r5
MOVI r1,0xF00F
OUTL r1,r5
MOVI r5,0x38
ADD r5,r6,r5
MOVI r2,0
OUTB r2,r5
; Build a 60-byte ICMP echo request.
MOVI r9,0xF800
MOVI r1,82
STB r1,r9,0
MOVI r1,85
STB r1,r9,1
MOVI r1,10
STB r1,r9,2
MOVI r1,0
STB r1,r9,3
MOVI r1,2
STB r1,r9,4
MOVI r1,2
STB r1,r9,5
MOVI r1,2
STB r1,r9,6
MOVI r1,78
STB r1,r9,7
MOVI r1,65
STB r1,r9,8
MOVI r1,78
STB r1,r9,9
MOVI r1,48
STB r1,r9,10
MOVI r1,83
STB r1,r9,11
MOVI r1,8
STB r1,r9,12
MOVI r1,0
STB r1,r9,13
MOVI r1,69
STB r1,r9,14
MOVI r1,0
STB r1,r9,15
MOVI r1,0
STB r1,r9,16
MOVI r1,44
STB r1,r9,17
MOVI r1,0
STB r1,r9,18
MOVI r1,1
STB r1,r9,19
MOVI r1,0
STB r1,r9,20
MOVI r1,0
STB r1,r9,21
MOVI r1,64
STB r1,r9,22
MOVI r1,1
STB r1,r9,23
MOVI r1,98
STB r1,r9,24
MOVI r1,192
STB r1,r9,25
MOVI r1,10
STB r1,r9,26
MOVI r1,0
STB r1,r9,27
MOVI r1,2
STB r1,r9,28
MOVI r1,15
STB r1,r9,29
MOVI r1,10
STB r1,r9,30
MOVI r1,0
STB r1,r9,31
MOVI r1,2
STB r1,r9,32
MOVI r1,2
STB r1,r9,33
MOVI r1,8
STB r1,r9,34
MOVI r1,0
STB r1,r9,35
MOVI r1,241
STB r1,r9,36
MOVI r1,238
STB r1,r9,37
MOVI r1,0
STB r1,r9,38
MOVI r1,1
STB r1,r9,39
MOVI r1,0
STB r1,r9,40
MOVI r1,1
STB r1,r9,41
MOVI r1,78
STB r1,r9,42
MOVI r1,97
STB r1,r9,43
MOVI r1,78
STB r1,r9,44
MOVI r1,32
STB r1,r9,45
MOVI r1,33
STB r1,r9,46
MOVI r1,61
STB r1,r9,47
MOVI r1,32
STB r1,r9,48
MOVI r1,78
STB r1,r9,49
MOVI r1,97
STB r1,r9,50
MOVI r1,78
STB r1,r9,51
MOVI r1,33
STB r1,r9,52
MOVI r1,32
STB r1,r9,53
MOVI r1,81
STB r1,r9,54
MOVI r1,79
STB r1,r9,55
MOVI r1,84
STB r1,r9,56
MOVI r1,68
STB r1,r9,57
MOVI r1,0
STB r1,r9,58
MOVI r1,0
STB r1,r9,59
; TXAD0
MOVI r5,0x20
ADD r5,r6,r5
MOVI r1,0x0800
MOVHI r1,0x0100
OUTL r1,r5
; TSD0
MOVI r5,0x10
ADD r5,r6,r5
MOVI r2,60
OUTL r2,r5
MOVI r8,60000
pingtx:
INW r1,r5
MOVI r3,0x8000
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @pingtxok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @pingtx
MOVI r1,@t_pingno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
pingtxok:
MOVI r1,@t_pingtx
CALL @sputs
MOVI r1,10
PUTC r1
MOVI r5,0x3E
ADD r5,r6,r5
MOVI r8,60000
pingrx:
INW r1,r5
MOVI r3,1
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @pingrxok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @pingrx
MOVI r1,@t_pingno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
pingrxok:
MOVI r7,0xF000
LDB r1,r7,16
MOVI r3,8
CMP r1,r3
JMP[NE] @pingbad
LDB r1,r7,17
CMP r1,r0
JMP[NE] @pingbad
LDB r1,r7,27
MOVI r3,1
CMP r1,r3
JMP[NE] @pingbad
LDB r1,r7,38
CMP r1,r0
JMP[NE] @pingbad
MOVI r1,@t_pingok
CALL @sputs
MOVI r1,10
PUTC r1
MOVI r1,@t_host
CALL @sputs
MOVI r1,10
PUTC r1
CALL @dns_run
LD r15,r0,@np_ret
RET
pingbad:
MOVI r1,@t_pingno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
nicrx_plain:
MOVI r1,@t_rxok
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@np_ret
RET
nicrx_bad:
MOVI r1,@t_rxno
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
dns_run:
ST r15,r0,@dns_ret
LD r6,r0,@nc_base
; Reset/reinit RX for the DNS exchange.
MOVI r5,0x37
ADD r5,r6,r5
MOVI r2,0x10
OUTB r2,r5
MOVI r8,10000
dnrst:
INB r1,r5
MOVI r3,16
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[EQ] @dnrst_d
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @dnrst
dnrst_d:
MOVI r2,0x0C
OUTB r2,r5
MOVI r5,0x30
ADD r5,r6,r5
MOVI r1,0
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x44
ADD r5,r6,r5
MOVI r1,0xF00F
OUTL r1,r5
MOVI r5,0x38
ADD r5,r6,r5
MOVI r2,0
OUTB r2,r5
MOVI r9,0xF800
MOVI r1,82
STB r1,r9,0
MOVI r1,85
STB r1,r9,1
MOVI r1,10
STB r1,r9,2
MOVI r1,0
STB r1,r9,3
MOVI r1,2
STB r1,r9,4
MOVI r1,2
STB r1,r9,5
MOVI r1,2
STB r1,r9,6
MOVI r1,78
STB r1,r9,7
MOVI r1,65
STB r1,r9,8
MOVI r1,78
STB r1,r9,9
MOVI r1,48
STB r1,r9,10
MOVI r1,83
STB r1,r9,11
MOVI r1,8
STB r1,r9,12
MOVI r1,0
STB r1,r9,13
MOVI r1,69
STB r1,r9,14
MOVI r1,0
STB r1,r9,15
MOVI r1,0
STB r1,r9,16
MOVI r1,57
STB r1,r9,17
MOVI r1,0
STB r1,r9,18
MOVI r1,2
STB r1,r9,19
MOVI r1,0
STB r1,r9,20
MOVI r1,0
STB r1,r9,21
MOVI r1,64
STB r1,r9,22
MOVI r1,17
STB r1,r9,23
MOVI r1,98
STB r1,r9,24
MOVI r1,161
STB r1,r9,25
MOVI r1,10
STB r1,r9,26
MOVI r1,0
STB r1,r9,27
MOVI r1,2
STB r1,r9,28
MOVI r1,15
STB r1,r9,29
MOVI r1,10
STB r1,r9,30
MOVI r1,0
STB r1,r9,31
MOVI r1,2
STB r1,r9,32
MOVI r1,3
STB r1,r9,33
MOVI r1,20
STB r1,r9,34
MOVI r1,233
STB r1,r9,35
MOVI r1,0
STB r1,r9,36
MOVI r1,53
STB r1,r9,37
MOVI r1,0
STB r1,r9,38
MOVI r1,37
STB r1,r9,39
MOVI r1,0
STB r1,r9,40
MOVI r1,0
STB r1,r9,41
MOVI r1,18
STB r1,r9,42
MOVI r1,52
STB r1,r9,43
MOVI r1,1
STB r1,r9,44
MOVI r1,0
STB r1,r9,45
MOVI r1,0
STB r1,r9,46
MOVI r1,1
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
MOVI r1,7
STB r1,r9,54
MOVI r1,101
STB r1,r9,55
MOVI r1,120
STB r1,r9,56
MOVI r1,97
STB r1,r9,57
MOVI r1,109
STB r1,r9,58
MOVI r1,112
STB r1,r9,59
MOVI r1,108
STB r1,r9,60
MOVI r1,101
STB r1,r9,61
MOVI r1,3
STB r1,r9,62
MOVI r1,99
STB r1,r9,63
MOVI r1,111
STB r1,r9,64
MOVI r1,109
STB r1,r9,65
MOVI r1,0
STB r1,r9,66
MOVI r1,0
STB r1,r9,67
MOVI r1,1
STB r1,r9,68
MOVI r1,0
STB r1,r9,69
MOVI r1,1
STB r1,r9,70
MOVI r5,0x20
ADD r5,r6,r5
MOVI r1,0x0800
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x10
ADD r5,r6,r5
MOVI r2,71
OUTL r2,r5
MOVI r8,60000
dnstx:
INW r1,r5
MOVI r3,0x8000
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @dnstxok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @dnstx
MOVI r1,@t_dnsno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@dns_ret
RET
dnstxok:
MOVI r5,0x3E
ADD r5,r6,r5
MOVI r8,60000
dnsrx:
INW r1,r5
MOVI r3,1
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @dnsrxok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @dnsrx
MOVI r1,@t_dnsno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@dns_ret
RET
dnsrxok:
MOVI r7,0xF000
LDB r1,r7,16
MOVI r3,8
CMP r1,r3
JMP[NE] @dnsbad
LDB r1,r7,17
CMP r1,r0
JMP[NE] @dnsbad
LDB r1,r7,27
MOVI r3,17
CMP r1,r3
JMP[NE] @dnsbad
MOVI r1,@t_dnsok
CALL @sputs
MOVI r1,10
PUTC r1
CALL @tcp_run
LD r15,r0,@dns_ret
RET
dnsbad:
MOVI r1,@t_dnsno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@dns_ret
RET
tcp_run:
ST r15,r0,@tcp_ret
LD r6,r0,@nc_base
MOVI r5,0x37
ADD r5,r6,r5
MOVI r2,0x10
OUTB r2,r5
MOVI r8,10000
tcp_rst:
INB r1,r5
MOVI r3,16
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[EQ] @tcp_rstd
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @tcp_rst
tcp_rstd:
MOVI r2,0x0C
OUTB r2,r5
MOVI r5,0x30
ADD r5,r6,r5
MOVI r1,0
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x44
ADD r5,r6,r5
MOVI r1,0xF00F
OUTL r1,r5
MOVI r5,0x38
ADD r5,r6,r5
MOVI r2,0
OUTB r2,r5
MOVI r9,0xF800
MOVI r1,82
STB r1,r9,0
MOVI r1,85
STB r1,r9,1
MOVI r1,10
STB r1,r9,2
MOVI r1,0
STB r1,r9,3
MOVI r1,2
STB r1,r9,4
MOVI r1,2
STB r1,r9,5
MOVI r1,2
STB r1,r9,6
MOVI r1,78
STB r1,r9,7
MOVI r1,65
STB r1,r9,8
MOVI r1,78
STB r1,r9,9
MOVI r1,48
STB r1,r9,10
MOVI r1,83
STB r1,r9,11
MOVI r1,8
STB r1,r9,12
MOVI r1,0
STB r1,r9,13
MOVI r1,69
STB r1,r9,14
MOVI r1,0
STB r1,r9,15
MOVI r1,0
STB r1,r9,16
MOVI r1,40
STB r1,r9,17
MOVI r1,0
STB r1,r9,18
MOVI r1,3
STB r1,r9,19
MOVI r1,0
STB r1,r9,20
MOVI r1,0
STB r1,r9,21
MOVI r1,64
STB r1,r9,22
MOVI r1,6
STB r1,r9,23
MOVI r1,98
STB r1,r9,24
MOVI r1,91
STB r1,r9,25
MOVI r1,10
STB r1,r9,26
MOVI r1,0
STB r1,r9,27
MOVI r1,2
STB r1,r9,28
MOVI r1,15
STB r1,r9,29
MOVI r1,10
STB r1,r9,30
MOVI r1,0
STB r1,r9,31
MOVI r1,2
STB r1,r9,32
MOVI r1,100
STB r1,r9,33
MOVI r1,156
STB r1,r9,34
MOVI r1,64
STB r1,r9,35
MOVI r1,9
STB r1,r9,36
MOVI r1,19
STB r1,r9,37
MOVI r1,0
STB r1,r9,38
MOVI r1,0
STB r1,r9,39
MOVI r1,3
STB r1,r9,40
MOVI r1,232
STB r1,r9,41
MOVI r1,0
STB r1,r9,42
MOVI r1,0
STB r1,r9,43
MOVI r1,0
STB r1,r9,44
MOVI r1,0
STB r1,r9,45
MOVI r1,80
STB r1,r9,46
MOVI r1,2
STB r1,r9,47
MOVI r1,255
STB r1,r9,48
MOVI r1,255
STB r1,r9,49
MOVI r1,238
STB r1,r9,50
MOVI r1,52
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
MOVI r5,0x20
ADD r5,r6,r5
MOVI r1,0x0800
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x10
ADD r5,r6,r5
MOVI r2,60
OUTL r2,r5
MOVI r8,60000
tcptx:
INW r1,r5
MOVI r3,0x8000
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @tcptxok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @tcptx
MOVI r1,@t_tcpno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tcp_ret
RET
tcptxok:
MOVI r5,0x3E
ADD r5,r6,r5
MOVI r8,60000
tcprx:
INW r1,r5
MOVI r3,1
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @tcprxok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @tcprx
MOVI r1,@t_tcpno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tcp_ret
RET
tcprxok:
MOVI r7,0xF000
LDB r1,r7,16
MOVI r3,8
CMP r1,r3
JMP[NE] @tcpbad
LDB r1,r7,17
CMP r1,r0
JMP[NE] @tcpbad
LDB r1,r7,27
MOVI r3,6
CMP r1,r3
JMP[NE] @tcpbad
LDB r1,r7,51
MOVI r3,0x12
CMP r1,r3
JMP[NE] @tcpbad
MOVI r1,@t_tcpok
CALL @sputs
MOVI r1,10
PUTC r1
CALL @tcp_ack
LD r15,r0,@tcp_ret
RET
tcp_ack:
ST r15,r0,@tack_ret
MOVI r7,0xF000
; server sequence raw+42..45
LDB r8,r7,42
SHL r8,r8,24
LDB r9,r7,43
SHL r9,r9,16
BOOL.14 r8,r8,r9
LDB r9,r7,44
SHL r9,r9,8
BOOL.14 r8,r8,r9
LDB r9,r7,45
BOOL.14 r8,r8,r9
ADDI r10,r8,1
MOVI r9,0xF800
; seq=1001, ack=server+1
MOVI r1,0
STB r1,r9,42
STB r1,r9,43
MOVI r1,3
STB r1,r9,44
MOVI r1,0xE9
STB r1,r9,45
SHR r8,r10,24
STB r8,r9,46
SHR r8,r10,16
MOVI r2,255
BOOL.8 r8,r8,r2
STB r8,r9,47
SHR r8,r10,8
BOOL.8 r8,r8,r2
STB r8,r9,48
MOVI r2,255
BOOL.8 r8,r10,r2
STB r8,r9,49
MOVI r1,0x50
STB r1,r9,50
MOVI r1,0x10
STB r1,r9,51
MOVI r1,0
STB r1,r9,54
STB r1,r9,55
; checksum = fold(0x211D8 + ack_hi + ack_lo)
MOVI r1,0x11D8
MOVI r2,2
SHL r2,r2,16
BOOL.14 r1,r1,r2
SHR r2,r10,16
MOVI r3,0xFFFF
BOOL.8 r2,r2,r3
BOOL.14 r1,r1,r2
MOVI r3,0xFFFF
BOOL.8 r2,r10,r3
BOOL.14 r1,r1,r2
tack_fold:
MOVI r3,0xFFFF
BOOL.8 r2,r1,r3
SHR r4,r1,16
ADD r1,r2,r4
SHR r4,r1,16
CMP r4,r0
JMP[NE] @tack_fold
tack_fd:
MOVI r2,0xFFFF
BOOL.6 r1,r1,r2
SHR r2,r1,8
STB r2,r9,54
MOVI r2,255
BOOL.8 r1,r1,r2
STB r1,r9,55
; TX via descriptor 1
LD r6,r0,@nc_base
MOVI r5,0x24
ADD r5,r6,r5
MOVI r1,0x0800
MOVHI r1,0x0100
OUTL r1,r5
MOVI r5,0x14
ADD r5,r6,r5
MOVI r2,60
OUTL r2,r5
MOVI r8,60000
tack_tx:
INW r1,r5
MOVI r3,0x8000
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @tack_ok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @tack_tx
MOVI r1,@t_tcpno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tack_ret
RET
tack_ok:
MOVI r1,@t_tack
CALL @sputs
MOVI r1,10
PUTC r1
; Wait for the first TCP data packet.
MOVI r5,0x3E
ADD r5,r6,r5
MOVI r8,60000
tdata_rx:
INW r1,r5
MOVI r3,1
BOOL.8 r1,r1,r3
CMP r1,r0
JMP[NE] @tdata_ok
SUB r8,r8,r13
CMP r8,r0
JMP[NE] @tdata_rx
MOVI r1,@t_datano
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tack_ret
RET
tdata_ok:
MOVI r7,0xF000
LDB r1,r7,16
MOVI r3,8
CMP r1,r3
JMP[NE] @tdata_bad
LDB r1,r7,17
CMP r1,r0
JMP[NE] @tdata_bad
LDB r1,r7,27
MOVI r3,6
CMP r1,r3
JMP[NE] @tdata_bad
MOVI r1,@t_dataok
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tack_ret
RET
tdata_bad:
MOVI r1,@t_datano
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tack_ret
RET
tcpbad:
MOVI r1,@t_tcpno
CALL @sputs
MOVI r1,10
PUTC r1
LD r15,r0,@tcp_ret
RET
t_none:
.str "NIC NONE"
t_reset:
.str "RESET "
t_txok:
.str "TX OK"
t_txno:
.str "TX FAIL"
t_rxok:
.str "RX OK"
t_rxno:
.str "RX FAIL"
t_arp:
.str "ARP "
t_pad:
.str "PAD LO FROM NAN0S 1969"
t_pingok:
.str "PING OK"
t_pingno:
.str "PING FAIL"
t_pingtx:
.str "PING TX"
t_host:
.str "HOST NaN0S  HINFO NaN-LATTICE NAN0S"
t_dnsok:
.str "DNS OK"
t_dnsno:
.str "DNS FAIL"
t_tcpok:
.str "TCP SYNACK"
t_tcpno:
.str "TCP FAIL"
t_tack:
.str "TCP ACK"
t_dataok:
.str "TCP DATA"
t_datano:
.str "TCP NODATA"
t_mac:
.str "MAC "
nc_ret:
.word 0
np_ret:
.word 0
nc_base:
.word 0
nc_msr:
.word 0
dns_ret:
.word 0
tcp_ret:
.word 0
tack_ret:
.word 0
ph4_ret:
.word 0
ph2_ret:
.word 0
