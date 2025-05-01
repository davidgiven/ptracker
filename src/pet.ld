MEMORY {
    zp : ORIGIN = 0, LENGTH = 0x90
    ram (rw) : ORIGIN = 0x3ff, LENGTH = 0x8000-0x3ff
}

SECTIONS {
	.zp : {
		*(.zp .zp.*)
	} >zp

	.text : {
		*(.text.header)
		*(.text.init)
		*(.text .text.*)
	} >ram
	.data : { *(.data .data.* .rodata .rodata.*) } >ram
	.noinit (NOLOAD) : { *(.noinit .noinit.*) } >ram
}
