#include "nes.h"
#include "gba-regs.h"

	SECTION_FAST
	ALIGN

#define NES_A	0x01
#define NES_B	0x02
#define NES_SEL	0x04
#define NES_STA	0x08
#define NES_U	0x10
#define NES_D	0x20
#define NES_L	0x40
#define NES_R	0x80


	.globl	read_pad
read_pad:	
	mov	r0, #0
	mov	r1, #GBA_REG_BASE
	ldr	r1, [r1, #GBA_KEY]

	tst	r1, #GBA_KEY_A;		orreq	r0, r0, #NES_A
	tst	r1, #GBA_KEY_B;		orreq	r0, r0, #NES_B
	tst	r1, #GBA_KEY_SEL;	orreq	r0, r0, #NES_SEL
	tst	r1, #GBA_KEY_STA;	orreq	r0, r0, #NES_STA
	tst	r1, #GBA_KEY_UP;	orreq	r0, r0, #NES_U
	tst	r1, #GBA_KEY_DOWN;	orreq	r0, r0, #NES_D
	tst	r1, #GBA_KEY_LEFT;	orreq	r0, r0, #NES_L
	tst	r1, #GBA_KEY_RIGHT;	orreq	r0, r0, #NES_R

	str	r0, pad_1
	mov	pc, lr

pad_1:		.long	0
pad_strobe:	.long	0
pad_bits_1:	.long	0
pad_bits_2:	.long	0

	.globl	write_4016
write_4016:	
	ands	r1, r0, #1
	strne	r1, pad_strobe
	movne	pc, lr

	ldr	r1, pad_strobe
	teq	r1, #0
	moveq	pc, lr

	mov	r0, #0
	str	r0, pad_strobe
	ldr	r0, pad_1
	str	r0, pad_bits_1
	mov	pc, lr

	.globl	read_4016
read_4016:	
	ldr	r1, pad_bits_1
	and	r0, r1, #1
	mov	r1, r1, lsr #1
	str	r1, pad_bits_1
	mov	pc, lr

	.globl	read_4017
read_4017:	
	mov	r0, #0
	mov	pc, lr
