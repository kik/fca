#include "nes.h"

	.section mapper0, "awx"
init_mapper0:
	adr	r0, m0_write_rom
	b	install_rom_write_handler

m0_write_rom:
	mov	r0, #0x10000000
	b	emu_panic



	.section mapper3, "awx"


init_mapper3:	
	ldr	r0, =chr_rom_start
	ldr	r0, [r0]
	str	r0, m3_chr_rom
	adr	r0, m3_write_rom
	b	install_rom_write_handler

m3_chr_rom:	.long	0

m3_write_rom:
	and	r0, r0, #3
	ldr	r1, m3_chr_rom
	add	r0, r1, r0, lsl #13
	b	set_vram_bank_0to7
	mov	pc, lr

	.pool



	.section mapper4, "awx"
init_mapper4:	
	stmfd	sp!, {lr}
	ldr	r0, = prg_rom_start
	ldr	r0, [r0]
	str	r0, m4_prg_rom
	str	r0, m4_prg0
	add	r1, r0, #0x2000
	str	r1, m4_prg1

	ldr	r1, = n_prg_rom
	ldr	r1, [r1]
	str	r1, m4_n_prg_rom

	add	r0, r0, r1, lsl #14
	sub	r0, r0, #0x4000
	str	r0, m4_prg_rom_last

	adr	r0, m4_write_rom
	bl	install_rom_write_handler
	bl	m4_set_cpu_banks
	bl	m4_set_ppu_banks

	adr	r0, m4_hsync
	bl	install_hsync_handler

	ldmfd	sp!, {pc}

	.pool

m4_n_prg_rom:	.long	0
m4_prg_rom:	.long	0
m4_prg_rom_last:
		.long	0
m4_regs:	.fill	8, 1, 0
m4_prg0:	.long	0
m4_prg1:	.long	0

m4_n_chr_rom:	.long	0
m4_chr_rom:	.long	0

m4_chr01:	.long	0
m4_chr23:	.long	2
m4_chr4:	.long	4
m4_chr5:	.long	5
m4_chr6:	.long	6
m4_chr7:	.long	7

m4_enb_irq:	.long	0

m4_write_rom:
	tst	REG_ADDR, #1
	and	r1, REG_ADDR, #0xE000
	bne	1f
	teq	r1, #0x8000;	beq	m4_write_8000
#if 1
	teq	r1, #0xA000;	beq	m4_write_A000
	teq	r1, #0xC000;	beq	m4_write_C000
	teq	r1, #0xE000;	beq	m4_write_E000
#endif
	mov	pc, lr
1:	
	teq	r1, #0x8000;	beq	m4_write_8001
#if 1
	teq	r1, #0xA000;	beq	m4_write_A001
	teq	r1, #0xC000;	beq	m4_write_C001
	teq	r1, #0xE000;	beq	m4_write_E001
#endif
	mov	pc, lr

m4_write_8000:
	strb	r0, m4_regs
	b	m4_set_cpu_banks

m4_write_8001:
	strb	r0, m4_regs + 1
	ldrb	r1, m4_regs
	and	r1, r1, #0x07
	ldr	pc, [pc, r1, lsl #2]
	nop
	.long	0f, 1f, 2f, 3f, 4f, 5f, 6f, 7f
0:
	and	r0, r0, #0xFE
	str	r0, m4_chr01
	b	m4_set_ppu_banks
1:	
	and	r0, r0, #0xFE
	str	r0, m4_chr23
	b	m4_set_ppu_banks
2:	
	str	r0, m4_chr4
	b	m4_set_ppu_banks
3:	
	str	r0, m4_chr5
	b	m4_set_ppu_banks
4:	
	str	r0, m4_chr6
	b	m4_set_ppu_banks
5:	
	str	r0, m4_chr7
	b	m4_set_ppu_banks

6:	
	ldr	r1, m4_prg_rom
	add	r0, r1, r0, lsl #13
	str	r0, m4_prg0
	b	m4_set_cpu_banks
7:	
	ldr	r1, m4_prg_rom
	add	r0, r1, r0, lsl #13
	str	r0, m4_prg1
	b	m4_set_cpu_banks

m4_write_A000:
	mov	pc, lr
m4_write_A001:
	mov	pc, lr
m4_write_C000:
	strb	r0, m4_regs + 4
	mov	pc, lr
m4_write_C001:
	strb	r0, m4_regs + 5
	mov	pc, lr
m4_write_E000:
	strb	r0, m4_regs + 6
	mov	r0, #0
	str	r0, m4_enb_irq
	mov	pc, lr
	adr	r0, 1f
	b	emu_printf
	mov	pc, lr
m4_write_E001:
	strb	r0, m4_regs + 7
	mov	r0, #1
	str	r0, m4_enb_irq
	mov	pc, lr
	adr	r0, 2f
	b	emu_printf
	mov	pc, lr
1:	.string	"irq disable\n"
2:	.string	"irq enable\n"
	ALIGN

m4_set_cpu_banks:
	stmfd	sp!, {lr}
	ldrb	r0, m4_regs
	tst	r0, #0x40
	beq	1f
	
	ldr	r0, m4_prg_rom_last
	sub	r0, r0, #0x8000
	bl	set_memory_map_8

	ldr	r0, m4_prg1
	sub	r0, r0, #0xA000
	bl	set_memory_map_A

	ldr	r0, m4_prg0
	sub	r0, r0, #0xC000
	bl	set_memory_map_C

	ldr	r0, m4_prg_rom_last
	sub	r0, r0, #0xE000 - 0x2000
	bl	set_memory_map_E

	ldmfd	sp!, {pc}
1:	
	ldr	r0, m4_prg0
	sub	r0, r0, #0x8000
	bl	set_memory_map_8

	ldr	r0, m4_prg1
	sub	r0, r0, #0xA000
	bl	set_memory_map_A

	ldr	r0, m4_prg_rom_last
	sub	r0, r0, #0xC000
	bl	set_memory_map_CtoE

	ldmfd	sp!, {pc}

m4_set_ppu_banks:
	mov	pc, lr

m4_hsync:	
	ldr	r1, m4_enb_irq
	teq	r1, #0
	moveq	pc, lr

	cmp	r0, #240
	movcs	pc, lr

	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	moveq	pc, lr

	ldrb	r0, m4_regs + 4
	teq	r0, #0
	ldreqb	r0, m4_regs + 5
	orreq	REG_P_REST, REG_P_REST, #P_REST_INT_PENDING
	subne	r0, r0, #1
	strb	r0, m4_regs + 4
	mov	pc, lr
