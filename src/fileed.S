#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

zproc file_editor
    ldx #0
    txs

    zloop
        jsr setup_screen_for_file_editor
        jsr do_keypress
    zendloop
zendproc
          
zlproc do_keypress
    zrepeat
        jsr getch
    zuntil ne

    key_lookup key_table
    rts
    
key_table:
    key 0x09, pattern_editor ; tab
    key 0x13, pattern_editor ; clr/home
    key 'L', key_l
    key 'S', key_s
    .byte 0
zendproc

zlproc key_l
    lda #20 - (2f-1f)/2
    ldx #<1f
    ldy #>1f
    jsr text_prompt
    tya
    zif ne
        jsr kernal_mode
        jsr load_file
        jsr engine_mode
    zendif
    rts

1:
    ; "Filename to load:"
    .byte 70, 9, 12, 5, 14, 1, 13, 5, 32, 20, 15, 32, 12, 15, 1, 4, 58, 0
2:
zendproc

zlproc key_s
    lda #20 - (2f-1f)/2
    ldx #<1f
    ldy #>1f
    jsr text_prompt
    tya
    zif ne
        jsr kernal_mode
        jsr save_file
        jsr engine_mode
    zendif
    rts

1:
    ; "Filename to save:"
    .byte 70, 9, 12, 5, 14, 1, 13, 5, 32, 20, 15, 32, 19, 1, 22, 5, 58, 0
2:
zendproc

zlproc setup_screen_for_file_editor
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
#include "filepage_compressed.inc"
zendproc

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

    ldx #15
    zrepeat
        lda #1
        sta samplespeed, x
        sta pitchscale, x
        lda #64
        sta repeatend, x
        dex
    zuntil mi
 
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
    
zlproc print_filename
    ldy #0
    zrepeat
        lda (FNADR), y
        jsr CHROUT
        iny
        cpy FNLEN
    zuntil eq
    rts
zendproc

zproc load_file
    jsr clear_screen

    ldy #0
    zrepeat
        lda loading_msg, y
        jsr CHROUT
        iny
        cpy #(loading_msg_end - loading_msg)
    zuntil eq

    jsr print_filename

    lda #0x60
    sta SA            ; secondary address
    lda #8
    sta FA            ; device number
    
    jsr 0xf449          ; open?
    jsr 0xf4a5          ; LISTEN
    jsr 0xf0d2          ; TALK
    lda SA
    jsr 0xf193          ; send IEEE-488 char
    
    jsr clear_all_data
    lda #<MUSIC_DATA
    sta w+0
    lda #>MUSIC_DATA
    sta w+1
    zrepeat
        lda #0
        sta STATUS

        jsr 0xf1c0      ; read byte
        ldy #0
        sta (w), y

        inc w+0
        zif eq
            inc w+1
            lda #'.'
            jsr CHROUT
        zendif

        lda STATUS
    zuntil ne
    pha
    jsr 0xf3ce          ; untalk and close
    pla

    and #0x40           ; EOF
    zif eq
        jsr show_disk_error
    zendif
    rts

loading_msg:
    .ascii "LOADING "
loading_msg_end:
zendproc

zproc save_file
    jsr clear_screen

    ldy #0
    zrepeat
        lda saving_msg, y
        jsr CHROUT
        iny
        cpy #(saving_msg_end - saving_msg)
    zuntil eq

    jsr print_filename

    lda #0x61
    sta SA            ; secondary address
    lda #8
    sta FA            ; device number
    
    jsr 0xf4a5
    jsr 0xf0d5
    lda SA
    jsr 0xf143
    
    lda #<MUSIC_DATA
    sta w+0
    lda #>MUSIC_DATA
    sta w+1
    clc
    lda numpatterns
    adc #>PATTERN_DATA
    sta p
    zrepeat
        lda w+1
        cmp p
        zbreakif eq

        lda #0
        sta STATUS

        ldy #0
        lda (w), y
        jsr 0xf143

        inc w+0
        zif eq
            inc w+1
            lda #'.'
            jsr CHROUT
        zendif

        lda STATUS
    zuntil ne
    pha
    jsr 0xf72c          ; unlisten and close
    pla

    jmp show_disk_error

saving_msg:
    .ascii "SAVING "
saving_msg_end:
zendproc

zproc show_disk_error
    lda #13
    jsr CHROUT
    jsr CHROUT

    lda #0x6f
    sta SA            ; secondary address (error channel)
    lda #8
    sta FA            ; device number
    
    jsr 0xf0d2          ; TALK
    lda SA
    jsr 0xf193          ; send IEEE-488 char
    
    zrepeat
        lda #0
        sta STATUS

        jsr 0xf1c0      ; read byte
        jsr CHROUT

        lda STATUS
    zuntil ne

    jsr 0xf1ae          ; UNTALK

    ldy #0
    zrepeat
        lda wait_msg, y
        jsr CHROUT
        iny
        cpy #(wait_msg_end - wait_msg)
    zuntil eq

    zrepeat
        jsr GETIN
    zuntil ne
    rts

wait_msg:
    .byte 13, 13
    .ascii "PRESS ANY KEY"
wait_msg_end:
zendproc
