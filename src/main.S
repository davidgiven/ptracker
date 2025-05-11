    #include "zif.inc"
    #include "pet.inc"
    #include "globals.inc"

zproc _init, .text.header
    .word loadaddr
loadaddr:
    .word _entry_string_end, 1
    .byte 0x9e
    .ascii "1037" ; decimal address of _start
    .byte 0
_entry_string_end:
    .word 0
zendproc

.section .zp, "zax", @nobits

.global w, q, p
w:          .fill 2 ; general purpose temp
q:          .fill 2 ; general purpose temp
p:          .fill 2 ; general purpose temp

zproc _start, .text.init
    ; Clear zero page.

    ldx #__last_zp-1
    lda #0
    zrepeat
        sta 0, x
        dex
    zuntil mi

    jsr engine_mode
    jsr init_screen
    jsr clear_all_data
    jsr init_pattern_editor

    jsr reset_row_pointer
    jmp file_editor

bad_rom:
zendproc

zproc engine_mode
    sei
    rts
zendproc

; Force an immediate hardware interrupt to let the kernal do housekeeping. Run
; with interrupts off.
        
zlproc keyboard_interrupt
    lda #>1f
    pha
    lda #<1f
    pha
    php                     ; P
    php                     ; A
    php                     ; Y
    php                     ; X
    jmp (IRQ_VECTOR)
1:
    rts
zendproc

zproc kernal_mode
    pha
    sei
    jsr keyboard_interrupt
    cli
    zrepeat
        jsr GETIN
    zuntil eq
    pla
    rts
zendproc
