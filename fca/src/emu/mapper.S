@@@ 
@@@ 
@@@ 
@@@ 
@@@ 
#include "nes.h"

	SECTION_SLOW
	ALIGN

num_rom:	
	.short	0
num_vrom:	
	.short	0
mapper_num:	
	.short	0
mirror_type:	
	.short	0
has_sram:	
	.short	0
has_trainer:	
	.short	0

	SECTION_FAST
	ALIGN
rom_start:	
	.long	0
vrom_start:	
	.long	0


	SECTION_SLOW
	ALIGN

	.globl	init_mapper

init_mapper:	
	ldrb	r1, [r0, #4]
	ldr	r2, =num_rom
	strh	r1, [r2]

	ldrb	r1, [r0, #5]
	ldr	r2, =num_vrom
	strh	r1, [r2]

	ldrb	r1, [r0, #6]
	ldr	r2, =mapper_num
	ldrb	r3, [r0, #7]
	and	r1, r1, #0xF0
	and	r3, r3, #0xF0
	orr	r1, r3, r1, lsr #4
	strh	r1, [r2]

	ldrb	r1, [r0, #6]
	ldr	r2, =mirror_type
	tst	r1, #8
	movne	r3, #FOUR_SCREEN
	bne	1f
	tst	r1, #1
	movne	r3, #VERTICAL_SCREEN
	moveq	r3, #HORIZONTAL_SCREEN
1:	strh	r3, [r2]

	ldrb	r1, [r0, #6]
	ldr	r2, =has_sram
	and	r3, r1, #2
	strh	r3, [r2]
	ldr	r2, =has_trainer
	ands	r3, r3, #4
	strh	r3, [r2]
	
	@@ skip NES header
	add	r0, r0, #16
	@@ skip trainer if exists
	addne	r0, r0, #512	

	ldr	r2, =rom_start
	str	r0, [r2]
	ldr	r2, =num_rom
	ldrh	r3, [r2]
	@@ skip 16KB * num_rom bank
	add	r0, r0, r3, lsl #14
	ldr	r2, =vrom_start
	str	r0, [r2]

@@@ test code
@@@ 
@@@ assume smb1.nes
	stmfd	sp!, {lr}
	bl	set_vram_bank_0to7
	bl	translate_tiles
	ldr	r0, =rom_start
	ldr	r0, [r0]
	sub	r0, r0, #0x8000
	bl	set_memory_map_8toE
@	sub	r0, r0, #0x4000
@	bl	set_memory_map_CtoE
	mov	r1, r0
	adr	r0, 1f
	bl	emu_printf
	ldmfd	sp!, {pc}
	mov	pc, lr

1:	.string "mem bank %x\n"
	.pool

