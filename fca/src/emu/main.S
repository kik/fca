
#include "nes.h"
@@@ 
@@@ 
@@@ 

	SECTION_SLOW
	ALIGN
reg_save:
	.long 0, 0, 0, 0	@ r4-r7
	.long 0, 0, 0, 0	@ r8-r11
	.long 0, 0, 0		@ r12-r14

rom_base_addr:	
	.long	0


	ALIGN

@@@ 
@@@ emulator entry point
@@@ 
@@@ r0	=> address of rom image
@@@ 
	.globl	emulator_entry
emulator_entry:	
	ldr	ip, =rom_base_addr
	str	r0, [ip]

	@@ save registers
	ldr	ip, =reg_save
	stmia	ip, {r4-r14}

	@@ initialize registers

@	mov	REG_BASE, #BASE_ADDR

#ifdef CPU_TEST
	bl	run_cpu_test
#endif
	bl	init_emulator
	bl	run_emulator

	@@ restore registers

	ldr	ip, =reg_save
	ldmia	ip, {r4-r14}

	mov	pc, lr

	.pool

@@@ 
@@@ init_emulator
@@@ 
@@@ r0	=> address of rom image
@@@ 
init_emulator:	
	stmfd	sp!, {r0, lr}
	bl	init_cpu
	bl	init_ppu
	bl	init_apu
	ldmfd	sp!, {r0, lr}
	b	init_mapper

@@@ 
@@@ for debug
@@@ 
	.globl	emu_printf

emu_printf:	
	stmfd	sp!, {r0-r12,lr}
	adr	lr, 1f
	ldr	pc, =printf
1:	ldmfd	sp!, {r0-r12,pc}

	.pool


	SECTION_FAST
	ALIGN
	.globl	emu_break
emu_break:
	nop
	nop
	nop
	nop
	mov	pc, lr

	ALIGN
int_handler:
	stmfd	sp!, {lr}
	mov	r0, #0x04000000
	add	r0, r0, #0x200

	ldrh	r1, [r0, #2]
	strh	r1, [r0, #2]

	mov	r2, #1
	strh	r2, [r0]

	tst	r1, #1
	blne	vbl_handler

	ldmfd	sp!, {pc}


current_line:	.long	0
hsync_handler:	.long	0

	.globl	install_hsync_handler
install_hsync_handler:	
	str	r0, hsync_handler
	mov	pc, lr

.macro	HSYNC
	ldr	r1, hsync_handler
	teq	r1, #0
	adr	lr, 9999f
	movne	pc, r1
9999:	
.endm

run_emulator:	
	stmfd	sp!, {lr}
#if 1
	mov	r0, #0x04000000
	adr	r1, int_handler
	str	r1, [r0, #-4]
	mov	r1, #0x8
	strh	r1, [r0, #4]
	mov	r1, #1
	add	r0, r0, #0x200
	strh	r1, [r0]
	strh	r1, [r0, #2]
	strh	r1, [r0, #8]
#endif
	bl	cpu_reset
emulate_frame:	
	@@ 
	@@ R を押している間テキストを表示する
	@@ Lを押しながらRを押すとパニック(デバッグ用)
	@@ 
	mov	r0, #0x04000000
	ldr	r1, [r0, #0x130]
	tst	r1, #0x100
	bne	1f
	tst	r1, #0x200
	moveq	r0, #0x01000000
	beq	emu_panic
	mov	r2, #0x0840
	ldr	r3, = 0x1C08
2:	
	strh	r2, [r0]
	strh	r3, [r0, #0xE]
	ldr	r1, [r0, #0x130]
	tst	r1, #0x100
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
