
#include "nes.h"
#include "gba-regs.h"
#include "struct.h"

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
@@@ エミュレータのオプション
@@@ ローダが設定するinclude/struct.hを参照
@@@ 

	.globl	emulator_opt
emulator_opt:	.fill	EMU_OPT_size, 1, 0

@@@ 
@@@ エントリポイント
@@@ 
	.globl	emulator_entry

emulator_entry:	
	@@ レジスタを保存
	ldr	ip, =reg_save
	stmia	ip, {r4-r14}

	@bl	run_cpu_test
	bl	init_emulator
	bl	init_interrupt
	bl	run_emulator

	bl	exit_emulator

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
	bl	init_save_ram
	bl	init_mapper
	ldmfd	sp!, {pc}

@@@ 
@@@ 
@@@ 
reset_emulator:	
	stmfd	sp!, {lr}
	bl	reset_mapper
	bl	reset_ppu
	bl	reset_apu
	bl	reset_cpu
	ldmfd	sp!, {pc}


exit_emulator:	
	stmfd	sp!, {lr}

	@@ まず割り込みを止める
	mov	r0, #GBA_REG_BASE
	mov	r1, #0
	str	r1, [r0, #GBA_IME]

	bl	exit_ppu
	bl	exit_apu
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

	tst	r1, #GBA_IRQ_VBL
	ldrne	r0, vbl_count
	addne	r0, r0, #1
	strne	r0, vbl_count
	blne	vbl_handler

	ldr	r1, [sp]
	tst	r1, #GBA_IRQ_TIMERn(0)
	ldrne	r0, timer_count
	addne	r0, r0, #1
	strne	r0, timer_count
	blne	timer0_handler

	mov	r0, #GBA_REG_BASE
	mov	r2, #1
	str	r2, [r0, #GBA_IME]

	ldmfd	sp!, {r1, pc}

timer_count:	.long	0
vbl_count:	.long	0

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


.macro	DMC_IRQ
	tst	REG_P_REST, #P_REST_DMC_IRQ
	orrne	REG_P_REST, REG_P_REST, #P_REST_INT_PENDING
.endm

@@@ 
@@@ 現在のライン番号[0..262]
@@@ 

current_line:	.long	0


sync_vbl_value:	.long	0

sync_gba_vbl:	
	ldr	r0, sync_vbl_value
1:	
	ldr	r1, vbl_count
	teq	r0, r1
	beq	1b
	str	r1, sync_vbl_value
	mov	pc, lr

#define CYCLES_PER_LINE 114

@@@ 
@@@ メインループ
@@@ 
run_emulator:	
	stmfd	sp!, {lr}
	bl	reset_emulator
emulate_frame:	
	mov	r0, #GBA_REG_BASE
	ldr	r1, [r0, #GBA_KEY]
	tst	r1, #GBA_KEY_L
	bne	1f
	bl	enter_L_menu
	ldmnefd	sp!, {pc}

1:	
	@@ 
	@@ フレームの開始
	@@ 
	bl	sync_gba_vbl
	bl	read_pad

	mov	r0, #0
	str	r0, current_line
	bl	ppu_start_frame

1:	
	@@ 0-239
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE
	bl	cpu_exec
	DMC_IRQ	

	ldr	r0, current_line
	HSYNC

	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	@@ Zの場合は描画しない
	ldrne	r0, current_line
	blne	draw_line

	ldr	r0, current_line

	add	r0, r0, #1
	str	r0, current_line
	cmp	r0, #240
	bcc	1b

	ldr	r0, reg_4017
	tst	r0, #0xC0
	orreq	REG_P_REST, REG_P_REST, #P_REST_INT_PENDING

	@@ 240
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE
	bl	cpu_exec
	DMC_IRQ	
	mov	r0, #240
	HSYNC
	@@ 241
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE
	bl	cpu_exec
	DMC_IRQ	
	mov	r0, #241
	HSYNC
	@@ 242
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE
	bl	cpu_exec
	DMC_IRQ	
	mov	r0, #242
	HSYNC

	@@ 243 vbl start
	bl	ppu_start_vbl
	add	REG_CYCLE, REG_CYCLE, #1
	bl	cpu_exec
	DMC_IRQ	
	tst	REG_P_REST, #P_REST_ENB_NMI
	orrne	REG_P_REST, REG_P_REST, #P_REST_NMI_PENDING
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE - 1
	bl	cpu_exec
	DMC_IRQ	
	mov	r0, #243
	HSYNC

	@@ 244..261
	mov	r0, #244
	str	r0, current_line
1:	
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE
	bl	cpu_exec
	DMC_IRQ	

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
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE
	bl	cpu_exec
	DMC_IRQ	
	mov	r0, #6
	add	r0, r0, #256
	HSYNC

	@@ 262.5
	add	REG_CYCLE, REG_CYCLE, #CYCLES_PER_LINE / 2
	bl	cpu_exec
	DMC_IRQ	

	b	emulate_frame

	.pool

	.globl	reg_4017
reg_4017:	.long	0xFF

	.globl	write_4017
write_4017:	
	str	r0, reg_4017
	mov	pc, lr


L_menu_dat:	.fill	L_MENU_size, 1, 0

enter_L_menu:	
	stmfd	sp!, {ip, lr}

	@@ まず割り込みを止める
	mov	r0, #GBA_REG_BASE
	mov	r1, #0
	str	r1, [r0, #GBA_IME]

	bl	leave_emu_ppu
	bl	leave_emu_sound

	adr	r0, L_menu_dat
	adr	lr, 1f
	ldr	pc, = L_button_menu
1:	
	bl	enter_emu_ppu
	bl	enter_emu_sound

	ldr	r0, L_menu_dat + L_MENU_reset
	teq	r0, #0
	beq	2f
	bl	reset_emulator

2:	

	ldr	r0, L_menu_dat + L_MENU_save_file_write
	teq	r0, #0
	blne	set_save_file_write

	@@ 最後に割り込みを再開
	mov	r0, #GBA_REG_BASE
	mov	r1, #1
	str	r1, [r0, #GBA_IME]

	ldr	r0, L_menu_dat + L_MENU_exit
	teq	r0, #0
	ldmfd	sp!, {ip, pc}

	.pool
