; ata.nas - ATA PIO driver in NaN16. The native core only gives port I/O.
; LBA28, one sector at a time. No BIOS, no Python, no host helper.
.equ ATA_DATA 0x1F0
.equ ATA_SECCOUNT 0x1F2
.equ ATA_LBA0 0x1F3
.equ ATA_LBA1 0x1F4
.equ ATA_LBA2 0x1F5
.equ ATA_DRIVE 0x1F6
.equ ATA_STATUS 0x1F7
.equ ATA_CMD 0x1F7
.equ ATA_CTRL 0x3F6

ata_delay:
  MOVI r1,#ATA_STATUS
  INB r2,r1
  INB r2,r1
  INB r2,r1
  INB r2,r1
  RET

ata_wait_bsy:
  ST r15,r0,@awb_ret
awb_l:
  MOVI r1,#ATA_STATUS
  INB r2,r1
  MOVI r3,0x80
  BOOL.8 r2,r2,r3
  CMP r2,r0
  JMP[NE] @awb_l
  LD r15,r0,@awb_ret
  RET
awb_ret:
.word 0

ata_wait_drq:
  ST r15,r0,@awd_ret
awd_l:
  MOVI r1,#ATA_STATUS
  INB r2,r1
  MOVI r3,0x08
  BOOL.8 r2,r2,r3
  CMP r2,r0
  JMP[EQ] @awd_l
  LD r15,r0,@awd_ret
  RET
awd_ret:
.word 0

; ata_read28: r1=LBA, r2=destination buffer
ata_read28:
  ST r15,r0,@ar_ret
  ADD r10,r1,r0
  ADD r11,r2,r0
  MOVI r1,#ATA_DRIVE
  MOVI r2,0xE0
  SHR r3,r10,24
  MOVI r4,15
  BOOL.8 r3,r3,r4
  BOOL.14 r2,r2,r3
  OUTB r2,r1
  CALL @ata_delay
  MOVI r1,#ATA_SECCOUNT
  MOVI r2,1
  OUTB r2,r1
  MOVI r1,#ATA_LBA0
  MOVI r2,255
  BOOL.8 r2,r10,r2
  OUTB r2,r1
  MOVI r1,#ATA_LBA1
  SHR r3,r10,8
  MOVI r2,255
  BOOL.8 r2,r3,r2
  OUTB r2,r1
  MOVI r1,#ATA_LBA2
  SHR r3,r10,16
  MOVI r2,255
  BOOL.8 r2,r3,r2
  OUTB r2,r1
  MOVI r1,#ATA_CMD
  MOVI r2,0x20
  OUTB r2,r1
  CALL @ata_wait_bsy
  CALL @ata_wait_drq
  MOVI r1,#ATA_DATA
  MOVI r12,256
ar_l:
  INW r3,r1
  ST r3,r11,0
  ADD r11,r11,r13
  SUB r12,r12,r13
  JMP[NE] @ar_l
  LD r15,r0,@ar_ret
  RET
ar_ret:
.word 0

; ata_write28: r1=LBA, r2=source buffer. Writes one sector and flushes.
ata_write28:
  ST r15,r0,@aw_ret
  ADD r10,r1,r0
  ADD r11,r2,r0
  MOVI r1,#ATA_DRIVE
  MOVI r2,0xE0
  SHR r3,r10,24
  MOVI r4,15
  BOOL.8 r3,r3,r4
  BOOL.14 r2,r2,r3
  OUTB r2,r1
  CALL @ata_delay
  MOVI r1,#ATA_SECCOUNT
  MOVI r2,1
  OUTB r2,r1
  MOVI r1,#ATA_LBA0
  MOVI r2,255
  BOOL.8 r2,r10,r2
  OUTB r2,r1
  MOVI r1,#ATA_LBA1
  SHR r3,r10,8
  MOVI r2,255
  BOOL.8 r2,r3,r2
  OUTB r2,r1
  MOVI r1,#ATA_LBA2
  SHR r3,r10,16
  MOVI r2,255
  BOOL.8 r2,r3,r2
  OUTB r2,r1
  MOVI r1,#ATA_CMD
  MOVI r2,0x30
  OUTB r2,r1
  CALL @ata_wait_bsy
  CALL @ata_wait_drq
  MOVI r1,#ATA_DATA
  MOVI r12,128
aw_l:
  LD r3,r11,0
  MOVI r4,0xFFFF
  BOOL.8 r3,r3,r4
  LD r5,r11,1
  BOOL.8 r5,r5,r4
  SHL r5,r5,16
  BOOL.14 r3,r3,r5
  OUTL r3,r1
  MOVI r4,2
  ADD r11,r11,r4
  SUB r12,r12,r13
  JMP[NE] @aw_l
  MOVI r1,#ATA_CMD
  MOVI r2,0xE7
  OUTB r2,r1
  CALL @ata_wait_bsy
  LD r15,r0,@aw_ret
  RET
aw_ret:
.word 0
