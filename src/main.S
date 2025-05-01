    #include "zif.inc"
    #include "pet.inc"
    #include "globals.inc"

zproc _init, .text.header
    .word _loadaddr
_loadaddr:
    .word _entry_string_end, 1
    .byte 0x9e
    .ascii "1037" ; decimal address of _start
    .byte 0
_entry_string_end:
    .word 0
zendproc

.section .zp, "zax", @nobits

t1_l:       .fill 1
t2_l:       .fill 1
t3_l:       .fill 1
t4_l:       .fill 1
t1_h:       .fill 1
t2_h:       .fill 1
t3_h:       .fill 1
t4_h:       .fill 1
t1p_l:      .fill 1
t2p_l:      .fill 1
t3p_l:      .fill 1
t4p_l:      .fill 1
t1p_h:      .fill 1
t2p_h:      .fill 1
t3p_h:      .fill 1
t4p_h:      .fill 1
t1len:      .fill 1
t2len:      .fill 1
t3len:      .fill 1
t4len:      .fill 1
ticklen:    .fill 2 ; negative!
flag:       .fill 1

N1 = (1000000 / 2 / 262)
N2 = (1000000 / 2 / 330)
N3 = (1000000 / 2 / 392)
N4 = (1000000 / 2 / 523)

BITRATE = 20

zproc _start, .text.init
    sei

    jsr init_caramel

    ;lda #0x14
    ;sta VIA_ACR

    lda #0xcc
    sta VIA_PCR

    lda #0
    sta VIA_T1C_L
    sta VIA_T1C_H

    lda #lo(BITRATE)
    sta VIA_T2C_L
    lda #hi(BITRATE)
    sta VIA_T2C_H

    lda #<N1
    sta t1p_l
    lda #>N1
    sta t1p_h
    lda #<N2
    sta t2p_l
    lda #>N2
    sta t2p_h
    lda #<N3
    sta t3p_l
    lda #>N3
    sta t3p_h
    lda #<N4
    sta t4p_l
    lda #>N4
    sta t4p_h
    lda #4
    sta t1len
    sta t2len
    sta t3len
    sta t4len

    zloop
        ; Get the length of the last tick and reset the timer.

        zrepeat
            lda VIA_T1C_L
            ldx VIA_T1C_H
            cpx VIA_T1C_H
        zuntil eq
        sta ticklen+0
        stx ticklen+1
        lda #lo(-32)        ; adjustment for the number of cycles between reading the timer and resetting it
        sta VIA_T1C_L
        lda #hi(-32)
        sta VIA_T1C_H

        ; Update the timers.

        ldy #0
        ldx #3
        zrepeat
            clc
            lda ticklen+0
            adc t1_l, x
            sta t1_l, x
            lda ticklen+1
            adc t1_h, x
            sta t1_h, x
            zif cc
                zif ne
                    clc
                    lda t1p_l, x
                    adc t1_l, x
                    sta t1_l, x
                    lda t1p_h x
                    adc t1_h, x
                    sta t1_h, x

                    tya
                    cmp t1len, x
                    zif lt
                        ldy t1len, x
                    zendif
                zendif
            zendif

            dex
        zuntil_mi

        ; If any note wants to trigger a pulse, program T2 with the pulse duration.

        tya
        zif ne
            lda #0xec
            sta VIA_PCR
            zrepeat
                dey
            zuntil eq
            lda #0xcc
            sta VIA_PCR
        zendif

        jsr caramel_step
    zendloop
zendproc