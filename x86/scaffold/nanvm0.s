# SCAFFOLD SOURCE (not shipped): derives src/vm/nanvm0.nan bytes. objdump-verified.
# NaNVM0: smallest native boundary. Fetches 8-byte NaN words, gates both faces,
# decodes class nibble n=(cn<<2)|cf, executes NaN16 (see spec/NAN16_SPEC.md).
.intel_syntax noprefix
.code16
.global _start
.equ REGS,0x0600
.equ FK,0x0640
.equ NB,0x0641
.equ OPV,0x0642
.equ TMP,0x0644
_start:
  xor ax,ax
  mov ds,ax
  mov ax,0x1000
  mov es,ax              # ES = guest memory (8192 words)
  mov ax,0xB800
  mov fs,ax              # FS = VGA text
  mov ax,0x0040
  mov gs,ax              # GS = BIOS data (tick @6C)
  cld
  mov bx,REGS
  mov cx,18
z0:
  mov dword ptr [bx],0
  add bx,4
  loop z0
  xor si,si              # pc = 0
run:
  and si,0x1FFF
  mov bx,si
  shl bx,3
  inc si
  mov ax,es:[bx+6]       # near face head
  call hc
  jc tgate
  shl al,2
  mov ch,al
  mov ax,es:[bx]         # far face head (BE read)
  xchg al,ah
  call hc
  jc tgate
  or ch,al
  mov [NB],ch            # n
  mov edx,es:[bx+2]      # payload
  mov eax,edx
  shr eax,24
  mov [OPV],al
  test al,al
  jz go                  # BOOL: n is the function, no predicate
  cmp al,0xFF
  je h_halt
  cmp al,0x1F
  ja tbadop
  mov cl,[FK]
  mov ah,[NB]
  shr ah,cl
  test ah,1
  jz run                 # predicate false: skip
go:
  mov ecx,edx
  shr ecx,20
  and cx,15
  shl cx,2
  mov bx,cx              # bx = d*4
  mov ecx,edx
  shr ecx,16
  and cx,15
  shl cx,2
  mov di,cx              # di = a*4 ; dx = imm16
  movzx bp,byte ptr [OPV]
  add bp,bp
  call word ptr ds:[bp+JT]
  jmp run
hc:                      # ax=head -> al=class 2Q+S ; CF=1 if not a legal face
  mov dx,ax
  and dx,0x7FF0
  cmp dx,0x7FF0
  jne hbad
  mov dl,al
  and dl,15
  cmp dl,1
  je hok
  cmp dl,8
  jne hbad
hok:
  mov dl,al
  shr dl,3
  and dl,1
  add dl,dl
  shr ax,15
  or al,dl
  ret
hbad:
  stc
  ret
putal:
  pusha
  mov ah,0x0E
  mov bx,7
  int 0x10
  popa
  ret
tgate:
  mov al,'!'
  call putal
  mov al,'G'
  jmp tp
tbadop:
  mov al,'!'
  call putal
  mov al,'O'
tp:
  call putal
  mov cx,4
tp1:
  rol si,4
  mov ax,si
  and al,15
  add al,'0'
  cmp al,'9'
  jbe tp2
  add al,7
tp2:
  call putal
  loop tp1
h_halt:
  cli
  hlt
  jmp h_halt
getb:
  mov bp,dx
  and bp,15
  shl bp,2
  mov ecx,ds:[bp+REGS]
  ret
setfk:                   # cl=L ch=Z
  add ch,ch
  or ch,cl
  mov [FK],ch
  ret
ea:                      # bp = ((r[a]+imm)&0x1FFF)*8
  mov eax,[di+REGS]
  add ax,dx
  and ax,0x1FFF
  shl ax,3
  mov bp,ax
  ret
h_bool:
  call getb
  mov eax,[di+REGS]
  xor edx,edx
  mov edi,eax
  or edi,ecx
  not edi
  bt word ptr [NB],0
  sbb ebp,ebp
  and edi,ebp
  or edx,edi
  mov edi,eax
  not edi
  and edi,ecx
  bt word ptr [NB],1
  sbb ebp,ebp
  and edi,ebp
  or edx,edi
  mov edi,ecx
  not edi
  and edi,eax
  bt word ptr [NB],2
  sbb ebp,ebp
  and edi,ebp
  or edx,edi
  mov edi,eax
  and edi,ecx
  bt word ptr [NB],3
  sbb ebp,ebp
  and edi,ebp
  or edx,edi
  mov [bx+REGS],edx
  test edx,edx
  setz ch
  xor cl,cl
  jmp setfk
h_movi:
  movzx edx,dx
  mov [bx+REGS],edx
  ret
h_movhi:
  mov [bx+REGS+2],dx
  ret
h_add:
  call getb
  mov eax,[di+REGS]
  add eax,ecx
  mov [bx+REGS],eax
  setc cl
  setz ch
  jmp setfk
h_sub:
  call getb
  mov eax,[di+REGS]
  sub eax,ecx
  mov [bx+REGS],eax
  setc cl
  setz ch
  jmp setfk
h_shl:
  mov cl,dl
  and cl,31
  mov eax,[di+REGS]
  shl eax,cl
  jmp shfin
h_shr:
  mov cl,dl
  and cl,31
  mov eax,[di+REGS]
  shr eax,cl
shfin:
  mov [bx+REGS],eax
  test eax,eax
  setz ch
  xor cl,cl
  jmp setfk
h_cmp:
  call getb
  mov eax,[di+REGS]
  cmp eax,ecx
  setc cl
  setz ch
  jmp setfk
h_ld:
  call ea
  mov eax,es:[bp+2]
  mov [bx+REGS],eax
  ret
h_st:
  call ea
  mov eax,[bx+REGS]
  mov es:[bp+2],eax
  mov word ptr es:[bp],0xF87F
  mov word ptr es:[bp+6],0x7FF8
  ret
h_jmp:
  mov si,dx
  ret
h_call:
  movzx eax,si
  mov [REGS+60],eax
  mov si,dx
  ret
h_ret:
  mov si,[REGS+60]
  ret
h_jmpr:
  mov si,[di+REGS]
  ret
h_nop:
  ret
h_vpoke:
  mov eax,[di+REGS]
  cmp eax,2000
  jae h_nop
  mov bp,ax
  add bp,bp
  mov ax,[bx+REGS]
  mov fs:[bp],ax
  ret
h_vpeek:
  mov eax,[di+REGS]
  cmp eax,2000
  jae h_nop
  mov bp,ax
  add bp,bp
  movzx eax,word ptr fs:[bp]
  mov [bx+REGS],eax
  ret
h_key:
  pushad
  xor ax,ax
  int 0x16
  mov [TMP],ax
  popad
  movzx eax,word ptr [TMP]
  mov [bx+REGS],eax
  ret
h_tick:
  mov eax,gs:[0x6C]
  mov [bx+REGS],eax
  ret
h_bswapm:
  call ea
  mov eax,es:[bp]
  mov edx,es:[bp+4]
  bswap eax
  bswap edx
  mov es:[bp],edx
  mov es:[bp+4],eax
  ret
h_putc:
  mov al,[bx+REGS]
  jmp putal
h_stw:                   # mem[r[a]] = word(class r[b]&15, payload r[d])
  call getb
  mov eax,[di+REGS]
  and ax,0x1FFF
  shl ax,3
  mov bp,ax
  mov eax,[bx+REGS]
  mov es:[bp+2],eax
  mov bx,cx
  and bx,15
  mov ax,bx
  and ax,3
  add ax,ax
  mov di,ax
  mov ax,[di+HEADS]
  xchg al,ah
  mov es:[bp],ax
  mov ax,bx
  shr ax,2
  add ax,ax
  mov di,ax
  mov ax,[di+HEADS]
  mov es:[bp+6],ax
  ret
h_ldn:                   # r[d] = class nibble of mem[r[a]+imm], or FFFFFFFF if gate fails
  call ea
  mov ax,es:[bp+6]
  call hc
  jc ldnbad
  shl al,2
  mov cl,al
  mov ax,es:[bp]
  xchg al,ah
  call hc
  jc ldnbad
  or al,cl
  movzx eax,al
  mov [bx+REGS],eax
  ret
ldnbad:
  mov dword ptr [bx+REGS],0xFFFFFFFF
  ret
h_dispq:                 # r[d] = mode<<16 | rows<<8 | cols
  pushad
  mov ah,0x0F
  int 0x10
  mov [TMP],ax
  popad
  movzx edx,byte ptr [TMP+1]
  movzx eax,byte ptr gs:[0x84]
  inc eax
  shl eax,8
  or edx,eax
  movzx eax,byte ptr [TMP]
  and al,0x7F
  shl eax,16
  or edx,eax
  mov [bx+REGS],edx
  ret
h_dispset:               # BIOS set video mode r[d]&255
  pushad
  mov al,[bx+REGS]
  xor ah,ah
  int 0x10
  popad
  ret
h_keyq:                  # r[d] = next key (scan<<8|ascii) or 0 if none; never blocks
  pushad
  mov ah,1
  int 0x16
  jz kq0
  xor ax,ax
  int 0x16
  jmp kq1
kq0:
  xor ax,ax
kq1:
  mov [TMP],ax
  popad
  movzx eax,word ptr [TMP]
  mov [bx+REGS],eax
  ret
h_beep:                  # PC speaker: r[d]=PIT divisor (1193182/hz); 0 = off
  mov ax,[bx+REGS]
  test ax,ax
  jz bq0
  push ax
  mov al,0xB6
  out 0x43,al
  pop ax
  out 0x42,al
  mov al,ah
  out 0x42,al
  in al,0x61
  or al,3
  out 0x61,al
  ret
bq0:
  in al,0x61
  and al,0xFC
  out 0x61,al
  ret
HEADS:
  .word 0x7FF1,0xFFF1,0x7FF8,0xFFF8
JT:
  .word h_bool,h_movi,h_movhi,h_add,h_sub,h_shl,h_shr,h_cmp
  .word h_ld,h_st,h_jmp,h_call,h_ret,h_jmpr,tbadop,h_nop
  .word h_vpoke,h_vpeek,h_key,h_tick,h_bswapm,h_putc,h_stw,h_ldn
  .word h_dispq,h_dispset,h_keyq,h_beep,tbadop,tbadop,tbadop,tbadop
