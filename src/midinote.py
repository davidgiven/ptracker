print("""
.global midinote_hi, midinote_lo
.data
""")

def period(n):
    freq = (2 ** ((n-69)/12))*440
    return int(1e6 / freq)

print("midinote_lo:")
for n in range(21, 109):
    p = period(n)
    print(f" .byte {p & 0xff}")

print("midinote_hi:")
for n in range(21, 109):
    p = period(n)
    print(f" .byte {p >> 8}")