#include "nes.h"
#include "struct.h"

	.section mapper2, "awx"
reset_mapper2:	
	stmfd	sp!, {lr}

	orr	REG_P_REST, REG_P_REST, #P_REST_HAS_VRAM

	mov	r0, #0
	bl	set_memory_map_8toA

	ldopt	r1, EMU_OPT_n_prg_rom
	str	r1, m2_n_prg_rom
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
	mov	r0, r0, lsl #1
	b	set_memory_map_8toA

m2_n_prg_rom:	.long	0

	.pool
