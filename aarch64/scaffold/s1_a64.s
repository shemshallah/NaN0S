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
        cmp     w25, #0x15
        b.eq    op_putc
        cmp     w25, #0x29
        b.eq    op_addi
        cmp     w25, #0x2C
        b.eq    op_callr
        b       trapO
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
trapG:
        ldr     x0, =msgG
        b       puts_halt
trapO:
        ldr     x0, =msgO
        b       puts_halt
puts_halt:
        ldrb    w2, [x0], #1
        cbz     w2, halt
        str     w2, [x20]
        b       puts_halt
halt:
        wfe
        b       halt

        .section .rodata
msgG:   .asciz "!G\n"
msgO:   .asciz "!O\n"

        .balign 8
guest_img:
        .include "s1_guest.inc"
guest_end:

        .section .bss
        .balign 8
regs:   .space 64
        .balign 4096
guest_ram:
        .space 33554432            // 4M words (M = 0x3FFFFF)
        .balign 16
        .space 16384
stack_top:
