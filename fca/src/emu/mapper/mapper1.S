#include "nes.h"
#include "struct.h"

	.section mapper1, "awx"
#define M1_1024K	0
#define M1_512K		1
#define M1_SMALL	2

reset_mapper1:	
	stmfd	sp!, {lr}

	ldopt	r0, EMU_OPT_n_chr_rom
	str	r0, m1_n_chr_rom
	teq	r0, #0
	orreq	REG_P_REST, REG_P_REST, #P_REST_HAS_VRAM
	movne	r0, #0
	blne	set_vram_bank_0to7

	ldopt	r1, EMU_OPT_n_prg_rom
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

	mov	r0, #0
	str	r0, m1_write_rom_count
	str	r0, m1_bits
	str	r0, m1_last_write_addr
	str	r0, m1_regs
	mov	r0, #0x0C
	strb	r0, m1_regs

	adr	r0, m1_write_rom
	bl	install_rom_write_handler
	
	ldmfd	sp!, {pc}

.macro	m1_cpu_bank	bank
	ldr	r1, m1_256k_base
	ldr	r0, \bank
	and	r0, r0, #31
	add	r0, r0, r1, lsl #5
.endm

m1_set_cpu_banks:	
	stmfd	sp!, {lr}
	m1_cpu_bank	m1_bank0;	bl	set_memory_map_8
	m1_cpu_bank	m1_bank1;	bl	set_memory_map_A
	m1_cpu_bank	m1_bank2;	bl	set_memory_map_C
	m1_cpu_bank	m1_bank3;	bl	set_memory_map_E

	ldmfd	sp!, {pc}

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
	.word	write_reg_0, write_reg_1, write_reg_2, write_reg_3

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ reg 0
@@@ 

write_reg_0:	
	strb	r3, m1_regs
	and	r0, r3, #3
	ldr	pc, [pc, r0, lsl #2]
	nop
	@@ 実際には少し違うらしい
	.word	set_v_scroll
	.word	set_v_scroll
	.word	set_h_scroll
	.word	set_v_scroll

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ reg 1
@@@ 
write_reg_1:	
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
	mov	r0, r1, lsl #2
	bne	set_vram_bank_0to3
	beq	set_vram_bank_0to7
13:	
	mov	pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ reg 2
@@@ 
write_reg_2:	
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

	ldrb	r0, m1_regs + 2
	mov	r0, r0, lsl #2
	bl	set_vram_bank_4to7
	ldmfd	sp!, {pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ 
@@@ 
write_reg_3:	
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

	.pool
