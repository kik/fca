#include "nes.h"

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

#define GBA_A	0x01
#define GBA_B	0x02
#define GBA_SEL	0x04
#define GBA_STA	0x08
#define GBA_R	0x10
#define GBA_L	0x20
#define GBA_U	0x40
#define GBA_D	0x80


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
	mov	r1, #0x04000000
	ldr	r1, [r1, #0x130]

	tst	r1, #GBA_A;	orreq	r0, r0, #NES_A
	tst	r1, #GBA_B;	orreq	r0, r0, #NES_B
	tst	r1, #GBA_SEL;	orreq	r0, r0, #NES_SEL
	tst	r1, #GBA_STA;	orreq	r0, r0, #NES_STA
	tst	r1, #GBA_U;	orreq	r0, r0, #NES_U
	tst	r1, #GBA_D;	orreq	r0, r0, #NES_D
	tst	r1, #GBA_L;	orreq	r0, r0, #NES_L
	tst	r1, #GBA_R;	orreq	r0, r0, #NES_R

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
