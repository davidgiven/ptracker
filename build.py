from build.ab import export, simplerule
from build.c import hostcxxprogram
from build.llvm import llvmrawprogram

simplerule(
    name="midinote_tab",
    ins=["src/midinote.py", "src/samplerate.py"],
    outs=["=midinote.S"],
    commands=["python3 $[ins[0]] > $[outs]"],
    label="MIDINOTE",
)

hostcxxprogram(name="compressor", srcs=["utils/compressor.cpp"])

SCREENS = ["toneeditor", "patterneditor"]

compressed_screens = []
for b in SCREENS:
    compressed_screens += [simplerule(
        name=f"compressed_{b}",
        ins=[".+compressor", f"screens/{b}.prg"],
        outs=[f"={b}_compressed.inc"],
        commands=["tail -c +8194 $[ins[1]] | head -c 1000 | $[ins[0]] > $[outs]"],
        label="COMPRESS",
    )]

llvmrawprogram(
    name="ptracker_elf",
    linkscript="src/pet.ld",
    srcs=[
        ".+midinote_tab",
        "include/pet.inc",
        "include/zif.inc",
        "src/globals.inc",
        "src/engine.S",
        "src/filedata.S",
        "src/fileed.S",
        "src/main.S",
        "src/patterned.S",
        "src/pcmdata.S",
        "src/screenutils.S",
        "src/toneed.S",
        "src/decompress.S",
        "src/samplerate.py",
    ] + compressed_screens,
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
