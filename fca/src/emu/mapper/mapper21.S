#include "nes.h"
#include "struct.h"

@@@ 
@@@ ¥³¥Ê¥ß VRC4
@@@ 

	.section	mapper21, "awx"
reset_mapper21:	
	stmfd	sp!, {lr}

	mov	r0, #0
	bl	set_memory_map_8toA

	ldopt	r0, EMU_OPT_n_prg_rom
	mov	r0, r0, lsl #1
	sub	r0, r0, #2
	bl	set_memory_map_CtoE

	adr	r0, m21_write_rom
	bl	install_rom_write_handler

	adrl	r0, m21_hsync
	bl	install_hsync_handler

	mov	r0, #0
	bl	set_vram_bank_0to7

	ldr	r0, = 0x03020100
	str	r0, chr_reg
	ldr	r0, = 0x07060504
	str	r0, chr_reg + 4

	mov	r0, #0
	str	r0, reg_9002

	ldmfd	sp!, {pc}

	.pool

reg_9002:	.long	0

m21_write_rom:	
	and	r1, REG_ADDR, #0x7000
	and	r2, REG_ADDR, #0xCF
	ldr	pc, [pc, r1, lsr #10]
	nop
	.word	m21_write_8, m21_write_9, m21_write_A, m21_write_B
	.word	m21_write_C, m21_write_D, m21_write_E, m21_write_F
	
m21_write_8:
	teq	r2, #0
	movne	pc, lr

	ldrb	r1, reg_9002
	tst	r1, #2
	beq	set_memory_map_8
	b	set_memory_map_C
	
m21_write_9:
	teq	r2, #2
	teqne	r2, #0x80
	streq	r0, reg_9002
	moveq	pc, lr

	teq	r2, #0
	movne	pc, lr

	and	r0, r0, #3
	ldr	pc, [pc, r0, lsl #2]
	nop
	.word	set_h_scroll, set_v_scroll
	.word	set_0_scroll, set_1_scroll

m21_write_A:	
	teq	r2, #0
	movne	pc, lr
	b	set_memory_map_A

m21_write_B:	
	teq	r2, #0x00;	beq	m21_0_lo
	teq	r2, #0x02;	beq	m21_0_hi
	teq	r2, #0x40;	beq	m21_0_hi
	teq	r2, #0x01;	beq	m21_1_lo
	teq	r2, #0x04;	beq	m21_1_lo
	teq	r2, #0x80;	beq	m21_1_lo
	teq	r2, #0x03;	beq	m21_1_hi
	teq	r2, #0x06;	beq	m21_1_hi
	teq	r2, #0xC0;	beq	m21_1_hi
	mov	pc, lr

m21_write_C:	
	teq	r2, #0x00;	beq	m21_2_lo
	teq	r2, #0x02;	beq	m21_2_hi
	teq	r2, #0x40;	beq	m21_2_hi
	teq	r2, #0x01;	beq	m21_3_lo
	teq	r2, #0x04;	beq	m21_3_lo
	teq	r2, #0x80;	beq	m21_3_lo
	teq	r2, #0x03;	beq	m21_3_hi
	teq	r2, #0x06;	beq	m21_3_hi
	teq	r2, #0xC0;	beq	m21_3_hi
	mov	pc, lr

m21_write_D:	
	teq	r2, #0x00;	beq	m21_4_lo
	teq	r2, #0x02;	beq	m21_4_hi
	teq	r2, #0x40;	beq	m21_4_hi
	teq	r2, #0x01;	beq	m21_5_lo
	teq	r2, #0x04;	beq	m21_5_lo
	teq	r2, #0x80;	beq	m21_5_lo
	teq	r2, #0x03;	beq	m21_5_hi
	teq	r2, #0x06;	beq	m21_5_hi
	teq	r2, #0xC0;	beq	m21_5_hi
	mov	pc, lr

m21_write_E:	
	teq	r2, #0x00;	beq	m21_6_lo
	teq	r2, #0x02;	beq	m21_6_hi
	teq	r2, #0x40;	beq	m21_6_hi
	teq	r2, #0x01;	beq	m21_7_lo
	teq	r2, #0x04;	beq	m21_7_lo
	teq	r2, #0x80;	beq	m21_7_lo
	teq	r2, #0x03;	beq	m21_7_hi
	teq	r2, #0x06;	beq	m21_7_hi
	teq	r2, #0xC0;	beq	m21_7_hi
	mov	pc, lr

m21_write_F:	
	teq	r2, #0x00;	beq	m21_irq_lo
	teq	r2, #0x02;	beq	m21_irq_hi
	teq	r2, #0x40;	beq	m21_irq_hi
	teq	r2, #0x03;	beq	m21_irq_enb
	teq	r2, #0xC0;	beq	m21_irq_enb
	teq	r2, #0x04;	beq	m21_irq_reset
	teq	r2, #0x80;	beq	m21_irq_reset
	mov	pc, lr

chr_reg:	.fill	8, 1, 0

.macro	m21_n_lo	n
	ldrb	r1, chr_reg + \n
	and	r0, r0, #0x0F
	and	r1, r1, #0xF0
	orr	r0, r1, r0
	strb	r0, chr_reg + \n
.endm

.macro	m21_n_hi	n
	ldrb	r1, chr_reg + \n
	and	r0, r0, #0x0F
	and	r1, r1, #0x0F
	orr	r0, r1, r0, lsl #4
	strb	r0, chr_reg + \n
.endm

m21_0_lo:	m21_n_lo	0;	b	set_vram_bank_0
m21_0_hi:	m21_n_hi	0;	b	set_vram_bank_0
m21_1_lo:	m21_n_lo	1;	b	set_vram_bank_1
m21_1_hi:	m21_n_hi	1;	b	set_vram_bank_1
m21_2_lo:	m21_n_lo	2;	b	set_vram_bank_2
m21_2_hi:	m21_n_hi	2;	b	set_vram_bank_2
m21_3_lo:	m21_n_lo	3;	b	set_vram_bank_3
m21_3_hi:	m21_n_hi	3;	b	set_vram_bank_3
m21_4_lo:	m21_n_lo	4;	b	set_vram_bank_4
m21_4_hi:	m21_n_hi	4;	b	set_vram_bank_4
m21_5_lo:	m21_n_lo	5;	b	set_vram_bank_5
m21_5_hi:	m21_n_hi	5;	b	set_vram_bank_5
m21_6_lo:	m21_n_lo	6;	b	set_vram_bank_6
m21_6_hi:	m21_n_hi	6;	b	set_vram_bank_6
m21_7_lo:	m21_n_lo	7;	b	set_vram_bank_7
m21_7_hi:	m21_n_hi	7;	b	set_vram_bank_7

irq_enb:	.long	0
irq_latch:	.long	0
irq_counter:	.long	0

m21_irq_lo:
	ldr	r1, irq_latch
	and	r0, r0, #0x0F
	and	r1, r1, #0xF0
	orr	r0, r0, r1
	str	r0, irq_latch
	mov	pc, lr

m21_irq_hi:	
	ldr	r1, irq_latch
	and	r0, r0, #0x0F
	and	r1, r1, #0x0F
	orr	r0, r1, r0, lsl #4
	str	r0, irq_latch
	mov	pc, lr

m21_irq_enb:	
	ldr	r0, irq_enb
	and	r0, r0, #1
	add	r0, r0, r0, lsl #1
	str	r0, irq_enb
	mov	pc, lr

m21_irq_reset:	
	and	r0, r0, #3
	str	r0, irq_enb
	tst	r0, #2
	ldrne	r0, irq_latch
	strne	r0, irq_counter
	mov	pc, lr

m21_hsync:	
	ldr	r0, irq_enb
	tst	r0, #2
	moveq	pc, lr

	ldr	r1, irq_counter
	teq	r1, #0xFF
	addne	r1, r1, #1
	ldreq	r1, irq_latch
	str	r1, irq_counter
	movne	pc, lr

	and	r0, r0, #1
	add	r0, r0, r0, lsl #1
	str	r0, irq_enb
	orr	REG_P_REST, REG_P_REST, #P_REST_INT_PENDING

	mov	pc, lr
