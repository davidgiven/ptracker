from build.ab import export, simplerule
from build.llvm import llvmrawprogram

simplerule(
    name="midinote_tab",
    ins=["src/midinote.py"],
    outs=["=midinote.S"],
    commands=["python3 $[ins] > $[outs]"],
    label="MIDINOTE",
)

simplerule(
    name="kick_inc",
    ins=["src/to3bit.py", "drums/kick.wav"],
    outs=["=kick.inc"],
    commands=["python3 $[ins] > $[outs]"],
    label="TO3BIT"
)

llvmrawprogram(
    name="ptracker_elf",
    linkscript="src/pet.ld",
    srcs=[
        ".+midinote_tab",
        ".+kick_inc",
        "include/pet.inc",
        "include/zif.inc",
        "src/globals.inc",
        "src/main.S",
        "src/pcmdata.S",
    ],
)

simplerule(
    name="ptracker",
    ins=[".+ptracker_elf"],
    outs=["=ptracker.prg"],
    commands=["$(LLVM)/llvm-objcopy --output-target=binary $[ins] $[outs]"],
    label=["ELFTOPRG"],
)

export(
    name="all",
    items={"p.elf": ".+ptracker_elf", "p": ".+ptracker"},
)
