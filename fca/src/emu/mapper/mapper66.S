#include "nes.h"
#include "struct.h"


	.section mapper66, "awx"
reset_mapper66:	
	stmfd	sp!, {lr}

	mov	r0, #0
	bl	set_memory_map_8toE

	mov	r0, #0
	bl	set_vram_bank_0to7

	adr	r0, m66_write_rom
	bl	install_rom_write_handler

	adr	r0, m66_write_rom
	bl	install_save_ram_write_handler

	ldmfd	sp!, {pc}

m66_write_rom:	
	stmfd	sp!, {r4, lr}

	and	r4, r0, #0x0F
	and	r0, r0, #0xF0
	mov	r0, r0, lsr #2
	bl	set_memory_map_8toE

	mov	r0, r4, lsl #3
	bl	set_vram_bank_0to7

	ldmfd	sp!, {r4, pc}
