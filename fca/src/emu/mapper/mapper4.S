#include "nes.h"
#include "struct.h"


	.section mapper4, "awx"
reset_mapper4:	
	stmfd	sp!, {lr}

	mov	r0, #0
	str	r0, m4_regs
	str	r0, m4_regs + 4
	str	r0, m4_enb_irq
	ldr	r0, = 0x03020100
	str	r0, m4_chr0
	ldr	r0, = 0x07060504
	str	r0, m4_chr4

	ldopt	r0, EMU_OPT_prg_rom_start
	str	r0, m4_prg_rom
#if 0
	str	r0, m4_prg0
	add	r1, r0, #0x2000
	str	r1, m4_prg1
#endif
	mov	r1, #0
	str	r1, m4_prg0
	mov	r1, #1
	str	r1, m4_prg1

	ldopt	r1, EMU_OPT_n_prg_rom
	str	r1, m4_n_prg_rom

#if 0
	add	r0, r0, r1, lsl #14
	sub	r0, r0, #0x4000
	str	r0, m4_prg_rom_last
#endif
	mov	r1, r1, lsl #1
	sub	r1, r1, #2
	str	r1, m4_prg_rom_last

	ldopt	r0, EMU_OPT_chr_rom_start
	str	r0, m4_chr_rom

	ldopt	r0, EMU_OPT_n_chr_rom
	str	r0, m4_n_chr_rom

	adr	r0, m4_write_rom
	bl	install_rom_write_handler
	bl	m4_set_cpu_banks
	@bl	m4_set_ppu_banks

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

m4_chr0:	.byte	0
m4_chr1:	.byte	1
m4_chr2:	.byte	2
m4_chr3:	.byte	3
m4_chr4:	.byte	4
m4_chr5:	.byte	5
m4_chr6:	.byte	6
m4_chr7:	.byte	7

m4_enb_irq:	.long	0

m4_write_rom:
	tst	REG_ADDR, #1
	and	r1, REG_ADDR, #0xE000
	bne	1f
	teq	r1, #0x8000;	beq	m4_write_8000
	teq	r1, #0xA000;	beq	m4_write_A000
	teq	r1, #0xC000;	beq	m4_write_C000
	teq	r1, #0xE000;	beq	m4_write_E000
	mov	pc, lr
1:	
	teq	r1, #0x8000;	beq	m4_write_8001
	teq	r1, #0xA000;	beq	m4_write_A001
	teq	r1, #0xC000;	beq	m4_write_C001
	teq	r1, #0xE000;	beq	m4_write_E001
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
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr
	and	r0, r0, #0xFE
	orr	r1, r0, r0, lsl #8
	add	r1, r1, #1
	strh	r1, m4_chr0
	ldr	r2, m4_chr_rom
	add	r0, r2, r0, lsl #10
	b	set_vram_bank_0to1
1:	
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr
	and	r0, r0, #0xFE
	orr	r1, r0, r0, lsl #8
	add	r1, r1, #1
	strh	r1, m4_chr2
	ldr	r2, m4_chr_rom
	add	r0, r2, r0, lsl #10
	b	set_vram_bank_2to3
2:	
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr
	strb	r0, m4_chr4
	mov	r1, r0
	ldr	r2, m4_chr_rom
	add	r0, r2, r0, lsl #10
	b	set_vram_bank_4
3:	
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr
	strb	r0, m4_chr5
	mov	r1, r0
	ldr	r2, m4_chr_rom
	add	r0, r2, r0, lsl #10
	b	set_vram_bank_5
4:	
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr
	strb	r0, m4_chr6
	mov	r1, r0
	ldr	r2, m4_chr_rom
	add	r0, r2, r0, lsl #10
	b	set_vram_bank_6
5:	
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr
	strb	r0, m4_chr7
	mov	r1, r0
	ldr	r2, m4_chr_rom
	add	r0, r2, r0, lsl #10
	b	set_vram_bank_7

6:	
	@ldr	r1, m4_prg_rom
	@add	r0, r1, r0, lsl #13
	@str	r0, m4_prg0
	str	r0, m4_prg0
	b	m4_set_cpu_banks
7:	
	@ldr	r1, m4_prg_rom
	@add	r0, r1, r0, lsl #13
	@str	r0, m4_prg1
	str	r0, m4_prg1
	b	m4_set_cpu_banks

m4_write_A000:
	tst	r0, #1
	bne	set_v_scroll
	b	set_h_scroll
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

m4_write_E001:
	strb	r0, m4_regs + 7
	mov	r0, #1
	str	r0, m4_enb_irq
	mov	pc, lr

m4_set_cpu_banks:
	stmfd	sp!, {lr}
	ldrb	r0, m4_regs
	tst	r0, #0x40
	beq	1f

#if 0	
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
#endif
	ldr	r0, m4_prg_rom_last
	bl	set_memory_map_8

	ldr	r0, m4_prg1
	bl	set_memory_map_A

	ldr	r0, m4_prg0
	bl	set_memory_map_C

	ldr	r0, m4_prg_rom_last
	add	r0, r0, #1
	bl	set_memory_map_E

	ldmfd	sp!, {pc}
1:	
#if 0
	ldr	r0, m4_prg0
	sub	r0, r0, #0x8000
	bl	set_memory_map_8

	ldr	r0, m4_prg1
	sub	r0, r0, #0xA000
	bl	set_memory_map_A

	ldr	r0, m4_prg_rom_last
	sub	r0, r0, #0xC000
	bl	set_memory_map_CtoE
#endif
	ldr	r0, m4_prg0
	bl	set_memory_map_8

	ldr	r0, m4_prg1
	bl	set_memory_map_A

	ldr	r0, m4_prg_rom_last
	bl	set_memory_map_CtoE

	ldmfd	sp!, {pc}

#if 0
m4_set_ppu_banks:
	ldr	r1, m4_n_chr_rom
	teq	r1, #0
	moveq	pc, lr

	stmfd	sp!, {lr}
	bl	get_tile_map
	ldr	r1, m4_chr_rom

	ldr	r2, m4_chr01
	add	r2, r1, r2, lsl #10
	str	r2, [r0]
	str	r2, [r0, #0x4]

	ldr	r2, m4_chr23
	add	r2, r1, r2, lsl #10
	sub	r2, r2, #0x800
	str	r2, [r0, #0x8]
	str	r2, [r0, #0xC]

	ldr	r2, m4_chr4
	add	r2, r1, r2, lsl #10
	sub	r2, r2, #0x1000
	str	r2, [r0, #0x10]

	ldr	r2, m4_chr5
	add	r2, r1, r2, lsl #10
	sub	r2, r2, #0x1400
	str	r2, [r0, #0x14]

	ldr	r2, m4_chr6
	add	r2, r1, r2, lsl #10
	sub	r2, r2, #0x1800
	str	r2, [r0, #0x18]

	ldr	r2, m4_chr7
	add	r2, r1, r2, lsl #10
	sub	r2, r2, #0x1C00
	str	r2, [r0, #0x1C]

	ldmfd	sp!, {lr}

#endif
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
