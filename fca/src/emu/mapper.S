@@@ 
@@@ 
@@@ 
@@@ 
@@@ 
#include "nes.h"
#include "struct.h"

	SECTION_SLOW
	ALIGN
	.globl	init_mapper
init_mapper:	

	.globl	reset_mapper
reset_mapper:	
	stmfd	sp!, {lr}

	ldopt	r1, EMU_OPT_n_chr_rom
	teq	r1, #0
	orreq	REG_P_REST, REG_P_REST, #P_REST_HAS_VRAM
	beq	1f

	ldopt	r0, EMU_OPT_chr_rom_start
	ldr	r1, = 0x03020100
	ldr	r2, = 0x07060504
	bl	set_vram_bank_0to7

1:	
	ldopt	r1, EMU_OPT_n_prg_rom
	teq	r1, #1
	beq	1f
	teq	r1, #0
	bne	2f

	@@ 1 bank
	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0x8000
	bl	set_memory_map_8

	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0xA000
	bl	set_memory_map_A

	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0xC000
	bl	set_memory_map_C

	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0xE000
	bl	set_memory_map_E
	b	3f
1:	
	@@ 2 banks
	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toA

	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0xC000
	bl	set_memory_map_CtoE
	b	3f
2:	
	@@ >2 banks
	ldopt	r0, EMU_OPT_prg_rom_start
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toE

3:	
	ldopt	r0, EMU_OPT_scroll_type
	adr	lr, 4f
	teq	r0, #0
	beq	set_h_scroll
	teq	r0, #1
	beq	set_v_scroll
	teq	r0, #2
	beq	set_4_scroll
4:	
	bl	_start_mapper
	ldmfd	sp!, {pc}

	.pool
