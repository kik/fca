#include "nes.h"
#include "struct.h"

	.section mapper3, "awx"


reset_mapper3:	
	stmfd	sp!, {lr}

	mov	r0, #0
	bl	set_memory_map_8toE

	ldopt	r1, EMU_OPT_n_prg_rom
	teq	r1, #1
	mov	r0, #0
	bleq	set_memory_map_CtoE

	ldopt	r0, EMU_OPT_n_chr_rom
	sub	r0, r0, #1
	str	r0, m3_n_chr_rom
	adr	r0, m3_write_rom
	bl	install_rom_write_handler
	ldmfd	sp!, {pc}


m3_n_chr_rom:	.long	0

m3_write_rom:
	ldr	r1, m3_n_chr_rom
	and	r0, r0, r1
	mov	r0, r0, lsl #3
	b	set_vram_bank_0to7

	.pool

