import math

# Produces a list of sample rates and errors for note values This lets us come
# up with a sample rate which is both fairly accurate and which also is low
# enough not to use up all our precious CPU bandwidth.

OCTAVES = 4

for samplerate in range(4000, 15000):
    cerror = 0
    for n in range(24, 24+(OCTAVES*12)):
        freq = (2 ** ((n-69)/12))*440
        period = int(round(samplerate / freq))
        if (period > 255):
            period = 1
        realfreq = samplerate/period
        realmidi = 69 + 12*math.log2(realfreq / 440)

        cerror += abs((n - realmidi)*100)
    print(cerror, samplerate)
