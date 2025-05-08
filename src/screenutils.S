#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

.global scrptr
scrptr:     .fill 2
cursor_flag: .fill 1

zproc init_screen
    lda #0
    sta cursor_flag
    sta PNT+0
    lda #0x80
    sta PNT+1
    jsr clear_screen

    lda #0xae       ; switch to lower case
    sta VIA_PCR
    rts
zendproc

; Various print-char routines.

zproc print_h8
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr print_h4
    pla
    and #0x0f
.global print_h4
print_h4:
    tay
    lda hex_table, y
.global print_char
print_char:
    ldy #0
    sta (scrptr), y
    inc16 scrptr
    rts
zendproc

zproc print_space
    lda #' '
    jmp print_char
zendproc

zproc hex_table
    .ascii "0123456789"
    .byte 1, 2, 3, 4, 5, 6 ; PET screen codes for a-f
zendproc

; Move scrptr to the beginning of line Y

zproc set_scrptr_y
    lda screen_table_lo, y
    sta scrptr+0
    lda screen_table_hi, y
    sta scrptr+1
    rts
zendproc

zproc screen_table_hi
    i = 0
    .rept 25
        .byte hi(VRAM + i*40)
        i = i + 1
    .endr
zendproc

zproc screen_table_lo
    i = 0
    .rept 25
        .byte lo(VRAM + i*40)
        i = i + 1
    .endr
zendproc

; Advances/retards the screen pointer by A bytes.

zproc advance_scrptr
    clc
    adc scrptr+0
    sta scrptr+0
    zif cs
        inc scrptr+1
    zendif
    rts
zendproc

zproc retard_scrptr
    sec
    eor #0xff
    adc scrptr+0
    sta scrptr+0
    zif cc
        dec scrptr+1
    zendif
    rts
zendproc

zproc clear_screen
    lda #147            ; clear screen
    jmp CHROUT
zendproc

; Move PNT to the beginning of line Y

zproc set_curptr_y
    ldx screen_table_lo, y
    lda screen_table_hi, y
    tay
; Moves the cursor to the address at YYXX.
.global move_cursor
move_cursor:
    stx PNT+0
    sty PNT+1
    lda #0
    sta PNTR
    rts
zendproc

zproc toggle_cursor
    ldy PNTR
    lda #0x80
    eor (PNT), y
    sta (PNT), y
    rts
zendproc

zproc cursor_on
    bit cursor_flag
    zif pl
        jsr toggle_cursor
        dec cursor_flag
    zendif
    rts
zendproc

zproc cursor_off
    bit cursor_flag
    zif mi
        jsr toggle_cursor
        inc cursor_flag
    zendif
    rts
zendproc

; Polls the keyboard but does not consume the key (can be run with the vsync
; interrupt disabled).

zproc is_key_pressed
    lda PIA1_PA
    and #0xf0
    sta PIA1_PA

    lda #0xff
    .rept 10
        and PIA1_PB
        inc PIA1_PA
    .endr

    cmp #0xff
    rts
zendproc

; Given a subpixel coordinate in X, Y, prepare (scrptr)+y to access it, set
; q to the subpixel mask, and read and decode the byte itself.

zproc access_subpixel_xy
    stx w+0
    sty w+1

    ; Adjust coordinates and compute the subpixel mask.

    lda #0
    lsr w+1
    rol a
    lsr w+0
    rol a
    tax
    lda 1f, x
    sta q+0

    ; Read and decode the subpixel itself.

    ldy w+1
    jsr set_scrptr_y
    ldy w+0
    lda (scrptr), y
    jmp decode_subpixel

1:
    .byte 1, 2, 4, 8
zendproc

; Uses w and q.

zproc plot_subpixel
    txa
    pha
    tya
    pha
    
    jsr access_subpixel_xy
    ora q
    tax
    lda subpixel_table, x
    sta (scrptr), y
    
    pla
    tay
    pla
    tax
    rts
zendproc

; Uses w and q.

zproc unplot_subpixel
    txa
    pha
    tya
    pha

    jsr access_subpixel_xy
    sta q+1
    lda q
    eor #0x0f
    and q+1
    tax
    lda subpixel_table, x
    sta (scrptr), y
    
    pla
    tay
    pla
    tax
    rts
zendproc

zproc subpixel_table
    .byte 32, 126, 124, 226, 123, 97, 255, 236
    .byte 108, 127, 225, 251, 98, 252, 254, 160
zendproc

zproc decode_subpixel
    ldx #15
    zrepeat
        cmp subpixel_table, x
        beq 1f
        dex
    zuntil mi
    ldx #0
1:
    txa
    rts
zendproc

; Returns the length of the message in Y.

zproc text_prompt
    sta p+0     ; text indent
    stx w+0     ; pointer to message
    sty w+1

    ; Draw the 'dialogue box' with the message in it.

    ldy #10
    jsr set_scrptr_y
    ldy #39
    lda #0x63
    zrepeat
        sta (scrptr), y
        dey
    zuntil mi

    ldy #11
    jsr set_scrptr_y
    ldy #40*5-1
    lda #0x20
    zrepeat
        sta (scrptr), y
        dey
    zuntil mi

    ldy #16
    jsr set_scrptr_y
    ldy #39
    lda #0x64
    zrepeat
        sta (scrptr), y
        dey
    zuntil mi
    
    ldy #11
    jsr set_scrptr_y
    lda #0
    sta p+1         ; offset into message
    zloop
        ldy p+1
        lda (w), y  ; read char from message
        zbreakif eq

        ldy p+0
        sta (scrptr), y ; write char to screen

        inc p+0
        inc p+1
    zendloop

    ldy #15
    jsr set_scrptr_y
    ldy #12
    lda #0x63
    zrepeat
        sta (scrptr), y
        iny
        cpy #28
    zuntil eq

    lda #62
    sta VRAM + 14*40 + 10

    ; The editor itself.

    lda #<(VRAM + 14*40 + 12)
    sta PNT+0
    lda #>(VRAM + 14*40 + 12)
    sta PNT+1

    ldy #0              ; X position
    sty PNTR
    zloop
        jsr cursor_on
        zrepeat
            jsr GETIN
        zuntil ne

        pha
        jsr cursor_off
        lda #<VRAM
        sta scrptr+0
        lda #>VRAM
        sta scrptr+1
        pla
        pha
        jsr print_h8
        pla

        ldy PNTR

        cmp #0x0d ; return
        zbreakif eq

        cmp #0x03 ; escape
        zif eq
        1:
            ldy #0
            sta FNLEN
            rts
        zendif

        cmp #0x14 ; delete
        zif eq
            cpy #0
            zif ne
                jsr CHROUT
                zcontinue
            zendif
        zendif

        cmp #32
        zif ge
            cmp #127
            zif lt
                cpy #16
                zif ne
                    sta text_buffer, y
                    jsr CHROUT
                zendif
            zendif
        zendif
    zendloop
    lda #0
    sta text_buffer, y
    lda #<text_buffer
    sta FNADR+0
    lda #>text_buffer
    sta FNADR+1
    sty FNLEN
    rts
zendproc

.common text_buffer, 16+1
