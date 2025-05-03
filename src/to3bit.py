import subprocess
import sys

SAMPLERATE = 16000 / 2

p = subprocess.Popen(
    f"sox {sys.argv[1]} -r {SAMPLERATE} -c 1 -t u1 -",
    shell=True,
    stdout=subprocess.PIPE,
)
while True:
    b = p.stdout.read(2)
    if len(b) != 2:
        break
    b1 = (b[0] & 0xE0) >> 5
    b2 = (b[1] & 0xE0) >> 5
    bb = b1 | (b2 << 4)

    print(f".byte {hex(bb)}")
p.stdout.close()
