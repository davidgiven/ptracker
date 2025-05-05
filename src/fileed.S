#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

zproc clear_all_data
    ; Wipe everything in the header area to zeroes (the pattern data is written
    ; completely later).

    lda #>MUSIC_DATA
    sta w+1
    lda #0
    sta w+0
    zrepeat
        ldy #0
        tya
        zrepeat
            sta (w), y
            iny
        zuntil eq

        inc w+1
        lda w+1
        cmp #>PATTERN_DATA
    zuntil eq

    lda #32
    sta tempo
    sta patternlength
    lda #1
    sta sequencelength
    sta numpatterns

    ; Initialise sequence.

    ldx #1
    lda #0xff
    zrepeat
        sta sequence, x
        inx
        cpx #128
    zuntil eq

    ; Initialise tone data.

    .if 0
    ldx #15
    zrepeat
        lda #1
        sta samplespeed, x
        sta pitchscale, x
        lda #64
        sta repeatend, x
        dex
    zuntil mi
    .endif
 
    ; Wipe pattern data.

    lda #>PATTERN_DATA
    sta w+1
    ; w+0 is still 0 from above
    zrepeat
        ldy #0
        zrepeat
            lda #FIRST_COMMAND + 'B' - 'A'
            sta (w), y
            iny
            iny
            sta (w), y
            iny
            iny
            sta (w), y
            iny
            iny
            sta (w), y

            tya
            sec
            sbc #5
            tay

            lda #0x0f
            sta (w), y
            iny
            iny
            sta (w), y
            iny
            iny
            sta (w), y
            iny
            iny
            sta (w), y
            iny
        zuntil eq

        inc w+1
        lda w+1
        cmp #>VRAM
    zuntil eq

    lda #8
    sta 0xd1            ; length of filename
    lda #<name
    sta 0xda+0          ; filename
    lda #>name
    sta 0xda+1          ; filename
    jsr load_file

    rts

name:
    .ascii "0:DEBRIS"
name_end:
zendproc
    
zproc load_file
    lda #147            ; clear screen
    jsr CHROUT

    ldy #0
    zrepeat
        lda loading_msg, y
        jsr CHROUT
        iny
        cpy #(loading_msg_end - loading_msg)
    zuntil eq

    ldy #0
    zrepeat
        lda (0xda), y
        jsr CHROUT
        iny
        cpy 0xd1
    zuntil eq

    lda #<MUSIC_DATA
    sta w+0
    lda #>MUSIC_DATA
    sta w+1

    lda #0x60
    sta 0xd3            ; secondary address
    lda #8
    sta 0xd4            ; device number
    
    jsr 0xf449
    jsr 0xf4a5
    jsr 0xf0d2
    lda 0xd3
    jsr 0xf193
    
    zrepeat
        lda #0
        sta 0x96

        jsr 0xf1c0      ; read byte
        ldy #0
        sta (w), y

        inc w+0
        zif eq
            inc w+1
            lda #'.'
            jsr CHROUT
        zendif

        lda 0x96
    zuntil ne

    jsr 0xf1ae          ; UNTALK
    jsr 0xf72f
    jmp .
    rts

loading_msg:
    .ascii "LOADING "
loading_msg_end:
zendproc
