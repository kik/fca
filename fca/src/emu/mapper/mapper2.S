#include "nes.h"
#include "struct.h"

	.section mapper2, "awx"
reset_mapper2:	
	stmfd	sp!, {lr}
	ldopt	r0, EMU_OPT_prg_rom_start
	str	r0, m2_prg_rom

	ldopt	r1, EMU_OPT_n_prg_rom
	str	r1, m2_n_prg_rom

	@add	r0, r0, r1, lsl #14
	@sub	r0, r0, #0x4000 + 0xC000
	@bl	set_memory_map_CtoE

	mov	r1, r1, lsl #1
	sub	r0, r1, #2
	bl	set_memory_map_CtoE

	adr	r0, m2_write_rom
	bl	install_rom_write_handler

	ldmfd	sp!, {pc}

m2_write_rom:
	ldr	r1, m2_n_prg_rom
	sub	r1, r1, #1
	and	r0, r0, r1
	@ldr	r1, m2_prg_rom
	@add	r0, r1, r0, lsl #14
	@sub	r0, r0, #0x8000
	mov	r0, r0, lsl #1
	b	set_memory_map_8toA

m2_prg_rom:	.long	0
m2_n_prg_rom:	.long	0

	.pool
