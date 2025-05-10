#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

disptr:         .fill 2 ; pointer to row being displayed
disrow:         .fill 1 ; row number being displayed
cursorx:        .fill 1 ; position of cursor (0-15)

LINE_PADDING = 4
LINE_OFFSET = 3
MIDDLE_ROW = 16
SEQUENCE_ADDRESS = VRAM + 2*40
PATTERN_NUMBER_ADDRESS = VRAM + 4*40 + 19
TEMPO_ADDRESS = VRAM + 4*40 + 16
PATTERNLENGTH_ADDRESS = VRAM + 5*40 + 16
PATTERNCOUNT_ADDRESS = VRAM + 4*40 + 38
MUTE_ADDRESS = VRAM + 7*40 + 7
REPEAT_ADDRESS = VRAM + 7*40
MIDDLE_ROW_ADDRESS = VRAM + (MIDDLE_ROW)*40

zproc pattern_editor
    ldx #0xff
    txs
    jsr setup_screen_for_pattern_editor
    
    zloop
        jsr reset_row_pointer
        jsr draw_screen
        jsr do_keypress
    zendloop
zendproc
        
zlproc do_keypress
    ; Place the cursor.

    ldy cursorx
    ldx editor_cursor_table, y
    ldy #>MIDDLE_ROW_ADDRESS
    jsr move_cursor

    jsr silence_engine
    jsr play_current_row
    jsr cursor_on
    zrepeat
        jsr just_play_without_processing
        jsr getch
    zuntil ne
    pha
    jsr cursor_off
    pla

    key_lookup key_table
    
    cmp #'A'
    zif ge
        cmp #'Z'+1
        zif lt
            bit ctrl_flag
            bpl letter_key

            key_lookup ctrl_key_table
            rts
        zendif
    zendif

    cmp #'0'
    zif ge
        cmp #'9'+1
        blt number_key
    zendif

    cmp #'A'|0x80
    zif ge
        cmp #('Z'+1)|0x80
        blt command_key
    zendif
    rts

key_table:
    key 0x03, key_esc
    key 0x11, key_down
    key 0x91, key_up
    key 0x1d, key_right
    key 0x9d, key_left
    key 0x14, key_delete
    key 0x09, tone_editor ; tab
    key 0x13, tone_editor ; clr/home
    key 0x2d, key_decrement
    key 0x2b, key_increment
    key 0xbb, key_increment ; SHIFT+; on the business keyboard
    key 0x20, key_space
    .byte 0

ctrl_key_table:
    key 'S', key_ctrl_s     ; save to sequence
    key 'A', key_ctrl_a     ; insert after into sequence
    key 'W', key_ctrl_w     ; insert before into sequence
    key 'D', key_ctrl_d     ; delete from sequence
    key 'N', key_ctrl_n     ; create new pattern
    key 'T', key_ctrl_t     ; change tempo
    key 'L', key_ctrl_l     ; change pattern length
    key 'C', key_ctrl_c     ; clone this pattern
    key 'I', key_ctrl_i     ; tab to next voice
    key 'R', key_ctrl_r     ; toggle looping flag
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

zproc command_key
    and #0x7f
    jmp set_command
zendproc

zproc key_delete
    lda #'B'
    jmp set_command
zendproc

zproc key_esc
    lda #0
    sta e1v
    sta e2v
    sta e3v
    rts
zendproc

zproc key_up
    bit ctrl_flag
    zif mi
        ldx patternno
        dex
        zif mi
            ldx numpatterns
            dex
        zendif
        stx patternno
        rts
    zendif

    ldx rowno
    dex
    zif mi
        ldx patternlength
        dex
    zendif
    stx rowno
    rts
zendproc

zproc key_down
    bit ctrl_flag
    zif mi
        ldx patternno
        inx
        cpx numpatterns
        zif eq
            ldx #0
        zendif
        stx patternno
        rts
    zendif

    ldx rowno
    inx
    cpx patternlength
    zif eq
        ldx #0
    zendif
    stx rowno
    rts
zendproc

zproc key_left
    bit ctrl_flag
    zif mi
        ldx seqindex
        dex
        zif mi
            ldx #128            ; find the last allocated sequence slot
            zrepeat
                dex
                lda sequence, x
            zuntil pl
        zendif

        lda sequence, x
        sta patternno
        stx seqindex
        rts
    zendif

    lda cursorx
    sec
    sbc #1
    and #15
    sta cursorx
    rts
zendproc

zproc key_right
    bit ctrl_flag
    zif mi
        ldx seqindex
        inx
        lda sequence, x
        zif mi
            ldx #0
            lda sequence
        zendif
        sta patternno
        stx seqindex
        rts
    zendif

    lda cursorx
    clc
    adc #1
    and #15
    sta cursorx
    rts
zendproc

zproc key_ctrl_i
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
    jsr play_entire_song
    jmp setup_screen_for_pattern_editor
zendproc

; Save current pattern to sequence.

zlproc key_ctrl_s
    ldx seqindex
    lda patternno
    sta sequence, x
    rts
zendproc
   
; Insert before into sequence.

zlproc key_ctrl_a
    ldx #127
    lda sequence, x
    zif mi
        zrepeat
            lda sequence-1, x
            sta sequence, x
            dex
            cpx seqindex
        zuntil eq

        ldx seqindex
        lda patternno
        sta sequence, x
    zendif
    rts
zendproc

; Insert after into sequence.

zlproc key_ctrl_w
    ldx #127
    lda sequence, x
    zif mi
        zrepeat
            lda sequence-1, x
            sta sequence, x
            dex
            cpx seqindex
        zuntil eq

        ldx seqindex
        inx
        stx seqindex
        lda patternno
        sta sequence, x
    zendif
    rts
zendproc

; Delete from sequence

zlproc key_ctrl_d
    ldx seqindex
    zif eq
        lda sequence+1, x
        zif mi
            ; There's only one item in the sequence. Don't delete it.
            rts
        zendif
    zendif

    cpx #127
    zif ne
        zrepeat
            lda sequence+1, x
            sta sequence, x
            inx
            cpx #127
        zuntil eq
    zendif

    lda #0xff
    sta sequence+127

    ldx seqindex
    lda sequence, x
    zif mi
        ; The current item no longer exists; we must have deleted the last item.
        dex
        stx seqindex
    zendif

    lda sequence, x
    sta patternno
    rts
zendproc

; Allocate new pattern.

zlproc key_ctrl_n
    ldx numpatterns
    cpx #MAX_PATTERNS
    zif ne
        stx patternno
        inc numpatterns
    zendif
    rts
zendproc

; Clone this pattern into a new one.

zlproc key_ctrl_c
    lda patternno
    pha
    jsr key_ctrl_n

    pla
    clc
    adc #>PATTERN_DATA
    sta p+1

    lda patternno
    clc
    adc #>PATTERN_DATA
    sta w+1

    ldy #0
    sty p+0
    sty w+0
    zrepeat
        lda (p), y
        sta (w), y
        dey
    zuntil eq
    rts
zendproc

; Change the tempo.

zlproc key_ctrl_t
    lda #20 - (2f-1f)/2
    ldx #<1f
    ldy #>1f
    jsr text_prompt
    tya
    zif ne
        jsr parse_hex
        bcs 3f

        sta tempo
    zendif
    jmp setup_screen_for_pattern_editor

3:
    jsr invalid_value_error
    jmp setup_screen_for_pattern_editor
1:
    ; "Enter new tempo:"
    .byte 0x45, 0x0e, 0x14, 0x05, 0x12, 0x20, 0x0e, 0x05
    .byte 0x17, 0x20, 0x14, 0x05, 0x0d, 0x10, 0x0f, 0x3a
2:
    .byte 0
zendproc

; Change the pattern length.

zlproc key_ctrl_l
    lda #20 - (2f-1f)/2
    ldx #<1f
    ldy #>1f
    jsr text_prompt
    tya
    zif ne
        jsr parse_hex
        bcs 3f

        cmp #0x20
        bge 3f

        sta patternlength
    zendif
    jmp setup_screen_for_pattern_editor

3:
    jsr invalid_value_error
    jmp setup_screen_for_pattern_editor
1:
    ; "Enter new pattern length (01-20):"
    .byte 0x45, 0x0e, 0x14, 0x05, 0x12, 0x20, 0x0e, 0x05
    .byte 0x17, 0x20, 16, 1, 20, 20, 5, 18, 14, 32
    .byte 12, 5, 14, 7, 20, 8, 32
    .byte 40, 48, 49, 45, 50, 48, 41
2:
    .byte 0
zendproc

; Toggle the looping flag.

zlproc key_ctrl_r
    ldx #0
    bit looping_flag
    zif pl
        dex
    zendif
    stx looping_flag
    rts
zendproc

zproc setup_screen_for_pattern_editor
    lda #<data
    sta w+0
    lda #>data
    sta w+1
    lda #<VRAM
    sta p+0
    lda #>VRAM
    sta p+1
    jmp decompress

data:
#include "patterned_compressed.inc"
zendproc

zproc editor_cursor_table
    i = 0
    .rept 4
        .byte lo(MIDDLE_ROW_ADDRESS) + LINE_OFFSET + 5 + 8*i + 0
        .byte lo(MIDDLE_ROW_ADDRESS) + LINE_OFFSET + 5 + 8*i + 2
        .byte lo(MIDDLE_ROW_ADDRESS) + LINE_OFFSET + 5 + 8*i + 4
        .byte lo(MIDDLE_ROW_ADDRESS) + LINE_OFFSET + 5 + 8*i + 5
        i = i + 1
    .endr
zendproc

zproc draw_screen
    ; Some basic indicators.

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

    lda #lo(PATTERNCOUNT_ADDRESS)
    sta scrptr+0
    lda #hi(PATTERNCOUNT_ADDRESS)
    sta scrptr+1
    lda numpatterns
    jsr print_h8

    ; The sequence.

    ldy #39
    lda #' '
    zrepeat
        sta SEQUENCE_ADDRESS, y
        dey
    zuntil mi

    lda #lo(SEQUENCE_ADDRESS+1)
    sta scrptr+0
    lda #hi(SEQUENCE_ADDRESS+1)
    sta scrptr+1

    ldx #0          ; count
    lda seqindex
    sec
    sbc #6
    tay             ; sequence index
    zrepeat
        tya         ; set flags from Y
        zif mi
        1:
            lda #3
            jsr advance_scrptr
        zelse
            lda sequence, y
            bmi 1b
            stx p
            sty q
            jsr print_h8
            lda #' '
            jsr print_char
            ldx p
            ldy q
        zendif
        iny
        inx
        cpx #13
    zuntil eq

    ; Looping flag.

    ldx #(2f-1f)-1
    zrepeat
        lda #0x40
        bit looping_flag
        zif mi
            lda 1f, x
        zendif
        sta REPEAT_ADDRESS, x
        dex
    zuntil mi

    ; Draw the arrows.

    lda #62 ; >
    sta MIDDLE_ROW_ADDRESS
    lda #60 ; <
    sta MIDDLE_ROW_ADDRESS + 39

    ; Draw lines below the middle.

    lda #<(MIDDLE_ROW_ADDRESS+LINE_OFFSET)
    sta scrptr+0
    lda #>(MIDDLE_ROW_ADDRESS+LINE_OFFSET)
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

    lda #<(MIDDLE_ROW_ADDRESS-40+LINE_OFFSET)
    sta scrptr+0
    lda #>(MIDDLE_ROW_ADDRESS-40+LINE_OFFSET)
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

1:
    ; "REPEAT"
    .byte 210, 197, 208, 197, 193, 212
2:
zendproc

zproc draw_row
    lda disrow
    cmp patternlength
    zif lt
        lda disrow
        jsr print_h8
        lda #3
        jsr advance_scrptr
        jsr draw_note
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_note
        jsr print_space
        jsr draw_drum
        rts
    zendif

    ; Not a displayable row --- blank it.

    ldy #(39-LINE_OFFSET-LINE_PADDING+2)
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
    cmp #FIRST_COMMAND + ('O' - 'A')
    zif eq
        lda #'='
        jmp banner
    zendif

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
    jsr print_space
    jmp done
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
    asl a
    clc
    adc (disptr), y
    tax
    ldy #5
    sty p
    zrepeat
        lda drum_to_name_table, x
        jsr print_char
        inx
        dec p
    zuntil eq
    rts

drum_to_name_table:
    .byte 66, 23, 5, 5, 16   ; Bweep
    .byte 66, 23, 15, 15, 16 ; Bwoop
    .byte 75, 9, 3, 11, 32   ; Kick
    .byte 83, 14, 1, 18, 5   ; Snare
    .byte 72, 9, 8, 1, 20    ; Hihat
    .byte 78, 15, 9, 19, 49  ; Nois1
    .byte 78, 15, 9, 19, 50  ; Nois1
    .byte 78, 15, 9, 19, 51  ; Nois1
    .byte 78, 15, 9, 19, 52  ; Nois1
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

; Sets a command to A ('A'..'Z').

zproc set_command
    sec
    sbc #'@'
    clc
    adc #FIRST_COMMAND-1
    tax
    lda cursorx
    lsr a
    and #0x0e
    tay
    txa
    sta (rowptr), y
    rts
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
    cpx #0x10
    zif lt
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
    zendif
    rts

volume:
    cpx #0x10
    zif lt
        iny
        lda (rowptr), y
        and #0xf0
        sta w

        txa
        ora w
        sta (rowptr), y
    zendif
    rts

drum:
    txa
    cmp #NUM_DRUMS
    zif lt
        sta (rowptr), y
    zendif
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
    clc
    adc (rowptr), y
    zif mi
        lda #NUM_DRUMS-1
    zendif
    cmp #NUM_DRUMS
    zif eq
        lda #0
    zendif
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
