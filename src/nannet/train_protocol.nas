; NaN16 network frame validator v1.
; Header: N16T | version:u16 | type:u16 | session:16 | seq:u32 | len:u32
; Body: payload[len] | CRC32(header+payload):u32, all integer fields LE.
; API n16_frame_validate(r1=byte base,r2=frame bytes) -> r1=type,r2=payload bytes,r3=status.
; API n16_frame_route(r1=byte base,r2=frame bytes) -> gateway,ifid,status,logical point address.
; CRC32, replay sequence, framing and route selection are guest-side operations.
n16_frame_validate:
ST r15,r0,@n16v_ret
ST r1,r0,@n16v_base
ST r2,r0,@n16v_frame_len
MOVI r13,1
MOVI r4,36
CMP r2,r4
JMP[LT] @n16v_bounds
LD r4,r0,@n16v_base
LDB r5,r4,0
MOVI r6,78
CMP r5,r6
JMP[NE] @n16v_magic
LDB r5,r4,1
MOVI r6,49
CMP r5,r6
JMP[NE] @n16v_magic
LDB r5,r4,2
MOVI r6,54
CMP r5,r6
JMP[NE] @n16v_magic
LDB r5,r4,3
MOVI r6,84
CMP r5,r6
JMP[NE] @n16v_magic
LDB r5,r4,4
CMP r5,r13
JMP[NE] @n16v_magic
LDB r5,r4,5
CMP r5,r0
JMP[NE] @n16v_magic
ADDI r4,r4,6
MOVI r5,0
LDB r6,r4,0
BOOL.14 r5,r5,r6
LDB r6,r4,1
SHL r6,r6,8
BOOL.14 r5,r5,r6
CMP r5,r0
JMP[EQ] @n16v_magic
MOVI r6,14
CMP r6,r5
JMP[LT] @n16v_magic
ST r5,r0,@n16v_type
LD r4,r0,@n16v_base
ADDI r4,r4,24
MOVI r6,0
LDB r7,r4,0
BOOL.14 r6,r6,r7
LDB r7,r4,1
SHL r7,r7,8
BOOL.14 r6,r6,r7
LDB r7,r4,2
SHL r7,r7,16
BOOL.14 r6,r6,r7
LDB r7,r4,3
SHL r7,r7,24
BOOL.14 r6,r6,r7
ST r6,r0,@n16v_seq
LD r4,r0,@n16v_base
ADDI r4,r4,28
MOVI r8,0
LDB r7,r4,0
BOOL.14 r8,r8,r7
LDB r7,r4,1
SHL r7,r7,8
BOOL.14 r8,r8,r7
LDB r7,r4,2
SHL r7,r7,16
BOOL.14 r8,r8,r7
LDB r7,r4,3
SHL r7,r7,24
BOOL.14 r8,r8,r7
ST r8,r0,@n16v_payload
MOVI r9,0
MOVHI r9,1
CMP r8,r9
JMP[GT] @n16v_bounds
MOVI r9,36
ADD r9,r9,r8
LD r10,r0,@n16v_frame_len
CMP r9,r10
JMP[NE] @n16v_bounds
LD r12,r0,@n16v_last_seq
CMP r6,r12
JMP[LE] @n16v_sequence
MOVI r11,65535
MOVHI r11,65535
MOVI r7,0
MOVI r9,32
ADD r9,r9,r8
n16v_crc_byte:
CMP r7,r9
JMP[GE] @n16v_crc_done
LD r4,r0,@n16v_base
ADD r4,r4,r7
LDB r10,r4,0
BOOL.6 r11,r11,r10
MOVI r10,8
n16v_crc_bit:
MOVI r12,1
BOOL.8 r12,r11,r12
CMP r12,r0
JMP[EQ] @n16v_crc_zero
SHR r11,r11,1
MOVI r12,0x8320
MOVHI r12,0xEDB8
BOOL.6 r11,r11,r12
JMP @n16v_crc_next
n16v_crc_zero:
SHR r11,r11,1
n16v_crc_next:
SUB r10,r10,r13
CMP r10,r0
JMP[NE] @n16v_crc_bit
ADDI r7,r7,1
JMP @n16v_crc_byte
n16v_crc_done:
MOVI r12,65535
MOVHI r12,65535
BOOL.6 r11,r11,r12
; Lock the first validated 128-bit session id. Frames from another
; session are rejected until the owning session explicitly resets state.
LD r12,r0,@n16v_session_active
CMP r12,r0
JMP[NE] @n16v_session_check
LD r4,r0,@n16v_base
ADDI r4,r4,8
LD r5,r4,0
ST r5,r0,@n16v_session_0
LD r5,r4,1
ST r5,r0,@n16v_session_1
LD r5,r4,2
ST r5,r0,@n16v_session_2
LD r5,r4,3
ST r5,r0,@n16v_session_3
MOVI r12,1
ST r12,r0,@n16v_session_active
JMP @n16v_session_ok
n16v_session_check:
LD r4,r0,@n16v_base
ADDI r4,r4,8
LD r5,r4,0
LD r12,r0,@n16v_session_0
CMP r5,r12
JMP[NE] @n16v_session_error
LD r5,r4,1
LD r12,r0,@n16v_session_1
CMP r5,r12
JMP[NE] @n16v_session_error
LD r5,r4,2
LD r12,r0,@n16v_session_2
CMP r5,r12
JMP[NE] @n16v_session_error
LD r5,r4,3
LD r12,r0,@n16v_session_3
CMP r5,r12
JMP[NE] @n16v_session_error
n16v_session_ok:
LD r4,r0,@n16v_base
ADD r4,r4,r9
MOVI r10,0
LDB r12,r4,0
BOOL.14 r10,r10,r12
LDB r12,r4,1
SHL r12,r12,8
BOOL.14 r10,r10,r12
LDB r12,r4,2
SHL r12,r12,16
BOOL.14 r10,r10,r12
LDB r12,r4,3
SHL r12,r12,24
BOOL.14 r10,r10,r12
CMP r11,r10
JMP[NE] @n16v_crc_error
LD r6,r0,@n16v_seq
ST r6,r0,@n16v_last_seq
LD r1,r0,@n16v_type
LD r2,r0,@n16v_payload
MOVI r3,0
LD r15,r0,@n16v_ret
RET
n16v_magic:
MOVI r3,1
JMP @n16v_error
n16v_bounds:
MOVI r3,2
JMP @n16v_error
n16v_sequence:
MOVI r3,3
JMP @n16v_error
n16v_session_error:
MOVI r3,5
JMP @n16v_error
n16v_crc_error:
MOVI r3,4
n16v_error:
MOVI r1,0
MOVI r2,0
LD r15,r0,@n16v_ret
RET
n16v_ret:
.word 0
n16v_base:
.word 0
n16v_frame_len:
.word 0
n16v_type:
.word 0
n16v_seq:
.word 0
n16v_payload:
.word 0
n16v_last_seq:
.word 0
n16v_session_active:
.word 0
n16v_session_0:
.word 0
n16v_session_1:
.word 0
n16v_session_2:
.word 0
n16v_session_3:
.word 0
; Reset only after the owning transport has closed/aborted its session.
n16_session_reset:
MOVI r4,0
ST r4,r0,@n16v_session_active
ST r4,r0,@n16v_last_seq
RET
n16_frame_route:
ST r15,r0,@n16r_ret
ST r1,r0,@n16r_base
ST r2,r0,@n16r_len
CALL @n16_frame_validate
CMP r3,r0
JMP[NE] @n16r_done
LD r2,r0,@n16v_payload
MOVI r5,2
CMP r2,r5
JMP[LT] @n16r_short
LD r4,r0,@n16r_base
ADDI r4,r4,32
LDB r1,r4,0
LDB r5,r4,1
SHL r5,r5,8
BOOL.14 r1,r1,r5
CALL @ob_point_to_route
JMP @n16r_done
n16r_short:
MOVI r1,0
MOVI r2,0
MOVI r3,2
MOVI r4,0
n16r_done:
LD r15,r0,@n16r_ret
RET
n16r_ret:
.word 0
n16r_base:
.word 0
n16r_len:
.word 0
