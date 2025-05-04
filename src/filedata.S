#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

.global MUSIC_DATA, PATTERN_DATA
.global sequence, tempo, patternlength, numpatterns, sequencelength

zproc filedata, .filedata
MUSIC_DATA:
sequence:       .fill 128
tempo:          .fill 1
patternlength:  .fill 1
numpatterns:    .fill 1
sequencelength: .fill 1
samplespeed:    .fill 16
pitchscale:     .fill 16
repeatstart:    .fill 16
repeatend:      .fill 16
    .align 0x100
TONE_DATA:      .fill TONE_SAMPLES*2*16
PATTERN_DATA:
zendproc

zproc reset_file

zendproc
