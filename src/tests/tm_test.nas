; tm_test.nas - table-driven Turing machine in NaN16.
;
; One fixed step() reads a transition table from guest memory, reads/writes a
; tape in guest memory, and updates state/head/halt words.  The same step code
; runs three machines:
;   A: binary increment 1011 -> 1100
;   B: unary increment  111  -> 1111
;   C: carry           111  -> 1000 (left of the starting cell)
;
; The tape base is word 4096; logical position 0 starts at base+8 so a left
; move has room below position 0.  This test is intentionally self-contained:
; it is assembled by nmk.awk and can run natively or under n16i.
main:
MOVI r13,1
CALL @tm_a
CALL @tm_b
CALL @tm_c
MOVI r1,@s_all
CALL @puts
CALL @newline
HALT

; ---------------------------------------------------------------------------
; A: binary increment, tape "1011", head at the last 1.
tm_a:
ST r15,r0,@link
CALL @reset
MOVI r3,4096
MOVI r1,1
ST r1,r3,8
MOVI r1,0
ST r1,r3,9
MOVI r1,1
ST r1,r3,10
MOVI r1,1
ST r1,r3,11
MOVI r1,11
ST r1,r0,@head
MOVI r1,@table_a
ST r1,r0,@table
MOVI r1,3
ST r1,r0,@tcount
CALL @run
; expect base+8..11 = 1100
LD r1,r0,4104
CMP r1,r13
JMP[NE] @fail
LD r1,r0,4105
CMP r1,r13
JMP[NE] @fail
LD r1,r0,4106
CMP r1,r0
JMP[NE] @fail
LD r1,r0,4107
CMP r1,r0
JMP[NE] @fail
MOVI r1,@s_a
CALL @puts
CALL @newline
LD r15,r0,@link
RET

; ---------------------------------------------------------------------------
; B: unary increment, tape "111", head at the first 1.
tm_b:
ST r15,r0,@link
CALL @reset
MOVI r3,4096
MOVI r1,1
ST r1,r3,8
ST r1,r3,9
ST r1,r3,10
MOVI r1,8
ST r1,r0,@head
MOVI r1,@table_b
ST r1,r0,@table
MOVI r1,2
ST r1,r0,@tcount
CALL @run
; expect base+8..11 = 1111
LD r1,r0,4104
CMP r1,r13
JMP[NE] @fail
LD r1,r0,4105
CMP r1,r13
JMP[NE] @fail
LD r1,r0,4106
CMP r1,r13
JMP[NE] @fail
LD r1,r0,4107
CMP r1,r13
JMP[NE] @fail
MOVI r1,@s_b
CALL @puts
CALL @newline
LD r15,r0,@link
RET

; ---------------------------------------------------------------------------
; C: carry, tape "111", head at the last 1, must write a new cell at -1.
tm_c:
ST r15,r0,@link
CALL @reset
MOVI r3,4096
MOVI r1,1
ST r1,r3,8
ST r1,r3,9
ST r1,r3,10
MOVI r1,10
ST r1,r0,@head
MOVI r1,@table_a
ST r1,r0,@table
MOVI r1,3
ST r1,r0,@tcount
CALL @run
; expect base+7 = 1, base+8..10 = 000
LD r1,r0,4103
CMP r1,r13
JMP[NE] @fail
LD r1,r0,4104
CMP r1,r0
JMP[NE] @fail
LD r1,r0,4105
CMP r1,r0
JMP[NE] @fail
LD r1,r0,4106
CMP r1,r0
JMP[NE] @fail
MOVI r1,@s_c
CALL @puts
CALL @newline
LD r15,r0,@link
RET

; ---------------------------------------------------------------------------
; Zero the tape window and control words.
reset:
MOVI r3,4096
MOVI r4,32
MOVI r2,2
rloop:
ST r2,r3,0
ADD r3,r3,r13
SUB r4,r4,r13
JMP[NE] @rloop
ST r0,r0,@halt
ST r0,r0,@state
RET

; Run until halted.
run:
ST r15,r0,@run_link
rrun:
LD r1,r0,@halt
CMP r1,r0
JMP[NE] @run_done
CALL @step
JMP @rrun
run_done:
LD r15,r0,@run_link
RET

; ---------------------------------------------------------------------------
; A fixed table-driven TM step.  Table entry (8 words):
;   from, read, write, move(0=left,1=stay,2=right), to, halt, pad, pad
step:
LD r1,r0,@halt
CMP r1,r0
JMP[NE] @step_ret
LD r1,r0,@state
LD r2,r0,@head
LD r5,r0,@table
LD r6,r0,@tcount
LD r3,r0,@tbase
ADD r3,r3,r2
LD r4,r3,0
MOVI r8,0
scan:
CMP r8,r6
JMP[GE] @no_transition
ADD r7,r8,r8
SHL r7,r7,2
ADD r7,r7,r5
LD r9,r7,0
CMP r9,r1
JMP[NE] @next_entry
LD r9,r7,1
CMP r9,r4
JMP[NE] @next_entry
; matched
LD r9,r7,2
ST r9,r3,0
LD r9,r7,3
MOVI r10,0
CMP r9,r10
JMP[EQ] @move_left
MOVI r10,2
CMP r9,r10
JMP[EQ] @move_right
JMP @move_done
move_left:
SUB r2,r2,r13
JMP @move_done
move_right:
ADD r2,r2,r13
move_done:
ST r2,r0,@head
LD r9,r7,4
ST r9,r0,@state
LD r9,r7,5
CMP r9,r0
JMP[EQ] @step_ret
MOVI r9,1
ST r9,r0,@halt
step_ret:
RET
next_entry:
ADD r8,r8,r13
JMP @scan
no_transition:
MOVI r9,1
ST r9,r0,@halt
RET

; ---------------------------------------------------------------------------
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

newline:
MOVI r1,10
PUTC r1
RET

fail:
MOVI r1,@s_fail
CALL @puts
CALL @newline
HALT

; ---------------------------------------------------------------------------
; data
tbase:
.word 4096
state:
.word 0
head:
.word 0
halt:
.word 0
table:
.word 0
tcount:
.word 0
link:
.word 0
run_link:
.word 0

table_a:
.word 0,1,0,0,0,0,0,0
.word 0,0,1,1,0,1,0,0
.word 0,2,1,1,0,1,0,0

table_b:
.word 0,1,1,2,0,0,0,0
.word 0,2,1,1,0,1,0,0

s_a:
.str "TM BINARY 1100 PASS"
.word 0
s_b:
.str "TM UNARY 1111 PASS"
.word 0
s_c:
.str "TM CARRY 1000 PASS"
.word 0
s_all:
.str "TM ALL PASS"
.word 0
s_fail:
.str "TM FAIL"
.word 0
