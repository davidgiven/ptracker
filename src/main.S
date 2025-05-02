    #include "zif.inc"
    #include "pet.inc"
    #include "globals.inc"

zproc _init, .text.header
    .word oadaddr
oadaddr:
    .word _entry_string_end, 1
    .byte 0x9e
    .ascii "1037" ; decimal address of _start
    .byte 0
_entry_string_end:
    .word 0
zendproc

.section .zp, "zax", @nobits

t1:       .fill 1
t2:       .fill 1
t3:       .fill 1
t4:       .fill 1
t1p:      .fill 1
t2p:      .fill 1
t3p:      .fill 1
t4p:      .fill 1
t1len:      .fill 1
t2len:      .fill 1
t3len:      .fill 1
t4len:      .fill 1
lastlen:    .fill 1
flag:       .fill 1

TICK_PERIOD = 150

N1 = ((1000000 / 262) / TICK_PERIOD)
N2 = ((1000000 / 330) / TICK_PERIOD)
N3 = ((1000000 / 392) / TICK_PERIOD)
N4 = ((1000000 / 523) / TICK_PERIOD)

BITRATE = 3

zproc _start, .text.init
    sei

    jsr init_caramel

    lda #0x54 ; T1 continuous, SR under T2 control
    sta VIA_ACR

    lda #0xac
    sta VIA_PCR

    lda #lo(BITRATE)
    sta VIA_T2C_L
    lda #hi(BITRATE)
    sta VIA_T2C_H

    lda #0
    sta VIA_SR
    sta t1
    sta t2
    sta t3
    sta t4

    lda #<N1
    sta t1p
    lda #<N2
    sta t2p
    lda #<N3
    sta t3p
    lda #<N4
    sta t4p
    lda #7
    sta t1len
    sta t2len
    sta t3len
    sta t4len

    lda #lo(TICK_PERIOD)
    sta VIA_T1C_L
    lda #hi(TICK_PERIOD)
    sta VIA_T1C_H

    zloop
        lda VIA_T1C_L

        ; Trigger any pulse made in the previous loop (done here for precise timing).

        lda lastlen
        zif ne
            lda volume_bits-1, y
            sta VIA_SR
        zendif

        ; Update the timers.

        ldy #0
        ; Worst case for the following: 20 cycles
        dec t1
        zif eq
            cpy t1len       ; 3
            zif lt          ; 2
                ldy t1len   ; 3
            zendif
            lda t1p         ; 3
            sta t1          ; 3 = 14

            ;ldx t1len       ; 3
            ;lda volume_bits, x ; 4
            ;sta VIA_SR      ; 4 = 11
        zendif

        dec t2
        zif eq
            cpy t2len
            zif lt
                ldy t2len
            zendif
            lda t2p
            sta t2
        zendif

        dec t3
        zif eq
            cpy t3len
            zif lt
                ldy t3len
            zendif
            lda t3p
            sta t3
        zendif

        dec t4
        zif eq
            cpy t4len
            zif lt
                ldy t4len
            zendif
            lda t4p
            sta t4
        zendif

        sty lastlen

        ;jsr caramel_step

        ; Spin for the rest of the tick.

        lda #0x40
        ;bit VIA_IFR
        ;zif ne
        ;    brk
        ;zendif

        zrepeat
            bit VIA_IFR
        zuntil ne
    zendloop

volume_bits:
    .byte 0x80
    .byte 0xc0
    .byte 0xe0
    .byte 0xf0
    .byte 0xf8
    .byte 0xfc
    .byte 0xfe
zendproc