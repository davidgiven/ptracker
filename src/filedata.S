#include "globals.inc"
#include "pet.inc"
#include "zif.inc"

.global sequence, tempo, patternlength, numpatterns, sequencelength

zproc filedata, .filedata
sequence:       .fill 128
tempo:          .fill 1
patternlength:  .fill 1
numpatterns:    .fill 1
sequencelength: .fill 1
    .align 0x100
patterns:
zendproc
