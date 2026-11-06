; Android-callable NaN16 N16T guest ABI.
; The host sets r1..r6 and PC to one of the public entry labels below.
; Each public entry returns through HALT; the same VM instance is retained.
; All framing, CRC, session and transition semantics remain in this guest.
;
; n16_android_build: r1=out,r2=type,r3=seq,r4=payload,r5=len,r6=sid
; n16_android_route: r1=frame,r2=frame_bytes -> r1..r4 route,status
; n16_android_advance: r1=type,r2=payload_bytes -> r1=state,r2=error,r3=status
; n16_android_reset: reset validator replay/session and transition state.

n16_android_build:
CALL @n16_android_build_impl
HALT

n16_android_route:
CALL @n16_android_route_impl
HALT

n16_android_advance:
CALL @n16_android_advance_impl
HALT

n16_android_reset:
CALL @n16_android_reset_impl
HALT

; Callable implementations are also used by the NaN16 guest regression.
n16_android_build_impl:
ST r15,r0,@n16a_call_ret
CALL @n16_frame_build
LD r15,r0,@n16a_call_ret
RET

n16_android_route_impl:
ST r15,r0,@n16a_call_ret
CALL @n16_frame_route
LD r15,r0,@n16a_call_ret
RET

n16_android_advance_impl:
ST r15,r0,@n16a_call_ret
CALL @n16_session_transition
LD r15,r0,@n16a_call_ret
RET

n16a_call_ret:
.word 0

n16_android_reset_impl:
ST r15,r0,@n16a_reset_ret
CALL @n16_session_reset
MOVI r4,0
ST r4,r0,@n16s_state
LD r15,r0,@n16a_reset_ret
RET
n16a_reset_ret:
.word 0
