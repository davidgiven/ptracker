import math
import statistics
from types import SimpleNamespace as ns
from itertools import groupby

# Produces a list of sample rates and errors for note values This lets us come
# up with a sample rate which is both fairly accurate and which also is low
# enough not to use up all our precious CPU bandwidth.

OCTAVES = 4
ERRORLIMIT = 15

allnotes = []
for transpose in range(0, 2 * 12):
    for samplerate in range(1000, 10000):
        notes = []
        for n in range(24 + transpose, 24 + transpose + (OCTAVES * 12)):
            freq = (2 ** ((n - 69) / 12)) * 440
            period = int(round(samplerate / freq))
            realfreq = samplerate / period
            realmidi = 69 + 12 * math.log2(realfreq / 440)
            if period > 255:
                continue

            notes += [ns(note=n, error=abs((n - realmidi) * 100))]

        groups = [
            list(n[1])
            for n in groupby(notes, lambda x: x.error < ERRORLIMIT)
            if n[0]
        ]
        if not groups:
            continue
        longest = max(groups, key=len)
        allnotes += [
            ns(
                transpose=transpose,
                samplerate=samplerate,
                notes=longest,
                error=statistics.mean([n.error for n in longest]),
            )
        ]

s = sorted(allnotes, key=lambda x: (len(x.notes), -x.error))
# print(s)
# bylen = groupby(allnotes, lambda x: len(x.notes))
# print(list(bylen))
# bylen = [ns(basenote=x[0], len=len(x[1][0]), notes=x[1][0]) for x in bylen]
# bylen = sorted(bylen, key=lambda x: x[0])
for i in s:
    print(len(i.notes), i.samplerate, i.transpose, i.error)
