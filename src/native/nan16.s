# nan16.s — NaN16/NaNVM1 native core, flat 32-bit x86 (the ONE host file; everything else is NaN16 guest code)
# build: as --32 -o n.o nan16.s && ld -m elf_i386 -o nan16 n.o      run: ./nan16 image [maxsteps]
# image: raw guest words at guest word 0; a 1474560-byte floppy image is read from byte 2048.
# stdout = PUTC bytes + trap text (!G<pc> gate, !O<pc> bad op); fd2 = 4000-byte VGA cell dump at exit.
# Double-endian trick: ONE head decoder (head:) runs on the near face (edx>>16) and again on bswap(eax)>>16.
	.equ MASK,0xFFFFF
	.equ MAXOP,0x43
	.macro VAR n,sz,addr
	.ifdef BARE
	.equ \n,\addr
	.else
	.lcomm \n,\sz
	.endif
	.endm
	.ifdef BARE
	.equ G,0x200000            # bare metal map: kernel 0x10000, guest image 0x12000, vars 0x8000, G 2MB..10MB, VGA text 0xB8000
	.else
	.lcomm G,8<<20
	.endif
	VAR R,64,0x8000
	VAR VGA,4000,0xB8000
	VAR FBUF,64000,0xA0000
	VAR VMODE,4,0x8066
	VAR FLAGM,4,0x8040
	VAR STEPS,4,0x8044
	VAR MAXS,4,0x8048
	VAR T0,4,0x804C
	VAR KB,4,0x8050
	VAR OB,4,0x8054
	.data
heads:	.word 0x7FF1,0xFFF1,0x7FF8,0xFFF8
	.text
	.globl _start
_start:
	.ifdef BARE
	cld
	movl $0x7FFFFFFF,MAXS
	movl $1,FLAGM
	movl $0,STEPS
	mov $G,%edi                # zero the 8MB guest memory (RAM is not zeroed on real hardware)
	xor %eax,%eax
	mov $2<<20,%ecx
	rep stosl
	mov $0x12000,%esi          # guest image (loaded by the boot sector) -> word 0
	mov $G,%edi
	mov $0x4000,%ecx           # 60 KB of guest words
	rep movsl
	xor %esi,%esi
	.else
	movl $200000000,MAXS
	movl $1,FLAGM
	mov 12(%esp),%esi          # argv[2] = optional step cap (decimal)
	test %esi,%esi
	jz 2f
	xor %eax,%eax
1:	movzbl (%esi),%ecx
	sub $48,%ecx
	jb 3f
	imul $10,%eax
	add %ecx,%eax
	inc %esi
	jmp 1b
3:	mov %eax,MAXS
2:	mov $5,%eax                # open(argv[1],O_RDONLY)
	mov 8(%esp),%ebx
	xor %ecx,%ecx
	int $0x80
	mov %eax,%ebx
	mov $19,%eax               # lseek(fd,0,SEEK_END)
	xor %ecx,%ecx
	mov $2,%edx
	int $0x80
	xor %ecx,%ecx
	cmp $1474560,%eax
	jne 4f
	mov $2048,%ecx
4:	mov $19,%eax               # lseek(fd,off,SEEK_SET)
	xor %edx,%edx
	int $0x80
	mov $3,%eax                # read(fd,G,8MB)
	mov $G,%ecx
	mov $8<<20,%edx
	int $0x80
	xor %esi,%esi              # esi = guest pc
	.endif
loop:	mov STEPS,%eax
	cmp MAXS,%eax
	jae done
	inc %eax
	mov %eax,STEPS
	mov %esi,%ecx
	and $MASK,%ecx
	call nib                   # eax:edx = word, edi = class nibble n
	jc gate
	inc %esi
	shrd $16,%edx,%eax         # eax = payload
	mov %eax,%ebx
	shr $24,%ebx               # ebx = op
	cmp $0xFF,%ebx
	je done
	cmp $MAXOP,%ebx
	ja badop
	mov %eax,%ebp
	shr $18,%ebp
	and $0x3C,%ebp             # ebp = d*4
	mov %eax,%ecx
	shr $14,%ecx
	and $0x3C,%ecx
	mov R(%ecx),%ecx           # ecx = x = r[a]
	mov %eax,%edx
	and $15,%edx
	mov R(,%edx,4),%edx        # edx = b = r[imm&15]
	test %ebx,%ebx
	jz 5f
	testl %edi,FLAGM           # predicate: bit (2Z+L) of n (F is one-hot)
	jz loop
5:	jmp *tbl(,%ebx,4)

# ---- double-endian word decoder ----
# head: in ebx = 16-bit head; out ecx = class 2Q+S, CF=1 if illegal
head:	mov %ebx,%ecx
	and $0x7FF0,%ecx
	cmp $0x7FF0,%ecx
	jne 8f
	mov $0x01020000,%ecx       # legal low nibbles 1 and 8 (bit 16+l, bit4 of h is set)
	bt %ebx,%ecx
	jnc 8f
	mov %ebx,%ecx
	shr $2,%ecx
	and $2,%ecx
	shr $15,%ebx
	or %ebx,%ecx
	clc
	ret
8:	stc
	ret
# nib: in ecx = word index; out eax:edx = qword, edi = n = (c_near<<2)|c_far, CF=1 on gate failure
nib:	mov G(,%ecx,8),%eax
	mov G+4(,%ecx,8),%edx
	mov %edx,%ebx
	shr $16,%ebx               # near face
	call head
	jc 9f
	lea 0(,%ecx,4),%edi
	mov %eax,%ebx
	bswap %ebx
	shr $16,%ebx               # far face = same decoder on the byte-swapped word
	call head
	jc 9f
	or %ecx,%edi
9:	ret
# putw: in eax = word index (masked), ebx = payload, ecx = n (0..15); writes a word with heads for class n. clobbers ebx ecx edx
putw:	mov %ecx,%edx
	and $3,%ecx
	movzwl heads(,%ecx,2),%ecx
	rol $8,%cx                 # far head is stored byte-swapped (b0,b1)
	push %ebx
	shl $16,%ebx
	or %ecx,%ebx
	mov %ebx,G(,%eax,8)
	pop %ebx
	shr $16,%ebx
	shr $2,%edx
	movzwl heads(,%edx,2),%edx
	shl $16,%edx
	or %edx,%ebx
	mov %ebx,G+4(,%eax,8)
	ret

# ---- flag tails: F = 1<<(2Z+L) ----
wrz:	mov %ebx,R(%ebp)           # store result, Z=(res==0), L=0
	test %ebx,%ebx
wf:	mov %ebx,R(%ebp)           # store result, flags from the x86 op just executed (ZF, CF)
fl:	setc %cl
	setz %al
fl2:	movzbl %cl,%ecx
	movzbl %al,%eax
	lea (%ecx,%eax,2),%ecx
	mov $1,%eax
	shl %cl,%eax
	mov %eax,FLAGM
	jmp loop
st:	mov %ebx,R(%ebp)
	jmp loop
stf:	mov %ebx,R(%ebp)           # float result: flags (0,0)
	movl $1,FLAGM
	jmp loop

# ---- handlers: eax=payload ecx=x edx=b ebx=op ebp=d*4 edi=n ----
h_bool:	xor %ebx,%ebx
	mov %ecx,%eax; or %edx,%eax; not %eax
	test $1,%edi; jz 1f; or %eax,%ebx
1:	mov %ecx,%eax; not %eax; and %edx,%eax
	test $2,%edi; jz 1f; or %eax,%ebx
1:	mov %edx,%eax; not %eax; and %ecx,%eax
	test $4,%edi; jz 1f; or %eax,%ebx
1:	mov %ecx,%eax; and %edx,%eax
	test $8,%edi; jz 1f; or %eax,%ebx
1:	jmp wrz
h_movi:	movzwl %ax,%ebx
	jmp st
h_movhi: movzwl R(%ebp),%ebx
	shl $16,%eax
	or %eax,%ebx
	jmp st
h_add:	mov %ecx,%ebx
	add %edx,%ebx
	jmp wf
h_sub:	mov %ecx,%ebx
	sub %edx,%ebx
	jmp wf
h_shl:	mov %ecx,%ebx
	mov %eax,%ecx
	shl %cl,%ebx
	jmp wrz
h_shr:	mov %ecx,%ebx
	mov %eax,%ecx
	shr %cl,%ebx
	jmp wrz
h_sar:	mov %ecx,%ebx
	mov %eax,%ecx
	sar %cl,%ebx
	jmp wrz
h_cmp:	cmp %edx,%ecx
	jmp fl
h_cmps:	cmp %edx,%ecx
	setz %al
	setl %cl
	jmp fl2
h_ld:	movzwl %ax,%eax
	add %ecx,%eax
	and $MASK,%eax
	mov G+2(,%eax,8),%ebx     # payload = bytes b2..b5
	jmp st
h_st:	movzwl %ax,%eax
	add %ecx,%eax
	and $MASK,%eax
	mov R(%ebp),%ebx
	mov $10,%ecx
	call putw
	jmp loop
h_stw:	mov %ecx,%eax
	and $MASK,%eax
	mov R(%ebp),%ebx
	mov %edx,%ecx
	and $15,%ecx
	call putw
	jmp loop
h_ldn:	movzwl %ax,%eax
	add %ecx,%eax
	and $MASK,%eax
	mov %eax,%ecx
	call nib
	mov %edi,%ebx
	jnc st
	or $-1,%ebx
	jmp st
h_jmp:	movzwl %ax,%esi
	jmp loop
h_call:	mov %esi,R+60
	movzwl %ax,%esi
	jmp loop
h_ret:	mov R+60,%esi
	jmp loop
h_jmpr:	mov %ecx,%esi
	jmp loop
h_callr: mov %esi,R+60
	mov %ecx,%esi
	jmp loop
h_nop:	jmp loop
h_vpoke: cmpl $0,VMODE
	jne 1f
	cmp $2000,%ecx
	jae loop
	mov R(%ebp),%ebx
	mov %bx,VGA(,%ecx,2)
	jmp loop
1:	cmp $64000,%ecx
	jae loop
	mov R(%ebp),%ebx
	mov %bl,FBUF(,%ecx,1)
	jmp loop
h_vpeek: cmpl $0,VMODE
	jne 2f
	cmp $2000,%ecx
	jae loop
	movzwl VGA(,%ecx,2),%ebx
	jmp st
2:	cmp $64000,%ecx
	jae loop
	movzbl FBUF(,%ecx,1),%ebx
	jmp st
h_key:	.ifdef BARE
	xor %ebx,%ebx              # poll the keyboard controller: make-code scancode or 0
	in $0x64,%al
	test $1,%al
	jz st
	in $0x60,%al
	test $0x80,%al
	jnz st
	movzbl %al,%eax            # set-1 scancode -> ASCII (the guest sees what BIOS INT 16h gave it)
	cmp $0x3A,%eax
	jae st
	movzbl ktab(%eax),%ebx
	jmp st
	.else
	movl $0,KB
	mov $3,%eax
	xor %ebx,%ebx
	mov $KB,%ecx
	mov $1,%edx
	int $0x80
	movzbl KB,%ebx
	jmp st
	.endif
h_tick:	mov STEPS,%eax
	xor %edx,%edx
	mov $1000,%ecx
	div %ecx
	mov %eax,%ebx
	jmp st
h_bswapm: movzwl %ax,%eax
	add %ecx,%eax
	and $MASK,%eax
	mov G(,%eax,8),%ecx
	mov G+4(,%eax,8),%edx
	bswap %ecx
	bswap %edx
	mov %edx,G(,%eax,8)
	mov %ecx,G+4(,%eax,8)
	jmp loop
h_putc:	mov R(%ebp),%ebx
	mov %bl,OB
	call out1
	jmp loop
out1:	.ifdef BARE                # PUTC -> COM1
	mov $0x3FD,%edx
1:	in %dx,%al
	test $0x20,%al
	jz 1b
	mov $0x3F8,%edx
	movzbl OB,%eax
	out %al,%dx
	ret
	.else
	mov $4,%eax
	mov $1,%ebx
	mov $OB,%ecx
	mov $1,%edx
	int $0x80
	ret
	.endif
h_dispq: cmpl $0,VMODE
	je 1f
	mov $0x1300C800,%ebx
	jmp st
1:	mov $0x31950,%ebx
	jmp st
h_dispset: mov R(%ebp),%eax
	and $255,%eax
	cmp $0x13,%eax
	jne 2f
	movl $1,VMODE
	xor %eax,%eax
	mov $16000,%ecx
	mov $FBUF,%edi
	cld
	rep stosl
	jmp loop
2:	movl $0,VMODE
	xor %eax,%eax
	mov $1000,%ecx
	mov $VGA,%edi
	cld
	rep stosl
	jmp loop
h_fbinfo: cmpl $0,VMODE
	je 3f
	mov $0x140000C8,%ebx
	jmp st
3:	mov $0x00500019,%ebx
	jmp st
h_vsync: jmp loop
h_fbcopy: mov R(%ebp),%ecx
	test %ecx,%ecx
	jz loop
	mov %ecx,%edi
	mov %edx,%ebx
	mov R(%ebp),%ecx
1:	movzbl FBUF(%ebx),%eax
	mov %al,FBUF(%edi)
	inc %ebx
	inc %edi
	loop 1b
	jmp loop
h_fbfill: mov %ecx,%edi
	mov R(%ebp),%ecx
	mov %edx,%eax
	and $255,%eax
1:	mov %al,FBUF(%edi)
	inc %edi
	loop 1b
	jmp loop
h_outb: jmp loop
h_inb: xor %ebx,%ebx
	jmp st
h_inw: xor %ebx,%ebx
	jmp st
h_outw: jmp loop
h_outsw: jmp loop
h_outl: jmp loop

# ---- NaNVM1 integer ops ----
h_mul:	mov %ecx,%ebx
	imul %edx,%ebx
	jmp wrz
h_mulh:	mov %ecx,%eax
	imul %edx
	mov %edx,%ebx
	jmp wrz
h_mulhu: mov %ecx,%eax
	mul %edx
	mov %edx,%ebx
	jmp wrz
h_div:	test %edx,%edx
	jz z0
	cmp $-1,%edx
	jne 1f
	mov %ecx,%ebx
	neg %ebx
	jmp wrz
1:	mov %edx,%ebx
	mov %ecx,%eax
	cltd
	idiv %ebx
	mov %eax,%ebx
	jmp wrz
h_mod:	test %edx,%edx
	jz zx
	cmp $-1,%edx
	jne 1f
	xor %ebx,%ebx
	jmp wrz
1:	mov %edx,%ebx
	mov %ecx,%eax
	cltd
	idiv %ebx
	mov %edx,%ebx
	jmp wrz
h_divu:	test %edx,%edx
	jz z0
	mov %edx,%ebx
	mov %ecx,%eax
	xor %edx,%edx
	div %ebx
	mov %eax,%ebx
	jmp wrz
h_modu:	test %edx,%edx
	jz zx
	mov %edx,%ebx
	mov %ecx,%eax
	xor %edx,%edx
	div %ebx
	mov %edx,%ebx
	jmp wrz
z0:	xor %ebx,%ebx              # divide by zero: result 0, flags (Z,L)=(1,1) => only ALWAYS runs
	jmp zf
zx:	mov %ecx,%ebx              # modulo by zero: result x
zf:	mov %ebx,R(%ebp)
	movl $8,FLAGM
	jmp loop
h_addi:	movswl %ax,%ebx
	add %ecx,%ebx
	jmp wf
h_ldb:	movzwl %ax,%eax
	add %ecx,%eax
	mov %eax,%ecx
	shr $2,%eax
	and $MASK,%eax
	mov G+2(,%eax,8),%ebx
	shl $3,%ecx
	shr %cl,%ebx
	movzbl %bl,%ebx
	jmp st
h_stb:	movzwl %ax,%eax
	add %ecx,%eax
	mov %eax,%ecx
	shl $3,%ecx
	shr $2,%eax
	and $MASK,%eax
	mov G+2(,%eax,8),%ebx
	mov $255,%edx
	shl %cl,%edx
	not %edx
	and %edx,%ebx
	movzbl R(%ebp),%edx
	shl %cl,%edx
	or %edx,%ebx
	mov $10,%ecx
	call putw
	jmp loop
h_bcopy: mov %ecx,%eax
	and $MASK,%eax             # src
	mov R(%ebp),%ebx
	and $MASK,%ebx             # dst
	mov %edx,%ecx              # count
	jecxz 3f
	mov %ebx,%edi
	sub %eax,%edi
	and $MASK,%edi
	cmp %ecx,%edi
	jb 2f                      # dst inside src range ahead of it: copy backwards
1:	movq G(,%eax,8),%xmm0
	movq %xmm0,G(,%ebx,8)
	inc %eax
	and $MASK,%eax
	inc %ebx
	and $MASK,%ebx
	loop 1b
3:	jmp loop
2:	lea -1(%eax,%ecx),%eax
	and $MASK,%eax
	lea -1(%ebx,%ecx),%ebx
	and $MASK,%ebx
1:	movq G(,%eax,8),%xmm0
	movq %xmm0,G(,%ebx,8)
	dec %eax
	and $MASK,%eax
	dec %ebx
	and $MASK,%ebx
	loop 1b
	jmp loop
h_bfill: mov %ecx,T0
	mov %edx,%edi
	mov R(%ebp),%eax
1:	test %edi,%edi
	jz loop
	and $MASK,%eax
	mov T0,%ebx
	mov $10,%ecx
	call putw
	inc %eax
	dec %edi
	jmp 1b

# ---- NaNVM1 float ops (IEEE binary32 in the payload; SSE scalar single) ----
h_fadd:	movd %ecx,%xmm0
	movd %edx,%xmm1
	addss %xmm1,%xmm0
	jmp fres
h_fsub:	movd %ecx,%xmm0
	movd %edx,%xmm1
	subss %xmm1,%xmm0
	jmp fres
h_fmul:	movd %ecx,%xmm0
	movd %edx,%xmm1
	mulss %xmm1,%xmm0
	jmp fres
h_fdiv:	test $0x7FFFFFFF,%edx
	jnz 1f
	mov %ecx,%ebx              # x/0: 0/0 or NaN/0 -> +qNaN, else signed infinity
	and $0x7FFFFFFF,%ebx
	jz fnan
	cmp $0x7F800000,%ebx
	ja fnan
1:	movd %ecx,%xmm0
	movd %edx,%xmm1
	divss %xmm1,%xmm0
fres:	movd %xmm0,%ebx
	jmp stf
fnan:	mov $0x7FC00000,%ebx
	jmp stf
h_fsqrt: movd %ecx,%xmm0
	xorps %xmm1,%xmm1
	ucomiss %xmm1,%xmm0
	jp fnan
	jb fnan
	sqrtss %xmm0,%xmm0
	jmp fres
h_fcmp:	movd %ecx,%xmm0
	movd %edx,%xmm1
	ucomiss %xmm1,%xmm0
	jp 1f
	jmp fl
1:	movl $8,FLAGM              # unordered -> (Z,L)=(1,1)
	jmp loop
h_cvtif: cvtsi2ss %ecx,%xmm0
	jmp fres
h_cvtfi: movd %ecx,%xmm0
	xor %ebx,%ebx
	ucomiss %xmm0,%xmm0
	jp wrz                     # NaN -> 0
	cvttss2si %xmm0,%ebx
	cmp $0x80000000,%ebx
	jne wrz
	test %ecx,%ecx
	js wrz                     # negative overflow stays INT_MIN
	mov $0x7FFFFFFF,%ebx
	jmp wrz

# ---- exits and traps ----
gate:	inc %esi                   # model prints pc after increment
	mov $0x47,%eax             # 'G'
	jmp trap
badop:	mov $0x4F,%eax             # 'O'
trap:	push %eax
	movb $0x21,OB                # '!'
	call out1
	pop %eax
	mov %al,OB
	call out1
	mov $12,%ecx               # print pc as hex, at least 4 digits
1:	mov %esi,%edx
	shr %cl,%edx
	shr $4,%edx
	jz 2f
	add $4,%ecx
	jmp 1b
2:	mov %esi,%edx
	shr %cl,%edx
	and $15,%edx
	movzbl hexd(%edx),%eax
	mov %al,OB
	push %ecx
	call out1
	pop %ecx
	sub $4,%ecx
	jns 2b
done:	.ifdef BARE
	cli
1:	hlt
	jmp 1b
	.else
	mov $4,%eax                # write(2,VGA,4000)
	mov $2,%ebx
	mov $VGA,%ecx
	mov $4000,%edx
	int $0x80
	mov $1,%eax
	xor %ebx,%ebx
	int $0x80
	.endif
	.data
hexd:	.ascii "0123456789ABCDEF"
ktab:	.byte 0,27
	.ascii "1234567890-="
	.byte 8,9
	.ascii "qwertyuiop[]"
	.byte 13,0
	.ascii "asdfghjkl;'`"
	.byte 0
	.ascii "\\zxcvbnm,./"
	.byte 0,42,0,32
tbl:	.long h_bool,h_movi,h_movhi,h_add,h_sub,h_shl,h_shr,h_cmp,h_ld,h_st,h_jmp,h_call,h_ret,h_jmpr,badop,h_nop
	.long h_vpoke,h_vpeek,h_key,h_tick,h_bswapm,h_putc,h_stw,h_ldn,h_dispq,h_dispset,h_key,h_nop,badop,badop,badop,badop
	.long h_mul,h_mulh,h_mulhu,h_div,h_mod,h_divu,h_modu,h_sar,h_cmps,h_addi,h_ldb,h_stb,h_callr,h_bcopy,h_bfill,h_nop
	.long h_fadd,h_fsub,h_fmul,h_fdiv,h_fsqrt,h_fcmp,h_cvtif,h_cvtfi
	.long badop,badop,h_fbinfo,h_vsync,h_fbcopy,h_fbfill,h_outb,h_inb,h_inw,h_outw,h_outsw,h_outl
