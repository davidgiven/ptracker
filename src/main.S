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

.global w
w:          .fill 2 ; general purpose temp

t1:         .fill 1
t2:         .fill 1
t3:         .fill 1
t1m:        .fill 1
t2m:        .fill 1
t3m:        .fill 1
t1p:        .fill 1
t2p:        .fill 1
t3p:        .fill 1
t4ptr:      .fill 1
t4len:      .fill 1

nextsample: .fill 1

; Match this with the value in midinote.py.
#include "samplerate.py"
SAMPLE_PERIOD = 1000000 / SAMPLE_FREQ

BITRATE = 3

zproc _start, .text.init
    sei

    ; Clear zero page.

    ldx #__last_zp-1
    lda #0
    zrepeat
        sta 0, x
        dex
    zuntil mi

    jsr init_screen

    lda #0xbc
    sta PIA1_CRB            ; disable VSYNC interrupt

    lda #0x54               ; T1 continuous, T2 one-shot, SR under T2 control
    sta VIA_ACR

    lda #0xae               ; CB2 outputs SR pulses; lower case mode
    sta VIA_PCR

    lda #0x84
    sta VIA_IER             ; generate software interrupts on SR empty

    lda #<interrupt_handler ; set interrupt handler vector
    sta IRQ_VECTOR+0
    lda #>interrupt_handler
    sta IRQ_VECTOR+1

    lda #lo(SAMPLE_PERIOD/2) ; one bit is clocked out every _two_ T2 ticks
    sta VIA_T2C_L
    lda #hi(SAMPLE_PERIOD/2)
    sta VIA_T2C_H

    lda #0                  ; T1 makes an interrupt every 65.536ms
    sta VIA_T1C_L
    sta VIA_T1C_H

    lda #0
    sta VIA_SR

    cli
    jmp pattern_editor
zendproc

zproc interrupt_handler
    lda #0x04           ; clear IFR flag (to allow seamless playback)
    sta VIA_IFR

    lda nextsample
    sta VIA_SR          ; play the previously calculated sample

    ; Calculate the next sample, now timing isn't as tight.

    .macro synth var, varp, varm
        ldx \var            ; 3
        dex                 ; 2
        zif eq              ; 2/3
            ldx \varp       ; 3
        zendif
        stx \var            ; 3
        cpx \varm           ; 3
        adc #0xff           ; 2
    .endm                   ; = 18

    .rept 8
        lda #0
        synth t1, t1p, t1m
        synth t2, t2p, t2m
        synth t3, t3p, t3m

        cmp #1          ; sets C if >= 1
        rol nextsample
    .endr

    ldx t4ptr
    cpx t4len
    zif ne
        lda pcm_table, x
        eor nextsample
        sta nextsample
        inc t4ptr
    zendif

    pla
    tay
    pla
    tax
    pla
    rti
zendproc

.if 0
zproc player
    lda #<notedata
    sta noteptr+0
    lda #>notedata
    sta noteptr+1

    zloop
        ldy #0
        lda (noteptr), y
        sta notedelay+0
        iny
        lda (noteptr), y
        sta notedelay+1

        ora notedelay+0
        beq player

        iny
        lda (noteptr), y
        tax
        lda midinote_table-21, x
        sta t1p
        sta 0x8000

        iny
        lda (noteptr), y
        tax
        lda midinote_table-21, x
        sta t2p
        sta 0x8001

        iny
        lda (noteptr), y
        tax
        lda midinote_table-21, x
        sta t3p
        sta 0x8002

        clc
        lda noteptr+0
        adc #5
        sta noteptr+0
        zif cs
            inc noteptr+1
        zendif

        sei
        ldx #4
        lda drum_instrument_table, x
        sta t4ptr
        lda drum_instrument_table+1, x
        sta t4len
        cli

        zrepeat
            lda #0x40
            zrepeat
                bit VIA_IFR
            zuntil ne
            sta VIA_IFR

            dec16 notedelay
            lda notedelay+0
            ora notedelay+1
        zuntil_eq
    zendloop

zendproc
.endif

.data
pcm_table: