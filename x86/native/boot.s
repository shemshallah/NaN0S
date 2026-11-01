# boot.s — NaN/0S boot sector: BIOS floppy -> load 528 sectors to 0x10000 -> A20 -> protected mode (flat) -> jump to kernel (nan16.s built with BARE).
# build: as --32 -o b.o boot.s && ld -m elf_i386 -Ttext=0x7c00 --oformat binary -o boot.bin b.o
	.code16
	.globl _start
_start:	cli
	xor %ax,%ax
	mov %ax,%ds
	mov %ax,%ss
	mov $0x7C00,%sp
	sti
	mov %dl,drive
	mov $0x1000,%ax
	mov %ax,%es
	xor %bx,%bx
	mov $0x0002,%cx            # cyl 0, sector 2
	xor %dh,%dh
	mov $528,%si               # 16 kernel + 120 guest sectors
1:	mov $0x0201,%ax
	mov drive,%dl
	int $0x13
	jc fail
	mov %es,%ax
	add $0x20,%ax
	mov %ax,%es
	inc %cl
	cmp $19,%cl
	jb 2f
	mov $1,%cl
	xor $1,%dh
	jnz 2f
	inc %ch
2:	dec %si
	jnz 1b
	in $0x92,%al               # fast A20
	or $2,%al
	out %al,$0x92
	cli
	lgdt gdtr
	mov %cr0,%eax
	or $1,%eax
	mov %eax,%cr0
	ljmp $8,$pm
fail:	hlt
	jmp fail
	.code32
pm:	mov $0x10,%ax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%ss
	mov %ax,%fs
	mov %ax,%gs
	mov $0x90000,%esp
	mov $0x10000,%eax
	jmp *%eax
	.code16
drive:	.byte 0
	.align 4
gdt:	.quad 0
	.quad 0x00CF9A000000FFFF
	.quad 0x00CF92000000FFFF
gdtr:	.word 23
	.long gdt
	.org 510
	.word 0xAA55
