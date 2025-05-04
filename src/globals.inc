
.macro ZEROPAGE
    .section .zp, "zax", @nobits
.endm

#define lo(n) ((n) & 0xff)
#define hi(n) ((n)>>8 & 0xff)

.macro inc16 var:vararg
    inc 0+\var
    zif eq
        inc 1+\var
    zendif
.endm

.macro dec16 var:vararg
    lda 0+\var
    zif eq
        dec 1+\var
    zendif
    dec 0+\var
.endm

#define BYTE .byte

; One pattern is 256 bytes.
SEQUENCE_LENGTH = 128
NUM_STEPS = 32
NOTE_LENGTH = 2 ; pitch, volume/tone; or: command, param
MAX_PATTERNS = 70
NUM_VOICES = 4
TONE_SAMPLES = 64

; Notes

NUM_PITCHES = 201
FIRST_COMMAND = 256-26

ROW_LENGTH = NOTE_LENGTH * NUM_VOICES


.extern midinote_table

.zeropage w
.zeropage scrptr

.extern sequence
.extern tempo
.extern patternlength
.extern numpatterns
.extern sequencelength

.extern pcm_table

#define G9  127
#define Fs9 126
#define F9  125
#define E9  124
#define Ds9 123
#define D9  122
#define Cs9 121
#define C9  120
#define B8  119
#define As8 118
#define A8  117
#define Gs8 116
#define G8  115
#define Fs8 114
#define F8  113
#define E8  112
#define Ds8 111
#define D8  110
#define Cs8 109
#define C8  108
#define B7  107
#define As7 106
#define A7  105
#define Gs7 104
#define G7  103
#define Fs7 102
#define F7  101
#define E7  100
#define Ds7 99
#define D7  98
#define Cs7 97
#define C7  96
#define B6  95
#define As6 94
#define A6  93
#define Gs6 92
#define G6  91
#define Fs6 90
#define F6  89
#define E6  88
#define Ds6 87
#define D6  86
#define Cs6 85
#define C6  84
#define B5  83
#define As5 82
#define A5  81
#define Gs5 80
#define G5  G5
#define Fs5 78
#define F5  77
#define E5  76
#define Ds5 75
#define D5  74
#define Cs5 73
#define C5  72
#define B4  71
#define As4 70
#define A4  69
#define Gs4 68
#define G4  67
#define Fs4 66
#define F4  65
#define E4  64
#define Ds4 63
#define D4  62
#define Cs4 61
#define C4  60
#define B3  59
#define As3 58
#define A3  57
#define Gs3 56
#define G3  55
#define Fs3 54
#define F3  53
#define E3  52
#define Ds3 51
#define D3  50
#define Cs3 49
#define C3  48
#define B2  47
#define As2 46
#define A2  45
#define Gs2 44
#define G2  43
#define Fs2 42
#define F2  41
#define E2  40
#define Ds2 39
#define D2  38
#define Cs2 37
#define C2  36
#define B1  35
#define As1 34
#define A1  33
#define Gs1 32
#define G1  31
#define Fs1 30
#define F1  29
#define E1  28
#define Ds1 27
#define D1  26
#define Cs1 25
#define C1  24
#define B0  23
#define As0 22
#define A0  21
