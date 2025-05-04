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

VRAM = 0x8000

.macro blt label
    bcc \label
.endm

.macro bge label
    bcs \label
.endm
