
#include "nes.h"
#include "gba-regs.h"

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ エミュレータのエントリポイント
@@@ 

@@@ 
@@@ 保存しないといけないレジスタをここに保存する
@@@ 
	SECTION_SLOW
	ALIGN
reg_save:
	.long 0, 0, 0, 0	@ r4-r7
	.long 0, 0, 0, 0	@ r8-r11
	.long 0, 0, 0		@ r12-r14

	ALIGN

@@@ 
@@@ エントリポイント
@@@ 
	.globl	emulator_entry

emulator_entry:	
	@@ レジスタを保存
	ldr	ip, =reg_save
	stmia	ip, {r4-r14}

#ifdef CPU_TEST
	bl	run_cpu_test
#endif
	bl	init_emulator
	bl	init_interrupt
	bl	run_emulator

	@@ レジスタを復元
	ldr	ip, =reg_save
	ldmia	ip, {r4-r13, pc}

	.pool

@@@ 
@@@ エミュレータの初期化
@@@ 
@@@ 
init_emulator:	
	stmfd	sp!, {lr}
	bl	init_cpu
	bl	init_ppu
	bl	init_apu
	bl	init_mapper
	ldmfd	sp!, {pc}

@@@ 
@@@ デバッグ用のprintf
@@@ かなり遅いので注意して使う
@@@ 
	.globl	emu_printf

emu_printf:	
	stmfd	sp!, {r0-r12,lr}
	adr	lr, 1f
	ldr	pc, =printf
1:	ldmfd	sp!, {r0-r12,pc}

	.pool

#if 0
@@@ 
@@@ デバッグ用のパニック
@@@ 
@@@ r0 => パニックナンバー
@@@ 
	.globl	emu_panic_data

emu_panic_data:
	.long	0, 0, 0, 0	@ r0-r3
	.long	0, 0, 0, 0	@ r4-r7
	.long	0, 0, 0, 0	@ r8-r11
	.long	0		@ r12
	.long	0		@ pc_bank

	.globl	emu_panic

emu_panic:	
	str	r0, emu_panic_data
	adr	r0, emu_panic_data + 4
	stmia	r0!, {r2-r12}
	ldr	r1, =pc_bank
	ldr	r1, [r1]
	str	r1, [r0], #4
	adr	r0, emu_panic_data
	b	panic
#endif

@@@ 
@@@ 割り込みの設定
@@@ 

init_interrupt:	
	mov	r1, #GBA_REG_BASE

	@@ ハンドラを登録
	ldr	r0, =int_handler
	str	r0, [r1, #-4]

	@mov	r1, #0x8
	@strh	r1, [r0, #4]

	mov	r0, #(GBA_IRQ_VBL | GBA_IRQ_TIMERn(0))
	orr	r0, r0, r0, lsl #16
	@@ IFをクリアして
	@@ IEを設定する
	str	r0, [r1, #GBA_IE]

	@@ 割り込みを有効にする
	mov	r0, #1
	str	r0, [r1, #GBA_IME]
	
	mov	pc, lr

	.pool


	SECTION_FAST
	ALIGN

@@@ 
@@@ RAMの先頭にこれを置いておく
@@@ エミュレータでデバッグするときにブレークポイントをしかけやすいので
@@@ 
	.globl	emu_break

emu_break:
	nop
	nop
	mov	pc, lr


@@@ 
@@@ 割り込みハンドラ
@@@ 

int_handler:
	mov	r0, #GBA_REG_BASE

	ldr	r1, [r0, #GBA_IE]
	str	r1, [r0, #GBA_IE]

	mov	r1, r1, lsr #16
	stmfd	sp!, {r1, lr}

	mov	r2, #1
	str	r2, [r0, #GBA_IME]

	tst	r1, #GBA_IRQ_VBL
	blne	vbl_handler
#if 1
	ldr	r1, [sp]
	tst	r1, #GBA_IRQ_TIMERn(0)
	blne	timer0_handler
#endif
	ldmfd	sp!, {r1, pc}


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ エミュレータのメインループ
@@@ 

@@@ 
@@@ 多くのマッパーがHSYNCをトラップする
@@@ 
hsync_handler:	.long	0

@@@ 
@@@ Hsyncハンドラの登録
@@@ 
@@@ Hsyncハンドラは現在のライン番号を引数にして呼ばれる
@@@ 
	.globl	install_hsync_handler

install_hsync_handler:	
	str	r0, hsync_handler
	mov	pc, lr


@@@ 
@@@ r0にライン番号をロードしておくこと
@@@ 
.macro	HSYNC
	ldr	r1, hsync_handler
	teq	r1, #0
	adr	lr, 9999f
	movne	pc, r1
9999:	
.endm


@@@ 
@@@ 現在のライン番号[0..262]
@@@ 

current_line:	.long	0

999:	.string "tm count %x %x\n"
	ALIGN

@@@ 
@@@ メインループ
@@@ 
run_emulator:	
	stmfd	sp!, {lr}
	bl	cpu_reset
emulate_frame:	
	@@ 
	@@ R を押している間テキストを表示する
	@@ Lを押しながらRを押すとパニック(デバッグ用)
	@@ 
	mov	r0, #GBA_REG_BASE
	ldr	r1, [r0, #GBA_KEY]
	tst	r1, #GBA_KEY_R
	bne	1f
	@@ Rが押されている
	tst	r1, #0x200
	moveq	r0, #0x01000000
	@@ Lも押されていればパニック
	beq	emu_panic

	ldr	r1, =ch1_freq
	ldr	r1, [r1]
	ldr	r2, =ch1_length
	ldr	r2, [r2]
	adr	r0, 999b
	bl	emu_printf
	mov	r0, #GBA_REG_BASE

	mov	r2, #GBA_DISP_CR_ENB_BG3
	ldr	r3, = GBA_BG_CR_MAP_ADDR(0x1C) | GBA_BG_CR_TILE_ADDR(2)
2:	
	strh	r2, [r0, #GBA_DISP_CR]
	strh	r3, [r0, #GBA_BGn_CR(3)]

	@@ Rが押されてる間ループ
	ldr	r1, [r0, #GBA_KEY]
	tst	r1, #GBA_KEY_R
	beq	2b
1:	

	@@ 
	@@ フレームの開始
	@@ 
	mov	r0, #0
	str	r0, current_line
	bl	ppu_start_frame

1:	
	@@ 0-239
	add	REG_CYCLE, REG_CYCLE, #113
	bl	cpu_exec
	
	ldr	r0, current_line
	HSYNC

	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	@@ Zの場合は描画しない
	ldrne	r0, current_line
	blne	draw_line

	ldr	r0, current_line
	@@ SMB1はここでHITを立てる
	@@ HITの実装をしなければ
	teq	r0, #30
	orreq	REG_P_REST, REG_P_REST, #P_REST_SPR_HIT

	add	r0, r0, #1
	str	r0, current_line
	cmp	r0, #240
	bcc	1b

	@@ 240
	add	REG_CYCLE, REG_CYCLE, #113
	bl	cpu_exec
	mov	r0, #240
	HSYNC
	@@ 241
	add	REG_CYCLE, REG_CYCLE, #113
	bl	cpu_exec
	mov	r0, #241
	HSYNC
	@@ 242
	add	REG_CYCLE, REG_CYCLE, #113
	bl	cpu_exec
	mov	r0, #242
	HSYNC

	@@ 243 vbl start
	bl	ppu_start_vbl
	add	REG_CYCLE, REG_CYCLE, #1
	bl	cpu_exec
	tst	REG_P_REST, #P_REST_ENB_NMI
	orrne	REG_P_REST, REG_P_REST, #P_REST_NMI_PENDING
	add	REG_CYCLE, REG_CYCLE, #112
	bl	cpu_exec
	mov	r0, #243
	HSYNC

	@@ 244..261
	mov	r0, #244
	str	r0, current_line
1:	
	add	REG_CYCLE, REG_CYCLE, #113
	bl	cpu_exec

	ldr	r0, current_line
	HSYNC

	ldr	r0, current_line
	add	r0, r0, #1
	str	r0, current_line

	sub	r0, r0, #244
	cmp	r0, #18
	bcc	1b

	@@ 262
	bl	ppu_end_vbl
	add	REG_CYCLE, REG_CYCLE, #113
	bl	cpu_exec
	mov	r0, #6
	add	r0, r0, #256
	HSYNC

	@@ 262.5
	add	REG_CYCLE, REG_CYCLE, #56
	bl	cpu_exec

	b	emulate_frame


	.pool
