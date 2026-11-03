// s1_a64.s - AArch64 S1 boundary.
// Layer 0: boot at 0x40000000 (EL2, qemu virt), PL011 UART, halt.
// Layer 1: NaN16 fetch/decode/gate/predication + MOVI MOVHI ADD SUB CMP
//          ADDI SHL SHR JMP JMPR CALL CALLR RET NOP PUTC LD ST HALT.
//          Unimplemented ops trap !O.
// Guest memory: 4M words (32 MB) of RAM, image copied at boot, M=0x3FFFFF.
        .section .text
        .global _start
_start:
        ldr     x0, =stack_top
        mov     sp, x0
        // allow FP/SIMD at the current EL (qemu enters EL2 or EL1)
        mrs     x0, CurrentEL
        lsr     x0, x0, #2
        cmp     x0, #2
        b.ne    1f
        mov     x0, #0x300          // CPTR_EL2.FPEN = 3
        msr     cptr_el2, x0
1:      mov     x0, #0x300000       // CPACR_EL1.FPEN = 3
        msr     cpacr_el1, x0
        isb
        // display state: text mode, cells 0x0720, FBTOT 64000 (core reset)
        ldr     x9, =cells
        mov     w10, #0x0720
        mov     x11, #2000
2:      strh    w10, [x9], #2
        subs    x11, x11, #1
        b.ne    2b
        ldr     x9, =disp_fbtot
        mov     w10, #64000
        str     w10, [x9]
        mov     x29, #0             // step counter (RDTSC)
        // PL011 at 0x09000000: 8N1 + FIFO, UART/TX/RX enable, clear IRQs
        ldr     x20, =0x09000000
        mov     w2, #0x70
        str     w2, [x20, #0x2C]
        mov     w2, #0x301
        str     w2, [x20, #0x30]
        mov     w2, #0x7FF
        str     w2, [x20, #0x44]
        // copy the guest image into RAM (the machine zero-fills RAM)
        ldr     x19, =guest_ram
        ldr     x9, =guest_img
        ldr     x10, =guest_end
        sub     x10, x10, x9
        lsr     x10, x10, #3
        mov     x11, #0
copy:   cmp     x11, x10
        b.hs    copy_done
        ldr     x12, [x9, x11, lsl #3]
        str     x12, [x19, x11, lsl #3]
        add     x11, x11, #1
        b       copy
copy_done:
        ldr     x21, =regs
        mov     w9, #1
        str     w9, [x21, #52]      // r13 = 1 (NaN16 convention)
        mov     w22, #0             // pc
        mov     w23, #0             // k = 2Z+L
loop:
        add     x29, x29, #1
        and     w9, w22, #0x3FFFFF
        lsl     x9, x9, #3
        add     x9, x19, x9
        ldr     x10, [x9]           // word (LE u64)
        lsr     x11, x10, #48       // near head
        and     w12, w10, #0xFFFF
        rev16   w12, w12
        and     w12, w12, #0xFFFF   // far head
        // gate: near
        ubfx    w9, w11, #4, #11
        cmp     w9, #0x7FF
        b.ne    trapG
        and     w9, w11, #15
        cmp     w9, #1
        b.eq    1f
        cmp     w9, #8
        b.ne    trapG
1:      // gate: far
        ubfx    w9, w12, #4, #11
        cmp     w9, #0x7FF
        b.ne    trapG
        and     w9, w12, #15
        cmp     w9, #1
        b.eq    2f
        cmp     w9, #8
        b.ne    trapG
2:      add     w22, w22, #1
        ubfx    x24, x10, #16, #32  // payload
        lsr     w25, w24, #24       // op
        cmp     w25, #0xFF
        b.eq    halt
        cmp     w25, #0x45
        b.hi    trapO
        // n = cls(near)<<2 | cls(far); cls(h) = ((h>>2)&2) | (h>>15)
        lsr     w13, w11, #2
        and     w13, w13, #2
        lsr     w9, w11, #15
        orr     w13, w13, w9
        lsr     w14, w12, #2
        and     w14, w14, #2
        lsr     w9, w12, #15
        orr     w14, w14, w9
        lsl     w24, w13, #2
        orr     w24, w24, w14
        cbz     w25, disp
        lsr     w9, w24, w23
        tbz     w9, #0, loop        // predicated off: skip silently
disp:
        ubfx    x26, x10, #36, #4   // d
        ubfx    x27, x10, #32, #4   // a
        ubfx    w28, w10, #16, #16  // imm
        cbz     w25, op_bool
        cmp     w25, #0x01
        b.eq    op_movi
        cmp     w25, #0x02
        b.eq    op_movhi
        cmp     w25, #0x03
        b.eq    op_add
        cmp     w25, #0x04
        b.eq    op_sub
        cmp     w25, #0x05
        b.eq    op_shl
        cmp     w25, #0x06
        b.eq    op_shr
        cmp     w25, #0x07
        b.eq    op_cmp
        cmp     w25, #0x08
        b.eq    op_ld
        cmp     w25, #0x09
        b.eq    op_st
        cmp     w25, #0x0A
        b.eq    op_jmp
        cmp     w25, #0x0B
        b.eq    op_call
        cmp     w25, #0x0C
        b.eq    op_ret
        cmp     w25, #0x0D
        b.eq    op_jmpr
        cmp     w25, #0x0F
        b.eq    loop
        cmp     w25, #0x1B
        b.eq    loop
        cmp     w25, #0x15
        b.eq    op_putc
        cmp     w25, #0x29
        b.eq    op_addi
        cmp     w25, #0x2C
        b.eq    op_callr
        cmp     w25, #0x14
        b.eq    op_bswapm
        cmp     w25, #0x16
        b.eq    op_stw
        cmp     w25, #0x17
        b.eq    op_ldn
        cmp     w25, #0x20
        b.eq    op_mul
        cmp     w25, #0x21
        b.eq    op_mulh
        cmp     w25, #0x22
        b.eq    op_mulhu
        cmp     w25, #0x23
        b.eq    op_div
        cmp     w25, #0x24
        b.eq    op_mod
        cmp     w25, #0x25
        b.eq    op_divu
        cmp     w25, #0x26
        b.eq    op_modu
        cmp     w25, #0x27
        b.eq    op_sar
        cmp     w25, #0x28
        b.eq    op_cmps
        cmp     w25, #0x2A
        b.eq    op_ldb
        cmp     w25, #0x2B
        b.eq    op_stb
        cmp     w25, #0x2D
        b.eq    op_bcopy
        cmp     w25, #0x2E
        b.eq    op_bfill
        cmp     w25, #0x30
        b.eq    op_fadd
        cmp     w25, #0x31
        b.eq    op_fsub
        cmp     w25, #0x32
        b.eq    op_fmul
        cmp     w25, #0x33
        b.eq    op_fdiv
        cmp     w25, #0x34
        b.eq    op_fsqrt
        cmp     w25, #0x35
        b.eq    op_fcmp
        cmp     w25, #0x36
        b.eq    op_cvtif
        cmp     w25, #0x37
        b.eq    op_cvtfi
        cmp     w25, #0x2F
        b.eq    loop
        cmp     w25, #0x10
        b.eq    op_vpoke
        cmp     w25, #0x11
        b.eq    op_vpeek
        cmp     w25, #0x12
        b.eq    op_key
        cmp     w25, #0x13
        b.eq    op_tick
        cmp     w25, #0x18
        b.eq    op_dispq
        cmp     w25, #0x19
        b.eq    op_dispset
        cmp     w25, #0x1A
        b.eq    op_keyq
        cmp     w25, #0x3A
        b.eq    op_fbinfo
        cmp     w25, #0x3B
        b.eq    op_vsync
        cmp     w25, #0x3C
        b.eq    op_fbcopy
        cmp     w25, #0x3D
        b.eq    op_fbfill
        cmp     w25, #0x3E
        b.eq    loop
        cmp     w25, #0x3F
        b.eq    op_in0
        cmp     w25, #0x40
        b.eq    op_in0
        cmp     w25, #0x41
        b.eq    loop
        cmp     w25, #0x42
        b.eq    loop
        cmp     w25, #0x43
        b.eq    loop
        cmp     w25, #0x44
        b.eq    op_cpuid
        cmp     w25, #0x45
        b.eq    op_rdtsc
        cmp     w25, #0x38
        b.eq    op_jmpf
        cmp     w25, #0x39
        b.eq    op_callf
        b       trapO
op_bool:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        orr     w11, w9, w10
        mvn     w11, w11            // ~(A|B)      bit 0
        bic     w12, w10, w9        // B & ~A       bit 1
        bic     w13, w9, w10        // A & ~B       bit 2
        and     w14, w9, w10        // A & B        bit 3
        mov     w15, #0
        tbz     w24, #0, 1f
        orr     w15, w15, w11
1:      tbz     w24, #1, 2f
        orr     w15, w15, w12
2:      tbz     w24, #2, 3f
        orr     w15, w15, w13
3:      tbz     w24, #3, 4f
        orr     w15, w15, w14
4:      str     w15, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1        // Z only (L=0)
        b       loop
op_movi:
        str     w28, [x21, x26, lsl #2]
        b       loop
op_movhi:
        ldr     w9, [x21, x26, lsl #2]
        and     w9, w9, #0xFFFF
        lsl     w10, w28, #16
        orr     w9, w9, w10
        str     w9, [x21, x26, lsl #2]
        b       loop
op_add:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        adds    w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        cset    w13, cs
        lsl     w12, w12, #1
        add     w23, w12, w13
        b       loop
op_sub:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        subs    w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        cset    w13, cc             // borrow
        lsl     w12, w12, #1
        add     w23, w12, w13
        b       loop
op_shl:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #31
        lsl     w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_shr:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #31
        lsr     w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_cmp:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        cmp     w9, w10
        cset    w12, eq
        cset    w13, cc             // A < B unsigned
        lsl     w12, w12, #1
        add     w23, w12, w13
        b       loop
op_addi:
        ldr     w9, [x21, x27, lsl #2]
        sxth    w10, w28
        adds    w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        cset    w13, cs
        lsl     w12, w12, #1
        add     w23, w12, w13
        b       loop
op_ld:
        ldr     w9, [x21, x27, lsl #2]
        add     w9, w9, w28
        and     w9, w9, #0x3FFFFF
        ldr     x10, [x19, x9, lsl #3]
        lsr     x10, x10, #16
        str     w10, [x21, x26, lsl #2]
        b       loop
op_st:
        ldr     w9, [x21, x27, lsl #2]
        add     w9, w9, w28
        and     w9, w9, #0x3FFFFF
        ldr     w10, [x21, x26, lsl #2]
        lsl     x10, x10, #16
        movz    x11, #0xF87F        // far +q bytes
        orr     x10, x10, x11
        movz    x11, #0x7FF8, lsl #48
        orr     x10, x10, x11
        str     x10, [x19, x9, lsl #3]
        b       loop
op_jmp:
        mov     w22, w28
        b       loop
op_jmpr:
        ldr     w22, [x21, x27, lsl #2]
        b       loop
op_call:
        str     w22, [x21, #60]     // r15 = pc (after fetch increment)
        mov     w22, w28
        b       loop
op_callr:
        str     w22, [x21, #60]
        ldr     w22, [x21, x27, lsl #2]
        b       loop
op_ret:
        ldr     w22, [x21, #60]
        b       loop
op_putc:
        ldr     w9, [x21, x26, lsl #2]
        and     w9, w9, #0xFF
        str     w9, [x20]
        b       loop

// ---- extension ops -------------------------------------------------------
op_bswapm:
        ldr     w9, [x21, x27, lsl #2]
        add     w9, w9, w28
        and     w9, w9, #0x3FFFFF
        ldr     x10, [x19, x9, lsl #3]
        rev     x10, x10
        str     x10, [x19, x9, lsl #3]
        b       loop
op_stw:
        ldr     w9, [x21, x27, lsl #2]
        and     w9, w9, #0x3FFFFF
        ldr     w0, [x21, x26, lsl #2]
        and     w1, w28, #15
        ldr     w1, [x21, x1, lsl #2]
        and     w1, w1, #15
        bl      mkword
        str     x0, [x19, x9, lsl #3]
        b       loop
op_ldn:
        ldr     w9, [x21, x27, lsl #2]
        add     w9, w9, w28
        and     w9, w9, #0x3FFFFF
        ldr     x10, [x19, x9, lsl #3]
        lsr     x11, x10, #48
        and     x12, x10, #0xFFFF
        rev16   w12, w12
        and     w12, w12, #0xFFFF
        ubfx    w9, w11, #4, #11
        cmp     w9, #0x7FF
        b.ne    ldn_bad
        and     w9, w11, #15
        cmp     w9, #1
        b.eq    1f
        cmp     w9, #8
        b.ne    ldn_bad
1:      ubfx    w9, w12, #4, #11
        cmp     w9, #0x7FF
        b.ne    ldn_bad
        and     w9, w12, #15
        cmp     w9, #1
        b.eq    2f
        cmp     w9, #8
        b.ne    ldn_bad
2:      lsr     w13, w11, #2
        and     w13, w13, #2
        lsr     w9, w11, #15
        orr     w13, w13, w9
        lsr     w14, w12, #2
        and     w14, w14, #2
        lsr     w9, w12, #15
        orr     w14, w14, w9
        lsl     w13, w13, #2
        orr     w13, w13, w14
        str     w13, [x21, x26, lsl #2]
        b       loop
ldn_bad:
        mvn     w9, wzr
        str     w9, [x21, x26, lsl #2]
        b       loop
op_mul:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        mul     w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_mulh:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        smull   x11, w9, w10
        lsr     x11, x11, #32
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_mulhu:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        umull   x11, w9, w10
        lsr     x11, x11, #32
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_div:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        cbnz    w10, 1f
        mov     w11, #0
        mov     w23, #3
        b       3f
1:      cmn     w10, #1
        b.ne    2f
        neg     w11, w9
        b       3f
2:      sdiv    w11, w9, w10
3:      str     w11, [x21, x26, lsl #2]
        cbz     w10, loop
        cmp     w11, #0
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_mod:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        cbnz    w10, 1f
        mov     w11, w9
        mov     w23, #3
        b       3f
1:      cmn     w10, #1
        b.ne    2f
        mov     w11, #0
        b       3f
2:      sdiv    w12, w9, w10
        msub    w11, w12, w10, w9
3:      str     w11, [x21, x26, lsl #2]
        cbz     w10, loop
        cmp     w11, #0
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_divu:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        cbnz    w10, 1f
        mov     w11, #0
        mov     w23, #3
        b       3f
1:      udiv    w11, w9, w10
3:      str     w11, [x21, x26, lsl #2]
        cbz     w10, loop
        cmp     w11, #0
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_modu:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        cbnz    w10, 1f
        mov     w11, w9
        mov     w23, #3
        b       3f
1:      udiv    w12, w9, w10
        msub    w11, w12, w10, w9
3:      str     w11, [x21, x26, lsl #2]
        cbz     w10, loop
        cmp     w11, #0
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_sar:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #31
        asr     w11, w9, w10
        str     w11, [x21, x26, lsl #2]
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop
op_cmps:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        cmp     w9, w10
        cset    w12, eq
        cset    w13, lt
        lsl     w12, w12, #1
        add     w23, w12, w13
        b       loop
op_ldb:
        ldr     w9, [x21, x27, lsl #2]
        add     w9, w9, w28
        lsr     w10, w9, #2
        and     w10, w10, #0x3FFFFF
        ldr     x11, [x19, x10, lsl #3]
        lsr     x11, x11, #16
        and     w12, w9, #3
        lsl     w12, w12, #3
        lsr     x11, x11, x12
        and     w11, w11, #0xFF
        str     w11, [x21, x26, lsl #2]
        b       loop
op_stb:
        ldr     w9, [x21, x27, lsl #2]
        add     w9, w9, w28
        lsr     w10, w9, #2
        and     w10, w10, #0x3FFFFF
        ldr     x11, [x19, x10, lsl #3]
        lsr     x11, x11, #16
        and     w12, w9, #3
        lsl     w12, w12, #3
        mov     w13, #0xFF
        lsl     w13, w13, w12
        mvn     w14, w13
        and     w11, w11, w14
        ldr     w15, [x21, x26, lsl #2]
        and     w15, w15, #0xFF
        lsl     w15, w15, w12
        orr     w11, w11, w15
        mov     w0, w11
        mov     w1, #10
        bl      mkword
        str     x0, [x19, x10, lsl #3]
        b       loop
op_bcopy:
        ldr     w9, [x21, x27, lsl #2]
        and     w9, w9, #0x3FFFFF       // src
        ldr     w10, [x21, x26, lsl #2]
        and     w10, w10, #0x3FFFFF     // dst
        and     w11, w28, #15
        ldr     w11, [x21, x11, lsl #2] // count
        cbz     w11, loop
        sub     w12, w10, w9
        and     w12, w12, #0x3FFFFF
        cmp     w12, w11
        b.lo    bc_back
        mov     w13, #0
bc_f:   cmp     w13, w11
        b.hs    loop
        add     w14, w9, w13
        and     w14, w14, #0x3FFFFF
        ldr     x15, [x19, x14, lsl #3]
        add     w14, w10, w13
        and     w14, w14, #0x3FFFFF
        str     x15, [x19, x14, lsl #3]
        add     w13, w13, #1
        b       bc_f
bc_back:
        sub     w13, w11, #1
bc_b:   add     w14, w9, w13
        and     w14, w14, #0x3FFFFF
        ldr     x15, [x19, x14, lsl #3]
        add     w14, w10, w13
        and     w14, w14, #0x3FFFFF
        str     x15, [x19, x14, lsl #3]
        subs    w13, w13, #1
        b.hs    bc_b
        b       loop
op_bfill:
        ldr     w9, [x21, x26, lsl #2]
        and     w9, w9, #0x3FFFFF
        ldr     w0, [x21, x27, lsl #2]
        mov     w1, #10
        bl      mkword
        and     w11, w28, #15
        ldr     w11, [x21, x11, lsl #2]
        cbz     w11, loop
        mov     w13, #0
bf_l:   add     w14, w9, w13
        and     w14, w14, #0x3FFFFF
        str     x0, [x19, x14, lsl #3]
        add     w13, w13, #1
        cmp     w13, w11
        b.lo    bf_l
        b       loop
op_jmpf:
        ubfx    x9, x10, #16, #32
        and     w22, w9, #0xFFFFFF
        b       loop
op_callf:
        ubfx    x9, x10, #16, #32
        str     w22, [x21, #60]
        and     w22, w9, #0xFFFFFF
        b       loop

// ---- float ops (x86 SSE NaN rules; FPCR default RNE, no FTZ) -------------
op_fadd:
        mov     w1, #0x30
        b       op_fp2
op_fsub:
        mov     w1, #0x31
        b       op_fp2
op_fmul:
        mov     w1, #0x32
op_fp2:
        ldr     w2, [x21, x27, lsl #2]
        and     w3, w28, #15
        ldr     w3, [x21, x3, lsl #2]
        bl      fpbin
        str     w0, [x21, x26, lsl #2]
        mov     w23, #0
        b       loop
op_fdiv:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        movz    w12, #0x7F80, lsl #16
        and     w11, w10, #0x7FFFFFFF
        cbnz    w11, fdiv_norm
        and     w11, w9, #0x7FFFFFFF
        cbz     w11, fdiv_nan
        and     w11, w9, w12
        cmp     w11, w12
        b.ne    fdiv_inf
        and     w11, w9, #0x7FFFFF
        cbnz    w11, fdiv_nan
fdiv_inf:
        eor     w11, w9, w10
        and     w11, w11, #0x80000000
        orr     w11, w11, #0x7F800000
        b       fdiv_store
fdiv_nan:
        movz    w11, #0x7FC0, lsl #16
        b       fdiv_store
fdiv_norm:
        mov     w1, #0x33
        mov     w2, w9
        mov     w3, w10
        bl      fpbin
        mov     w11, w0
fdiv_store:
        str     w11, [x21, x26, lsl #2]
        mov     w23, #0
        b       loop
op_fsqrt:
        ldr     w9, [x21, x27, lsl #2]
        movz    w12, #0x7F80, lsl #16
        and     w11, w9, w12
        cmp     w11, w12
        b.ne    1f
        and     w11, w9, #0x7FFFFF
        cbnz    w11, fsqrt_nan
1:      tbnz    w9, #31, 2f
3:      fmov    s0, w9
        fsqrt   s0, s0
        fmov    w11, s0
        b       fsqrt_store
2:      and     w11, w9, #0x7FFFFFFF
        cbnz    w11, fsqrt_nan
        b       3b
fsqrt_nan:
        movz    w11, #0x7FC0, lsl #16
fsqrt_store:
        str     w11, [x21, x26, lsl #2]
        mov     w23, #0
        b       loop
op_fcmp:
        ldr     w9, [x21, x27, lsl #2]
        and     w10, w28, #15
        ldr     w10, [x21, x10, lsl #2]
        movz    w12, #0x7F80, lsl #16
        and     w11, w9, w12
        cmp     w11, w12
        b.ne    1f
        and     w11, w9, #0x7FFFFF
        cbnz    w11, fcmp_un
1:      and     w11, w10, w12
        cmp     w11, w12
        b.ne    2f
        and     w11, w10, #0x7FFFFF
        cbnz    w11, fcmp_un
2:      fmov    s0, w9
        fmov    s1, w10
        fcmp    s0, s1
        cset    w12, eq
        cset    w13, lt
        lsl     w12, w12, #1
        add     w23, w12, w13
        b       loop
fcmp_un:
        mov     w23, #3
        b       loop
op_cvtif:
        ldr     w9, [x21, x27, lsl #2]
        scvtf   s0, w9
        fmov    w11, s0
        str     w11, [x21, x26, lsl #2]
        mov     w23, #0
        b       loop
op_cvtfi:
        ldr     w9, [x21, x27, lsl #2]
        movz    w12, #0x7F80, lsl #16
        and     w11, w9, w12
        cmp     w11, w12
        b.ne    1f
        and     w11, w9, #0x7FFFFF
        cbnz    w11, 2f
1:      fmov    s0, w9
        fcvtzs w11, s0
        b       3f
2:      mov     w11, #0
3:      str     w11, [x21, x26, lsl #2]
        cmp     w11, #0
        cset    w12, eq
        lsl     w23, w12, #1
        b       loop

// fpbin: w1=op (30 add,31 sub,32 mul,33 div), w2=A, w3=B -> w0=result
fpbin:
        movz    w12, #0x7F80, lsl #16
        and     w11, w2, w12
        cmp     w11, w12
        b.ne    1f
        and     w11, w2, #0x7FFFFF
        cbz     w11, 1f
        orr     w0, w2, #0x400000
        ret
1:      and     w11, w3, w12
        cmp     w11, w12
        b.ne    2f
        and     w11, w3, #0x7FFFFF
        cbz     w11, 2f
        orr     w0, w3, #0x400000
        ret
2:      fmov    s0, w2
        fmov    s1, w3
        cmp     w1, #0x30
        b.ne    3f
        fadd    s0, s0, s1
        b       6f
3:      cmp     w1, #0x31
        b.ne    4f
        fsub    s0, s0, s1
        b       6f
4:      cmp     w1, #0x32
        b.ne    5f
        fmul    s0, s0, s1
        b       6f
5:      fdiv    s0, s0, s1
6:      fmov    w0, s0
        and     w11, w0, w12
        cmp     w11, w12
        b.ne    7f
        and     w11, w0, #0x7FFFFF
        cbz     w11, 7f
        movz    w0, #0xFFC0, lsl #16
7:      ret

// ---- device boundary (text plane, VRAM, ports, timer, CPUID) -------------
op_vpoke:
        ldr     x9, =disp_vmode
        ldr     w10, [x9]
        ldr     w11, [x21, x27, lsl #2]
        ldr     w12, [x21, x26, lsl #2]
        cbnz    w10, 1f
        cmp     w11, #2000
        b.hs    9f
        ldr     x9, =cells
        strh    w12, [x9, x11, lsl #1]
        b       9f
1:      ldr     x9, =disp_fbtot
        ldr     w13, [x9]
        cmp     w11, w13
        b.hs    9f
        ldr     x9, =vram
        strb    w12, [x9, x11]
9:      b       loop
op_vpeek:
        ldr     x9, =disp_vmode
        ldr     w10, [x9]
        ldr     w11, [x21, x27, lsl #2]
        cbnz    w10, 1f
        cmp     w11, #2000
        b.hs    9f
        ldr     x9, =cells
        ldrh    w12, [x9, x11, lsl #1]
        str     w12, [x21, x26, lsl #2]
        b       9f
1:      ldr     x9, =disp_fbtot
        ldr     w13, [x9]
        cmp     w11, w13
        b.hs    9f
        ldr     x9, =vram
        ldrb    w12, [x9, x11]
        str     w12, [x21, x26, lsl #2]
9:      b       loop
op_key:
key_wait:
        wfe
        b       key_wait
op_tick:
        str     wzr, [x21, x26, lsl #2]
        b       loop
op_keyq:
        str     wzr, [x21, x26, lsl #2]
        b       loop
op_dispq:
        ldr     x9, =disp_vmode
        ldr     w10, [x9]
        cbz     w10, 1f
        movz    w11, #0xC800
        movk    w11, #0x1300, lsl #16
        b       2f
1:      movz    w11, #0x1950
        movk    w11, #0x0003, lsl #16
2:      str     w11, [x21, x26, lsl #2]
        b       loop
op_dispset:
        ldr     w9, [x21, x26, lsl #2]
        movz    w10, #0xFFFF, lsl #16
        cmp     w9, w10
        b.hs    ds_raw
        cmp     w9, #0x10000
        b.hs    ds_vbe
        and     w10, w9, #255
        cmp     w10, #0x13
        b.eq    ds_m13
        ldr     x9, =disp_vmode
        str     wzr, [x9]
        ldr     x9, =disp_fbw
        mov     w10, #80
        str     w10, [x9]
        ldr     x9, =disp_fbh
        mov     w10, #25
        str     w10, [x9]
        ldr     x0, =cells
        mov     x1, #4000
        bl      memzero
        b       ds_done
ds_m13:
        ldr     x9, =disp_vmode
        mov     w10, #1
        str     w10, [x9]
        ldr     x9, =disp_fbtot
        mov     w10, #64000
        str     w10, [x9]
        ldr     x9, =disp_fbw
        mov     w10, #320
        str     w10, [x9]
        ldr     x9, =disp_fbh
        mov     w10, #200
        str     w10, [x9]
        ldr     x0, =vram
        mov     x1, #64000
        bl      memzero
        b       ds_done
ds_vbe:
        lsr     w10, w9, #16
        and     w11, w9, #0xFFFF
        ldr     x12, =disp_fbw
        str     w10, [x12]
        ldr     x12, =disp_fbh
        str     w11, [x12]
        mul     w12, w10, w11
        ldr     x13, =disp_fbtot
        str     w12, [x13]
        ldr     x13, =disp_vmode
        mov     w14, #1
        str     w14, [x13]
        movz    w14, #0x0100, lsl #16
        cmp     w12, w14
        csel    w12, w12, w14, lo
        lsr     w12, w12, #2
        lsl     w12, w12, #2
        ldr     x0, =vram
        mov     w1, w12
        bl      memzero
        b       ds_done
ds_raw:
        and     w10, w9, #255
        ldr     x9, =disp_rawkb
        str     w10, [x9]
ds_done:
        b       loop
op_fbinfo:
        ldr     x9, =disp_fbw
        ldr     w10, [x9]
        ldr     x9, =disp_fbh
        ldr     w11, [x9]
        lsl     w10, w10, #16
        orr     w10, w10, w11
        str     w10, [x21, x26, lsl #2]
        b       loop
op_vsync:
        ldr     x9, =disp_vmode
        ldr     w10, [x9]
        cbz     w10, loop
        ldr     x9, =disp_frame
        ldr     w10, [x9]
        add     w10, w10, #1
        str     w10, [x9]
        b       loop
op_fbcopy:
        ldr     w9, [x21, x26, lsl #2]
        ldr     w10, [x21, x27, lsl #2]
        and     w11, w28, #15
        ldr     w11, [x21, x11, lsl #2]
        cbz     w9, loop
        ldr     x12, =vram
        movz    w13, #0x0100, lsl #16
        add     w14, w10, w9
        cmp     w14, w13
        b.hi    fbc_gen
        add     w14, w11, w9
        cmp     w14, w13
        b.hi    fbc_gen
        add     w14, w10, w9
        cmp     w14, w11
        b.ls    fbc_fast
        add     w14, w11, w9
        cmp     w14, w10
        b.ls    fbc_fast
        b       fbc_gen
fbc_fast:
        mov     w14, #0
fbc_f:  cmp     w14, w9
        b.hs    loop
        add     w15, w11, w14
        ldrb    w0, [x12, x15]
        add     w15, w10, w14
        strb    w0, [x12, x15]
        add     w14, w14, #1
        b       fbc_f
fbc_gen:
        mov     w14, #0
fbc_g:  cmp     w14, w9
        b.hs    loop
        add     w0, w10, w14
        cmp     w0, w13
        b.hs    2f
        add     w1, w11, w14
        cmp     w1, w13
        b.hs    3f
        ldrb    w2, [x12, x1]
        strb    w2, [x12, x0]
        b       2f
3:      strb    wzr, [x12, x0]
2:      add     w14, w14, #1
        b       fbc_g
op_fbfill:
        ldr     w9, [x21, x26, lsl #2]
        ldr     w10, [x21, x27, lsl #2]
        and     w11, w28, #15
        ldr     w11, [x21, x11, lsl #2]
        and     w11, w11, #0xFF
        ldr     x12, =vram
        movz    w13, #0x0100, lsl #16
        cmp     w10, w13
        b.hs    loop
        sub     w14, w13, w10
        cmp     w9, w14
        csel    w9, w9, w14, lo
        mov     w14, #0
ff_l:   cmp     w14, w9
        b.hs    loop
        add     w15, w10, w14
        strb    w11, [x12, x15]
        add     w14, w14, #1
        b       ff_l
op_in0:
        str     wzr, [x21, x26, lsl #2]
        b       loop
op_rdtsc:
        ldr     w9, [x21, x27, lsl #2]
        cbz     w9, 1f
        lsr     x10, x29, #32
        b       2f
1:      mov     w10, w29
2:      str     w10, [x21, x26, lsl #2]
        b       loop
op_cpuid:
        ldr     w9, [x21, x27, lsl #2]
        cbz     w9, cp_l0
        cmp     w9, #1
        b.eq    cp_l1
        movz    w10, #0x8000, lsl #16
        cmp     w9, w10
        b.eq    cp_l80
        add     w10, w10, #1
        cmp     w9, w10
        b.eq    cp_l81
        add     w10, w10, #1
        cmp     w9, w10
        b.eq    cp_l82
        add     w10, w10, #1
        cmp     w9, w10
        b.eq    cp_l83
        add     w10, w10, #1
        cmp     w9, w10
        b.eq    cp_l84
        ldr     x10, =cpuid_zero
        b       cp_pick
cp_l0:  ldr     x10, =cpuid_l0
        b       cp_pick
cp_l1:  ldr     x10, =cpuid_l1
        b       cp_pick
cp_l80: ldr     x10, =cpuid_l80
        b       cp_pick
cp_l81: ldr     x10, =cpuid_l81
        b       cp_pick
cp_l82: ldr     x10, =cpuid_l82
        b       cp_pick
cp_l83: ldr     x10, =cpuid_l83
        b       cp_pick
cp_l84: ldr     x10, =cpuid_l84
cp_pick:
        and     w11, w28, #15
        ldr     w11, [x21, x11, lsl #2]
        and     w11, w11, #3
        ldr     w12, [x10, x11, lsl #2]
        str     w12, [x21, x26, lsl #2]
        b       loop
memzero:
        cbz     x1, 2f
1:      strb    wzr, [x0], #1
        subs    x1, x1, #1
        b.ne    1b
2:      ret

// mkword: w0=payload, w1=nibble -> x0=word (clobbers x0,x2..x5)
mkword:
        adr     x2, heads
        and     w3, w1, #3
        ldrh    w4, [x2, x3, lsl #1]
        rev16   w4, w4
        lsr     w3, w1, #2
        and     w3, w3, #3
        ldrh    w5, [x2, x3, lsl #1]
        lsl     x5, x5, #48
        lsl     x0, x0, #16
        orr     x0, x0, x4
        orr     x0, x0, x5
        ret

trapG:
        add     w0, w22, #1         // shown = fetch pc + 1
        mov     w1, #71             // 'G'
        b       trap_common
trapO:
        mov     w0, w22             // shown = pc (after increment)
        mov     w1, #79             // 'O'
trap_common:
        mov     w2, #33             // '!'
        str     w2, [x20]
        str     w1, [x20]
        bl      puthex32
        mov     w2, #10
        str     w2, [x20]
        b       halt
puthex32:
        mov     w5, #28
        mov     w3, #8
ph_top: cmp     w3, #4
        b.le    ph_emit
        lsr     w2, w0, w5
        and     w2, w2, #15
        cbnz    w2, ph_emit
        sub     w5, w5, #4
        sub     w3, w3, #1
        b       ph_top
ph_emit:
        lsr     w2, w0, w5
        and     w2, w2, #15
        cmp     w2, #9
        add     w2, w2, #48
        b.ls    1f
        add     w2, w2, #7
1:      str     w2, [x20]
        subs    w5, w5, #4
        b.lo    ph_done
        b       ph_emit
ph_done:
        ret
halt:
        mov     w0, #0x18           // semihosting SYS_EXIT
        movz    x1, #0x2, lsl #16
        movz    x2, #0x26
        orr     x1, x1, x2          // ADP_Stopped_ApplicationExit
        hlt     #0xF000
        wfe
        b       halt

        .section .rodata
        .balign 2
heads:  .hword 0x7FF1, 0xFFF1, 0x7FF8, 0xFFF8
        .balign 4
cpuid_l0:      .word 0x16, 0x314E614E, 0x4D565F65, 0x726F4336
cpuid_l1:      .word 0x00000F10, 0, 0, 1
cpuid_l80:     .word 0x80000004, 0, 0, 0
cpuid_l81:     .word 0, 0, 0, 0x20000000
cpuid_l82:     .word 0x314E614E, 0x6F702036, 0x62617472, 0x4320656C
cpuid_l83:     .word 0x726F6320, 0x6E282065, 0x7820746F, 0x20293836
cpuid_l84:     .word 0, 0, 0, 0
cpuid_zero:    .word 0, 0, 0, 0

        .balign 8
guest_img:
        .include "s1_guest.inc"
guest_end:

        .section .bss
        .balign 8
regs:   .space 64
        .balign 8
disp_fbw:    .space 4
disp_fbh:    .space 4
disp_fbtot:  .space 4
disp_vmode:  .space 4
disp_frame:  .space 4
disp_rawkb:  .space 4
        .balign 8
cells:  .space 4000
        .balign 4096
vram:   .space 16777216           // 16 MiB display VRAM (NAN_VRAM)
        .balign 4096
guest_ram:
        .space 33554432            // 4M words (M = 0x3FFFFF)
        .balign 16
        .space 16384
stack_top:
