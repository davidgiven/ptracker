/* This is a hacked-up port of garfield's port of Tricky's compressor from here:
 * https://www.stardot.org.uk/forums/viewtopic.php?p=333389&hilit=compressor#p333389
 */

#include "globals.inc"
#include "zif.inc"

; There is a commented out INC after .done, that is only useful if you have more than 2 consecutive compressed blocks.
; Adding the final INC would increase the size of this code from 72 (+ RTS) bytes to 78, 79 including the RTS.
; The code could be prefixed with stx/sty to either src or dst, if that is used multiple times.
; The decompress will fail if wrapping arround to &0000 starts with a RAW sequence - see #1

#define decompress_src w
#define decompress_dst p
#define decompress_tmp q

zproc decompress
	ldx #0                  ; (zp,x) will be used to access (zp,0)
for:
	lda (decompress_src,x)  ; next control byte
	beq done                ; 0 signals end of decompression
	bpl copy_raw            ; msb=0 means just copy this many bytes from source
	clc
	adc #0x80 + 2           ; flip msb, then add 2, we wont request 0 or 1 as that wouldn't save anything
	sta decompress_tmp      ; count of bytes to copy (>= 2)
	ldy #1                  ; byte after control is offset
	lda (decompress_src),y  ; offset from current src - 256
	tay

    lda decompress_src  ; advance src past the control byte and offset
    clc
    adc #2
    sta decompress_src
    zif cs
        inc decompress_src+1
    zendif

copy_previous:             ; copy tmp bytes from dst - 256 + offset
	dec decompress_dst+1    ; -256
	lda (decompress_dst),y  ; +y
	inc decompress_dst+1    ; +256
	sta (decompress_dst,x)  ; +0

    inc16 decompress_dst  ; INC dst (used for both src of copy (-256) and dst)

	dec decompress_tmp      ; count down bytes to copy
	bne copy_previous
	beq for                 ; after copying, go back for next control byte

copy_raw:
	tay                     ; bytes to copy from src
copy:
    inc16 decompress_src  ; INC src (1st time past control byte)

	dey
	bmi for
	lda (decompress_src,x)  ; copy bytes
	sta (decompress_dst,x)

    inc16 decompress_dst
	bne copy                ; rest of bytes ; #1 replace with jmp if wrapping back to &0000 is required
done:
    rts
zendproc
