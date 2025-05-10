#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

zproc help_editor
    ldx #0xff
    txs

    zloop
        jsr setup_screen_for_help_editor
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
    key 0x09, file_editor ; tab
    key 0x13, file_editor ; clr/home
    .byte 0
zendproc

zlproc setup_screen_for_help_editor
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
#include "helped_compressed.inc"
zendproc