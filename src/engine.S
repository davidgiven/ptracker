#include "zif.inc"
#include "pet.inc"
#include "globals.inc"

ZEROPAGE

running_flag: .fill 1

.global t1, t2, t3
.global t1m, t2m, t3m
.global t1p, t2p, t3p
.global t4ptr, t4len

t1:         .fill 1 ; current counter
t2:         .fill 1
t3:         .fill 1
t1m:        .fill 1 ; 'mark' time
t2m:        .fill 1
t3m:        .fill 1
t1p:        .fill 1 ; 'period' time
t2p:        .fill 1
t3p:        .fill 1
t4ptr:      .fill 1 ; PCM pointer
t4len:      .fill 1 ; PCM max
nextsample: .fill 1

.global e1b, e2b, e3b
.global e1v, e2v, e3v
.global e1c, e2c, e3c
.global e1t, e2t, e3t

e1b:        .fill 1 ; base pitch
e2b:        .fill 1
e3b:        .fill 1
e1v:        .fill 1 ; base volume
e2v:        .fill 1
e3v:        .fill 1
e1c:        .fill 1 ; counter
e2c:        .fill 1
e3c:        .fill 1
e1t:        .fill 1 ; tone
e2t:        .fill 1
e3t:        .fill 1

.global playing_flag, looping_flag
.global tempoticks, rowptr, rowno, patternno, seqindex

playing_flag: .fill 1 ; are we playing the current pattern?
looping_flag: .fill 1 ; are we looping the current pattern?
tempoticks: .fill 1 ; number of ticks left until next row
rowptr:     .fill 2 ; pointer to current row
rowno:      .fill 1 ; current row number
patternno:  .fill 1 ; current pattern number
seqindex:   .fill 1 ; current index into the sequence

; Match this with the value in midinote.py.
#include "samplerate.py"
SAMPLE_PERIOD = 1000000 / SAMPLE_FREQ

BITRATE = 3

.comm old_interrupt_vector, 2

zproc start_engine
    bit running_flag
    zif pl
        sei

        lda #0xbc
        sta PIA1_CRB            ; disable VSYNC interrupt

        lda #0x54               ; T1 continuous, T2 one-shot, SR under T2 control
        sta VIA_ACR

        lda #0xae               ; CB2 outputs SR pulses; lower case mode
        sta VIA_PCR

        lda #0x84
        sta VIA_IER             ; generate software interrupts on SR empty

        lda IRQ_VECTOR+0
        sta old_interrupt_vector+0
        lda IRQ_VECTOR+1
        sta old_interrupt_vector+1

        lda #<interrupt_handler ; set interrupt handler vector
        sta IRQ_VECTOR+0
        lda #>interrupt_handler
        sta IRQ_VECTOR+1

        lda #lo(SAMPLE_PERIOD/2) ; one bit is clocked out every _two_ T2 ticks
        sta VIA_T2C_L
        lda #hi(SAMPLE_PERIOD/2)
        sta VIA_T2C_H

        lda #<5000              ; T1 ticks every 5ms
        sta VIA_T1C_L
        lda #>5000
        sta VIA_T1C_H

        lda #0
        sta VIA_SR

        lda tempo
        sta tempoticks

        dec running_flag
        lda #'Y'
        sta VRAM+39
        cli
    zendif
    rts
zendproc

zproc stop_engine
    bit running_flag
    zif mi
        sei

        lda #0xbd               ; enable VSYNC interrupt
        sta PIA1_CRB

        lda #0x04
        sta VIA_IER             ; disable SR software interrupts

        lda old_interrupt_vector+0 ; restore old interrupt handler
        sta IRQ_VECTOR+0
        lda old_interrupt_vector+1
        sta IRQ_VECTOR+1

        inc running_flag
        lda #'N'
        sta VRAM+39

        cli
    zendif
    rts

force_irq:
    php
    jmp (IRQ_VECTOR)
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
        
zproc keyboard_interrupt
    ; Force an immediate VSYNC interrupt.

    lda #>1f
    pha
    lda #<1f
    pha
    php                     ; P
    php                     ; A
    php                     ; Y
    php                     ; X
    sei
    jmp (old_interrupt_vector)
1:
    rts
zendproc

; Compute rowptr based on patternno and rowno.

zproc reset_row_pointer
    lda patternno
    clc
    adc #>PATTERN_DATA
    sta rowptr+1
    lda rowno
    asl a           ; multiply by eight, = ROW_LENGTH
    asl a
    asl a
    sta rowptr+0
    rts
zendproc

zproc engine_tick
    inc VRAM+37

    lda #0x40
    bit VIA_IFR             ; about 15 times per second
    zif ne
        sta VIA_IFR
        inc VRAM+36

        ; Process the envelope.

        ldx #2                ; voice count - 1
        zrepeat
            sei
            ldy e1b, x        ; get base note
            lda note_table, y ; convert to period
            sta t1p, x        ; update playing period

            lda e1v, x        ; get base volume
            sta t1m, x        ; update playing volume
            cli

            dex
        zuntil mi

        ; If playing, process the pattern.

        bit playing_flag
        zif mi
            dec tempoticks
            zif eq
                lda tempo
                sta tempoticks
                inc VRAM+35

                lda rowno
                clc
                adc #1
                and #NUM_STEPS-1
                zif eq
                    ldx seqindex
                    inx
                    lda sequence, x
                    cmp #0xff   ; marks the end of the sequence
                    zif eq
                        ldx #0
                        lda sequence+0
                    zendif
                    stx seqindex
                    sta patternno
                    lda #0
                zendif
                sta rowno
                
                jsr play_current_row
                sec
                rts
            zendif
        zendif
    zendif
    clc

    rts
zendproc

zproc play_current_row
    jsr reset_row_pointer

    ldx #2                      ; voice count - 1
    zrepeat
        txa
        asl a
        tay

        lda (rowptr), y         ; base note
        iny
        cmp #NUM_PITCHES
        zif lt
            sta e1b, x

            lda (rowptr), y     ; base volume
            pha
            and #0x0f
            sta e1v, x
            and #0xf0
            lsr a
            lsr a
            lsr a
            lsr a
            sta e1t, x          ; tone

            pla
            lda #0
            sta e1c, x          ; counter
        zendif

        dex
    zuntil mi
    rts
zendproc
