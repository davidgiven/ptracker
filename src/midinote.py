from samplerate import SAMPLE_FREQ

print("""
.global midinote_table
.data
""")

def period(n):
    freq = (2 ** ((n-69)/12))*440
    return int(SAMPLE_FREQ / freq)

print("midinote_table:")
for n in range(21, 109):
    p = period(n)
    if p < 256:
        print(f" .byte {p}")
    else:
        print(" .byte 0")
