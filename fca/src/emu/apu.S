#include "nes.h"
#include "gba-regs.h"

	SECTION_FAST
	ALIGN

@@@ 
@@@ 
@@@ NES ¤Î¥µ¥¦¥ó¥É¤Î¥á¥â
@@@ 
@@@ 
@@@ 
@@@ CH 1,2 ¶ë·ÁÇÈ
@@@ 
@@@ 1.79MHz   120/(N+1)Hz¢«4001[4-6]
@@@   ¢­           ¢­
@@@   ¢­         sweep¢«4001[0-2,3,7]
@@@   ¢­           ¢­
@@@ ¥×¥í¥°¥é¥Þ¥Ö¥ë¥¿¥¤¥Þ¢«4002[0-7]+4003[0-2]
@@@   ¢­
@@@ 1.79/(N+1)MHz
@@@   ¢­
@@@ Duty cycle generator¢«4000[6-7]
@@@   ¢­
@@@ 1.79/(N+1)/16MHz
@@@   ¢­
@@@   ¢­  240/(N+1)Hz¢«4000[0-3]
@@@   ¢­   ¢­
@@@ ¥Ü¥ê¥å¡¼¥à¢«4000[0-3]
@@@   ¢­/4
@@@   ¢­          60Hz
@@@   ¢­           ¢­
@@@   ¢­¢«¢«Length counter¢«4003[3-7]
@@@   ¢­
@@@ 4bit DAC
@@@ 
@@@ 

@@@ freq
@@@ GBA
@@@  4194304/(32*(2048-x)) 
@@@ NES
@@@  1789772/16/(N+1)
@@@ 
@@@ 2048-x = 0.579585(N+1)
@@@ ¤°¤é¤¤¤Ç¤¤¤¤¤«¤Ê(¤Æ¤­¤È¡¼
@@@ 0x00.95


	.globl	timer0_handler
timer0_handler:	
	mov	r1, #0x04000000
	add	r1, r1, #0x100
	mvn	r0, #67
	@mov	r0, #0
	strh	r0, [r1]

	@@ Ä¹¤µ¤ò¥Á¥§¥Ã¥¯
	mov	r1, #0x04000000

do_ch1:	
#if 1
	mov	r2, #0

	ldr	r0, ch1_length_stop
	teq	r0, #0
	bne	1f
	ldr	r0, ch1_length
	subs	r0, r0, #1
	strmi	r2, [r1, #GBA_SG10]
	bmi	do_ch2
	str	r0, ch1_length
1:	
	ldr	r0, ch1_env_reg
	tst	r0, #0x20
	ldrne	r2, ch1_vol
	bne	1f

	ldr	r2, ch1_env_count
	subs	r2, r2, #1
	ldrmi	r2, ch1_env_load
	str	r2, ch1_env_count
	ldr	r2, ch1_env_vol
	bpl	1f
	subs	r2, r2, #1
	movmi	r2, #0
	strpl	r2, ch1_env_vol

1:	
	ldr	r0, ch1_duty
	orr	r0, r0, r2, lsl #28
	str	r0, [r1, #GBA_SG10]

	ldrh	r0, ch1_freq
	bic	r0, r0, #0xF800
	mov	r0, r0, lsl #1
	ldr	r2, =freq_table
	ldrh	r0, [r2, r0]
	ldr	r2, [r1, #GBA_SGCNT1]
	tst	r2, #1
	orreq	r0, r0, #0x8000
	str	r0, [r1, #GBA_SG11]
#endif	
do_ch2:	
	mov	r2, #0

	ldr	r0, ch2_length_stop
	teq	r0, #0
	bne	1f
	ldr	r0, ch2_length
	subs	r0, r0, #1
	strmi	r2, [r1, #GBA_SG20]
	bmi	do_ch3
	str	r0, ch2_length
1:	
	ldr	r0, ch2_env_reg
	tst	r0, #0x20
	ldrne	r2, ch2_vol
	bne	1f

	ldr	r2, ch2_env_count
	subs	r2, r2, #1
	ldrmi	r2, ch2_env_load
	str	r2, ch2_env_count
	ldr	r2, ch2_env_vol
	bpl	1f
	subs	r2, r2, #1
	movmi	r2, #0
	strpl	r2, ch2_env_vol

1:	
	ldr	r0, ch2_duty
	orr	r0, r0, r2, lsl #12
	str	r0, [r1, #GBA_SG20]

	ldrh	r0, ch2_freq
	bic	r0, r0, #0xF800
	mov	r0, r0, lsl #1
	ldr	r2, =freq_table
	ldrh	r0, [r2, r0]
	ldr	r2, [r1, #GBA_SGCNT1]
	tst	r2, #2
	orreq	r0, r0, #0x8000
	str	r0, [r1, #GBA_SG21]

do_ch3:	
	mov	pc, lr

	.pool


length_table:	
	.byte	5, 127, 10,  1, 19,  2, 40,  3
	.byte	80,  4, 30,  5,  7,  6, 13,  7
	.byte	6,   8, 12,  9, 24, 10, 48, 11
	.byte	96, 12, 36, 13,  8, 14, 16, 15

	ALIGN

	.globl	ch1_length
	.globl	ch1_freq
ch1_length:	.long	0
ch1_length_stop:.long	0
ch1_freq:	.long	0
ch1_duty:	.long	0

ch1_env_reg:	.long	0
ch1_env_count:	.long	0
ch1_env_load:	.long	0
ch1_env_vol:	.long	0
ch1_vol:	.long	0

ch2_length:	.long	0
ch2_length_stop:.long	0
ch2_freq:	.long	0
ch2_duty:	.long	0

ch2_env_reg:	.long	0
ch2_env_count:	.long	0
ch2_env_load:	.long	0
ch2_env_vol:	.long	0
ch2_vol:	.long	0


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH 1
@@@ 
	.globl	write_4000
write_4000:	
	strb	r0, ch1_regs
#if 1
	str	r0, ch1_env_reg

	and	r1, r0, #0xF
	str	r1, ch1_env_load
	tst	r0, #0x20
	strne	r1, ch1_vol

	and	r1, r0, #0x20
	str	r1, ch1_length_stop

	and	r0, r0, #0xC0
	mov	r0, r0, lsl #16
	str	r0, ch1_duty
#endif
	mov	pc, lr

	.globl	write_4001
write_4001:	
	strb	r0, ch1_regs + 1
	mov	pc, lr

	.globl	write_4002
write_4002:	
	strb	r0, ch1_regs + 2
	strb	r0, ch1_freq
	mov	pc, lr

	.globl	write_4003
write_4003:	
#if 1
	strb	r0, ch1_regs + 3
	strb	r0, ch1_freq + 1
	adr	r2, length_table
	ldrb	r0, [r2, r0, lsr #3]
	mov	r0, r0, lsl #2
	str	r0, ch1_length

	mov	r0, #0xF
	str	r0, ch1_env_vol
#endif
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
	str	r0, ch2_env_reg

	and	r1, r0, #0xF
	str	r1, ch2_env_load
	tst	r0, #0x20
	strne	r1, ch2_vol

	and	r1, r0, #0x20
	str	r1, ch2_length_stop

	and	r0, r0, #0xC0
	str	r0, ch2_duty

	mov	pc, lr

	.globl	write_4005
write_4005:	
	strb	r0, ch2_regs + 1
	mov	pc, lr

	.globl	write_4006
write_4006:	
	strb	r0, ch2_regs + 2
	strb	r0, ch2_freq
	mov	pc, lr

	.globl	write_4007
write_4007:	
	strb	r0, ch2_regs + 3
	strb	r0, ch2_freq + 1
	adr	r2, length_table
	ldrb	r0, [r2, r0, lsr #3]
	mov	r0, r0, lsl #2
	str	r0, ch2_length

	mov	r0, #0xF
	str	r0, ch2_env_vol

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
	mov	pc, lr

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
#if 1
	mov	r1, #0x04000000
	ldrb	r0, [r1, #0x84]
	and	r0, r0, #0x0F
#endif
	@mov	r0, #0
	mov	pc, lr

triangle:	
	.long	0x67452301
	.long	0xEFCDAB89
	.long	0x98BACDFE
	.long	0x10325476

	.globl	init_apu
init_apu:	
	mov	r1, #0x04000000

#if 1
	@@ Mappy VM¤Î¥¿¥¤¥Þ¤ÏÊÑ¤Ê¤Î¤ÇÈô¤Ð¤¹
	movs	r0, #0xF0000000
	msr	CPSR_f, r0
	bne	1f
#endif
	@@ timer0 240/Hz
	mvn	r0, #67
	str	r0, [r1, #0x100]
	mov	r0, #0xC3
	strb	r0, [r1, #0x102]
1:	

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

#if 0
	mov	r0, #0
	str	r0, [r1, #GBA_SG10]
	mov	r0, #0x8000
	str	r0, [r1, #GBA_SG11]
#endif

	ldr	r1, =freq_table
	mov	r2, #0x1000
	ldr	r3, =0x012B
	@mov	r0, #0x0095
1:	
	mul	r0, r2, r3
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
