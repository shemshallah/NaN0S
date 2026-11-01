; nan16dump.nas - NaN16 word inspector. Pure NaN16, prints to COM1.
; Input r1 = word address. Clobbers r1..r9, r15. Preserves r10..r14.
nan16_dump:
  ST r15,r0,@nd_ret
  ST r1,r0,@nd_addr
  MOVI r1,@s_addr
  CALL @puts
  LD r1,r0,@nd_addr
  CALL @puthex
  LDN r2,r0,@nd_addr
  ST r2,r0,@nd_n
  MOVI r1,@s_pred
  CALL @puts
  LD r3,r0,@nd_n
  MOVI r4,@predtab
  ADD r4,r4,r3
  LD r1,r4,0
  CALL @puts
  MOVI r1,@s_op
  CALL @puts
  LD r3,r0,@nd_addr
  LD r3,r3,0
  SHR r3,r3,24
  MOVI r4,255
  BOOL.8 r1,r3,r4
  CALL @puthex
  MOVI r1,@s_d
  CALL @puts
  LD r3,r0,@nd_addr
  LD r3,r3,0
  SHR r3,r3,20
  MOVI r4,15
  BOOL.8 r1,r3,r4
  CALL @puthex
  MOVI r1,@s_a
  CALL @puts
  LD r3,r0,@nd_addr
  LD r3,r3,0
  SHR r3,r3,16
  MOVI r4,15
  BOOL.8 r1,r3,r4
  CALL @puthex
  MOVI r1,@s_imm
  CALL @puts
  LD r3,r0,@nd_addr
  LD r3,r3,0
  MOVI r4,0xFFFF
  BOOL.8 r1,r3,r4
  CALL @puthex4
  MOVI r1,@s_pay
  CALL @puts
  LD r1,r0,@nd_addr
  LD r1,r1,0
  CALL @puthex
  MOVI r1,@s_n
  CALL @puts
  LD r1,r0,@nd_n
  CALL @puthex
  MOVI r1,@s_nl
  CALL @puts
  LD r15,r0,@nd_ret
  RET
nd_ret:
.word 0
nd_addr:
.word 0
nd_n:
.word 0

puts:
  MOVI r4,255
p1:
  LD r2,r1,0
  MOVI r3,4
p2:
  BOOL.8 r5,r2,r4
  CMP r5,r0
  RET[EQ]
  PUTC r5
  SHR r2,r2,8
  SUB r3,r3,r13
  JMP[NE] @p2
  ADD r1,r1,r13
  JMP @p1

puthex:
  MOVI r7,7
  MOVI r2,8
ph1:
  SHR r3,r1,28
  SHL r1,r1,4
  MOVI r4,48
  ADD r4,r4,r3
  MOVI r5,10
  CMP r3,r5
  ADD[GE] r4,r4,r7
  PUTC r4
  SUB r2,r2,r13
  JMP[NE] @ph1
  RET

puthex4:
  MOVI r7,7
  MOVI r2,4
ph4:
  SHR r3,r1,28
  SHL r1,r1,4
  MOVI r4,48
  ADD r4,r4,r3
  MOVI r5,10
  CMP r3,r5
  ADD[GE] r4,r4,r7
  PUTC r4
  SUB r2,r2,r13
  JMP[NE] @ph4
  RET

s_addr:
.str "W"
s_pred:
.str " pred="
s_op:
.str " op="
s_d:
.str " d="
s_a:
.str " a="
s_imm:
.str " imm="
s_pay:
.str " pay="
s_n:
.str " n="
s_nl:
.str "\n"

predtab:
.word @p_n0
.word @p_n1
.word @p_n2
.word @p_n3
.word @p_n4
.word @p_n5
.word @p_n6
.word @p_n7
.word @p_n8
.word @p_n9
.word @p_n10
.word @p_n11
.word @p_n12
.word @p_n13
.word @p_n14
.word @p_n15
p_n0:
.str "NEVER"
p_n1:
.str "GT"
p_n2:
.str "LT"
p_n3:
.str "NE"
p_n4:
.str "EQ"
p_n5:
.str "GE"
p_n6:
.str "LE"
p_n7:
.str "n7"
p_n8:
.str "n8"
p_n9:
.str "n9"
p_n10:
.str "n10"
p_n11:
.str "n11"
p_n12:
.str "n12"
p_n13:
.str "n13"
p_n14:
.str "n14"
p_n15:
.str "ALWAYS"
