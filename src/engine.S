#include "zif.inc"
#include "pet.inc"
#include "globals.inc"

ZEROPAGE

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

.global e1d, e2d, e3d
.global e1b, e2b, e3b
.global e1v, e2v, e3v
.global e1c, e2c, e3c
.global e1t, e2t, e3t
.global e1p, e2p, e3p

e1b:        .fill 1 ; base pitch
e2b:        .fill 1
e3b:        .fill 1
e1d:        .fill 1 ; pitch delta
e2d:        .fill 1
e3d:        .fill 1
e1v:        .fill 1 ; base volume
e2v:        .fill 1
e3v:        .fill 1
e1p:        .fill 1 ; sample pointer
e2p:        .fill 1
e3p:        .fill 1
e1t:        .fill 1 ; tone
e2t:        .fill 1
e3t:        .fill 1
e4i:        .fill 1 ; drum instrument (reset after playing)
eindex:     .fill 1 ; how many voices are left for envelope processing

.global playing_flag, looping_flag
.global tempoticks, rowptr, rowno, patternno, seqindex

playing_flag: .fill 1 ; are we playing the current pattern?
looping_flag: .fill 1 ; are we looping the current pattern?
nextrow_flag: .fill 1 ; a N command was seen in the current row
key_flag:     .fill 1 ; a key was pressed
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
    lda #0x54               ; T1 continuous, T2 one-shot, SR under T2 control
    sta VIA_ACR

    lda #0xae               ; CB2 outputs SR pulses; lower case mode
    sta VIA_PCR

    lda #lo(SAMPLE_PERIOD/2) ; one bit is clocked out every _two_ T2 ticks
    sta VIA_T2C_L
    lda #hi(SAMPLE_PERIOD/2)
    sta VIA_T2C_H

    lda #<10000              ; T1 ticks every 10ms
    sta VIA_T1C_L
    lda #>10000
    sta VIA_T1C_H

    lda #0
    sta VIA_SR

    sta key_flag             ; no key is pressed

    lda #0xff
    sta playing_flag

    lda tempo
    sta tempoticks

    rts
zendproc

zproc stop_engine
    rts
zendproc

zproc silence_engine
    lda #0
    sta t1m
    sta t2m
    sta t3m
    sta t4ptr
    sta t4len
    sta e1v
    sta e1d
    sta e2v
    sta e3v
    rts
zendproc

zproc engine_tick
    ; Wait for the next SR interrupt.

    lda #0x04
    ;bit VIA_IFR
    ;zif ne
    ;    inc VRAM+34
    ;zendif
    ;stx VRAM+35

    zrepeat
        bit VIA_IFR
    zuntil ne
    sta VIA_IFR

    lda nextsample
    sta VIA_SR          ; play the previously calculated sample

    ; Note processing.

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
        inx
        stx t4ptr
    zendif

    ; Envelope processing.

    lda #0x40
    bit VIA_IFR
    zif ne
        sta VIA_IFR
        
        dec tempoticks

        ; Every 10ms tick, we need to update the envelopes. This is more work than will fit before the next
        ; shift register byte is due, so we split it into sections and handle it once every byte. Hopefully
        ; the user won't notice.

        lda #tick_processor_table_end - tick_processor_table
        sta eindex
    zendif

    ldx eindex
    zif ne
        dex
        dex
        stx eindex

        lda tick_processor_table+0, x
        sta w+0
        lda tick_processor_table+1, x
        sta w+1
        jmp (w)
    zendif
    rts

; Executed in reverse order!
tick_processor_table:
    .word tp_volume_envelope_3
    .word tp_volume_envelope_2
    .word tp_volume_envelope_1
    .word tp_pitch_envelope_3
    .word tp_pitch_envelope_2
    .word tp_pitch_envelope_1
    .word tp_advance_voice_3
    .word tp_advance_voice_2
    .word tp_advance_voice_1
    .word tp_check_for_keypress
tick_processor_table_end:
zendproc

zproc tp_check_for_keypress
    lda #0
    sta key_flag
    jsr is_key_pressed
    zif ne
        jsr is_key_pressed      ; debounce
        zif ne
            dec key_flag
        zendif
    zendif
    rts
zendproc

.macro tp_advance_voice voice
    zproc tp_advance_voice_\voice
        ldy e\voice\()t          ; get tone number
        lda e\voice\()p
        clc
        adc #1
        cmp repeatend, y
        zif eq
            lda repeatstart, y
        zendif
        sta e\voice\()p
        rts
    zendproc
.endm

tp_advance_voice 1
tp_advance_voice 2
tp_advance_voice 3

.macro tp_pitch_envelope voice
    zproc tp_pitch_envelope_\voice
        ; Locate the tone data.

        ldy e\voice\()t     ; get tone number
        lda tone_table_hi, y
        sta w+1
        lda tone_pitch_table_lo, y
        sta w+0

        ldy e\voice\()p     ; get sample pointer
        clc
        lda e\voice\()b     ; get base pitch
        adc (w), y          ; add delta from tone
        clc
        adc e\voice\()d     ; add pitch bend delta
        tax
        lda note_table, x   ; convert to period
        zif eq
            ; Out of bounds!
            lda e\voice\()t ; fall back to the base note
        zendif
        sta t\voice\()p

        rts
    zendproc
.endm

tp_pitch_envelope 1
tp_pitch_envelope 2
tp_pitch_envelope 3

.macro tp_volume_envelope voice
    zproc tp_volume_envelope_\voice
        ldy e\voice\()t         ; get tone number
        lda tone_table_hi, y
        sta w+1
        lda tone_volume_table_lo, y
        sta w+0

        clc
        lda e\voice\()v         ; get base volume
        ldy e\voice\()p         ; get sample pointer
        adc (w), y              ; add delta
        zif mi
            lda #0
        zendif
        cmp #0x10
        zif ge
            lda #0xf
        zendif
        sta t\voice\()m

        rts
    zendproc
.endm

tp_volume_envelope 1
tp_volume_envelope 2
tp_volume_envelope 3

zproc tone_table_hi
    i = 0
    .rept 16
        .byte (TONE_DATA + i*0x80)@mos16hi
        i = i + 1
    .endr
zendproc

zproc tone_pitch_table_lo
    i = 0
    .rept 16
        .byte (TONE_DATA + i*0x80)@mos16lo
        i = i + 1
    .endr
zendproc

zproc tone_volume_table_lo
    i = 0
    .rept 16
        .byte (TONE_DATA + i*0x80 + 0x40)@mos16lo
        i = i + 1
    .endr
zendproc

; Given a tone number in A, sets w to the address of its sample data.
; Preserves X/Y.

zproc get_tone_data_into_w
    pha
    lsr a
    clc
    adc #>TONE_DATA
    sta w+1             ; high byte

    pla
    lsr a
    lda #0
    ror a
    sta w+0             ; low byte
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

zproc process_row
    lda tempoticks
    zif eq
        lda tempo
        sta tempoticks

        lda rowno
        clc
        adc #1
        cmp patternlength
        zif eq
        nextrow:
            bit looping_flag
            zif pl
                ldx seqindex
                inx
                lda sequence, x
                zif mi              ; ff marks the end of the sequence
                    ldx #0
                    lda sequence+0
                zendif
                stx seqindex
                sta patternno
            zendif
            lda #0
        zendif
        sta rowno
        
        lda #0
        sta nextrow_flag
        jsr play_current_row
        bit looping_flag
        zif pl
            bit nextrow_flag
            bne nextrow
        zendif
    zendif
    rts
zendproc

zproc play_current_row
    jsr reset_row_pointer

    ldx #3                      ; voice count - 1
    zrepeat
        txa
        asl a
        tay

        lda (rowptr), y         ; base note
        iny
        cmp #FIRST_COMMAND
        blt is_note
        cmp #FIRST_COMMAND + ('O' - 'A')
        beq off_command
        cmp #FIRST_COMMAND + ('P' - 'A')
        beq pitchbend_command
        cmp #FIRST_COMMAND + ('V' - 'A')
        beq volume_command
        cmp #FIRST_COMMAND + ('N' - 'A')
        beq next_pattern_command
        cmp #FIRST_COMMAND + ('X' - 'A')
        beq stop_playing_command
    done:
        dex
    zuntil mi
    rts

is_note:
    cpx #3
    zif eq
        ; This is the drum channel. Bypass the envelope generator and just
        ; program the tone generator.

        tay
        lda drum_instrument_table+0, y
        sta t4ptr
        lda drum_instrument_table+1, y
        sta t4len
        jmp done
    zendif

    sta e1b, x

    lda (rowptr), y     ; base volume
    pha
    and #0x0f
    sta e1v, x

    pla
    and #0xf0
    lsr a
    lsr a
    lsr a
    lsr a
    sta e1t, x          ; tone

    lda #0
    sta e1p, x          ; sample pointer
    sta e1d, x          ; pitch delta

    jmp done

off_command:
    lda #0
    sta e1v, x          ; volume
    jmp done

next_pattern_command:
    dec nextrow_flag
    jmp done

stop_playing_command:
    lda #0
    sta playing_flag
    jmp done

pitchbend_command:
    lda (rowptr), y
    sta e1d, x
    jmp done

volume_command:
    lda (rowptr), y
    and #0x0f
    sta e1v, x
    jmp done
zendproc

zproc play_entire_song
    jsr draw_empty_dialogue

    ldx #2f-1f-1
    zrepeat
        lda 1f, x
        sta VRAM + 13*40 + 20 - (2f-1f)/2, x
        dex
    zuntil mi

    zrepeat
        zrepeat
            jsr is_key_pressed
        zuntil eq
        jsr is_key_pressed
    zuntil eq
    jsr scan_keyboard       ; so the keyboard sees a keyup

    jsr silence_engine
    jsr play_current_row
    jsr start_engine
    zrepeat
        jsr engine_tick
        jsr process_row
        bit playing_flag
        zbreakif pl
        bit key_flag
    zuntil mi               ; loop while not pressed
    jsr stop_engine
    
    zrepeat
        jsr getch
    zuntil eq
    rts

1:
    ; "Playing"
    .byte 80, 12, 1, 25, 9, 14, 7
2:
zendproc

zproc just_play_without_processing
    jsr start_engine
    dec key_flag            ; a key _is_ pressed
    zrepeat
        jsr engine_tick
        bit key_flag
    zuntil pl               ; loop until not pressed
    jsr scan_keyboard       ; so the keyboard sees a keyup
    zrepeat
        jsr engine_tick
        bit key_flag
    zuntil mi               ; loop until pressed
    jmp stop_engine
zendproc
