
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

NUM_PITCHES = 201
FIRST_COMMAND = 256-26

ROW_LENGTH = NOTE_LENGTH * NUM_VOICES


.extern midinote_table

.zeropage w
.zeropage scrptr

.extern sequence
.extern tempo
.extern patternlength
.extern numpatterns
.extern sequencelength

.extern pcm_table
