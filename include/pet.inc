STATUS    = 0x96 ; I/O status byte
PNT       = 0xc4 ; pointer to current cursor line
PNTR      = 0xc6 ; cursor offset into line
FNLEN     = 0xd1 ; length of current filename
LA        = 0xd2 ; current logical address
SA        = 0xd3 ; current secondary address
FA        = 0xd4 ; current device number
FNADR     = 0xda ; pointer to current filename

PIA1_PA   = 0xe810
PIA1_CRA  = 0xe811
PIA1_PB   = 0xe812
PIA1_CRB  = 0xe813

VIA_T1C_L = 0xe844
VIA_T1C_H = 0xe845
VIA_T1L_L = 0xe846
VIA_T1L_H = 0xe847
VIA_T2C_L = 0xe848
VIA_T2C_H = 0xe849
VIA_SR    = 0xe84a
VIA_ACR   = 0xe84b
VIA_PCR   = 0xe84c
VIA_IFR   = 0xe84d
VIA_IER   = 0xe84e

CRTC_ADDRESS = 0xe880
CRTC_DATA = 0xe881

IRQ_VECTOR = 0x0090
BRK_VECTOR = 0x0092

CHRIN       = 0xffcf
CHROUT      = 0xffd2
GETIN       = 0xffe4

VRAM = 0x8000

.macro blt label
    bcc \label
.endm

.macro bge label
    bcs \label
.endm
