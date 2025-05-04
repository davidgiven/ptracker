#include "zif.inc"
#include "pet.inc"
#include "globals.inc"

ZEROPAGE

running_flag: .fill 1

.global t1, t2, t3
.global t1m, t2m, t3m
.global t1p, t2p, t3p
.global t4ptr, t4len

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

        lda #0                  ; T1 makes an interrupt every 65.536ms
        sta VIA_T1C_L
        sta VIA_T1C_H

        lda #0
        sta VIA_SR

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
    jmp (old_interrupt_vector)
1:
    rts
zendproc

