#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

disptr:         .fill 2 ; pointer to row being displayed
disrow:         .fill 1 ; row number being displayed
cursorx:        .fill 1 ; position of cursor (0-15)
looping_flag:   .fill 1

LINE_PADDING = 4
MIDDLE_ROW = 16
PATTERN_NUMBER_ADDRESS = VRAM + 4*40 + 19
TEMPO_ADDRESS = VRAM + 4*40 + 16
PATTERNLENGTH_ADDRESS = VRAM + 5*40 + 16
MUTE_ADDRESS = VRAM + 7*40 + 7
MIDDLE_ROW_ADDRESS = VRAM + (MIDDLE_ROW)*40

zproc pattern_editor
    ldx #0
    txs
    jsr setup_screen_for_pattern_editor
    
    zloop
        jsr reset_row_pointer
        jsr draw_screen
        jsr do_patterneditor_keypress
    zendloop
zendproc
        
zproc do_patterneditor_keypress
    ; Place the cursor.

    ldy cursorx
    ldx editor_cursor_table, y
    ldy #>MIDDLE_ROW_ADDRESS
    jsr move_cursor

    jsr play_current_row
    jsr cursor_on
    zrepeat
        jsr start_engine
        zrepeat
            jsr engine_tick
            zif cs
                jsr draw_screen
            zendif
            jsr is_key_pressed
        zuntil eq
        jsr keyboard_interrupt
        zrepeat
            jsr engine_tick
            zif cs
                jsr draw_screen
            zendif
            jsr is_key_pressed
        zuntil ne
        jsr keyboard_interrupt
        jsr stop_engine
        jsr GETIN
    zuntil ne
    pha
    jsr cursor_off
    pla

    pha
    ldx #<VRAM
    stx scrptr+0
    ldx #>VRAM
    stx scrptr+1
    jsr print_h8
    pla

    key_lookup key_table
    
    cmp #'A'
    zif ge
        cmp #'Z'+1
        blt letter_key
    zendif

    cmp #'0'
    zif ge
        cmp #'9'+1
        blt number_key
    zendif
    rts

key_table:
    key 0x03, key_esc
    key 0x11, key_down
    key 0x91, key_up
    key 0x1d, key_right
    key 0x9d, key_left
    key 0x12, key_tab
    key 0x2d, key_decrement
    key 0x2b, key_increment
    key 0x20, key_space
    .byte 0
zendproc

zproc number_key
    ora #0x10
    sec
    sbc #'0'
    jmp set_value
zendproc

zproc letter_key
    sec
    sbc #'A'-10
    jmp set_value
zendproc

zproc key_esc
    sei
    lda #0
    sta e1v
    sta e2v
    sta e3v
    cli
    rts
zendproc

zproc key_up
    lda rowno
    sec
    sbc #1
    and #NUM_STEPS-1
    sta rowno
    rts
zendproc

zproc key_down
    lda rowno
    clc
    adc #1
    and #NUM_STEPS-1
    sta rowno
    rts
zendproc

zproc key_left
    lda cursorx
    zif ne
        dec cursorx
    zendif
    rts
zendproc

zproc key_right
    lda cursorx
    cmp #15
    zif ne
        inc cursorx
    zendif
    rts
zendproc

zproc key_tab
    lda cursorx
    clc
    adc #4
    and #15
    sta cursorx
    rts
zendproc

zproc key_increment
    lda #1
    jmp adjust_value
zendproc

zproc key_decrement
    lda #<-1
    jmp adjust_value
zendproc

zproc key_space
    lda playing_flag
    eor #0xff
    sta playing_flag
    rts
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

zproc editor_cursor_table
    i = 0
    .rept 4
        .byte lo(MIDDLE_ROW_ADDRESS) + 6 + 8*i + 0
        .byte lo(MIDDLE_ROW_ADDRESS) + 6 + 8*i + 2
        .byte lo(MIDDLE_ROW_ADDRESS) + 6 + 8*i + 4
        .byte lo(MIDDLE_ROW_ADDRESS) + 6 + 8*i + 5
        i = i + 1
    .endr
zendproc

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

    ; Draw the arrows.

    lda #62 ; >
    sta MIDDLE_ROW_ADDRESS
    lda #60 ; <
    sta MIDDLE_ROW_ADDRESS + 39

    ; Draw lines below the middle.

    lda #<(MIDDLE_ROW_ADDRESS+2)
    sta scrptr+0
    lda #>(MIDDLE_ROW_ADDRESS+2)
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

    lda #<(MIDDLE_ROW_ADDRESS-40+2)
    sta scrptr+0
    lda #>(MIDDLE_ROW_ADDRESS-40+2)
    sta scrptr+1
    sec
    lda rowptr+0
    sbc #ROW_LENGTH
    sta disptr+0
    lda rowptr+1
    sbc #0
    sta disptr+1

    ldx rowno
    dex
    stx disrow

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
        lda disrow
        jsr print_h8
        jsr print_space
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_drum
        jsr print_space
        rts
    zendif

    ; Not a displayable row --- blank it.

    ldy #(39-LINE_PADDING)
    lda #' '
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
        jsr print_space

        ; Tone/volume/control

        ldy #1
        lda (disptr), y
        jsr print_h8

    done:
        jsr print_space
        inc disptr+0
        inc disptr+0
        rts
    zendif

is_a_command:
    cmp #FIRST_COMMAND + ('B' - 'A')
    zif eq
        lda #'.'
        jmp banner
    zendif

    pha
    jsr print_space
    jsr print_space
    pla
    sec
    sbc #FIRST_COMMAND - 'A'
    jsr print_char
    jmp next

banner:
    pha
    jsr print_space
    pla
    ldx #3
    zrepeat
        jsr print_char
        dex
    zuntil mi
    jsr print_space
    jmp done
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
        .if (i % 3)
            .byte 0xff
        .else
            semis = i / 3
            .byte ((semis/12)<<4) | (semis % 12)
        .endif
        i = i + 1
    .endr
zendproc

; Sets the value under the cursor to A.
; (0-9 means octave; 10+ means a letter, with A=10.)

zproc set_value
    tax
    lda cursorx
    lsr a
    and #0xfe
    tay

    lda (rowptr), y     ; if not a note,
    cmp #FIRST_COMMAND
    blt is_a_note
    lda cursorx
    and #0x03
    cmp #2
    beq tone
    cmp #3
    beq volume

    lda #C_1            ; convert this to a note
    sta (rowptr), y

is_a_note:
    lda cursorx
    cmp #12
    beq drum
    cmp #13
    beq drum
    and #0x03
    cmp #2
    beq tone
    cmp #3
    beq volume

    ; Changing pitch or octave, depending on key pressed.

    cpx #10
    bge pitch

    ; Changing octave.

    stx w

    lda (rowptr), y
    tax
    lda note_decode_table, x    ; decode to octave, pitch
    lsr a
    lsr a
    lsr a
    lsr a
    cmp w                       ; test current octave against desired
    zif lt
        ; Raising octave.

        tax
        lda (rowptr), y
        zrepeat
            clc
            adc #12*3
            cmp #NUM_PITCHES
            bge 1f
            inx
            cpx w
        zuntil eq
        sta (rowptr), y
    1:
        rts
    zendif

    ; Lowering octave.

    tax
    lda (rowptr), y
    zrepeat
        sec
        sbc #12*3
        bcc 1f
        dex
        cpx w
    zuntil eq
    sta (rowptr), y
1:
    rts

tone:
    iny
    lda (rowptr), y
    and #0x0f
    sta w

    txa
    asl a
    asl a
    asl a
    asl a
    ora w
    sta (rowptr), y
    rts

volume:
    iny
    lda (rowptr), y
    and #0xf0
    sta w

    txa
    ora w
    sta (rowptr), y
    rts

drum:
    txa
    and #7
    sta (rowptr), y
    rts

pitch:
    txa
    cmp #17 ; G + 1
    zif lt
        ; Changing pitch.

        sec
        sbc #10
        zif ge
            pha
            lda (rowptr), y
            tax
            lda note_decode_table, x    ; decode to octave, pitch
            lsr a
            lsr a
            lsr a
            lsr a                       ; extract octave number
            tax
            lda octave_to_note_table, x ; get pitch of C for this octave
            sta w
            pla

            tax
            lda name_to_note_table, x   ; get relative pitch of this note
            clc
            adc w                       ; adjust for octave
            sta (rowptr), y
        zendif
        rts
    zendif
zendproc

; Adjusts the value under the cursor by A.
; (Use 1 or -1.)

zproc adjust_value
    tax
    lda cursorx
    lsr a
    and #0xfe
    tay

    lda (rowptr), y     ; if not a note,
    cmp #FIRST_COMMAND
    blt is_a_note2
    lda cursorx
    and #0x03
    cmp #2
    beq tone2
    cmp #3
    beq volume2

    lda #C_1            ; convert this to a note
    sta (rowptr), y

is_a_note2:
    lda cursorx
    cmp #12
    beq drum2
    cmp #13
    beq drum2
    and #0x03
    cmp #2
    beq tone2
    cmp #3
    beq volume2
    cmp #1
    beq octave2

    ; Changing pitch.

    txa
    clc
    adc (rowptr), y
    cmp #NUM_PITCHES
    zif lt
        sta (rowptr), y
    zendif
    rts

octave2:
    lda #36
    cpx #1
    zif ne
        lda #<-36
    zendif

    clc
    adc (rowptr), y
    cmp #NUM_PITCHES
    zif lt
        sta (rowptr), y
    zendif
    rts

tone2:
    iny
    lda (rowptr), y
    and #0x0f
    sta w

    txa
    asl a
    asl a
    asl a
    asl a
    clc
    adc (rowptr), y
    and #0xf0
    ora w
    sta (rowptr), y
    rts

volume2:
    iny
    lda (rowptr), y
    and #0xf0
    sta w

    txa
    clc
    adc (rowptr), y
    and #0x0f
    ora w
    sta (rowptr), y
    rts

drum2:
    txa
    and #7
    sta (rowptr), y
    rts
zendproc

zproc name_to_note_table
   .byte  9*3 ; "A-"
              ; "A#"
   .byte 11*3 ; "B-"
   .byte  0*3 ; "C-"
              ; "C#"
   .byte  2*3 ; "D-"
              ; "D#"
   .byte  4*3 ; "E-"
   .byte  5*3 ; "F-"
              ; "F#"
   .byte  7*3 ; "G-"
              ; "G#"
zendproc

zproc octave_to_note_table
    .byte 0*12*3, 1*12*3, 2*12*3, 3*12*3, 4*12*3, 5*12*3
zendproc
