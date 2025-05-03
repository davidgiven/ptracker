from build.ab import export, simplerule
from build.llvm import llvmrawprogram

simplerule(
    name="midinote_tab",
    ins=["src/midinote.py", "src/samplerate.py"],
    outs=["=midinote.S"],
    commands=["python3 $[ins[0]] > $[outs]"],
    label="MIDINOTE",
)

llvmrawprogram(
    name="ptracker_elf",
    linkscript="src/pet.ld",
    srcs=[
        ".+midinote_tab",
        "include/pet.inc",
        "include/zif.inc",
        "src/globals.inc",
        "src/main.S",
        "src/pcmdata.S",
        "src/samplerate.py",
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
