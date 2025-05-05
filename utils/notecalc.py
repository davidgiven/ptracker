import math
import statistics
from itertools import groupby
from collections import namedtuple
import os

# Produces a list of sample rates and errors for note values This lets us come
# up with a sample rate which is both fairly accurate and which also is low
# enough not to use up all our precious CPU bandwidth.

OCTAVES = 5
ERRORLIMIT = 10

Note = namedtuple('Note', ["note", "error"])
NoteSet = namedtuple('NoteSet', ["transpose", "samplerate", "notes", "error"])

allnotes = set()
for transpose in range(1*12, 1 * 12+1):
    for samplerate in range(8000, 20000):
        notes = []
        for n in range(24, 24 + (OCTAVES * 12)):
            n = n + transpose
            freq = (2 ** ((n - 69) / 12)) * 440
            period = int(round(samplerate / freq))
            realfreq = samplerate / period
            realmidi = 69 + 12 * math.log2(realfreq / 440)
            if period > 255:
                continue
            if period < 16:
                continue

            notes += [Note(note=n, error=abs((n - realmidi) * 100))]

        groups = [
            list(n[1])
            for n in groupby(notes, lambda x: x.error < ERRORLIMIT)
            if n[0]
        ]
        if not groups:
            continue
        longest = max(groups, key=len)
        allnotes.add(
            NoteSet(
                transpose=longest[0].note,
                samplerate=samplerate,
                notes=len(longest),
                error=statistics.mean([n.error for n in longest]),
            )
        )

s = sorted(allnotes, key=lambda x: (x.notes, -x.samplerate, -x.error))
for i in s:
    print(i.notes, i.samplerate, "%d-%d" % (i.transpose, i.transpose+i.notes), i.error)
