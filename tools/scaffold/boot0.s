# SCAFFOLD SOURCE (not shipped): derives src/boot/boot0.nan bytes. objdump-verified.
.intel_syntax noprefix
.code16
.global _start
_start:
  cli
  xor ax,ax
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,0x7C00
  sti
  mov [0x0500],dl          # boot drive (at 0000:0500, clear of the stack)
  mov ax,3                 # text mode 80x25, clears screen
  int 0x10
  mov bx,0x7E00            # NaNVM0 interpreter: sectors 2-4 -> 0000:7E00
  mov ax,0x0203
  mov cx,0x0002
  mov dl,[0x0500]
  xor dh,dh
  int 0x13
  jc fail
  mov ax,0x1000            # guest memory image: 128 sectors (64KB) from CHS 0/0/5 -> 1000:0000
  mov es,ax
  xor bx,bx
  mov cx,0x0005            # ch=cyl 0, cl=sector 5
  xor dh,dh
  mov si,128
rd:
  mov ax,0x0201
  mov dl,[0x0500]
  int 0x13
  jc fail
  add bx,512
  inc cl
  cmp cl,19
  jb nxt
  mov cl,1
  inc dh
  cmp dh,2
  jb nxt
  xor dh,dh
  inc ch
nxt:
  dec si
  jnz rd
  ljmp 0,0x7E00
fail:
  mov ax,0x0E44            # 'D' = disk error
  int 0x10
  cli
1: hlt
  jmp 1b
