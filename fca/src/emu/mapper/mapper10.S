#include "nes.h"
#include "struct.h"

@@@ 
@@@ MMC4
@@@ 
@@@ 

	.section mapper10, "awx"
reset_mapper10:	
	stmfd	sp!, {lr}

	ldopt	r0, EMU_OPT_n_prg_rom
	mov	r0, r0, lsl #1
	sub	r0, r0, #4
	bl	set_memory_map_8toE

	mov	r0, #0
	bl	set_memory_map_8toA

	mov	r0, #0
	bl	set_vram_bank_0to7

	adr	r0, m10_write_rom
	bl	install_rom_write_handler

	ldmfd	sp!, {pc}


m10_write_rom:	
	and	r1, REG_ADDR, #0x7000
	ldr	pc, [pc, r1, lsr #10]
	nop
	.word	m10_invalid, m10_invalid
	.word	m10_write_A, m10_write_B
	.word	m10_write_C, m10_write_D
	.word	m10_write_E, m10_write_F  


m10_invalid:	
	mov	pc, lr

m10_write_A:
	mov	r0, r0, lsl #1
	b	set_memory_map_8toA

m10_write_B:	
	b	set_vram_bank_0to3
m10_write_C:
	b	set_vram_bank_0to3

m10_write_D:	
	b	set_vram_bank_4to7
m10_write_E:	
	mov	pc, lr
	b	set_vram_bank_4to7

m10_write_F:	
	tst	r0, #1
	bne	set_v_scroll
	b	set_h_scroll

	.pool
