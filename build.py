from build.ab import export, simplerule
from build.c import hostcxxprogram
from build.llvm import llvmrawprogram

simplerule(
    name="notetable_tab",
    ins=["src/notetable.py", "src/samplerate.py"],
    outs=["=notetable.S"],
    commands=["python3 $[ins[0]] > $[outs]"],
    label="NOTETABLE",
)

hostcxxprogram(name="compressor", srcs=["utils/compressor.cpp"])
hostcxxprogram(name="petseq", srcs=["utils/petseq.cc"])
hostcxxprogram(name="seqpet", srcs=["utils/seqpet.cc"])
hostcxxprogram(
    name="blockify",
    srcs=["utils/blockify.cc"],
    ldflags=["-lfreeimageplus", "-lfreeimage"],
)

SCREENS = ["toneed", "patterned", "helped"]

compressed_screens = []
for b in SCREENS:
    compressed_screens += [
        simplerule(
            name=f"compressed_{b}",
            ins=[".+petseq", ".+compressor", f"screens/{b}.seq"],
            outs=[f"={b}_compressed.inc"],
            commands=["$[ins[0]] < $[ins[2]] | $[ins[1]] > $[outs]"],
            label="COMPRESS",
        )
    ]

compressed_screens += [
    simplerule(
        name=f"compressed_fileed",
        ins=[
            ".+petseq",
            ".+compressor",
            f"screens/fileed.seq",
            f".+blockify",
            f"extras/logo.png",
        ],
        outs=[f"=fileed_compressed.inc"],
        commands=[
            "$[ins[0]] < $[ins[2]] > tmp",
            "$[ins[3]] $[ins[4]] | dd of=tmp bs=1 seek=80 conv=notrunc status=none",
            "$[ins[1]] < tmp > $[outs]",
        ],
        label="COMPRESS",
    )
]

llvmrawprogram(
    name="ptracker_elf",
    linkscript="src/pet.ld",
    srcs=[
        ".+notetable_tab",
        "include/pet.inc",
        "include/zif.inc",
        "src/globals.inc",
        "src/decompress.S",
        "src/engine.S",
        "src/filedata.S",
        "src/fileed.S",
        "src/helped.S",
        "src/main.S",
        "src/patterned.S",
        "src/pcmdata.S",
        "src/samplerate.py",
        "src/screenutils.S",
        "src/toneed.S",
    ]
    + compressed_screens,
)

simplerule(
    name="ptracker",
    ins=[".+ptracker_elf"],
    outs=["=ptracker.prg"],
    commands=["$(LLVM)/llvm-objcopy --output-target=binary $[ins] $[outs]"],
    label=["ELFTOPRG"],
)

simplerule(
    name="diskimage",
    ins=[".+ptracker", "extras/onward-ride.ptr"],
    outs=["=ptracker.d64"],
    commands=[
        "chronic cc1541 -q -n ptracker $[outs]",
        "chronic cc1541 -q -f ptracker -w $[ins[0]] $[outs]",
        "chronic cc1541 -q -f onward -w $[ins[1]] $[outs]",
    ],
    label="CC1541",
)

export(
    name="all",
    items={
        "ptracker.elf": ".+ptracker_elf",
        "ptracker.prg": ".+ptracker",
        "ptracker.d64": ".+diskimage",
    },
)
