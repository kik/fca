#include "nes.h"
#include "struct.h"

@@@ 
@@@ MMC2
@@@ 
@@@ パンチアウトだけが使っている
@@@ 

	.section mapper9, "awx"
reset_mapper9:	
	stmfd	sp!, {lr}

	ldopt	r0, EMU_OPT_n_prg_rom
	mov	r0, r0, lsl #1
	sub	r0, r0, #4
	bl	set_memory_map_8toE

	mov	r0, #0
	bl	set_memory_map_8

	mov	r0, #0
	bl	set_vram_bank_0to7

	adr	r0, m9_write_rom
	bl	install_rom_write_handler

	ldmfd	sp!, {pc}


m9_write_rom:	
	and	r1, REG_ADDR, #0x7000
	ldr	pc, [pc, r1, lsr #10]
	nop
	.word	m9_invalid, m9_invalid
	.word	m9_write_A, m9_write_B
	.word	m9_write_C, m9_write_D
	.word	m9_write_E, m9_write_F  


m9_invalid:	
	mov	pc, lr

m9_write_A:
	b	set_memory_map_8

m9_write_B:	
	b	set_vram_bank_0to3
m9_write_C:
	b	set_vram_bank_0to3

m9_write_D:	
	b	set_vram_bank_4to7
m9_write_E:	
	mov	pc, lr
	b	set_vram_bank_4to7

m9_write_F:	
	tst	r0, #1
	bne	set_v_scroll
	b	set_h_scroll

	.pool
