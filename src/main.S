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

t1:         .fill 1
t2:         .fill 1
t3:         .fill 1
t4:         .fill 1
t1m:        .fill 1
t2m:        .fill 1
t3m:        .fill 1
t4m:        .fill 1
t1p:        .fill 1
t2p:        .fill 1
t3p:        .fill 1
t4p:        .fill 1
nextsample: .fill 1

SAMPLE_FREQ = 30000
SAMPLE_PERIOD = 1000000 / SAMPLE_FREQ

N1 = ((1000000 / 262) / SAMPLE_PERIOD)
N2 = ((1000000 / 330) / SAMPLE_PERIOD)
N3 = ((1000000 / 392) / SAMPLE_PERIOD)
N4 = ((1000000 / 523) / SAMPLE_PERIOD)

BITRATE = 3

zproc _start, .text.init
    sei

    lda #0x54 ; T1 continuous, SR under T2 control
    sta VIA_ACR

    lda #0xac
    sta VIA_PCR

    lda #lo(SAMPLE_PERIOD)
    sta VIA_T2C_L
    lda #hi(SAMPLE_PERIOD)
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
    lda #1
    sta t1
    sta t2
    sta t3
    sta t4
    lda #5
    sta t1m
    sta t2m
    sta t3m
    sta t4m

    zloop
        ; Generate one sample-worth of data.

        .rept 8
            jsr synthesise
        .endr

        ; Wait for a shift register interrupt.

        lda #0x04
        zrepeat
            bit VIA_IFR
        zuntil ne

        ; Clear it and write the sample.

        sta VIA_IFR
        lda nextsample
        sta VIA_SR
    zendloop
zendproc

zproc synthesise
    ldy #0

.macro synth var, varp, varm
    dec \var            ; 5
    zif eq              ; 2
        lda \varp       ; 3
        sta \var        ; 3
    zendif
    lda \varm           ; 3
    zif ne              ; 2
        cmp \var        ; 3
        zif cs          ; 2
            iny         ; 2
        zendif
    zendif
.endm                   ; = 25

    synth t1, t1p, t1m
    synth t2, t2p, t2m
    synth t3, t3p, t3m
    synth t4, t4p, t4m

    cpy #1          ; sets C is >= 1
    rol nextsample

    rts
zendproc
