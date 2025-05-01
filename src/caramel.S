#include "zif.inc"
#include "pet.inc"
#include "globals.inc"
#include "caramel.inc"

ZEROPAGE

cr0:   .fill 2
cr1:   .fill 2
cr2:   .fill 2
cr3:   .fill 2
cr4:   .fill 2
cr5:   .fill 2
cr6:   .fill 2
cr7:   .fill 2
crsp:  .fill 2
crpc:  .fill 2

CARAMEL_STACK_SIZE = 64
.common caramel_stack, CARAMEL_STACK_SIZE

.macro inc16 var:vararg
    inc 0+\var
    zif eq
        inc 1+\var
    zendif
.endm

.macro dec16 var:vararg
    lda 0+\var
    zif eq
        dec 1+\var
    zendif
    dec 0+\var
.endm

zproc init_caramel
    lda #<caramel_stack
    sta crsp+0
    lda #>caramel_stack
    sta crsp+1 

    lda #<(bytecode_entry-1)
    sta crpc+0
    lda #>(bytecode_entry-1)
    sta crpc+1
    rts
zendproc

zproc caramel_step
    ; PC is pre-incremented.

    inc16 crpc

    ; Fetch and decode instruction.

    ldy #0
    lda (crpc), y
    and #0x07               ; get just the register
    asl a
    tax                     ; register offset into -> x
    lsr a
    eor (crpc), y            ; now we just have the opcode in A

    ; Execute.

    lsr a
    lsr a
    tay
    lda dispatch_table+0, y
    sta 1f+1
    lda dispatch_table+1, y
    sta 1f+2
1:
    jmp 0xffff

__caramel_special0:
    lda special0_dispatch+0, x
    sta 1f+1
    lda special0_dispatch+1, x
    sta 1f+2
1:
    jmp 0xffff

__caramel_special1:

__caramel_b:
    ldy #2
    lda (crpc), y
    sta crpc+1
    dey
    lda (crpc), y
    sta crpc+0
    rts

__caramel_movi:
    ldy #2
    lda (crpc), y
    sta cr0+1, x
    dey
    lda (crpc), y
    sta cr0+0, x

    clc
    lda #2
    adc crpc+0
    sta crpc+0
    zif eq
        inc crpc+1
    zendif
    rts

__caramel_mov_to_a:
    lda cr0+0, x
    sta cr0+0
    lda cr0+1, x
    sta cr0+1
    rts

__caramel_mov_a_to:
    lda cr0+0
    sta cr0+0, x
    lda cr0+1
    sta cr0+1, x
    rts

__caramel_ldb:
    lda (cr0, x)
    sta cr0+0
    lda #0
    sta cr0+1
    rts

__caramel_ldbu:
    lda (cr0, x)
    sta cr0+0
    lda #0
    sta cr0+1

    inc16 cr0, x
    rts

__caramel_stb:
    lda cr0+0
    sta (cr0, x)
    rts

__caramel_stbu:
    lda cr0+0
    sta (cr0, x)

    inc16 cr0, x
    rts

__caramel_ld:
    lda (cr0, x)
    sta cr0+0
    inc16 cr0, x

    lda (cr0, x)
    sta cr0+1
    dec16 cr0, x
    rts
    
__caramel_ldu:
    lda (cr0, x)
    sta cr0+0
    inc16 cr0, x

    lda (cr0, x)
    sta cr0+1
    inc16 cr0, x
    rts
    
__caramel_st:
    lda cr0+0
    sta (cr0, x)
    inc16 cr0, x

    lda cr0+1
    sta (cr0, x)
    dec16 cr0, x
    rts
    
__caramel_stu:
    lda cr0+0
    sta (cr0, x)
    inc16 cr0, x

    lda cr0+1
    sta (cr0, x)
    inc16 cr0, x
    rts

special0_dispatch:
    .word __caramel_b
    
dispatch_table:
    .word __caramel_special0
    .word __caramel_special1
    .word __caramel_movi
    .word __caramel_mov_to_a
    .word __caramel_mov_a_to
    .word __caramel_ldb
    .word __caramel_ldbu
    .word __caramel_stb
    .word __caramel_stbu
    .word __caramel_ld
    .word __caramel_ldu
    .word __caramel_st
    .word __caramel_stu

bra_dispatch_table:
    .word 0
zendproc
