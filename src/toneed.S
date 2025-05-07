#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

zproc tone_editor
    ldx #0
    txs
    jsr setup_screen_for_tone_editor
    
    zloop
        jsr do_toneeditor_keypress
    zendloop
zendproc
        
zproc do_toneeditor_keypress
    jsr cursor_on
    zrepeat
;        jsr just_play_without_processing
        jsr GETIN
    zuntil ne
    pha
    jsr cursor_off
    pla

    key_lookup key_table
    rts
    
key_table:
    key 0x09, pattern_editor ; tab
    key 0x12, pattern_editor ; rvs/off
    .byte 0
zendproc

zproc setup_screen_for_tone_editor
    jsr clear_screen

    ldx #40*5
    zrepeat
        lda data+0*40-1, x
        sta VRAM+0*40-1, x
        dex
    zuntil eq

    lda #lo(VRAM+7*40+5)
    sta scrptr+0
    lda #hi(VRAM+7*40+5)
    sta scrptr+1
    ldx #15
    ldy #0
    zrepeat
        lda #0x5d
        sta (scrptr), y
        lda #40
        jsr advance_scrptr
        dex
    zuntil eq
    
    lda #0x64
    sta VRAM+6*40+5
    lda #0x71
    sta VRAM+22*40+5
    lda #0x30
    sta VRAM+14*40+4
    lda #0x2b
    sta VRAM+10*40+4
    lda #0x2d
    sta VRAM+18*40+4
    
    ldx #0
    jsr draw_pitch_label
    ldx #12
    jsr draw_volume_label
    
    ldx #5
    ldy #5
    jsr plot_subpixel
    ldx #6
    ldy #6
    jsr plot_subpixel
    ldx #5
    ldy #5
    jsr unplot_subpixel
    rts

data:
BYTE $20,$20,$46,$09,$0C,$05,$20,$20,$50,$01,$14,$14,$05,$12,$0E,$20,$A0,$D4,$8F,$8E,$85,$A0,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
BYTE $63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63,$63
BYTE $54,$0F,$0E,$05,$3A,$20,$20,$20,$20,$20,$20,$20,$20,$30,$30,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
BYTE $50,$09,$14,$03,$08,$20,$13,$03,$01,$0C,$05,$3A,$20,$30,$30,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
BYTE $52,$05,$10,$05,$01,$14,$3A,$20,$20,$20,$20,$20,$20,$30,$30,$20,$14,$0F,$20,$30,$30,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
zendproc

zproc draw_volume_label
    lda #lo(VRAM+16*40+2)
    sta scrptr+0
    lda #hi(VRAM+16*40+2)
    sta scrptr+1
    jmp draw_label
zendproc

zproc draw_pitch_label
    lda #lo(VRAM+7*40+2)
    sta scrptr+0
    lda #hi(VRAM+7*40+2)
    sta scrptr+1
    
draw_label:
    lda #6
    zrepeat
        pha
        lda 1f, x
        inx
        sta (scrptr), y
        lda #40
        jsr advance_scrptr
        pla
        sec
        sbc #1
    zuntil eq
    rts

1:
    .byte 0x50, 0x49, 0x54, 0x43, 0x48, 0x20
    .byte 0xd0, 0xc9, 0xd4, 0xc3, 0xc8, 0x20
    .byte 0x56, 0x4f, 0x4c, 0x55, 0x4d, 0x45
    .byte 0xd6, 0xcf, 0xcc, 0xd5, 0xcd, 0xc5
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

zproc plot_subpixel
    jsr access_subpixel_xy
    ora q
    tax
    lda subpixel_table, x
    sta (scrptr), y
    rts
zendproc

zproc unplot_subpixel
    jsr access_subpixel_xy
    sta q+1
    lda q
    eor #0x0f
    and q+1
    tax
    lda subpixel_table, x
    sta (scrptr), y
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

