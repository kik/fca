@@@ 
@@@ 
@@@ 
@@@ 
@@@ 
#include "nes.h"

	SECTION_FAST
	ALIGN
#if 0
	.globl	n_prg_rom
	.globl	n_chr_rom
	.globl	mapper_num
	.globl	scroll_type
	.globl	has_sram
	.globl	prg_rom_start
	.globl	chr_rom_start
n_prg_rom:	.long	0
n_chr_rom:	.long	0
mapper_num:	.long	0
scroll_type:	.long	0
has_sram:	.long	0
prg_rom_start:	.long	0
chr_rom_start:	.long	0

#endif

	SECTION_SLOW
	ALIGN
	.globl	init_mapper

init_mapper:	
	stmfd	sp!, {lr}

	ldr	r1, =emu_opt_n_chr_rom
	ldr	r1, [r1]
	teq	r1, #0
	orreq	REG_P_REST, REG_P_REST, #P_REST_HAS_VRAM
	beq	1f

	ldr	r0, =emu_opt_chr_rom_start
	ldr	r0, [r0]
	ldr	r1, = 0x03020100
	ldr	r2, = 0x07060504
	bl	set_vram_bank_0to7

1:	
	ldr	r1, =emu_opt_n_prg_rom
	ldr	r1, [r1]
	teq	r1, #1
	beq	1f
	teq	r1, #0
	bne	2f

	@@ 1 bank
	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0x8000
	bl	set_memory_map_8

	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0xA000
	bl	set_memory_map_A

	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0xC000
	bl	set_memory_map_C

	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0xE000
	bl	set_memory_map_E
	b	3f
1:	
	@@ 2 banks
	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toA
	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0xC000
	bl	set_memory_map_CtoE
	b	3f
2:	
	@@ >2 banks
	ldr	r0, =emu_opt_prg_rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toE

3:	
	ldr	r0, =emu_opt_scroll_type
	ldr	r0, [r0]
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
