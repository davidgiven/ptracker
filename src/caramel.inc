#define CR0 0
#define CR1 1
#define CR2 2
#define CR3 3
#define CR4 4
#define CR5 5
#define CR6 6
#define CR7 7

.macro cop opcode, reg
    .byte (opcode << 3) | reg
.endm

.macro cb dest
    cop 0, 0
    .word \dest-1
.endm

.macro cmovi reg, value
    cop 2, \reg
    .word \value
.endm
    
.macro clda reg
    cop 3, \reg
.endm

.macro csta reg
    cop 4, \reg
.endm

.macro cldb ptr
    cop 5, \ptr
.endm

.macro cldbu ptr
    cop 6, \ptr
.endm

.macro cstb ptr
    cop 7, \ptr
.endm

.macro cstbu ptr
    cop 9, \ptr
.endm

.macro cld ptr
    cop 10, \ptr
.endm

.macro cldu ptr
    cop 11, \ptr
.endm

.macro cst ptr
    cop 12, \ptr
.endm

.macro cstu ptr
    cop 13, \ptr
.endm
