#include "pet.inc"
#include "zif.inc"
#include "globals.inc"

ZEROPAGE

.global scrptr, ctrl_flag, shift_flag, pending_key

scrptr:         .fill 2
cursor_flag:    .fill 1
keymap_ptr:     .fill 2
keyboard_state: .fill 10
shift_flag:     .fill 1
ctrl_flag:      .fill 1
pending_key:    .fill 1

zproc init_screen
    jsr detect_keyboard_type

    ldx #9
    lda #0xff
    zrepeat
        sta keyboard_state, x
        dex
    zuntil mi

    lda #0
    sta cursor_flag
    ldy #0
    jsr set_curptr_y
    jsr clear_screen

    lda #0xae       ; switch to lower case
    sta VIA_PCR
    rts
zendproc

zlproc detect_keyboard_type
    ; Detect the scancode table.

    lda 0xe0df
    cmp #0xbd           ; check for lda <abs>, x
    zif eq              ; third generation EDIT rom
        sec
        lda 0xe0e0
        sbc #79
        sta keymap_ptr+0
        lda 0xe0e1
        sbc #0
        sta keymap_ptr+1
        rts
    zendif

    lda 0xe69c
    cmp #0xbd           ; check for lda <abs>, x
    zif eq
        lda 0xe69d
        sta keymap_ptr+0
        lda 0xe69e
        sta keymap_ptr+1
        inc16 keymap_ptr
        rts
    zendif

    lda 0xe73f
    cmp #0xbd           ; check for lda <abs>, x
    zif eq              ; first-generation EDIT rom
        lda 0xe740
        sta keymap_ptr+0
        lda 0xe741
        sta keymap_ptr+1
        inc16 keymap_ptr
        rts
    zendif

bad_rom:
    ldx #0
    zrepeat
        lda 1f, x
        jsr CHROUT
        inx
        cpx #2f - 1f
    zuntil eq
    brk
1:
    .byte 13
    .ascii "BAD ROM"
    .byte 13
2:
zendproc

; Various print-char routines.

zproc print_h8
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr print_h4
    pla
    and #0x0f
.global print_h4
print_h4:
    tay
    lda hex_table, y
.global print_char
print_char:
    ldy #0
    sta (scrptr), y
    inc16 scrptr
    rts
zendproc

zproc print_space
    lda #' '
    jmp print_char
zendproc

zproc hex_table
    .ascii "0123456789"
    .byte 1, 2, 3, 4, 5, 6 ; PET screen codes for a-f
zendproc

; Move scrptr to the beginning of line Y

zproc set_scrptr_y
    lda screen_table_lo, y
    sta scrptr+0
    lda screen_table_hi, y
    sta scrptr+1
    rts
zendproc

zproc screen_table_hi
    i = 0
    .rept 25
        .byte hi(VRAM + i*40)
        i = i + 1
    .endr
zendproc

zproc screen_table_lo
    i = 0
    .rept 25
        .byte lo(VRAM + i*40)
        i = i + 1
    .endr
zendproc

; Advances/retards the screen pointer by A bytes.

zproc advance_scrptr
    clc
    adc scrptr+0
    sta scrptr+0
    zif cs
        inc scrptr+1
    zendif
    rts
zendproc

zproc retard_scrptr
    sec
    eor #0xff
    adc scrptr+0
    sta scrptr+0
    zif cc
        dec scrptr+1
    zendif
    rts
zendproc

zproc clear_screen
    jsr kernal_mode
    lda #147            ; clear screen
    jsr CHROUT
    jmp engine_mode
zendproc

; Move PNT to the beginning of line Y

zproc set_curptr_y
    ldx screen_table_lo, y
    lda screen_table_hi, y
    tay
; Moves the cursor to the address at YYXX.
.global move_cursor
move_cursor:
    stx PNT+0
    sty PNT+1
    lda #0
    sta PNTR
    rts
zendproc

zproc toggle_cursor
    ldy PNTR
    lda #0x80
    eor (PNT), y
    sta (PNT), y
    rts
zendproc

zproc cursor_on
    bit cursor_flag
    zif pl
        jsr toggle_cursor
        dec cursor_flag
    zendif
    rts
zendproc

zproc cursor_off
    bit cursor_flag
    zif mi
        jsr toggle_cursor
        inc cursor_flag
    zendif
    rts
zendproc

; Polls the keyboard but does not consume the key (can be run with the vsync
; interrupt disabled). Returns Z for no.

zproc is_key_pressed
    lda PIA1_PA
    and #0xf0
    sta PIA1_PA

    ; Everything about the PET keyboard is annoying. At least the first five
    ; rows are the same on both the business and graphics keyboards.

    lda PIA1_PB
    inc PIA1_PA
    and PIA1_PB
    inc PIA1_PA
    and PIA1_PB
    inc PIA1_PA
    and PIA1_PB
    inc PIA1_PA
    and PIA1_PB
    inc PIA1_PA
    and PIA1_PB
    cmp #0xff
    bne 1f

    ldy #0
    lda (keymap_ptr), y
    cmp #0x3d
    zif eq
        ; Graphics keyboard
    
        inc PIA1_PA
        lda PIA1_PB
        inc PIA1_PA
        and PIA1_PB
        cmp #0xff
        bne 1f

        inc PIA1_PA
        lda PIA1_PB
        ora #0x21           ; always treat the shift keys as if they're released
        cmp #0xff
        bne 1f

        inc PIA1_PA
        lda PIA1_PB
        ora #0x01           ; always treat RVS/CTRL as if it's released
        cmp #0xff
        rts
    zendif

    ; Business keyboard.

    inc PIA1_PA
    lda PIA1_PB
    ora #0x41           ; always treat the shift keys as if they're released
    cmp #0xff
    bne 1f

    inc PIA1_PA
    ldx PIA1_PB
    inx
    bne 1f

    inc PIA1_PA
    lda PIA1_PB
    ora #0x01           ; always treat RVS/CTRL as if it's released
    cmp #0xff
    bne 1f

    inc PIA1_PA
    lda PIA1_PB
    cmp #0xff
1:
    rts
zendproc

; Given a subpixel coordinate in X, Y, prepare (scrptr)+y to access it, set
; q to the subpixel mask, and read and decode the byte itself.

zproc access_subpixel_xy
    stx w+0
    sty w+1

    ; Adjust coordinates and compute the subpixel mask.

    lda #0
    lsr w+1
    rol a
    lsr w+0
    rol a
    tax
    lda 1f, x
    sta q+0

    ; Read and decode the subpixel itself.

    ldy w+1
    jsr set_scrptr_y
    ldy w+0
    lda (scrptr), y
    jmp decode_subpixel

1:
    .byte 1, 2, 4, 8
zendproc

; Uses w and q.

zproc plot_subpixel
    txa
    pha
    tya
    pha
    
    jsr access_subpixel_xy
    ora q
    tax
    lda subpixel_table, x
    sta (scrptr), y
    
    pla
    tay
    pla
    tax
    rts
zendproc

; Uses w and q.

zproc unplot_subpixel
    txa
    pha
    tya
    pha

    jsr access_subpixel_xy
    sta q+1
    lda q
    eor #0x0f
    and q+1
    tax
    lda subpixel_table, x
    sta (scrptr), y
    
    pla
    tay
    pla
    tax
    rts
zendproc

zproc subpixel_table
    .byte 32, 126, 124, 226, 123, 97, 255, 236
    .byte 108, 127, 225, 251, 98, 252, 254, 160
zendproc

zproc decode_subpixel
    ldx #15
    zrepeat
        cmp subpixel_table, x
        beq 1f
        dex
    zuntil mi
    ldx #0
1:
    txa
    rts
zendproc

zproc draw_empty_dialogue
    ldy #10
    jsr set_scrptr_y
    ldy #39
    lda #0x63
    zrepeat
        sta (scrptr), y
        dey
    zuntil mi

    ldy #11
    jsr set_scrptr_y
    ldy #40*5
    lda #0x20
    zrepeat
        dey
        sta (scrptr), y
    zuntil eq

    ldy #16
    jsr set_scrptr_y
    ldy #39
    lda #0x64
    zrepeat
        sta (scrptr), y
        dey
    zuntil mi
    
    rts
zendproc

; YYXX = message; A = indent
zproc draw_dialogue
    sta p+0     ; text indent
    stx w+0     ; pointer to message
    sty w+1

    jsr draw_empty_dialogue

    ; Draw the 'dialogue box' with the message in it.

    ldy #11
    jsr set_scrptr_y
    lda #0
    sta p+1         ; offset into message
    zloop
        ldy p+1
        lda (w), y  ; read char from message
        zbreakif eq

        ldy p+0
        sta (scrptr), y ; write char to screen

        inc p+0
        inc p+1
    zendloop

    rts
zendproc

; Returns the length of the entered text in Y.
; YYXX = message; A = indent

zproc text_prompt
    jsr draw_dialogue

    ; Draw the text entry line.

    ldy #15
    jsr set_scrptr_y
    ldy #12
    lda #0x63
    zrepeat
        sta (scrptr), y
        iny
        cpy #28
    zuntil eq

    lda #62
    sta VRAM + 14*40 + 10

    ; The editor itself.

    lda #<(VRAM + 14*40 + 12)
    sta PNT+0
    lda #>(VRAM + 14*40 + 12)
    sta PNT+1

    ldy #0              ; X position
    sty PNTR
    zloop
        jsr cursor_on
        zrepeat
            jsr getch
        zuntil ne

        pha
        jsr cursor_off
        pla

        ldy PNTR

        cmp #0x0d ; return
        zbreakif eq

        cmp #0x03 ; escape
        zif eq
        1:
            ldy #0
            sta FNLEN
            rts
        zendif

        cmp #0x14 ; delete
        zif eq
            cpy #0
            zif ne
                dey
                sty PNTR
                lda #0x20
                sta (PNT), y
                zcontinue
            zendif
        zendif

        cmp #32
        zif ge
            cmp #127
            zif lt
                cpy #16
                zif ne
                    sta text_buffer, y
                    jsr petscii_to_screencode
                    sta (PNT), y
                    inc PNTR
                zendif
            zendif
        zendif
    zendloop
    lda #0
    sta text_buffer, y
    lda #<text_buffer
    sta FNADR+0
    lda #>text_buffer
    sta FNADR+1
    sty FNLEN
    rts
zendproc
.common text_buffer, 16+1

zproc display_message
    jsr draw_dialogue

    ldy #(2f-1f)-1
    zrepeat
        lda 1f, y
        sta VRAM+ 15*40 + 20 - (2f-1f)/2, y
        dey
    zuntil mi

    zrepeat
        jsr getch
    zuntil ne
    rts

1:
    .byte 60, 16, 18, 5, 19, 19, 32, 11, 5, 25, 62
2:
zendproc

zproc invalid_value_error
    lda #20 - (2f-1f)/2
    ldx #<1f
    ldy #>1f
    jmp display_message

1:
    ; "Invalid value"
    .byte 73, 14, 22, 1, 12, 9, 4, 32, 22, 1, 12, 21, 5
2:
    .byte 0
zendproc

zproc scan_keyboard
    lda PIA1_PA
    and #0xf0
    sta PIA1_PA

    zloop
        zrepeat
            lda PIA1_PA         ; get row being probed
            cmp PIA1_PA         ; debounce
        zuntil eq
        and #0x0f
        cmp #10
        zbreakif eq
        tay

        lda PIA1_PB
        tax
        eor keyboard_state, y
        zif ne
            ; Any set bits in A correspond to a key which has changes state.
            ; The corresponding bit in X tells us whether it went up or down.

            stx keyboard_state, y
            stx p+1

            pha
            tya
            eor #0xff       ; compute 9-A, because the scancode table is backwards
            sec
            adc #9
            asl a
            asl a
            asl a
            tay             ; compute row*8 to get base of row
            pla

            zrepeat
                asl a
                zif cs
                    pha
                    lda (keymap_ptr), y ; get scancode
                    jsr change_key_state
                    pla
                zendif
                asl p+1
                iny
                tax         ; set flags from A
            zuntil eq       ; no more bits set, give up
        zendif

        inc PIA1_PA         ; next row
    zendloop
    rts
zendproc
        
; A is the scancode; the top bit of p+1 is _clear_ if it's down.
; Don't corrupt Y.

zlproc change_key_state
    cmp #0xff
    zif ne                  ; no key
        cmp #0x00               ; shift
        zif eq
            ldx #0xff
            bit p+1
            zif mi
                inx
            zendif
            stx shift_flag
            rts
        zendif

        cmp #0x12               ; ctrl
        zif eq
            ldx #0xff
            bit p+1
            zif mi
                inx
            zendif
            stx ctrl_flag
            rts
        zendif

        ; Otherwise, it's a typing key.

        bit p+1
        zif pl
            sta pending_key
        zendif
    zendif
    rts
zendproc

; Fetches a character from the kernal, like GETIN, but with fake-ctrl-key mapping.

zproc getch
    lda pending_key
    zif eq
        jsr scan_keyboard
        lda pending_key
    zendif
    
    zif ne                  ; if key pressed
        php
        and #0x7f               ; remove non-shiftable flag bit
        plp
        zif pl                  ; if shiftable
            bit shift_flag      ; if shift pressed
            zif mi
                ora #0x80
            zendif
        zendif
    zendif

    ldx #0
    stx pending_key
    tax                     ; set flags
    rts
zendproc

zproc petscii_to_screencode
    cmp #0x20
    bcc rev

    cmp #0x60
    bcc b1

    cmp #0x80
    bcc b2

    cmp #0xa0
    bcc b3

    cmp #0xc0
    bcc b4

    cmp #0xff
    bcc rev

    lda #0x7e
    bne end

b2:
	and #0x5f		; if A=96..127 then strip bits 5 and 7
    bne end
b3:
	ora #0x40		; if A=128..159, then set bit 6
    bne end
b4:
	eor #0xc0		; if A=160..191 then flip bits 6 and 7
    bne end
b1:
	and #0x3f		; if A=32..95 then strip bits 6 and 7
    .byte 0x2c      ; BIT <abs>; skip next two bytes
rev:
	eor #0x80		; flip bit 7 (reverse on when off and vice versa)
end:
    rts
zendproc

; Parses a two-character hex string in the text buffer and returns it in A. Sets
; C on error.

zproc parse_hex
    lda FNLEN
    beq 1f          ; reject empty strings
    cmp #3
    bge 1f          ; reject too-long strings

    lda text_buffer+0
    jsr verify_hex
    bcs 1f

    lda text_buffer+1
    zif ne
        jsr verify_hex
        bcs 1f
    zendif

    lda text_buffer+0
    jsr decode_char

    ldx text_buffer+1
    zif ne
        asl a
        asl a
        asl a
        asl a
        sta p

        lda text_buffer+1
        jsr decode_char
        ora p
    zendif

    tax             ; set flags from A
    clc
    rts

decode_char:
    sec
    sbc #'0'
    cmp #10
    zif ge
        sbc #'A'-'0'-10
    zendif

1:
    sec
    rts
zendproc

zlproc verify_hex
    cmp #'0'
    zif ge
        cmp #'9'+1
        blt 1f ; bcc

        cmp #'A'
        zif ge
            cmp #'F'+1
            blt 1f ; bcc
        zendif
    zendif
1:
    rts
zendproc