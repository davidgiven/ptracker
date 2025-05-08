#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

edittone:               .fill 1 ; the tone we're currently editing
editsampledata:         .fill 2 ; pointer to the current tone's sample data
editcursorx:            .fill 1 ; current cursor position in a graph
editcursory:            .fill 1 ; what thing is being edited
editnote:               .fill 1 ; the current test note
editingvolume_flag:          .fill 1 ; whether editing volume (rather than pitch)

GRAPH_X = 8
GRAPH_Y = 31

TONE_ADDRESS        = VRAM + 13 + 2*40
REPEATSTART_ADDRESS = TONE_ADDRESS + 40
REPEATEND_ADDRESS   = REPEATSTART_ADDRESS + 6
EDITMODE_ADDRESS    = REPEATSTART_ADDRESS + 40
NOTE_ADDRESS        = VRAM + 37 + 2*40
CURSORX_ADDRESS     = VRAM + 33 + 3*40

MODE_PITCH = 0
MODE_VOLUME = 1

EDIT_TONE = 0
EDIT_REPEATSTART = 1
EDIT_REPEATEND = 2
EDIT_MODE = 3
EDIT_DATA = 4
EDIT__LAST = 4

zproc tone_editor
    ldx #0
    txs
    jsr setup_screen_for_tone_editor

    lda #0
    sta e1v
    sta e1d
    sta e2v
    sta e3v
    sta t4ptr
    sta t4len

    zloop
        ; Set editsampledata to the correct value.

        ldx edittone
        lda tone_pitch_table_lo, x
        bit editingvolume_flag
        zif mi
            ora #0x40
        zendif
        sta editsampledata+0
        lda tone_table_hi, x
        sta editsampledata+1

        jsr redraw
        jsr do_keypress
    zendloop
zendproc
        
zlproc do_keypress
    jsr select_edited_item

    zrepeat
        lda editnote
        sta e1b
        lda edittone
        sta e1t
        lda #15
        sta e1v
        lda #0
        sta e1p

        jsr just_play_without_processing
        jsr getch
    zuntil ne
    pha
    jsr cursor_off
    pla

    key_lookup key_table
    
    cmp #'0'
    zif ge
        cmp #'0'+OCTAVES+1
        blt number_key
    zendif

    cmp #'A'
    zif ge
        cmp #'G'+1
        blt letter_key
    zendif
    rts
    
key_table:
    key 0x09, file_editor ; tab
    key 0x11, key_down
    key 0x91, key_up
    key 0x1d, key_right
    key 0x9d, key_left
    key 0x2d, key_decrement
    key 0x2b, key_increment
    .byte 0
zendproc

zlproc letter_key
    sec
    sbc #'A'
    zif ge
        cmp #8
        zif lt
            pha
            ldx editnote
            lda note_decode_table, x    ; decode to octave, pitch
            lsr a
            lsr a
            lsr a
            lsr a                       ; extract octave number
            tax
            lda octave_to_note_table, x ; get pitch of C for this octave
            sta p
            pla

            tax
            lda name_to_note_table, x   ; get relative pitch of this note
            clc
            adc p                       ; adjust for octave
            sta editnote
        zendif
    zendif
    rts
zendproc

zlproc number_key
    sec
    sbc #'0'
    zif ge
        cmp #OCTAVES+1
        zif lt
            sta p

            lda editnote
            tax
            lda note_decode_table, x    ; decode to octave, pitch
            lsr a
            lsr a
            lsr a
            lsr a
            tax
            cmp p                       ; test current octave against desired
            zif lt
                ; Raising octave

                lda editnote
                zrepeat
                    clc
                    adc #12*3
                    cmp #NUM_PITCHES
                    bge 1f
                    inx
                    cpx p
                zuntil eq
                sta editnote
                rts
            zendif

            ; Lowering octave

            lda editnote
            zrepeat
                sec
                sbc #12*3
                bcc 1f
                dex
                cpx p
            zuntil eq
            sta editnote
        zendif
    zendif
1:
    rts
zendproc

zlproc key_up
    ldx editcursory
    dex
    zif mi
        ldx #EDIT__LAST
    zendif
    stx editcursory
    rts
zendproc

zlproc key_down
    ldx editcursory
    inx
    cpx #EDIT__LAST+1
    zif ge
        ldx #0
    zendif
    stx editcursory
    rts
zendproc

zlproc key_left
    lda #0xff
    .byte 0x2c          ; skip next two bytes
key_right:
    lda #0x01
    ldx editcursory
    cpx #EDIT_DATA
    zif eq
        clc
        adc editcursorx
        and #TONE_SAMPLES-1
        sta editcursorx
    zendif
    rts
zendproc

zlproc key_decrement
    lda #0xff
    jmp adjust_value
zendproc

zlproc key_increment
    lda #0x01
    jmp adjust_value
zendproc

zlproc setup_screen_for_tone_editor
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
#include "tonepage_compressed.inc"
zendproc

zlproc draw_label
    lda #lo(EDITMODE_ADDRESS)
    sta scrptr+0
    lda #hi(EDITMODE_ADDRESS)
    sta scrptr+1

    lda #6
    zrepeat
        pha
        lda 1f, x
        inx
        sta (scrptr), y
        iny
        pla
        sec
        sbc #1
    zuntil eq
    rts

1:
    .byte 0x50, 0x49, 0x54, 0x43, 0x48, 0x20
    .byte 0x56, 0x4f, 0x4c, 0x55, 0x4d, 0x45
zendproc

zlproc redraw
    ; Redraw the various indicators.

    lda #lo(TONE_ADDRESS)
    sta scrptr+0
    lda #hi(TONE_ADDRESS)
    sta scrptr+1
    lda edittone
    jsr print_h8

    ldx edittone
    lda #lo(REPEATSTART_ADDRESS)
    sta scrptr+0
    lda #hi(REPEATSTART_ADDRESS)
    sta scrptr+1
    lda repeatstart, x
    jsr print_h8

    lda #lo(REPEATEND_ADDRESS)
    sta scrptr+0
    lda #hi(REPEATEND_ADDRESS)
    sta scrptr+1
    lda repeatend, x
    jsr print_h8

    lda #lo(CURSORX_ADDRESS)
    sta scrptr+0
    lda #hi(CURSORX_ADDRESS)
    sta scrptr+1
    lda editcursorx
    jsr print_h8
    inc16 scrptr
    ldy editcursorx
    ldx #'+'
    lda (editsampledata), y
    zif mi
        ldx #'-'
        eor #0xff
        sec
        adc #0
    zendif
    pha
    txa
    jsr print_char
    pla
    jsr print_h8

    ldx #0
    bit editingvolume_flag
    zif mi
        ldx #6
    zendif
    jsr draw_label

    lda #lo(NOTE_ADDRESS)
    sta scrptr+0
    lda #hi(NOTE_ADDRESS)
    sta scrptr+1
    lda editnote
    jsr draw_raw_note

    ; Clear the graph area.

    ldy #8
    jsr set_scrptr_y
    ldx #16
    zrepeat
        ldy #4
        lda #' '
        zrepeat
            sta (scrptr), y
            iny
            cpy #36
        zuntil eq
        lda #40
        jsr advance_scrptr
        dex
    zuntil eq

    ; Draw the graphs.

    lda #63              ; X position
    sta p
    zrepeat
        lda p
        jsr get_sample_xy
        jsr plot_subpixel
        dec p
    zuntil mi
    rts
zendproc

zlproc get_sample_xy
    pha
    tay
    sec
    lda #GRAPH_Y
    sbc (editsampledata), y ; pitch
    
    tay
    pla
    clc
    adc #GRAPH_X
    tax
    rts
zendproc

zlproc select_edited_item
    lda editcursory
    cmp #EDIT_TONE
    zif eq
        ldx #lo(TONE_ADDRESS)
        ldy #hi(TONE_ADDRESS)
        jsr move_cursor
        jmp cursor_on
    zendif
    cmp #EDIT_REPEATSTART
    zif eq
        ldx #lo(REPEATSTART_ADDRESS)
        ldy #hi(REPEATSTART_ADDRESS)
        jsr move_cursor
        jmp cursor_on
    zendif
    cmp #EDIT_REPEATEND
    zif eq
        ldx #lo(REPEATEND_ADDRESS)
        ldy #hi(REPEATEND_ADDRESS)
        jsr move_cursor
        jmp cursor_on
    zendif
    cmp #EDIT_MODE
    zif eq
        ldx #lo(EDITMODE_ADDRESS)
        ldy #hi(EDITMODE_ADDRESS)
        jsr move_cursor
        jmp cursor_on
    zendif
    cmp #EDIT_DATA
    zif eq
        clc
        lda #GRAPH_X
        adc editcursorx
        tax
        ldy #GRAPH_Y+15
        jsr plot_subpixel
        ldy #GRAPH_Y-15
        jmp plot_subpixel
    zendif
    rts
zendproc

; On entry, A is the value to adjust by.

zlproc adjust_value
    ldx editcursory
    cpx #EDIT_TONE
    zif eq
        clc
        adc edittone
        and #0x0f
        sta edittone
        rts
    zendif
    cpx #EDIT_REPEATSTART
    zif eq
        ldx edittone
        clc
        adc repeatstart, x
        sta repeatstart, x
        rts
    zendif
    cpx #EDIT_REPEATEND
    zif eq
        ldx edittone
        clc
        adc repeatend, x
        sta repeatend, x
        rts
    zendif
    cpx #EDIT_MODE
    zif eq
        lda #0xff
        bit editingvolume_flag
        zif mi
            lda #0
        zendif
        sta editingvolume_flag
        rts
    zendif
    cpx #EDIT_DATA
    zif eq
        ldy editcursorx
        clc
        adc (editsampledata), y
        sta (editsampledata), y
        rts
    zendif
    rts
zendproc
