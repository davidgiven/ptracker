.macro pcm b1, brest:vararg
    b = \b1
    ; Reverse bits
    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4
    b = (b & 0xCC) >> 2 | (b & 0x33) << 2
    b = (b & 0xAA) >> 1 | (b & 0x55) << 1
    .byte b
    .ifnb \brest
        pcm \brest
    .endif
.endm

r = 1
.macro randomise
	.if !(r & 0x80)
		r = (r << 1) ^ 0x1d
	.else
		r = (r << 1)
	.endif
	r = r & 0xff
.endm

bitaccumulator = 0
bitcount = 0
.macro emitbit b1, brest:vararg
	bitaccumulator = (bitaccumulator << 1) | (\b1)
	bitcount = bitcount + 1
	.if bitcount == 8
		.byte bitaccumulator
		bitcount = 0
	.endif
	.ifnb \brest
		emitbit \brest
	.endif
.endm

.data
.global drum_instrument_table
drum_instrument_table:
	.byte bwoop_noise - pcm_table
	.byte beep_noise - pcm_table
	.byte kick_drum - pcm_table
	.byte snare_drum - pcm_table
	.byte highhat_drum - pcm_table
	.byte noise1_drum - pcm_table
	.byte noise2_drum - pcm_table
	.byte noise3_drum - pcm_table
	.byte noise4_drum - pcm_table
	.byte end_of_pcm_table - pcm_table

pcm_table:
 ; Borrowed from
 ; https://github.com/protodomemusic/mmml/blob/master/player-desktop/mmml-engine.c
bwoop_noise:
	pcm 0b10101010,0b10110110,0b10000111,0b11111000
	pcm 0b10000100,0b00110111,0b11101000,0b11000001
	pcm 0b00000111,0b00111101,0b11111000,0b11100000
	pcm 0b10010001,0b10000111,0b00000111,0b00001111
	pcm 0b00001111,0b00011011,0b00011110
beep_noise:
	pcm 0b10101010,0b00101010,0b00110011,0b00110011
	pcm 0b00110011,0b00110011,0b00110011,0b11001101
	pcm 0b11001100,0b11001100,0b11001100,0b10101100
	pcm 0b10011001,0b00110001,0b00110011
kick_drum:
	pcm 0b10010101,0b10110010,0b00000000,0b11100011
	pcm 0b11110000,0b00000000,0b11111111,0b00000000
	pcm 0b11111110,0b00000000,0b00000000,0b00000000
	pcm 0b11111111,0b11111111,0b11111111,0b00100101
	pcm 0b00000000,0b00000000,0b00000000,0b00000000
	pcm 0b11111111,0b11110111,0b11111111,0b11111111
	pcm 0b11111111,0b10111111,0b00010010,0b00000000
	pcm 0b10000000,0b00000000,0b00000000,0b00000000
	pcm 0b00000000,0b11101110,0b11111111,0b11111111
	pcm 0b11111111,0b11110111,0b11111111,0b11111110
snare_drum:
	pcm 0b10011010,0b10011010,0b10101010,0b10010110
	pcm 0b01110100,0b10010101,0b10001010,0b11011110
	pcm 0b01110100,0b10100000,0b11110111,0b00100101
	pcm 0b01110100,0b01101000,0b11111111,0b01011011
	pcm 0b01000001,0b10000000,0b11010100,0b11111101
	pcm 0b11011110,0b00010010,0b00000100,0b00100100
	pcm 0b11101101,0b11111011,0b01011011,0b00100101
	pcm 0b00000100,0b10010001,0b01101010,0b11011111
	pcm 0b01110111,0b00010101,0b00000010,0b00100010
	pcm 0b11010101,0b01111010,0b11101111,0b10110110
	pcm 0b00100100,0b10000100,0b10100100,0b11011010
highhat_drum:
	pcm 0b10011010,0b01110100,0b11010100,0b00110011
	pcm 0b00110011,0b11101000,0b11101000,0b01010101
	pcm 0b01010101
noise1_drum:
	; 32 samples of white noise, for hi hats and the like
	.rept 32
		randomise
		.byte r
	.endr
noise2_drum:
	; Again, but at half frequency.
	.rept 16
	 	randomise
		i = 0
		z = 0
		.rept 8
			z = z | (r & 1<<i)<<i | (r & 1<<i)<<(i+1)
			i = i + 1
		.endr
		.2byte z
	.endr
noise3_drum:
	; Again, but at quarter frequency.
	.rept 8
	 	randomise
		i = 0
		z = 0
		.rept 16
			z = z | (r & 1<<i)<<i | (r & 1<<i)<<(i+1)
			i = i + 1
		.endr
		.4byte z
	.endr
noise4_drum:
	; Again, but at one-eighth frequency.
	.rept 4
	 	randomise
		i = 0
		z = 0
		.rept 32
			z = z | (r & 1<<i)<<i | (r & 1<<i)<<(i+1)
			i = i + 1
		.endr
		.8byte z
	.endr
end_of_pcm_table:

	; kick (34)
	.byte 0b10010101,0b10110010,0b00000000,0b11100011
	.byte 0b11110000,0b00000000,0b11111111,0b00000000
	.byte 0b11111110,0b00000000,0b00000000,0b00000000
	.byte 0b11111111,0b11111111,0b11111111,0b00100101
	.byte 0b00000000,0b00000000,0b00000000,0b00000000
	.byte 0b11111111,0b11110111,0b11111111,0b11111111
	.byte 0b11111111,0b10111111,0b00010010,0b00000000
	.byte 0b10000000,0b00000000,0b00000000,0b00000000
	.byte 0b00000000,0b11101110,0b11111111,0b11111111
	.byte 0b11111111,0b11110111,0b11111111,0b11111110
	; snare (74)
	.byte 0b10011010,0b10011010,0b10101010,0b10010110
	.byte 0b01110100,0b10010101,0b10001010,0b11011110
	.byte 0b01110100,0b10100000,0b11110111,0b00100101
	.byte 0b01110100,0b01101000,0b11111111,0b01011011
	.byte 0b01000001,0b10000000,0b11010100,0b11111101
	.byte 0b11011110,0b00010010,0b00000100,0b00100100
	.byte 0b11101101,0b11111011,0b01011011,0b00100101
	.byte 0b00000100,0b10010001,0b01101010,0b11011111
	.byte 0b01110111,0b00010101,0b00000010,0b00100010
	.byte 0b11010101,0b01111010,0b11101111,0b10110110
	.byte 0b00100100,0b10000100,0b10100100,0b11011010