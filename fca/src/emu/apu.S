#include "nes.h"
#include "gba-regs.h"

	SECTION_FAST
	ALIGN

@@@ 
@@@ 
@@@ NES のサウンドのメモ
@@@ 
@@@ 
@@@ 
@@@ CH 1,2 矩形波
@@@ 
@@@ 1.79MHz   120/(N+1)Hz←4001[4-6]
@@@   ↓           ↓
@@@   ↓         sweep←4001[0-2,3,7]
@@@   ↓           ↓
@@@ プログラマブルタイマ←4002[0-7]+4003[0-2]
@@@   ↓
@@@ 1.79/(N+1)MHz
@@@   ↓
@@@ Duty cycle generator←4000[6-7]
@@@   ↓
@@@ 1.79/(N+1)/16MHz
@@@   ↓
@@@   ↓  240/(N+1)Hz←4000[0-3]
@@@   ↓   ↓
@@@ ボリューム←4000[0-3]
@@@   ↓/4
@@@   ↓          60Hz
@@@   ↓           ↓
@@@   ↓←←Length counter←4003[3-7]
@@@   ↓
@@@ 4bit DAC
@@@ 
@@@ 

@@@ freq
@@@ GBA
@@@  4194304/(32*(2048-x)) 
@@@ NES
@@@  1789772/16/(N+1)
@@@ 

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ 矩形波の更新
@@@ 
@@@ r0	=> 矩形波の設定の先頭アドレス
@@@ r1	<= ボリューム・波形レジスタの設定値
@@@ r2	<= 波長・リスタートレジスタの設定値
@@@ 
@@@ r4,r5を変更する

#define SQ_REG		0x00
#define SQ_ENB		0x04
#define SQ_LEN		0x08
#define SQ_FREQ		0x0C
#define SQ_FREQ_LIMIT	0x10
#define SQ_VOL		0x14
#define SQ_OUT		0x18
#define SQ_ENV_COUNT	0x1C
#define SQ_ENV_LOAD	0x20
#define SQ_ENV_VOL	0x24
#define SQ_SWEEP_COUNT	0x28
#define SQ_SWEEP_LOAD	0x2C
#define SQ_SWEEP_SHIFT	0x30

#define SQ_REG_SZ	0x34

#define SQ_REG_FIXED_ENV	0x0010
#define SQ_REG_HOLD_NOTE	0x0020
#define SQ_REG_DUTY		0x00C0
#define SQ_REG_SWEEP_INC	0x0800
#define SQ_REG_SWEEP_ON		0x8000

update_square:	
	mov	r1, #0
	mov	r2, #0

	ldr	r3, [r0, #SQ_ENB]
	teq	r3, #0
	moveq	pc, lr

	ldr	r4, [r0, #SQ_LEN]
	teq	r4, #0
	moveq	pc, lr

	ldr	r3, [r0, #SQ_REG]
	@@ lengthカウンタが有効か？
	tst	r3, #SQ_REG_HOLD_NOTE
	@@ lengthカウンタを更新
	subeq	r4, r4, #1
	streq	r4, [r0, #SQ_LEN]
1:	
	@@ エンベロープを更新
	ldr	r4, [r0, #SQ_ENV_COUNT]
	subs	r4, r4, #1
	ldrmi	r4, [r0, #SQ_ENV_LOAD]
	str	r4, [r0, #SQ_ENV_COUNT]
	bpl	2f
	@@ カウンタがエクスパイアしたのでボリュームを更新
	ldr	r4, [r0, #SQ_ENV_VOL]
	tst	r3, #SQ_REG_HOLD_NOTE
	teqeq	r4, #0
	@@ (Hold note が真) または (ボリュームが 0 でない)場合減らす
	@@ (Hold note が偽) かつ (ボリュームが 0) の場合は減らさない
	subne	r4, r4, #1	
	and	r4, r4, #0xF
	@@ 変化があった場合だけ保存
	strne	r4, [r0, #SQ_ENV_VOL]
2:	
	@@ スウィープを更新
	@@ まず新しい波長を計算
	ldr	r4, [r0, #SQ_SWEEP_SHIFT]
	ldr	r5, [r0, #SQ_FREQ]
	mov	r4, r5, lsr r4
	tst	r3, #SQ_REG_SWEEP_INC
	mvnne	r4, r4
	add	r5, r5, r4

	@@ 範囲を越えてないかチェック
	@@ 範囲を越えていれば止める
#if 1
	cmp	r5, #8
	movcc	pc, lr
	tst	r3, #SQ_REG_SWEEP_INC
	bne	3f
#if 0
	ldr	r4, [r0, #SQ_FREQ_LIMIT]
	cmp	r4, r5
	movcc	pc, lr
#else
	cmp	r5, #0x0800
	movcs	pc, lr
#endif
#endif
3:	
	@@ スウィープは有効？
	tst	r3, #SQ_REG_SWEEP_ON
	beq	4f
	ldr	r4, [r0, #SQ_SWEEP_SHIFT]
	teq	r4, #0
	beq	4f
	@@ スウィープは有効
	ldr	r4, [r0, #SQ_SWEEP_COUNT]
	subs	r4, r4, #1
	ldrmi	r4, [r0, #SQ_SWEEP_LOAD]
	str	r4, [r0, #SQ_SWEEP_COUNT]
	@@ スウィープのカウンタがエクスパイア
	strmi	r5, [r0, #SQ_FREQ]
4:	
	ldr	r5, [r0, #SQ_FREQ]
	ldr	r4, = freq_table
	mov	r5, r5, lsl #1
	ldrh	r2, [r4, r5]
	@@ ボリュームをロード
	tst	r3, #SQ_REG_FIXED_ENV
	ldrne	r1, [r0, #SQ_VOL]
	ldreq	r1, [r0, #SQ_ENV_VOL]
	@@ ボリュームが変化した時はリスタートしないと反映されないようだ
	ldr	r4, [r0, #SQ_OUT]
	teq	r4, r1
	orrne	r2, r2, #0x8000
	str	r1, [r0, #SQ_OUT]
	@@ 波形をロード
	and	r4, r3, #SQ_REG_DUTY
	orr	r1, r4, r1, lsl #12
	
	mov	pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@
@@@ タイマのハンドラ
@@@ 
@@@ 240Hzの周期でタイマを設定する
@@@ 
@@@ 各チャンネルの設定を更新する
@@@ 
@@@ 

	.globl	timer0_handler

timer0_handler:	
	stmfd	sp!, {r4, r5, lr}
	mov	r1, #0x04000000
	add	r1, r1, #0x100
	mvn	r0, #67
	@mov	r0, #0
	strh	r0, [r1]
#if 1

do_ch1:	
	adr	r0, ch1_reg
	bl	update_square
	mov	r0, #GBA_REG_BASE
	mov	r1, r1, lsl #16
	str	r1, [r0, #GBA_SG10]
	ldr	r1, [r0, #GBA_SGCNT1]
	tst	r1, #1
	orreq	r2, r2, #0x8000
	str	r2, [r0, #GBA_SG11]
#if 1
do_ch2:	
	adr	r0, ch2_reg
	bl	update_square
	mov	r0, #GBA_REG_BASE
	str	r1, [r0, #GBA_SG20]
	ldr	r1, [r0, #GBA_SGCNT1]
	tst	r1, #2
	orreq	r2, r2, #0x8000
	str	r2, [r0, #GBA_SG21]
#endif
do_ch3:	
#endif
	ldmfd	sp!, {r4, r5, pc}

	.pool

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ DMC割り込みをチェックする
@@@ 
@@@ このコードはCPUがREG_CYCLEだけ実行する直前に呼ばれる
@@@ REG_CYCLEだけDMCの処理を行ったふりをして，割り込みが
@@@ 発生するとフラグを立てるが，これは直後のCPUの実行で
@@@ 拾うべきではない。
@@@ 
#define DMC_REG			0x00
#define DMC_ENB			0x04
#define DMC_FREQ_COUNTER	0x08
#define DMC_FREQ_LOAD		0x0C
#define DMC_DMA_COUNTER		0x10
#define DMC_DMA_LOAD		0x14

#define DMC_REG_SZ		0x18
#define DMC_REG_LOOP		0x40
#define DMC_REG_IRQ		0x80

	.globl	sync_dmc

sync_dmc:	
#if 0
#if 0
	ldr	r0, ch5_reg + DMC_ENB
	teq	r0, #0
	moveq	pc, lr
#endif	
	ldr	r3, ch5_reg + DMC_REG
	ldr	r1, ch5_reg + DMC_FREQ_COUNTER
	sub	r1, r1, REG_CYCLE

1:	
	cmp	r1, #0
	strpl	r1, ch5_reg + DMC_FREQ_COUNTER
	movpl	pc, lr

	ldr	r2, ch5_reg + DMC_FREQ_LOAD
	add	r1, r1, r2, lsl #3

	ldr	r2, ch5_reg + DMC_DMA_COUNTER
	teq	r2, #0
	beq	1b

	subs	r2, r2, #1
	strne	r2, ch5_reg + DMC_DMA_COUNTER
	bne	1b

	tst	r3, #DMC_REG_LOOP
	ldrne	r2, ch5_reg + DMC_DMA_LOAD
	bicne	REG_P_REST, REG_P_REST, #P_REST_DMC_IRQ
	str	r2, ch5_reg + DMC_DMA_COUNTER
	bne	1b

	str	r2, ch5_reg + DMC_ENB
	tst	r3, #DMC_REG_IRQ
	orrne	REG_P_REST, REG_P_REST, #P_REST_DMC_IRQ
	b	1b
#else
	mov	pc, lr
#endif

length_table:	
	.byte	5, 127, 10,  1, 19,  2, 40,  3
	.byte	80,  4, 30,  5,  7,  6, 13,  7
	.byte	6,   8, 12,  9, 24, 10, 48, 11
	.byte	96, 12, 36, 13,  8, 14, 16, 15

	ALIGN

freq_limit_table:	
	.long   0x3FF, 0x555, 0x666, 0x71C, 0x787, 0x7C1, 0x7E0, 0x7F0

	ALIGN
dmc_clocks:	
	.long	428, 380, 340, 320, 286, 254, 226, 214
	.long	190, 160, 142, 128, 106,  85,  72,  54

	ALIGN
	.globl	ch1_reg
	.globl	ch2_reg
	.globl	ch5_reg
ch1_reg:	.fill	SQ_REG_SZ, 1, 0
ch2_reg:	.fill	SQ_REG_SZ, 1, 0

ch5_reg:	.fill	DMC_REG_SZ, 1, 0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH 1
@@@ 
	.globl	write_4000
write_4000:	
	strb	r0, ch1_reg + SQ_REG
	and	r1, r0, #0xF
	str	r1, ch1_reg + SQ_ENV_LOAD
	str	r1, ch1_reg + SQ_VOL
	mov	pc, lr

	.globl	write_4001
write_4001:	
	strb	r0, ch1_reg + SQ_REG + 1

	@@ 120Hz
	and	r1, r0, #0x70
	mov	r1, r1, lsr #3
	str	r1, ch1_reg + SQ_SWEEP_LOAD

	and	r1, r0, #7
	str	r1, ch1_reg + SQ_SWEEP_SHIFT
	adr	r2, freq_limit_table
	ldr	r1, [r2, r1, lsl #2]
	str	r1, ch1_reg + SQ_FREQ_LIMIT
	mov	pc, lr

	.globl	write_4002
write_4002:	
	strb	r0, ch1_reg + SQ_REG + 2
	ldr	r1, ch1_reg + SQ_FREQ
	and	r1, r1, #0x700
	orr	r1, r1, r0
	str	r1, ch1_reg + SQ_FREQ
	mov	pc, lr

	.globl	write_4003
write_4003:	
	strb	r0, ch1_reg + SQ_REG + 3

	ldrb	r1, ch1_reg + SQ_FREQ
	and	r2, r0, #7
	orr	r1, r1, r2, lsl #8
	str	r1, ch1_reg + SQ_FREQ

	adr	r2, length_table
	ldrb	r0, [r2, r0, lsr #3]
	mov	r0, r0, lsl #2
	str	r0, ch1_reg + SQ_LEN

	mov	r0, #0xF
	str	r0, ch1_reg + SQ_ENV_VOL

	mov	pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ CH 2
@@@ 
	.globl	write_4004
write_4004:	
	strb	r0, ch2_reg + SQ_REG
	and	r1, r0, #0xF
	str	r1, ch2_reg + SQ_ENV_LOAD
	str	r1, ch2_reg + SQ_VOL
	mov	pc, lr

	.globl	write_4005
write_4005:	
	strb	r0, ch2_reg + SQ_REG + 1

	@@ 120Hz
	and	r1, r0, #0x70
	mov	r1, r1, lsr #3
	str	r1, ch2_reg + SQ_SWEEP_LOAD

	and	r1, r0, #7
	str	r1, ch2_reg + SQ_SWEEP_SHIFT
	adr	r2, freq_limit_table
	ldr	r1, [r2, r1, lsl #2]
	str	r1, ch2_reg + SQ_FREQ_LIMIT
	mov	pc, lr

	.globl	write_4006
write_4006:	
	strb	r0, ch2_reg + SQ_REG + 2
	ldr	r1, ch2_reg + SQ_FREQ
	and	r1, r1, #0x700
	orr	r1, r1, r0
	str	r1, ch2_reg + SQ_FREQ
	mov	pc, lr

	.globl	write_4007
write_4007:	
	strb	r0, ch2_reg + SQ_REG + 3

	ldrb	r1, ch2_reg + SQ_FREQ
	and	r2, r0, #7
	orr	r1, r1, r2, lsl #8
	str	r1, ch2_reg + SQ_FREQ

	adr	r2, length_table
	ldrb	r0, [r2, r0, lsr #3]
	mov	r0, r0, lsl #2
	str	r0, ch2_reg + SQ_LEN

	mov	r0, #0xF
	str	r0, ch2_reg + SQ_ENV_VOL

	mov	pc, lr


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
#if 0
	mov	r1, #0x04000000

	ldr	r0, =0x20000080
	str	r0, [r1, #0x70]

	ldrh	r0, ch3_regs + 2
	bic	r0, r0, #0xF800
	rsb	r0, r0,	#2048
	ldr	r0, =1964
	orr	r0, r0, #0x8000
	@str	r0, [r1, #0x74]
#endif
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
@@@ CH5
@@@ 

	.globl	write_4010
write_4010:	
	strb	r0, ch5_reg + DMC_REG
	adr	r1, dmc_clocks
	and	r2, r0, #0xF
	ldr	r1, [r1, r2, lsl #2]
	str	r1, ch5_reg + DMC_FREQ_COUNTER
	str	r1, ch5_reg + DMC_FREQ_LOAD
	tst	r0, #0x80
	biceq	REG_P_REST, REG_P_REST, #P_REST_DMC_IRQ
	mov	pc, lr

	.globl	write_4011
write_4011:	
	strb	r0, ch5_reg + DMC_REG + 1
	mov	pc, lr

	.globl	write_4012
write_4012:	
	strb	r0, ch5_reg + DMC_REG + 2
	mov	pc, lr

	.globl	write_4013
write_4013:	
	strb	r0, ch5_reg + DMC_REG + 3
	mov	r1, r0, lsl #4
	add	r1, r1, #1
	str	r1, ch5_reg + DMC_DMA_LOAD
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
	bic	REG_P_REST, REG_P_REST, #P_REST_DMC_IRQ
	and	r1, r0, #0x01
	str	r1, ch1_reg + SQ_ENB
	and	r1, r0, #0x02
	str	r1, ch2_reg + SQ_ENB

#if 1
	mov	r2, #0
	ands	r1, r0, #0x10
	str	r1, ch5_reg + DMC_ENB
	streq	r2, ch5_reg + DMC_DMA_COUNTER
	moveq	pc, lr

	ldr	r1, ch5_reg + DMC_DMA_COUNTER
	teq	r1, #0
	ldreq	r1, ch5_reg + DMC_DMA_LOAD
	streq	r1, ch5_reg + DMC_DMA_COUNTER
#endif
#if 0
	mov	r1, r0
	adr	r0, 1f
	b	emu_printf
#endif
	mov	pc, lr
1:	.string	"4015 %x\n"
	ALIGN

	.globl	read_4015
read_4015:	
	mov	r0, #0
	ldr	r1, ch1_reg + SQ_ENB
	teq	r1, #0;		orrne	r0, r0, #1
	ldr	r1, ch2_reg + SQ_ENB
	teq	r1, #0;		orrne	r0, r0, #2
	tst	REG_P_REST, #P_REST_DMC_IRQ
	orrne	r0, r0, #0x80
	ldr	r1, =reg_4017
	ldr	r1, [r1]
	tst	r1, #0xC0
	orreq	r0, r0, #0x40
	mov	pc, lr

	.pool

triangle:	
	.long	0x67452301
	.long	0xEFCDAB89
	.long	0x98BACDFE
	.long	0x10325476

	.globl	init_apu
init_apu:	
	mov	r1, #0x04000000

#if 1
	@@ Mappy VMのタイマは変なので飛ばす
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

	mov	r0, #0
	b	write_4010
	@mov	pc, lr

	.pool

	SECTION_SLOW

freq_table:	
	.fill	0x800, 2, 0

	SECTION_FAST
	ALIGN


	.globl	read_high_reg
read_high_reg:	
	bic	r1, REG_ADDR, #0x4000
	teq	r1, #0x15;	beq	read_4015
	teq	r1, #0x16;	beq	read_4016
	teq	r1, #0x17;	beq	read_4017
	mov	r0, #0x40
	mov	pc, lr

	.globl	write_high_reg
write_high_reg:	
	and	r0, r0, #0xFF
	bic	r1, REG_ADDR, #0x4000
	cmp	r1, #0x18
	ldrcc	pc, [pc, r1, lsl #2]
	mov	pc, lr
	.long	write_4000, write_4001, write_4002, write_4003
	.long	write_4004, write_4005, write_4006, write_4007
	.long	write_4008, write_4009, write_400A, write_400B
	.long	write_400C, write_400D, write_400E, write_400F
	.long	write_4010, write_4011, write_4012, write_4013
	.long	write_4014, write_4015, write_4016, write_4017

