from samplerate import SAMPLE_FREQ, OCTAVES
import math

print("""
#include "zif.inc"
zproc note_table
""")

# Calculates the mapping between our internal note numbers (one third of a
# semitone with 0 being MIDI note 24) and the intervals that the timer is
# programmed with.

TRANSPOSE = 36

def period(n):
    freq = (2 ** ((n-69)/12))*440
    return int(SAMPLE_FREQ / freq)

for n in range(0, OCTAVES*12*3):
    n = n + TRANSPOSE
    midinote = 24 + (n/3)
    freq = (2 ** ((midinote-69)/12))*440
    period = int(round(SAMPLE_FREQ / freq))

    realfreq = SAMPLE_FREQ/period
    realmidi = 69 + 12*math.log2(realfreq / 440)

    if (n % 3) == 0:
        print(f" .byte {period} ; freq {freq:.1f}Hz midi note {midinote}, error {(midinote-realmidi)*100:.2f} cents")
    else:
        print(f" .byte {period}")

print("zendproc")
