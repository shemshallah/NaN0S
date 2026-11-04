; timing.nas - wall-clock, cycle, latency and throughput counters.
; TICK is integer milliseconds; RDTSC is the CPU cycle counter.
; Importable: call these labels from any guest cart.
tm_reset:
ST r15,r0,@tm_ret
ST r0,r0,@tm_t0
ST r0,r0,@tm_ms
ST r0,r0,@tm_c0lo
ST r0,r0,@tm_c0hi
ST r0,r0,@tm_clo
ST r0,r0,@tm_chi
ST r0,r0,@tm_pcnt
ST r0,r0,@tm_psum
ST r0,r0,@tm_pmin
ST r0,r0,@tm_pmax
ST r0,r0,@tm_tx
ST r0,r0,@tm_rx
ST r0,r0,@tm_st
ST r0,r0,@tm_sr
LD r15,r0,@tm_ret
RET
tm_start:
ST r15,r0,@tm_sret
TICK r1
ST r1,r0,@tm_t0
RDTSC r1,r0
ST r1,r0,@tm_c0lo
RDTSC r1,r13
ST r1,r0,@tm_c0hi
LD r15,r0,@tm_sret
RET
tm_stop:
ST r15,r0,@tm_xret
TICK r1
LD r2,r0,@tm_t0
SUB r1,r1,r2
ST r1,r0,@tm_ms
RDTSC r2,r0
LD r3,r0,@tm_c0lo
SUB r3,r2,r3
ST r3,r0,@tm_clo
RDTSC r2,r13
LD r3,r0,@tm_c0hi
SUB r2,r2,r3
ST r2,r0,@tm_chi
LD r15,r0,@tm_xret
RET
; tm_rate: r1=bytes, r2=ms -> r1=bytes/sec
tm_rate:
CMP r2,r0
JMP[EQ] @tm_rate0
MOVI r3,1000
MUL r1,r1,r3
DIVU r1,r1,r2
RET
tm_rate0:
MOVI r1,0
RET
; tm_ping_add: r1=latency ms
tm_ping_add:
ST r15,r0,@tm_pret
LD r2,r0,@tm_pcnt
ADDI r2,r2,1
ST r2,r0,@tm_pcnt
LD r3,r0,@tm_psum
ADD r3,r3,r1
ST r3,r0,@tm_psum
LD r3,r0,@tm_pmin
CMP r3,r0
JMP[NE] @tm_pmin2
ST r1,r0,@tm_pmin
JMP @tm_pmax2
tm_pmin2:
CMP r1,r3
JMP[GE] @tm_pmax2
ST r1,r0,@tm_pmin
tm_pmax2:
LD r3,r0,@tm_pmax
CMP r1,r3
JMP[LE] @tm_pdone
ST r1,r0,@tm_pmax
tm_pdone:
LD r15,r0,@tm_pret
RET
; tm_ping_get -> r1=count r2=avg r3=min r4=max
tm_ping_get:
LD r1,r0,@tm_pcnt
LD r2,r0,@tm_psum
CMP r1,r0
JMP[EQ] @tm_pg0
DIVU r2,r2,r1
JMP @tm_pg1
tm_pg0:
MOVI r2,0
tm_pg1:
LD r3,r0,@tm_pmin
LD r4,r0,@tm_pmax
RET
; tm_io_add: r1=dir(0 tx,1 rx,2 storage-read,3 storage-write), r2=bytes
tm_io_add:
ST r15,r0,@tm_iret
CMP r1,r0
JMP[NE] @tm_io1
LD r3,r0,@tm_tx
ADD r3,r3,r2
ST r3,r0,@tm_tx
JMP @tm_iod
tm_io1:
MOVI r4,1
CMP r1,r4
JMP[NE] @tm_io2
LD r3,r0,@tm_rx
ADD r3,r3,r2
ST r3,r0,@tm_rx
JMP @tm_iod
tm_io2:
MOVI r4,2
CMP r1,r4
JMP[NE] @tm_io3
LD r3,r0,@tm_sr
ADD r3,r3,r2
ST r3,r0,@tm_sr
JMP @tm_iod
tm_io3:
LD r3,r0,@tm_st
ADD r3,r3,r2
ST r3,r0,@tm_st
tm_iod:
LD r15,r0,@tm_iret
RET
; tm_cpu_mhz -> r1 MHz, measured over ~500 ms
tm_cpu_mhz:
ST r15,r0,@tm_cret
TICK r1
ST r1,r0,@tm_ct0
RDTSC r2,r0
ST r2,r0,@tm_cc0
tm_cloop:
TICK r3
LD r4,r0,@tm_ct0
SUB r4,r3,r4
MOVI r5,500
CMP r4,r5
JMP[LT] @tm_cloop
RDTSC r2,r0
LD r4,r0,@tm_cc0
SUB r2,r2,r4
MOVI r3,500
DIVU r2,r2,r3
MOVI r3,1000
DIVU r1,r2,r3
LD r15,r0,@tm_cret
RET
tm_ret:
.word 0
tm_sret:
.word 0
tm_xret:
.word 0
tm_pret:
.word 0
tm_iret:
.word 0
tm_cret:
.word 0
tm_t0:
.word 0
tm_ms:
.word 0
tm_c0lo:
.word 0
tm_c0hi:
.word 0
tm_clo:
.word 0
tm_chi:
.word 0
tm_pcnt:
.word 0
tm_psum:
.word 0
tm_pmin:
.word 0
tm_pmax:
.word 0
tm_tx:
.word 0
tm_rx:
.word 0
tm_sr:
.word 0
tm_st:
.word 0
tm_ct0:
.word 0
tm_cc0:
.word 0
