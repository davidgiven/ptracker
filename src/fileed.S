#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

zproc file_editor
    ldx #0xff
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
    key 'N', key_n
    key 'L', key_l
    key 'S', key_s
    key 32, key_space
    .byte 0
zendproc

zlproc key_n
    lda #20 - (2f-1f)/2
    ldx #<1f
    ldy #>1f
    jsr text_prompt
    tya
    zif ne
        lda text_buffer+0
        cmp #'Y'
        zif eq
            jsr clear_all_data
        zendif
    zendif
    rts

1:
    ; "Clear all data. Are you sure?"
    .byte 67, 12, 5, 1, 18, 32
    .byte 1, 12, 12, 32
    .byte 4, 1, 20, 1, 46, 32
    .byte 65, 18, 5, 32
    .byte 25, 15, 21, 32
    .byte 19, 21, 18, 5, 63
2:
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

zlproc key_space
    lda #0
    sta rowno
    sta seqindex
    lda sequence+0
    sta patternno
    sta looping_flag

    jsr play_entire_song
    jmp setup_screen_for_file_editor
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
#include "fileed_compressed.inc"
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

    lda #1            ; logical file handle
    sta LA
    lda #0x60
    sta SA            ; secondary address
    lda #8
    sta FA            ; device number

    jsr kopen

    jsr clear_all_data
    lda #0
    sta rowno
    sta seqindex
    lda sequence+0
    sta patternno

    lda #<MUSIC_DATA
    sta w+0
    lda #>MUSIC_DATA
    sta w+1
    
    ldx LA
    jsr CHKIN
    zrepeat
        lda #0
        sta STATUS

        jsr CHRIN
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
    lda LA
    jsr kclose
    jsr CLRCHN
    pla

    lda STATUS
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

    lda #1            ; logical file handle
    sta LA
    lda #0x61
    sta SA            ; secondary address
    lda #8
    sta FA            ; device number
    
    jsr kopen
    
    lda #<MUSIC_DATA
    sta w+0
    lda #>MUSIC_DATA
    sta w+1
    clc
    lda numpatterns
    adc #>PATTERN_DATA
    sta p
    
    ldx LA
    jsr CHKOUT

    zrepeat
        lda w+1
        cmp p
        zbreakif eq

        lda #0
        sta STATUS

        ldy #0
        lda (w), y
        jsr CHROUT

        inc w+0
        zif eq
            inc w+1
            jsr CLRCHN
            lda #'.'
            jsr CHROUT
            ldx LA
            jsr CHKOUT
        zendif

        lda STATUS
    zuntil ne
    pha
    lda LA
    jsr kclose
    jsr CLRCHN
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

    lda #0
    sta FNLEN
    lda #1
    sta LA            ; logical file handle
    lda #0x6f
    sta SA            ; secondary address (error channel)
    lda #8
    sta FA            ; device number
    
    jsr kopen

    ldx LA
    jsr CHKIN
    
    zrepeat
        lda #0
        sta STATUS

        jsr CHRIN
        jsr CHROUT

        lda STATUS
    zuntil ne

    lda LA
    jsr kclose
    jsr CLRCHN

wait_for_keypress:
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

; Kernal API wrappers.

zproc kopen
    lda PET_DETECT
    cmp #PET_4000
    zif eq
        jmp 0xf563
    zendif
    cmp #PET_2000
    zif eq
        jmp 0xf53d
    zendif
    jmp 0xf524
zendproc

zproc kclose
    ldx PET_DETECT
    cpx #PET_4000
    zif eq
        jmp 0xf2e2
    zendif
    cpx #PET_2000
    zif eq
        jmp 0xf2cb
    zendif
    jmp 0xf2ae
zendproc
