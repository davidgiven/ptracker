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

zproc retard_scrptr
    clc
    eor #0xff
    adc #1
.global advance_scrptr
advance_scrptr:
    clc
    adc scrptr+0
    sta scrptr+1
    zif cs
        inc scrptr+1
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
    lda #14
    sta CRTC_ADDRESS
    tya
    sec
    sbc #0x54
    sta CRTC_DATA
    lda #15
    sta CRTC_ADDRESS
    txa
    sta CRTC_DATA
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