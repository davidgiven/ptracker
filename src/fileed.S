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

    rts
zendproc
