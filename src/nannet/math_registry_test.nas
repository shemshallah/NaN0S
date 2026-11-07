; Typed math-object and operation registry gate.
; Exercises idempotence, immutable-key conflict, endpoint lookup, signature check,
; and operator dispatch resolution without executing the returned program.
main:
MOVI r13,1
; vector1337: kind 4, HW0 head 1, digest marker 0x1234
MOVI r1,1337
MOVI r2,4
MOVI r3,1
MOVI r4,0x1234
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
; exact duplicate must be idempotent
MOVI r1,1337
MOVI r2,4
MOVI r3,1
MOVI r4,0x1234
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
; same immutable key with changed digest must conflict
MOVI r1,1337
MOVI r2,4
MOVI r3,1
MOVI r4,0x1235
CALL @nmr_obj_put
MOVI r5,5
CMP r3,r5
JMP[NE] @fail
; hypergraph42: kind 8, HW0 head 1
MOVI r1,42
MOVI r2,8
MOVI r3,1
MOVI r4,0x5678
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
; scalar9: kind 3
MOVI r1,9
MOVI r2,3
MOVI r3,1
MOVI r4,0x2222
CALL @nmr_obj_put
CMP r3,r0
JMP[NE] @fail
; Register vector(4) x hypergraph(8) -> tensor(9), program 900.
MOVI r1,77
MOVI r2,4
MOVI r3,8
MOVI r4,9
MOVI r5,900
CALL @nmr_op_put
CMP r3,r0
JMP[NE] @fail
; Resolve vector1337 :: hypergraph42.
MOVI r1,1337
MOVI r2,42
MOVI r3,77
CALL @nmr_resolve
CMP r3,r0
JMP[NE] @fail
MOVI r5,9
CMP r1,r5
JMP[NE] @fail
MOVI r5,900
CMP r2,r5
JMP[NE] @fail
; Wrong left endpoint type must reject with signature status 6.
MOVI r1,9
MOVI r2,42
MOVI r3,77
CALL @nmr_resolve
MOVI r5,6
CMP r3,r5
JMP[NE] @fail
; Missing object must reject with status 1.
MOVI r1,999
MOVI r2,42
MOVI r3,77
CALL @nmr_resolve
MOVI r5,1
CMP r3,r5
JMP[NE] @fail
; MATH REGISTRY PASS
MOVI r1,77
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,72
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,71
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,89
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
fail:
MOVI r1,77
PUTC r1
MOVI r1,65
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,72
PUTC r1
MOVI r1,32
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,69
PUTC r1
MOVI r1,71
PUTC r1
MOVI r1,73
PUTC r1
MOVI r1,83
PUTC r1
MOVI r1,84
PUTC r1
MOVI r1,82
PUTC r1
MOVI r1,89
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
.include "math_registry.nas"
