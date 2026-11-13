; tm_n16i_test.nas - run tm_test.nas under the NaN16-in-NaN16 interpreter.
; The outer driver is native; the inner TM guest starts at word 8192 and uses
; the window wrap exactly like the n16i differential test.
JMP @drv
.include "../tools/n16i.nas"
drv:
MOVI r13,1
MOVI r1,@main
MOVI r2,8192
MOVI r3,8191
CALL @n16i_run
ST r1,r0,@steps
HALT
steps:
.word 0
.org 8192
.include "tm_test.nas"
