.org 0
JMP @n16srv_test_main
.include "nannet.nas"
.include "n16t_android_abi.nas"

n16srv_test_main:
MOVI r13,1
CALL @nn_tables_reset
MOVI r1,1
CALL @nn_link_up
CALL @n16_android_reset_impl

; Build a real guest-owned HELLO frame selecting logical portal point 1.
MOVI r1,@n16srv_test_request
SHL r1,r1,2
MOVI r2,1
MOVI r3,1
MOVI r4,@n16srv_test_hello_payload
SHL r4,r4,2
MOVI r5,2
MOVI r6,@n16srv_test_session
SHL r6,r6,2
CALL @n16_frame_build
MOVI r7,38
CMP r1,r7
JMP[NE] @n16srv_test_fail
CMP r3,r0
JMP[NE] @n16srv_test_fail
MOVI r1,65
PUTC r1

; The server ABI validates/routes HELLO and builds CAPABILITIES in NaN16.
MOVI r1,@n16srv_test_request
SHL r1,r1,2
MOVI r2,38
MOVI r4,@n16srv_test_response
SHL r4,r4,2
MOVI r5,@n16srv_test_response_payload
SHL r5,r5,2
MOVI r6,@n16srv_test_server_session
SHL r6,r6,2
CALL @n16_server_exchange_impl
CMP r3,r0
JMP[NE] @n16srv_test_fail
MOVI r7,44
CMP r1,r7
JMP[NE] @n16srv_test_fail
MOVI r1,66
PUTC r1
LD r7,r0,@n16s_state
MOVI r8,2
CMP r7,r8
JMP[NE] @n16srv_test_fail
LD r7,r0,@n16a_send_seq
CMP r7,r8
JMP[NE] @n16srv_test_fail
MOVI r1,67
PUTC r1

; Replaying the same HELLO must be denied without consuming another sequence.
MOVI r1,@n16srv_test_request
SHL r1,r1,2
MOVI r2,38
MOVI r4,@n16srv_test_response
SHL r4,r4,2
MOVI r5,@n16srv_test_response_payload
SHL r5,r5,2
MOVI r6,@n16srv_test_server_session
SHL r6,r6,2
CALL @n16_server_exchange_impl
MOVI r7,3
CMP r3,r7
JMP[NE] @n16srv_test_fail
MOVI r1,68
PUTC r1

; Validate the server response in the guest after resetting only the inbound
; replay cursor. This proves the emitted CRC, session, sequence and payload.
CALL @n16_session_reset
MOVI r1,@n16srv_test_response
SHL r1,r1,2
MOVI r2,44
CALL @n16_frame_validate
CMP r3,r0
JMP[NE] @n16srv_test_fail
MOVI r7,2
CMP r1,r7
JMP[NE] @n16srv_test_fail
MOVI r7,8
CMP r2,r7
JMP[NE] @n16srv_test_fail
MOVI r1,69
PUTC r1
MOVI r4,@n16srv_test_response
SHL r4,r4,2
ADDI r4,r4,32
LDB r7,r4,0
MOVI r8,1
CMP r7,r8
JMP[NE] @n16srv_test_fail
LDB r7,r4,1
CMP r7,r0
JMP[NE] @n16srv_test_fail
LDB r7,r4,2
CMP r7,r0
JMP[NE] @n16srv_test_fail
LDB r7,r4,3
CMP r7,r0
JMP[NE] @n16srv_test_fail
LDB r7,r4,4
CMP r7,r0
JMP[NE] @n16srv_test_fail
LDB r7,r4,5
CMP r7,r0
JMP[NE] @n16srv_test_fail
LDB r7,r4,6
CMP r7,r0
JMP[NE] @n16srv_test_fail
LDB r7,r4,7
CMP r7,r0
JMP[NE] @n16srv_test_fail
MOVI r1,70
PUTC r1

; CLOSE is routed by the guest, resets its session, and returns a guest-built
; terminal CLOSE frame. No host-side frame parsing or CRC generation occurs.
MOVI r1,@n16srv_test_request
SHL r1,r1,2
MOVI r2,13
MOVI r3,2
MOVI r4,@n16srv_test_hello_payload
SHL r4,r4,2
MOVI r5,0
MOVI r6,@n16srv_test_session
SHL r6,r6,2
CALL @n16_frame_build
MOVI r7,36
CMP r1,r7
JMP[NE] @n16srv_test_fail
CMP r3,r0
JMP[NE] @n16srv_test_fail
MOVI r1,@n16srv_test_request
SHL r1,r1,2
MOVI r2,36
MOVI r4,@n16srv_test_response
SHL r4,r4,2
MOVI r5,@n16srv_test_response_payload
SHL r5,r5,2
MOVI r6,@n16srv_test_server_session
SHL r6,r6,2
CALL @n16_server_exchange_impl
CMP r3,r0
JMP[NE] @n16srv_test_fail
MOVI r7,36
CMP r1,r7
JMP[NE] @n16srv_test_fail
LD r7,r0,@n16s_state
CMP r7,r0
JMP[NE] @n16srv_test_fail
MOVI r1,71
PUTC r1

; PASS
MOVI r1,78
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,54
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,86
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,80
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,10
PUTC r1
HALT

n16srv_test_fail:
MOVI r1,78
PUTC r1
MOVI r1,49
PUTC r1
MOVI r1,54
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,86
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,70
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,76
PUTC r1
MOVI r1,10
PUTC r1
HALT

.org 60000
n16srv_test_request:
.word 0,0,0,0,0,0,0,0,0,0
n16srv_test_response:
.word 0,0,0,0,0,0,0,0,0,0,0,0
n16srv_test_hello_payload:
.word 1
n16srv_test_response_payload:
.word 0,0
n16srv_test_session:
.word 0x12345678,0x90ABCDEF,0x13579BDF,0x2468ACE0
n16srv_test_server_session:
.word 0,0,0,0
