#include "nes.h"
#include "struct.h"

	.section mapper0, "awx"
reset_mapper0:
	stmfd	sp!, {lr}

	adr	r0, m0_write_rom
	bl	install_rom_write_handler

	ldopt	r1, EMU_OPT_n_chr_rom
	teq	r1, #0
	orreq	REG_P_REST, REG_P_REST, #P_REST_HAS_VRAM
	beq	1f

	mov	r0, #0
	bl	set_vram_bank_0to7
1:	
	ldopt	r1, EMU_OPT_n_prg_rom
	teq	r1, #1
	beq	1f
	teq	r1, #0
	bne	2f

	@@ 1 bank
	mov	r0, #0;	bl	set_memory_map_8
	mov	r0, #0;	bl	set_memory_map_A
	mov	r0, #0;	bl	set_memory_map_C
	mov	r0, #0;	bl	set_memory_map_E
	b	3f
1:	
	@@ 2 banks
	mov	r0, #0;	bl	set_memory_map_8toA
	mov	r0, #0;	bl	set_memory_map_CtoE
	b	3f
2:	
	@@ >2 banks
	mov	r0, #0;	bl	set_memory_map_8toE
3:	
	ldmfd	sp!, {pc}

m0_write_rom:
	mov	r0, #0x10000000
	b	emu_panic

	.pool
