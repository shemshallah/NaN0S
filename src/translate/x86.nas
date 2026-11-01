; x86.nas - x86 backend slice. The full encoder lives in nasm1 until extracted.
x86_emit_nop:
  MOVI r1,0x90
  JMP @common_emit8
x86_emit_ret:
  MOVI r1,0xC3
  JMP @common_emit8
x86_emit_int3:
  MOVI r1,0xCC
  JMP @common_emit8
