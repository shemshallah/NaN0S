; PARADOX ENGINE - a live sNaN/qNaN contradiction oscillator.
; This is a museum exhibit, not a power source. The word really flips between
; a signaling and a quiet NaN class at the loop rate. The "infinite power"
; claim is labelled as a joke on the plaque. ESC returns to the shell.
.equ SLOT 8192
.equ V_PUTS 1
.equ V_HEX 2
.equ V_DEC 3
.equ V_CLS 4
.equ V_KEY 5
.equ V_KEYQ 6
.equ V_TICK 7
.org 8192
cart_entry:
ST r15,r0,@p_ret
MOVI r13,1
CALL #V_CLS
MOVI r1,@p_title
MOVI r2,0
MOVI r3,0x1F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_state_l
MOVI r2,160
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_class_l
MOVI r2,240
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_pay_l
MOVI r2,280
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_tog_l
MOVI r2,320
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_rate_l
MOVI r2,400
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_le_l
MOVI r2,480
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_be_l
MOVI r2,520
MOVI r3,0x0F00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_loop_s
MOVI r2,560
MOVI r3,0x0B00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_plaque
MOVI r2,800
MOVI r3,0x0E00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r1,@p_foot
MOVI r2,1920
MOVI r3,0x0800
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
MOVI r14,0
MOVI r10,0
MOVI r1,0
ST r1,r0,@p_last
TICK r11
ST r11,r0,@p_t0
p_loop:
TICK r5
ST r5,r0,@p_now
ADD r1,r5,r0
MOVI r2,490
MOVI r3,0x0A00
CALL #V_HEX
MOVI r1,0xFFFF
MOVHI r1,0xFFFF
LD r4,r0,@p_now
SUB r1,r1,r4
MOVI r2,530
MOVI r3,0x0E00
CALL #V_HEX
MOVI r4,1
SUB r14,r4,r14
ADD r10,r10,r13
ADD r4,r14,r13
MOVI r5,1
MOVI r6,@p_word
STW r5,r6,r4
CMP r14,r0
JMP[EQ] @p_show_s
MOVI r1,@p_qnan
JMP @p_show
p_show_s:
MOVI r1,@p_snan
p_show:
MOVI r2,170
MOVI r3,0x0A00
MOVI r5,0
MOVI r6,0
CALL #V_PUTS
LDN r1,r0,@p_word
MOVI r2,250
MOVI r3,0x0F00
CALL #V_HEX
LD r1,r0,@p_word
MOVI r2,290
MOVI r3,0x0F00
CALL #V_HEX
ADD r1,r10,r0
MOVI r2,330
MOVI r3,0x0E00
CALL #V_HEX
MOVI r4,0
p_bar:
MOVI r5,46
MOVI r6,0x0800
CMP r14,r0
JMP[EQ] @p_bar_go
MOVI r5,35
MOVI r6,0x0E00
p_bar_go:
MOVI r7,640
ADD r7,r7,r4
BOOL.14 r6,r6,r5
VPOKE r6,r7
ADD r4,r4,r13
MOVI r7,60
CMP r4,r7
JMP[LT] @p_bar
TICK r11
LD r4,r0,@p_t0
SUB r5,r11,r4
MOVI r6,1000
CMP r5,r6
JMP[LT] @p_key
LD r4,r0,@p_last
SUB r5,r10,r4
ST r10,r0,@p_last
ST r11,r0,@p_t0
ADD r1,r5,r0
MOVI r2,420
MOVI r3,0x0A00
CALL #V_DEC
p_key:
KEYQ r1
MOVI r4,255
BOOL.8 r1,r1,r4
MOVI r4,27
CMP r1,r4
JMP[EQ] @p_exit
JMP @p_loop
p_exit:
MOVI r3,0
CALL #V_CLS
LD r15,r0,@p_ret
RET
p_ret:
.word 0
p_word:
.word 0
p_t0:
.word 0
p_last:
.word 0
p_now:
.word 0
p_title:
.str " NaN/0S  DOUBLE-ENDIAN CLOCK + PARADOX ENGINE"
p_state_l:
.str " STATE: "
p_class_l:
.str " CLASS: "
p_pay_l:
.str " PAYLOAD: "
p_tog_l:
.str " TOGGLES: "
p_rate_l:
.str " RATE (per second): "
p_le_l:
.str " LE TIME: "
p_be_l:
.str " BE TIME: "
p_loop_s:
.str " CAUSAL LOOP: 100 -> 50 -> 25 -> 12 -> 6 -> 3 -> 1 -> 0  (7 steps)"
p_snan:
.str "sNaN"
p_qnan:
.str "qNaN"
p_plaque:
.str " ENDIANNESS TIME DILATION: the same word has two faces.\n Read LE, time counts up. Read BE, time counts down.\n The causal loop is a toy fixed point, not a physics claim.\n The ALU mandate: a signaling NaN must quiet to a quiet NaN.\n The word flips between sNaN and qNaN at the loop rate.\n The frequency is real. It is not free energy and not infinite power.\n It is a logical contradiction that refuses to crash, forever.\n The plaque is honest: this is a representation, not a power source.\n\n ESC returns to the museum.\n"
p_foot:
.str "PARADOX ENGINE  ESC shell  the oscillator is a museum piece, not a generator"
