#include "nes.h"
#include "struct.h"

	.section mapper0, "awx"
reset_mapper0:
	adr	r0, m0_write_rom
	b	install_rom_write_handler

m0_write_rom:
	mov	r0, #0x10000000
	b	emu_panic

