#include "nes.h"
#include "struct.h"

	.section mapper3, "awx"


reset_mapper3:	
	ldopt	r0, EMU_OPT_chr_rom_start
	str	r0, m3_chr_rom
	ldopt	r0, EMU_OPT_n_chr_rom
	sub	r0, r0, #1
	str	r0, m3_n_chr_rom
	adr	r0, m3_write_rom
	b	install_rom_write_handler

m3_chr_rom:	.long	0
m3_n_chr_rom:	.long	0

m3_write_rom:
	ldr	r1, m3_n_chr_rom
	and	r1, r0, r1
	ldr	r0, m3_chr_rom
	add	r0, r0, r1, lsl #13

	add	r3, r1, #1
	orr	r1, r1, r3, lsl #8
	add	r3, r3, #1
	orr	r1, r1, r3, lsl #16
	add	r3, r3, #1
	orr	r1, r1, r3, lsl #24

	add	r3, r3, #1
	mov	r2, r3
	add	r3, r3, #1
	orr	r2, r2, r3, lsl #8
	add	r3, r3, #1
	orr	r2, r2, r3, lsl #16
	add	r3, r3, #1
	orr	r2, r2, r3, lsl #24
	b	set_vram_bank_0to7

	.pool

