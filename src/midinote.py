from samplerate import SAMPLE_FREQ
import math

print(
    """
#include "zif.inc"
zproc note_table
"""
)

# Calculates the mapping between our internal note numbers (one third of a
# semitone with 0 being MIDI note 24) and the intervals that the timer is
# programmed with.

TRANSPOSE = 0


def period(n):
    freq = (2 ** ((n - 69) / 12)) * 440
    return int(SAMPLE_FREQ / freq)


def notename(midi):
    octave = int(midi / 12) - 1
    o = int(midi%12)*2
    return "C C#D D#E F F#G G#A A#B "[o:o+2] + f"{octave}"


n = TRANSPOSE
for count in range(0, 256):
    midinote = 24 + (n / 3)
    freq = (2 ** ((midinote - 69) / 12)) * 440
    period = int(round(SAMPLE_FREQ / freq))

    realfreq = SAMPLE_FREQ / period
    realmidi = 69 + 12 * math.log2(realfreq / 440)

    if (period < 16) or (period > 255):
        period = 0

    if (n % 3) == 0:
        print(
            f" .byte {period} ; freq {freq:.1f}Hz midi note {midinote} {notename(midinote)}, error {(midinote-realmidi)*100:.2f} cents"
        )
    else:
        print(f" .byte {period}")

    n = n + 1

print("zendproc")
