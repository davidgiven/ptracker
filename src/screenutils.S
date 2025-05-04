#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

.global scrptr
scrptr:     .fill 2
curptr:     .fill 2
cursor_flag: .fill 1

zproc init_screen
    lda #0
    sta cursor_flag
    sta curptr+0
    lda #0x80
    sta curptr+1
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
zproc hex_table
    .ascii "0123456789"
    .byte 1, 2, 3, 4, 5, 6 ; PET screen codes for a-f
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
    lda #32
    ldx #0
    zrepeat
        sta VRAM+0x0000, x
        sta VRAM+0x0100, x
        sta VRAM+0x0200, x
        sta VRAM+0x0300, x
        dex
    zuntil eq
    rts
zendproc

; Moves the cursor to the address at YYXX.

zproc move_cursor
    stx curptr+0
    sty curptr+1
    rts
zendproc

zproc toggle_cursor
    ldy #0
    lda #0x80
    eor (curptr), y
    sta (curptr), y
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
    ldx #10
    zrepeat
        and PIA1_PB
        inc PIA1_PA
        dex
    zuntil eq

    cmp #0xff
    rts
zendproc