
.macro ZEROPAGE
    .section .zp, "zax", @nobits
.endm

#define lo(n) ((n) & 0xff)
#define hi(n) ((n)>>8 & 0xff)

.extern midinote_lo
.extern midinote_hi

.zeropage t1_l
.zeropage t2_l
.zeropage t3_l
.zeropage t4_l
.zeropage t1_h
.zeropage t2_h
.zeropage t3_h
.zeropage t4_h
.zeropage t1p_l
.zeropage t2p_l
.zeropage t3p_l
.zeropage t4p_l
.zeropage t1p_h
.zeropage t2p_h
.zeropage t3p_h
.zeropage t4p_h
.zeropage t1len
.zeropage t2len
.zeropage t3len
.zeropage t4len
