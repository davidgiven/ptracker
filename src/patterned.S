#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

ZEROPAGE

patternno:      .fill 1
looping_flag:   .fill 1
disptr:         .fill 2
rowptr:         .fill 2
disrow:         .fill 1
rowno:          .fill 1

zproc pattern_editor
    ldx #0
    txs
    jsr setup_screen_for_pattern_editor
    
    zloop
    zendloop
zendproc

zproc setup_screen_for_pattern_editor
    ldx #40*4
    zrepeat
        lda data+0*40*4-1, x
        sta VRAM+0*40*4-1, x
        lda data+1*40*4-1, x
        sta VRAM+1*40*4-1, x
        dex
    zuntil eq

    jsr draw_screen
    rts

data:
BYTE 0x20,0x20,0x46,0x09,0x0C,0x05,0x20,0xA0,0xD0,0x81,0x94,0x94,0x85,0x92,0x8E,0xA0,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20
BYTE 0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63,0x63
BYTE 0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20
BYTE 0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x6E,0x20,0x20,0x70,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40,0x40
BYTE 0x43,0x15,0x12,0x12,0x05,0x0E,0x14,0x20,0x14,0x05,0x0D,0x10,0x0F,0x3A,0x20,0x20,0x30,0x30,0x5D,0x30,0x30,0x5D,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20
BYTE 0x50,0x01,0x14,0x14,0x05,0x12,0x0E,0x20,0x0C,0x05,0x0E,0x07,0x14,0x08,0x3A,0x20,0x30,0x30,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20
BYTE 0x20,0x20,0x20,0x20,0x20,0x20,0x70,0x40,0x40,0x40,0x6E,0x20,0x20,0x70,0x40,0x40,0x40,0x6E,0x20,0x20,0x70,0x40,0x40,0x40,0x6E,0x20,0x20,0x70,0x40,0x40,0x40,0x40,0x6E,0x20,0x20,0x20,0x20,0x20,0x20,0x20
BYTE 0x40,0x40,0x40,0x40,0x40,0x40,0x7D,0x43,0x48,0x31,0x6D,0x40,0x40,0x7D,0x43,0x48,0x32,0x6D,0x40,0x40,0x7D,0x43,0x48,0x33,0x6D,0x40,0x40,0x7D,0x44,0x52,0x55,0x4D,0x6D,0x40,0x40,0x40,0x40,0x40,0x40,0x40
zendproc

LINE_PADDING = 0
MIDDLE_ROW = 16
PATTERN_NUMBER_ADDRESS = VRAM + 4*40 + 19
TEMPO_ADDRESS = VRAM + 4*40 + 16
PATTERNLENGTH_ADDRESS = VRAM + 5*40 + 16
MUTE_ADDRESS = VRAM + 7*40 + 7
MIDDLE_ROW_ADDRESS = VRAM + (MIDDLE_ROW)*40

zproc draw_screen
    lda #lo(PATTERN_NUMBER_ADDRESS)
    sta scrptr+0
    lda #hi(PATTERN_NUMBER_ADDRESS)
    sta scrptr+1
    lda patternno
    jsr print_h8

    lda #lo(TEMPO_ADDRESS)
    sta scrptr+0
    lda #hi(TEMPO_ADDRESS)
    sta scrptr+1
    lda tempo
    jsr print_h8

    lda #lo(PATTERNLENGTH_ADDRESS)
    sta scrptr+0
    lda #hi(PATTERNLENGTH_ADDRESS)
    sta scrptr+1
    lda patternlength
    jsr print_h8

    ; TODO: looping flag

    ; TODO: mute flags

    ; Draw lines below the middle.

    lda #<MIDDLE_ROW_ADDRESS
    sta scrptr+0
    lda #>MIDDLE_ROW_ADDRESS
    sta scrptr+1
    lda rowptr+0
    sta disptr+0
    lda rowptr+1
    sta disptr+1

    lda rowno
    sta disrow

    lda #9
    zrepeat
        pha
        jsr draw_row
        lda #LINE_PADDING
        jsr advance_scrptr
        inc disrow

        pla
        sec
        sbc #1
    zuntil eq

    ; Draw lines above the middle.

    lda #<(MIDDLE_ROW_ADDRESS-40)
    sta scrptr+0
    lda #>(MIDDLE_ROW_ADDRESS-40)
    sta scrptr+1
    sec
    lda rowptr+0
    sbc #ROW_LENGTH
    sta disptr+0
    lda rowptr+1
    sbc #0
    sta disptr+1

    lda rowno
    sta disrow
    dec disrow

    lda #8
    zrepeat
        pha

        jsr draw_row
        lda #80-LINE_PADDING
        jsr retard_scrptr
        dec disrow

        ; disptr has been advanced to the next row, so to get the previous row,
        ; we need to go back two..

        lda disptr+0
        sec
        sbc #ROW_LENGTH*2
        sta disptr+0

        pla
        sec
        sbc #1
    zuntil eq


    rts
zendproc

zproc draw_row
    lda disrow
    cmp #NUM_STEPS
    zif lt
        lda #' '
        jsr print_char

        lda #' '
        jsr print_char
        lda disrow
        jsr print_h8
        lda #' '
        jsr print_char
        jsr print_char
        jsr draw_note
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_drum
        jsr print_space
        lda #' '
        jsr print_char
        rts
    zendif

    ldy #39
    lda #32
    zrepeat
        sta (scrptr), y
        dey
    zuntil mi

    lda #40-LINE_PADDING
    jmp advance_scrptr
zendproc

; Draws the note at disptr to scrptr. Advances both.

zproc draw_note
   ; Note

    ldy #0
    lda (disptr), y
    cmp #FIRST_COMMAND
    zif lt
        jsr draw_raw_note
    next:
        lda #' '
        jsr print_char

        ; Tone/volume/control

        ldy #1
        lda (disptr), y
        jsr print_h8

    done:
        lda #' '
        jsr print_char
        inc disptr+0
        inc disptr+0
        rts
    zendif

is_a_command:
    pha
    lda #' '
    jsr print_char
    jsr print_char
    pla
    sec
    sbc #FIRST_COMMAND - 'A'
    jsr print_char
    jmp next

    rts
zendproc

zproc draw_drum
    ldy #0
    lda (disptr), y
    cmp #FIRST_COMMAND
    bge is_a_command
    jsr draw_raw_drum
    jmp next
zendproc

zproc draw_raw_note
    tax
    lda note_decode_table, x
    zif mi
        lda #'?'
        jsr print_char
        txa
        jmp print_h8
    zendif
    pha
    and #0x0f
    asl a
    tay
    pha
    lda note_to_name_table, y
    jsr print_char
    pla
    tay
    iny
    lda note_to_name_table, y
    jsr print_char
    pla
    lsr a
    lsr a
    lsr a
    lsr a
    jmp print_h4

note_to_name_table:
    .ascii "C-"
    .ascii "C#"
    .ascii "D-"
    .ascii "D#"
    .ascii "E-"
    .ascii "F-"
    .ascii "F#"
    .ascii "G-"
    .ascii "G#"
    .ascii "A-"
    .ascii "A#"
    .ascii "B-"
zendproc

; Draws the raw drum thingy in A to scrptr. Advances it. Does not draw the tone/volume byte.

zproc draw_raw_drum
    asl a
    clc
    adc (disptr), y
    tax
    lda drum_to_name_table, x
    jsr print_char
    inx
    lda drum_to_name_table, x
    jsr print_char
    inx
    lda drum_to_name_table, x
    jmp print_char

drum_to_name_table:
    .ascii "Bwo"
    .ascii "Bwe"
    .ascii "Kck"
    .ascii "Snr"
    .ascii "HiH"
    .ascii "N1 "
    .ascii "N2 "
    .ascii "N3 "
    .ascii "N4 "
zendproc

; For every note, this table contains a BCD-encoded representation of octave
; (top nibble) and note (bottom nibble), where the nibble 0 is a C. If the
; note is not representable (i.e. not a whole note), the result is &ff.

zproc note_decode_table
    i = 0
    .rept NUM_PITCHES
        semis = i - 24
        .byte ((semis/12)<<4) | (semis % 12)
        i = i + 1
    .endr
zendproc