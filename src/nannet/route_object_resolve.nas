; Resolve a parsed object key against the typed registry and logical owner point.
; ABI: r1=key byte pointer, r2=key byte length, r3=logical point.
; Returns r1=object ID, r2=kind, r3=status, r4=payload digest, r5=registry slot.
; Status: 0 success, 1/2 key-decoder error, 3 object missing, 4 kind mismatch, 5 owner mismatch.
nmr_route_resolve:
ST r15,r0,@nmr_route_resolve_ret
ST r3,r0,@nmr_route_point
CALL @nmr_key_decode
CMP r3,r0
JMP[NE] @nmr_route_key_error
ST r1,r0,@nmr_route_kind
ST r2,r0,@nmr_route_id
LD r1,r0,@nmr_route_id
CALL @nmr_obj_get
CMP r5,r0
JMP[NE] @nmr_route_missing
LD r8,r0,@nmr_route_kind
CMP r1,r8
JMP[NE] @nmr_route_kind_error
LD r8,r0,@nmr_route_point
CMP r2,r8
JMP[NE] @nmr_route_owner_error
LD r1,r0,@nmr_route_id
LD r2,r0,@nmr_route_kind
MOVI r3,0
LD r15,r0,@nmr_route_resolve_ret
RET
nmr_route_key_error:
; Preserve the decoder's 1/2 status.
LD r15,r0,@nmr_route_resolve_ret
RET
nmr_route_missing:
MOVI r1,0
MOVI r2,0
MOVI r3,3
MOVI r4,0
MOVI r5,0
LD r15,r0,@nmr_route_resolve_ret
RET
nmr_route_kind_error:
MOVI r1,0
MOVI r2,0
MOVI r3,4
MOVI r4,0
MOVI r5,0
LD r15,r0,@nmr_route_resolve_ret
RET
nmr_route_owner_error:
MOVI r1,0
MOVI r2,0
MOVI r3,5
MOVI r4,0
MOVI r5,0
LD r15,r0,@nmr_route_resolve_ret
RET
nmr_route_resolve_ret:
.word 0
nmr_route_point:
.word 0
nmr_route_kind:
.word 0
nmr_route_id:
.word 0
