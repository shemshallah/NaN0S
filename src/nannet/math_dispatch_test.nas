; Typed two-endpoint mathematical dispatch resolution regression.
; This resolves a registered operation program; it does not execute the math program.
main:
; Two vector endpoints owned by logical runner points 1 and 2.
MOVI r1,1337
MOVI r2,4
MOVI r3,1
MOVI r4,3001
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
MOVI r1,1338
MOVI r2,4
MOVI r3,2
MOVI r4,3002
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
; dot.v1: vector(4) x vector(4) -> scalar(1), NaN16 guest program 79.
MOVI r1,701
MOVI r2,4
MOVI r3,4
MOVI r4,3
MOVI r5,79
CALL @nmr_op_put
CMP r3,r0
JMP[NE] @fail
; Resolve the explicit operator against both typed endpoints.
MOVI r1,1337
MOVI r2,1338
MOVI r3,701
CALL @nmr_resolve
CMP r3,r0
JMP[NE] @fail
MOVI r7,3
CMP r1,r7
JMP[NE] @fail
MOVI r7,79
CMP r2,r7
JMP[NE] @fail
; Re-registering the exact immutable operator is idempotent.
MOVI r1,701
MOVI r2,4
MOVI r3,4
MOVI r4,3
MOVI r5,79
CALL @nmr_op_put
CMP r3,r0
JMP[NE] @fail
; A different signature cannot overwrite the same operator ID.
MOVI r1,701
MOVI r2,4
MOVI r3,8
MOVI r4,3
MOVI r5,79
CALL @nmr_op_put
MOVI r7,5
CMP r3,r7
JMP[NE] @fail
; Explicit wrong operator ID must fail closed.
MOVI r1,1337
MOVI r2,1338
MOVI r3,702
CALL @nmr_resolve
MOVI r7,3
CMP r3,r7
JMP[NE] @fail
; Type mismatch (hypergraph as right endpoint) fails closed.
MOVI r1,1339
MOVI r2,8
MOVI r3,3
MOVI r4,3003
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
MOVI r1,1337
MOVI r2,1339
MOVI r3,701
CALL @nmr_resolve
MOVI r7,6
CMP r3,r7
JMP[NE] @fail
; PASS
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
fail:
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
.include "math_registry.nas"
