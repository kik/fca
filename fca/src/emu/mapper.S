@@@ 
@@@ 
@@@ 
@@@ 
@@@ 
#include "nes.h"

	SECTION_FAST
	ALIGN
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

	ALIGN
	.globl	init_mapper

init_mapper:	
	stmfd	sp!, {lr}
	ldr	r0, chr_rom_start
	ldr	r1, n_chr_rom
	teq	r1, #0
	blne	set_vram_bank_0to7

	ldr	r1, n_prg_rom
	teq	r1, #1
	beq	1f
	teq	r1, #0
	bne	2f

	@@ 1 bank
	ldr	r0, prg_rom_start
	sub	r0, r0, #0x8000
	bl	set_memory_map_8
	ldr	r0, prg_rom_start
	sub	r0, r0, #0xA000
	bl	set_memory_map_A
	ldr	r0, prg_rom_start
	sub	r0, r0, #0xC000
	bl	set_memory_map_C
	ldr	r0, prg_rom_start
	sub	r0, r0, #0xE000
	bl	set_memory_map_E
	b	3f
1:	
	@@ 2 banks
	ldr	r0, prg_rom_start
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toA
	ldr	r0, prg_rom_start
	sub	r0, r0, #0xC000
	bl	set_memory_map_CtoE
	b	3f
2:	
	@@ >2 banks
	ldr	r0, prg_rom_start
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toE

3:	
	ldr	r0, scroll_type
	teq	r0, #0
	bleq	set_h_scroll
	ldr	r0, scroll_type
	teq	r0, #1
	bleq	set_v_scroll
	ldr	r0, scroll_type
	teq	r0, #2
	bleq	set_4_scroll

	bl	_start_mapper
	ldmfd	sp!, {pc}
