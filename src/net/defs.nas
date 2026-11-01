; defs.nas - NaNnet shared constants. Spec sheet: network_plan.txt (verbatim copy
; in TODO.md, r29 block). Mapping decisions live in spec/NET_STACK_PLAN.md.
;
; Unified codec return word (every codec in this tree emits it):
;   r_ret = (err << 16) | value    err = 16-bit two's complement error code
;   value  = bytes produced (err == 0) or bytes REQUIRED (err == ENOSPC,
;            saturated to 0xFFFF) or 0 for any other error.
; Codec ABI: r1 in byte addr, r2 inlen, r3 out byte addr, r4 out cap,
; codec-specific cfg in r5/r6. Codecs may clobber r1..r8 only; r9..r12
; are reserved to the vector runner and longer-lived callers. r13 = 1
; is set by the caller (tree convention), r15 = link, saved via @ret slots.
;
; Spec section 5 error table, as 16-bit halves:
.equ NET_ERR_OK      0
.equ NET_EAGAIN      0xFFFF     ; -1  EAGAIN
.equ NET_EIO         0xFFFE     ; -2  EIO
.equ NET_EINVAL      0xFFFD     ; -3  EINVAL
.equ NET_ENOTSUP     0xFFFC     ; -4  ENOTSUP
.equ NET_ETIMEDOUT   0xFFFB     ; -5  ETIMEDOUT
.equ NET_ECLOSED     0xFFFA     ; -6  ECLOSED
.equ NET_EFAULT      0xFFF9     ; -7  EFAULT
.equ NET_ENOSPC      0xFFF8     ; -8  ENOSPC
.equ NET_EPERM       0xFFF7     ; -9  EPERM
.equ NET_EPROTO      0xFFF6     ; -10 EPROTO
.equ NET_EBADENDIAN  0xFFF5     ; -11 EBADENDIAN
.equ NET_EBADTAG     0xFFF4     ; -12 EBADTAG
.equ NET_EOVERFLOW   0xFFF3     ; -13 EOVERFLOW
.equ NET_EEMPTY      0xFFF2     ; -14 EEMPTY
.equ NET_ECRC        0xFFF1     ; -15 ECRC
