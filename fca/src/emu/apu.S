#include "nes.h"

	SECTION_FAST
	ALIGN

@@@ 
@@@ 
@@@ NES 及扔它件玉及丟乒
@@@ 
@@@ 
@@@ 
@@@ CH 1,2 塞溥а
@@@ 
@@@ 1.79MHz   120/(N+1)Hz◤4001[4-6]
@@@   ╲           ╲
@@@   ╲         sweep◤4001[0-2,3,7]
@@@   ╲           ╲
@@@ 皿伕弘仿穴皮伙正奶穴◤4002[0-7]+4003[0-2]
@@@   ╲
@@@ 1.79/(N+1)MHz
@@@   ╲
@@@ Duty cycle generator◤4000[6-7]
@@@   ╲
@@@ 1.79/(N+1)/16MHz
@@@   ╲
@@@   ╲  240/(N+1)Hz◤4000[0-3]
@@@   ╲   ╲
@@@ 示伉亙□丞◤4000[0-3]
@@@   ╲/4
@@@   ╲          60Hz
@@@   ╲           ╲
@@@   ╲◤◤Length counter◤4003[3-7]
@@@   ╲
@@@ 4bit DAC
@@@ 
@@@ 

@@@ freq
@@@ GBA
@@@  4194304/(16*(2048-x)) 
@@@ NES
@@@  1789772/16/(N+1)
@@@ 
@@@ 2048-x = 0.579585(N+1)
@@@ 什日中匹中中井卅(化五午□
@@@ 0x00.95


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH 1
@@@ 
	.globl	write_4000
write_4000:	
	strb	r0, ch1_regs
	mov	pc, lr

	.globl	write_4001
write_4001:	
	strb	r0, ch1_regs + 1
	mov	pc, lr

	.globl	write_4002
write_4002:	
	strb	r0, ch1_regs + 2
	mov	pc, lr

	.globl	write_4003
write_4003:	
	strb	r0, ch1_regs + 3

	mov	r1, #0x04000000
	mov	r0, #0xF000
	str	r0, [r1, #0x68]

	ldrh	r0, ch1_regs + 2
	mov	r0, r0, lsl #1
	ldr	r1, =freq_table
	ldrh	r0, [r1, r0]
	orr	r0, r0, #0x8000
	str	r0, [r1, #0x6C]
	mov	pc, lr

ch1_regs:	.fill	4, 1, 0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH 2
@@@ 
	.globl	write_4004
write_4004:	
	strb	r0, ch2_regs
	mov	pc, lr

	.globl	write_4005
write_4005:	
	strb	r0, ch2_regs + 1
	mov	pc, lr

	.globl	write_4006
write_4006:	
	strb	r0, ch2_regs + 2
	mov	pc, lr

	.globl	write_4007
write_4007:	
	strb	r0, ch2_regs + 3

	mov	r1, #0x04000000
	mov	r0, #0xF0000000
	str	r0, [r1, #0x60]

	ldrh	r0, ch2_regs + 2
	mov	r0, r0, lsl #1
	ldr	r1, =freq_table
	ldrh	r0, [r1, r0]
	orr	r0, r0, #0x8000
	str	r0, [r1, #0x64]
	mov	pc, lr


ch2_regs:	.fill	4, 1, 0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH3
@@@ 

	.globl	write_4008
write_4008:	
	strb	r0, ch3_regs
	mov	pc, lr

	.globl	write_4009
write_4009:	
	strb	r0, ch3_regs + 1
	mov	pc, lr

	.globl	write_400A
write_400A:	
	strb	r0, ch3_regs + 2
	mov	pc, lr

	.globl	write_400B
write_400B:	
	strb	r0, ch3_regs + 3
	mov	r1, #0x04000000

	ldr	r0, =0x20000080
	str	r0, [r1, #0x70]

	ldrh	r0, ch3_regs + 2
	bic	r0, r0, #0xF800
	rsb	r0, r0,	#2048
	ldr	r0, =1964
	orr	r0, r0, #0x8000
	@str	r0, [r1, #0x74]
	mov	pc, lr



ch3_regs:	.fill	4, 1, 0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH4
@@@ 

	.globl	write_400C
write_400C:	

	.globl	write_400D
write_400D:	

	.globl	write_400E
write_400E:	

	.globl	write_400F
write_400F:	


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH enable/disable
@@@ 

@@@ 
@@@ write $4015
@@@ 
@@@ 76543210
@@@ |||||||+---CH 1 enable
@@@ ||||||+---CH 2 enable
@@@ |||||+---CH 3 enable
@@@ ||||+---CH 4 enable
@@@ |||+---CH 5 enable
@@@ +++---Unused
@@@ 
@@@ GBA NR 52 $084
@@@ 
@@@ 76543210
@@@ |||||||+---CH 1 stat(ro)
@@@ ||||||+---CH 2 stat(ro)
@@@ |||||+---CH 3 stat(ro)
@@@ ||||+---CH 4 stat(ro)
@@@ |+++---Unused
@@@ +---sound enable
@@@ 

	.globl	write_4015
write_4015:
#if 0
	tst	r0, #0x0F
	movne	r0, #0x80
	moveq	r0, #0x00
	mov	r1, #0x04000000
	strb	r0, [r1, #0x84]
	@mov	r0, #2
	@strh	r0, [r1, #0x82]
#endif
	mov	pc, lr

	.globl	read_4015
read_4015:	
	mov	r1, #0x04000000
	ldrb	r0, [r1, #0x84]
	and	r0, r0, #0x0F
	mov	pc, lr

triangle:	
	.long	0x67452301
	.long	0xEFCDAB89
	.long	0x98BACDFE
	.long	0x10325476

	.globl	init_apu
init_apu:	
	mov	r1, #0x04000000
	mov	r0, #0x80
	strh	r0, [r1, #0x84]

	ldr	r0, =0xFF77
	strh	r0, [r1, #0x80]

	mov	r0, #0x40
	strh	r0, [r1, #0x70]

	ldr	r0, =0x67452301
	str	r0, [r1, #0x90]
	ldr	r0, =0xEFCDAB89
	str	r0, [r1, #0x94]
	ldr	r0, =0x98BADCFE
	str	r0, [r1, #0x98]
	ldr	r0, =0x10325476
	str	r0, [r1, #0x9C]

	ldr	r1, =freq_table
	mov	r2, #0x1000
1:	
	mov	r0, #0x0095
	mul	r0, r2, r0
	mov	r0, r0, lsr #9
	rsb	r0, r0, #0x800
	subs	r2, r2, #2
	strh	r0, [r1, r2]
	bne	1b

	mov	pc, lr

	.pool

	SECTION_SLOW

freq_table:	
	.fill	0x800, 2, 0
