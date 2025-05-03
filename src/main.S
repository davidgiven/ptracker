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
t1m:        .fill 1
t2m:        .fill 1
t3m:        .fill 1
t1p:        .fill 1
t2p:        .fill 1
t3p:        .fill 1
t4ptr:      .fill 1
t4len:      .fill 1
t4bitcount: .fill 1
t4value:    .fill 1
ticks:      .fill 1

nextsample: .fill 1

noteptr:    .fill 2
notedelay:  .fill 2

; Match this with the value in midinote.py.
SAMPLE_FREQ = 16000
SAMPLE_PERIOD = 1000000 / SAMPLE_FREQ

BITRATE = 3

zproc _start, .text.init
    sei

    lda #0xbc
    sta PIA1_CRB            ; disable VSYNC interrupt

    lda #0x54               ; T1 continuous, T2 one-shot, SR under T2 control
    sta VIA_ACR

    lda #0xac               ; CB2 outputs SR pulses
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

    lda #0x0
    sta t1m
    sta t2m
    sta t3m

    lda #0
    sta VIA_SR

    cli
    jmp player
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

    .if 0
    ldx t4ptr
    cpx t4len
    zif ne
        inc ticks
        lda ticks
        and #1

        zif eq
            lda pcm_3bit_table, x
            and #0x0f
            tax
            lda volume_table, x
            eor nextsample
            sta nextsample
        zelse
            lda pcm_3bit_table, x
            lsr a
            lsr a
            lsr a
            lsr a
            tax
            lda volume_table, x
            eor nextsample
            sta nextsample

            inc t4ptr
        zendif
    zendif
    .endif

    .if 0
    inc ticks
    lda ticks
    and #0x01
    zif eq
        ldx t4ptr
        cpx t4len
        zif ne
            ror t4value
            zif cs
                lda nextsample
                ora #0x01
                sta nextsample
            zendif
            dec t4bitcount
            zif eq
                inx
                stx t4ptr
                ldy pcm_table, x
                sty t4value
                ldy #8
                sty t4bitcount
            zendif 
        zendif
    zendif
    .endif

    pla
    tay
    pla
    tax
    pla
    rti
zendproc

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
        lda #0
        sta t4ptr
        lda #153
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

    .macro note d, n1, n2, n3
        .word \d*7
        .byte \n1, \n2, \n3
    .endm
notedata:
   ; note 1200, D4, Fs4, A3

    note 120, D4, Fs4, A3
    note 120, D4, G4, A3
    note 120, D4, Fs4, A3
    note 120, D4, E4, A3
    note 1800, C4, D4, G3
    note 120, C4, D4, G3
    note 120, C4, F4, G3
    note 120, C4, G4, G3
    note 120, C4, F4, G3
    note 120, C4, C4, G3
    note 120, B3, C4, G3
    note 120, D4, D4, G3
    note 120, B3, D4, G3
    note 120, A3, D4, G3
    note 120, G3, D4, G3
    note 120, F3, D4, G3
    note 120, G3, D4, G3
    note 120, A3, D4, G3
    note 120, D4, D4, G3
    note 120, B3, B2, Fs3
    note 120, Cs4, B2, Fs3
    note 120, D4, B2, Fs3
    note 120, Fs4, B2, Fs3
    note 120, D4, B2, Fs3
    note 120, Cs4, B2, Fs3
    note 120, B3, B2, Fs3
    note 120, A3, B2, Fs3
    note 120, E4, A2, E3
    note 120, D4, A2, E3
    note 120, C4, A2, E3
    note 120, B3, A2, E3
    note 120, A3, A2, E3
    note 120, G3, A2, E3
    note 120, A3, A2, E3
    note 120, B3, A2, E3
    note 120, Ds4, Gs2, Ds3
    note 120, Cs4, Gs2, Ds3
    note 120, Ds4, Gs2, Ds3
    note 120, Fs4, Gs2, Ds3
    note 120, F4, Gs2, Ds3
    note 120, Cs4, Gs2, Ds3
    note 120, Ds4, Gs2, Ds3
    note 120, Cs4, Gs2, Ds3
    note 120, Ds4, Gs2, Ds3
    note 120, B3, Gs2, Ds3
    note 120, As3, Gs2, Ds3
    note 120, Fs3, Gs2, Ds3
    note 120, Gs3, Gs2, Ds3
    note 120, Gs3, Gs2, Ds3
    note 120, Gs3, Gs2, Ds3
    note 120, Gs3, Gs2, Ds3
    note 120, Cs4, B2, B2
    note 120, Cs4, D4, B2
    note 120, Cs4, Fs4, B2
    note 120, Cs4, A4, B2
    note 120, Cs4, B2, B2
    note 120, Cs4, D4, B2
    note 120, Cs4, Fs4, B2
    note 120, Cs4, A4, B2
    note 120, B3, D4, B2
    note 120, D4, B2, B2
    note 120, D4, Fs4, B2
    note 120, D4, A4, B2
    note 120, B3, D4, B2
    note 120, D4, B2, B2
    note 120, D4, Fs4, B2
    note 120, D4, A4, B2
    note 120, B3, A2, A2
    note 120, B3, C4, A2
    note 120, B3, E4, A2
    note 120, B3, G4, A2
    note 120, B3, A2, A2
    note 120, B3, C4, A2
    note 120, B3, E4, A2
    note 120, B3, G4, A2
    note 120, A3, C4, A2
    note 120, C4, A2, A2
    note 120, C4, E4, A2
    note 120, C4, G4, A2
    note 120, A3, C4, A2
    note 120, C4, A2, A2
    note 120, C4, E4, A2
    note 120, C4, G4, A2
    note 120, B3, B2, A3
    note 120, D4, B2, A3
    note 120, Fs4, B2, A3
    note 120, A4, B2, A3
    note 120, B3, B2, Fs3
    note 120, D4, B2, Fs3
    note 120, Fs4, B2, Fs3
    note 120, A4, B2, Fs3
    note 120, A3, A2, G3
    note 120, C4, A2, G3
    note 120, E4, A2, G3
    note 120, G4, A2, G3
    note 120, A3, A2, E3
    note 120, C4, A2, E3
    note 120, E4, A2, E3
    note 120, G4, A2, E3
    note 120, B3, B2, Fs3
    note 120, D4, B2, Fs3
    note 120, Fs4, B2, Fs3
    note 120, A4, B2, Fs3
    note 120, B3, B2, A3
    note 120, D4, B2, A3
    note 120, Fs4, B2, A3
    note 120, A4, B2, A3
    note 120, B3, B2, B3
    note 120, D4, B2, B3
    note 120, Fs4, B2, B3
    note 120, A4, B2, B3
    note 120, B3, B2, B3
    note 120, D4, B2, B3
    note 120, Fs4, B2, B3
    note 120, A4, B2, B3
    note 120, B3, B2, B2
    note 120, C4, D4, B2
    note 120, B3, Fs4, B2
    note 120, C4, A4, B2
    note 120, B3, B2, B2
    note 120, C4, D4, B2
    note 120, B3, Fs4, B2
    note 120, C4, A4, B2
    note 120, As3, C4, As2
    note 120, Cs4, As2, As2
    note 120, C4, F4, As2
    note 120, Cs4, Gs4, As2
    note 120, As3, C4, As2
    note 120, Cs4, As2, As2
    note 120, C4, F4, As2
    note 120, Cs4, Gs4, As2
    note 120, As3, C4, As2
    note 120, Cs4, As2, As2
    note 120, C4, F4, As2
    note 120, Cs4, Gs4, As2
    note 120, As3, C4, F3
    note 120, Cs4, F3, F3
    note 120, C4, F4, F3
    note 120, Cs4, Gs4, F3
    note 120, B3, A2, A2
    note 120, B3, C4, A2
    note 120, B3, E4, A2
    note 120, B3, G4, A2
    note 120, B3, A2, A2
    note 120, B3, C4, A2
    note 120, B3, E4, A3
    note 120, B3, G4, A2
    note 120, B3, E3, E3
    note 120, B3, C4, G2
    note 120, B3, E4, G2
    note 120, B3, G4, G2
    note 120, B3, G2, Fs2
    note 120, B3, C4, G2
    note 120, B3, E4, G2
    note 120, B3, G4, G2
    note 120, B3, G2, Fs2
    note 120, B3, C4, G2
    note 120, B3, E4, G2
    note 120, B3, G4, G2
    note 120, B3, G2, Fs2
    note 120, B3, C4, G2
    note 120, B3, E4, G2
    note 120, B3, G4, G2
    note 120, A3, B3, G2
    note 120, A3, C4, G2
    note 120, A3, E4, G2
    note 120, A3, G4, G2
    note 120, A3, B3, G2
    note 120, A3, C4, G2
    note 120, A3, E4, G2
    note 120, A3, G4, G2
    note 240, Cs4, E4, A2
    note 240, B3, D4, A2
    note 240, A3, Cs4, A2
    note 240, B3, D4, A2
    note 240, G3, B3, G2
    note 240, A3, Cs4, G2
    note 240, Cs4, E4, G2
    note 240, A3, Cs4, G2
    note 120, As3, Cs4, Fs3
    note 120, As3, Fs3, Fs3
    note 120, Fs3, As3, Fs3
    note 120, As3, B3, Fs3
    note 120, As3, Fs3, Fs3
    note 120, Fs3, As3, Fs3
    note 120, A3, B3, E3
    note 120, A3, E3, E3
    note 120, E3, A3, E3
    note 120, A3, Cs4, E3
    note 120, A3, E3, E3
    note 120, E3, A3, E3
    note 120, As3, Cs4, Fs3
    note 120, As3, Fs3, Fs3
    note 120, Fs3, As3, Fs3
    note 120, As3, B3, Fs3
    note 120, As3, Fs3, Fs3
    note 120, Fs3, As3, Fs3
    note 120, A3, B3, E3
    note 120, A3, E3, E3
    note 120, E3, A3, E3
    note 120, Gs3, A3, E3
    note 120, A3, E3, E3
    note 120, E3, A3, E3
    note 120, As3, As2, F3
    note 120, As3, As2, F3
    note 120, As3, As2, F3
    note 120, As3, As2, F3
    note 120, Gs3, As2, Ds3
    note 120, As3, As2, F3
    note 120, Gs3, As2, Ds3
    note 120, As3, As2, F3
    note 120, Cs4, As2, Fs3
    note 120, As3, As2, Fs3
    note 120, As3, As2, Fs3
    note 120, As3, As2, Fs3
    note 120, Gs3, As2, Fs3
    note 120, As3, As2, Fs3
    note 120, Cs4, As2, Fs3
    note 120, As3, As2, Fs3
    note 120, Ds4, As2, Gs3
    note 120, C4, As2, Gs3
    note 120, Gs3, As2, Gs3
    note 120, F3, As2, Gs3
    note 120, Gs3, As2, Gs3
    note 120, C4, As2, Gs3
    note 120, Ds4, As2, Gs3
    note 120, Cs4, As2, Gs3
    note 120, C4, As2, Gs3
    note 120, Gs3, As2, Gs3
    note 120, As3, As2, As3
    note 120, As3, As2, As3
    note 120, As3, As2, As3
    note 120, As3, As2, As3
    note 120, As3, As2, As3
    note 120, As3, As2, As3
    note 120, As2, As3, As3
    note 120, As2, As3, As3
    note 120, As2, As3, As3
    note 240, Fs2, As2, As2
    note 240, Fs2, As2, As2
    note 120, F3, Gs3, As3
    note 120, Fs2, As2, As2
    note 120, Fs2, As2, As2
    note 120, F3, Gs3, As3
    note 120, Fs2, As2, As2
    note 120, Fs2, As2, As2
    note 120, F3, Gs3, As3
    note 120, Fs2, As2, As2
    note 480, Ds3, Gs3, A3
    note 120, Cs3, Gs3, F4
    note 120, Cs3, As3, D4
    note 120, Cs3, Gs3, D4
    note 120, Ds3, As3, Fs4
    note 120, Ds3, C4, F4
    note 120, Ds3, As3, E4
    note 120, Cs3, Gs3, F4
    note 120, Cs3, As3, Ds4
    note 120, Cs3, Gs3, D4
    note 120, Ds3, As3, Fs4
    note 120, Ds3, C4, F4
    note 120, Ds3, As3, E4
    note 240, Fs2, As2, As2
    note 240, Fs2, As2, As2
    note 120, F3, Gs3, As3
    note 120, Fs2, As2, As2
    note 120, Fs2, As2, As2
    note 120, F3, Gs3, As3
    note 120, Fs2, As2, As2
    note 120, Fs2, As2, As2
    note 120, F3, Gs3, As3
    note 120, Fs2, As2, As2
    note 480, G3, As3, C4
    note 120, Cs3, Gs3, F4
    note 120, Fs4, Cs3, As3
    note 120, F4, Cs3, Gs3
    note 120, As4, Ds3, As3
    note 120, Gs4, Ds3, C4
    note 120, G4, Ds3, As3
    note 120, Fs4, B2, Fs3
    note 120, E4, B2, Gs3
    note 120, Ds4, B2, Fs3
    note 120, Gs4, Cs3, Gs3
    note 120, Fs4, Cs3, As3
    note 120, F4, Cs3, Gs3
    note 120, E4, A2, E3
    note 120, D4, A2, Fs3
    note 120, Cs4, A2, E3
    note 120, Fs4, B2, Fs3
    note 120, E4, B2, Gs3
    note 120, Ds4, B2, Fs3
    note 120, Gs4, Cs3, Gs3
    note 120, Fs4, Cs3, As3
    note 120, F4, Cs3, Gs3
    note 120, As4, Ds3, As3
    note 120, Gs4, Ds3, C4
    note 120, G4, Ds3, As3
    note 120, C5, F3, C4
    note 120, As4, F3, D4
    note 120, A4, F3, C4
    note 120, As4, F3, D4
    note 120, C5, F3, C4
    note 120, As4, F3, D4
    note 120, A4, F3, C4
    note 120, As4, F3, D4
    note 120, C5, F3, C4
    note 120, As4, F3, D4
    note 120, A4, F3, C4
    note 120, As4, F3, D4
    note 120, C5, F3, C4
    note 120, As4, F3, D4
    note 120, A4, F3, C4
    note 120, As4, F3, D4
    note 2849, A4, F3, C4
    .word 0

zendproc

.data
pcm_table: