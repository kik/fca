
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

	bl	init_emulator
#ifdef CPU_TEST
	bl	run_cpu_test
#endif
	bl	run_emulator

	@@ restore registers

	ldr	ip, =reg_save
	ldmia	ip, {r4-r14}

	mov	pc, lr

1:	.string "C\n"
2:	.string "NC\n"

	.pool


@@@ 
@@@ init_emulator
@@@ 
@@@ r0	=> address of rom image
@@@ 
init_emulator:	
	stmfd	sp!, {r0, lr}
	bl	init_cpu
	@bl	init_memory
	bl	init_ppu
	ldmfd	sp!, {r0, lr}
	b	init_mapper


@@@ 
@@@ for debug
@@@ 
	.globl	emu_printf

emu_printf:	
	@mov	pc, lr
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

current_line:	.long	0
vbl_count:	.long	0

	ALIGN
int_handler:
	ldr	r0, vbl_count
	add	r0, r0, #1
	str	r0, vbl_count
	bx	lr

run_emulator:	
	stmfd	sp!, {lr}
	mov	r0, #0x04000000
	adr	r1, int_handler
	str	r1, [r0, #-4]
	mov	r1, #0x8
	strh	r1, [r0, #4]
	mov	r1, #1
	add	r0, r0, #0x200
	strh	r1, [r0]
	strh	r1, [r0, #8]
	bl	cpu_reset
emulate_frame:	
	bl	ppu_start_frame
	@@ 0..239
	mov	r0, #0
	str	r0, vbl_count
1:	
	str	r0, current_line
	mov	REG_CYCLE, #113
	bl	cpu_exec
	@@ Hsync
	@@ draw line
	
	ldr	r0, current_line
	add	r0, r0, #1
	cmp	r0, #240
	bcc	1b

	@@ 240
	mov	REG_CYCLE, #113
	bl	cpu_exec
	@@ 241
	mov	REG_CYCLE, #113
	bl	cpu_exec
	@@ 242
	mov	REG_CYCLE, #113
	bl	cpu_exec

	@@ 243 vbl start
	bl	ppu_start_vbl
	mov	REG_CYCLE, #1
	bl	cpu_exec
	tst	REG_P_REST, #P_REST_ENB_NMI
	orrne	REG_P_REST, REG_P_REST, #P_REST_NMI_PENDING
	mov	REG_CYCLE, #112
	bl	cpu_exec

	@@ 244..261
	mov	r0, #0
1:	str	r0, current_line
	mov	REG_CYCLE, #113
	bl	cpu_exec
	ldr	r0, current_line
	add	r0, r0, #1
	cmp	r0, #18
	bcc	1b

	@@ 262
	bl	ppu_end_vbl
	mov	REG_CYCLE, #113
	bl	cpu_exec

	@@ 262.5
	mov	REG_CYCLE, #56
	bl	cpu_exec

	b	emulate_frame


	.pool
