
.macro ZEROPAGE
    .section .zp, "zax", @nobits
.endm

#define lo(n) ((n) & 0xff)
#define hi(n) ((n)>>8 & 0xff)

.macro inc16 var:vararg
    inc 0+\var
    zif eq
        inc 1+\var
    zendif
.endm

.macro dec16 var:vararg
    lda 0+\var
    zif eq
        dec 1+\var
    zendif
    dec 0+\var
.endm

.macro cpy16 src, dst
    lda #<\src
    sta \dst+0
    lda #>\src
    sta \dst+1
.endm

; Given a keytable specified by name, looks through it and jumps to the
; appropriate routine, or falls out the bottom.

.macro key_lookup key_table
    ldy #0
    zrepeat
        cmp \key_table, y
        zif eq
            lda \key_table+2, y
            pha
            lda \key_table+1, y
            pha
            rts
        zendif
        iny
        iny
        iny
        ldx \key_table, y
    zuntil eq
.endm

.macro key n, label
    .byte \n
    .word \label-1
.endm

#define BYTE .byte

; One pattern is 256 bytes.
SEQUENCE_LENGTH = 128
NUM_STEPS = 32
NOTE_LENGTH = 2 ; pitch, volume/tone; or: command, param
MAX_PATTERNS = 70
NUM_VOICES = 4
TONE_SAMPLES = 64

; Notes

#include "samplerate.py"
NUM_PITCHES = 36*OCTAVES
FIRST_COMMAND = 256-26

ROW_LENGTH = NOTE_LENGTH * NUM_VOICES


.extern midinote_table

.zeropage w, q, p

.extern sequence
.extern tempo
.extern patternlength
.extern numpatterns
.extern sequencelength

.extern pcm_table

.zeropage e1b, e2b, e3b
.zeropage e1v, e2v, e3v
.zeropage e1c, e2c, e3c
.zeropage e1t, e2t, e3t
.zeropage e1d, e2d, e3d
.zeropage t4ptr, t4len

.zeropage rowno, rowptr, patternno

C_0  = 0*36+0
CS_0 = 0*36+3
D_0  = 0*36+6
DS_0 = 0*36+9
E_0  = 0*36+12
F_0  = 0*36+15
FS_0 = 0*36+18
G_0  = 0*36+21
GS_0 = 0*36+24
A_0  = 0*36+27
AS_0 = 0*36+30
B_0  = 0*36+33

C_1  = 1*36+0
CS_1 = 1*36+3
D_1  = 1*36+6
DS_1 = 1*36+9
E_1  = 1*36+12
F_1  = 1*36+15
FS_1 = 1*36+18
G_1  = 1*36+21
GS_1 = 1*36+24
A_1  = 1*36+27
AS_1 = 1*36+30
B_1  = 1*36+33

C_2  = 2*36+0
CS_2 = 2*36+3
D_2  = 2*36+6
DS_2 = 2*36+9
E_2  = 2*36+12
F_2  = 2*36+15
FS_2 = 2*36+18
G_2  = 2*36+21
GS_2 = 2*36+24
A_2  = 2*36+27
AS_2 = 2*36+30
B_2  = 2*36+33

C_3  = 3*36+0
CS_3 = 3*36+3
D_3  = 3*36+6
DS_3 = 3*36+9
E_3  = 3*36+12
F_3  = 3*36+15
FS_3 = 3*36+18
G_3  = 3*36+21
GS_3 = 3*36+24
A_3  = 3*36+27
AS_3 = 3*36+30
B_3  = 3*36+33
