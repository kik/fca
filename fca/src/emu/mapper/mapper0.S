#include "nes.h"

	.section mapper0, "awx"
init_mapper0:
	adr	r0, m0_write_rom
	b	install_rom_write_handler

m0_write_rom:
	mov	r0, #0x10000000
	b	emu_panic


	.section mapper1, "awx"
#define M1_1024K	0
#define M1_512K		1
#define M1_SMALL	2

init_mapper1:	
	stmfd	sp!, {lr}

	ldr	r0, = emu_opt_chr_rom_start
	ldr	r0, [r0]
	str	r0, m1_chr_rom
	ldr	r0, = emu_opt_n_chr_rom
	ldr	r0, [r0]
	str	r0, m1_n_chr_rom

	ldr	r0, = emu_opt_prg_rom_start
	ldr	r0, [r0]
	str	r0, m1_prg_rom
	ldr	r1, = emu_opt_n_prg_rom
	ldr	r1, [r1]
	mov	r2, #M1_SMALL
	teq	r1, #64
	moveq	r2, #M1_1024K
	teq	r1, #32
	moveq	r2, #M1_512K
	str	r2, m1_size

	teq	r2, #M1_SMALL
	mov	r1, r1, lsl #1
	sub	r2, r1, #2
	sub	r3, r1, #1
	movne	r2, #30
	movne	r3, #31

	strb	r2, m1_bank2
	strb	r2, m1_hi0
	strb	r3, m1_bank3
	strb	r3, m1_hi1
	mov	r2, #0
	strb	r2, m1_bank0
	mov	r2, #1
	strb	r2, m1_bank1

	bl	m1_set_cpu_banks

	adr	r0, m1_write_rom
	bl	install_rom_write_handler
	
	ldmfd	sp!, {pc}

m1_set_cpu_banks:	
	stmfd	sp!, {lr}
	ldr	r0, m1_prg_rom
	ldr	r1, m1_256k_base
	ldr	r2, m1_bank0
	and	r2, r2, #31
	add	r0, r0, r1, lsl #18
	add	r0, r0, r2, lsl #13
	sub	r0, r0, #0x8000
	bl	set_memory_map_8
	
	ldr	r0, m1_prg_rom
	ldr	r1, m1_256k_base
	ldr	r2, m1_bank1
	and	r2, r2, #31
	add	r0, r0, r1, lsl #18
	add	r0, r0, r2, lsl #13
	sub	r0, r0, #0xA000
	bl	set_memory_map_A
	
	ldr	r0, m1_prg_rom
	ldr	r1, m1_256k_base
	ldr	r2, m1_bank2
	and	r2, r2, #31
	add	r0, r0, r1, lsl #18
	add	r0, r0, r2, lsl #13
	sub	r0, r0, #0xC000
	bl	set_memory_map_C
	
	ldr	r0, m1_prg_rom
	ldr	r1, m1_256k_base
	ldr	r2, m1_bank3
	and	r2, r2, #31
	add	r0, r0, r1, lsl #18
	add	r0, r0, r2, lsl #13
	sub	r0, r0, #0xE000
	bl	set_memory_map_E
	ldmfd	sp!, {pc}

m1_prg_rom:		.long	0
m1_chr_rom:		.long	0
m1_n_chr_rom:		.long	0

m1_write_rom_count:	.long	0
m1_bits:		.long	0
m1_regs:		.byte	0x0C, 0, 0, 0
m1_last_write_addr:	.long	0

m1_size:		.long	0

m1_256k_base:		.long	0
m1_swap:		.long	0


m1_bank0:	.byte	0
m1_bank1:	.byte	0
m1_bank2:	.byte	0
m1_bank3:	.byte	0

m1_hi0:		.byte	0
m1_hi1:		.byte	0

	ALIGN

m1_write_rom:	
	ldr	r1, m1_last_write_addr
	eor	r2, r1, REG_ADDR
	tst	r2, #0x6000
	mov	r2, #0
	strne	r2, m1_write_rom_count
	strne	r2, m1_bits
	strne	REG_ADDR, m1_last_write_addr
	
	tst	r0, #0x80
	strne	r2, m1_write_rom_count
	strne	r2, m1_bits
	movne	pc, lr

	ldr	r1, m1_write_rom_count
	ldr	r3, m1_bits
	and	r0, r0, #1
	orr	r3, r3, r0, lsl r1
	add	r1, r1, #1
	cmp	r1, #5
	movhs	r1, #0
	str	r1, m1_write_rom_count
	strhs	r1, m1_bits
	strlo	r3, m1_bits
	movlo	pc, lr

	mov	r0, REG_ADDR, lsr #13
	and	r0, r0, #3
	ldr	pc, [pc, r0, lsl #2]
	nop
	.word	0f, 1f, 2f, 3f

0:	
	strb	r3, m1_regs
	and	r0, r3, #3
	ldr	pc, [pc, r0, lsl #2]
	nop
	.word	set_v_scroll
	.word	set_v_scroll
	.word	set_h_scroll
	.word	set_v_scroll

	mov	pc, lr
1:	
	strb	r3, m1_regs + 1
	ldr	r0, m1_size
	teq	r0, #M1_1024K
	bne	10f
	@@ 1024KB MMC1
	ldr	r1, m1_regs
	tst	r1, #0x10
	bne	11f
	tst	r1, #0x1000
	moveq	r0, #0
	movne	r0, #3
	str	r0, m1_256k_base
	b	m1_set_cpu_banks
11:	
	ldr	r2, m1_swap
	rsbs	r1, r2, #1
	str	r1, m1_swap
	movne	pc, lr
	mov	r0, r1, lsr #12
	and	r0, r0, #1
	tst	r1, #0x08
	movne	r2, r1, lsr #19
	andne	r2, r2, #2
	orrne	r0, r0, r2
	str	r0, m1_256k_base
	b	m1_set_cpu_banks
10:	
	@@ not 1024KB MMC1
	ldr	r1, m1_n_chr_rom
	teq	r0, #M1_512K
	teqeq	r1, #0
	bne	12f
	ldr	r1, m1_regs
	mov	r0, r1, lsr #12
	and	r0, r0, #1
	str	r0, m1_256k_base
	b	m1_set_cpu_banks
12:	
	teq	r1, #0
	beq	13f
	ldrb	r1, m1_regs
	tst	r1, #0x10
	ldrb	r1, m1_regs + 1
	mov	r1, r1, lsl #2
	ldr	r0, m1_chr_rom
	add	r0, r0, r1, lsl #10
	add	r2, r1, #1
	orr	r1, r1, r2, lsl #8
	add	r2, r2, #1
	orr	r1, r1, r2, lsl #16
	add	r2, r2, #1
	orr	r1, r1, r2, lsl #24
	ldr	r2, = 0x04040404
	add	r2, r1, r2
	bne	set_vram_bank_0to3
	beq	set_vram_bank_0to7
13:	
	mov	pc, lr

2:	
	stmfd	sp!, {lr}
	strb	r3, m1_regs + 2
	ldr	r1, m1_regs
	ldr	r0, m1_size
	teq	r0, #M1_1024K
	bne	20f
	tst	r1, #0x08
	beq	20f

	ldr	r2, m1_swap
	rsbs	r1, r2, #1
	str	r1, m1_swap
	bne	20f

	mov	r0, r1, lsr #12
	and	r0, r0, #1
	tst	r1, #0x1000
	orrne	r0, r0, #2
	str	r0, m1_256k_base
	bl	m1_set_cpu_banks
	ldr	r1, m1_regs
20:	
	ldr	r0, m1_n_chr_rom
	teq	r0, #0
	tstne	r1, #0x10
	ldmeqfd	sp!, {pc}

	ldr	r0, m1_chr_rom
	ldrb	r1, m1_regs + 2
	mov	r1, r1, lsl #2
	add	r0, r0, r1, lsl #10
	add	r2, r1, #1
	orr	r1, r1, r2, lsl #8
	add	r2, r2, #1
	orr	r1, r1, r2, lsl #16
	add	r2, r2, #1
	orr	r1, r1, r2, lsl #24
	bl	set_vram_bank_4to7
	ldmfd	sp!, {pc}
3:	
	strb	r3, m1_regs + 3
	ldr	r2, m1_regs
	tst	r2, #0x08
	mov	r1, r3, lsl #1
	beq	30f
	tst	r2, #0x04
	beq	31f
	strb	r1, m1_bank0
	add	r1, r1, #1
	strb	r1, m1_bank1
	ldrb	r1, m1_hi0
	strb	r1, m1_bank2
	ldrb	r1, m1_hi1
	strb	r1, m1_bank3
	b	m1_set_cpu_banks
31:	
	ldr	r2, m1_size
	teq	r2, #M1_SMALL
	movne	pc, lr
	strb	r1, m1_bank2
	add	r1, r1, #1
	strb	r1, m1_bank3
	mov	r1, #0
	strb	r1, m1_bank0
	mov	r1, #1
	strb	r1, m1_bank1
	b	m1_set_cpu_banks
30:	
	strb	r1, m1_bank0
	add	r1, r1, #1
	strb	r1, m1_bank1
	ldr	r2, m1_size
	teq	r2, #M1_SMALL
	bne	m1_set_cpu_banks
	add	r1, r1, #1
	strb	r1, m1_bank2
	add	r1, r1, #1
	strb	r1, m1_bank3
	b	m1_set_cpu_banks


	.section mapper2, "awx"
init_mapper2:	
	stmfd	sp!, {lr}
	ldr	r0, = emu_opt_prg_rom_start
	ldr	r0, [r0]
	str	r0, m2_prg_rom

	ldr	r1, = emu_opt_n_prg_rom
	ldr	r1, [r1]
	str	r1, m2_n_prg_rom

	add	r0, r0, r1, lsl #14
	sub	r0, r0, #0x4000 + 0xC000
	bl	set_memory_map_CtoE

	adr	r0, m2_write_rom
	bl	install_rom_write_handler

	ldmfd	sp!, {pc}

m2_write_rom:
	ldr	r1, m2_n_prg_rom
	sub	r1, r1, #1
	and	r0, r0, r1
	ldr	r1, m2_prg_rom
	add	r0, r1, r0, lsl #14
	sub	r0, r0, #0x8000
	b	set_memory_map_8toA

m2_prg_rom:	.long	0
m2_n_prg_rom:	.long	0

	.section mapper3, "awx"


init_mapper3:	
	ldr	r0, =emu_opt_chr_rom_start
	ldr	r0, [r0]
	str	r0, m3_chr_rom
	ldr	r0, =emu_opt_n_chr_rom
	ldr	r0, [r0]
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

	.section mapper4, "awx"
init_mapper4:	
	stmfd	sp!, {lr}
	ldr	r0, = emu_opt_prg_rom_start
	ldr	r0, [r0]
	str	r0, m4_prg_rom
	str	r0, m4_prg0
	add	r1, r0, #0x2000
	str	r1, m4_prg1

	ldr	r1, = emu_opt_n_prg_rom
	ldr	r1, [r1]
	str	r1, m4_n_prg_rom

	add	r0, r0, r1, lsl #14
	sub	r0, r0, #0x4000
	str	r0, m4_prg_rom_last

	ldr	r0, = emu_opt_chr_rom_start
	ldr	r0, [r0]
	str	r0, m4_chr_rom

	ldr	r0, = emu_opt_n_chr_rom
	ldr	r0, [r0]
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
