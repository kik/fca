@
@
@ gbaÍÑ crt0.o
@
@

#include "gba-arm.h"

	.section .text.head, "ax"
	.global _start
_start:
	b _end_of_header
        .long 0,0,0,0,0,0,0,0
        .long 0,0,0,0,0,0,0,0
        .long 0,0,0,0,0,0,0,0
        .long 0,0,0,0,0,0,0,0
        .long 0,0,0,0,0,0,0
        .long 0,0,0,0,0,0,0,0
_end_of_header:	
	
_real_start:
	ldr r0,=(ARM_MODE_IRQ | ARM_IRQ_DISABLE | ARM_FIQ_DISABLE)
	msr cpsr, r0
	ldr sp, =_stack_irq

	ldr r0,=(ARM_MODE_SVC | ARM_IRQ_DISABLE | ARM_FIQ_DISABLE)
	msr cpsr, r0
	ldr sp, =_stack_svc

	ldr r0,=(ARM_MODE_USR | ARM_FIQ_DISABLE)
	msr cpsr, r0
	ldr sp, =_stack_usr

	ldr r0, =_sdata
	ldr r1, =_load_start
	ldr r2, =_load_end

1:	
	teq r1, r2
	ldrne r3, [r1], #4
	strne r3, [r0], #4
	bne 1b

	ldr r0, =__bss_start
	ldr r1, =__bss_end
	ldr r2, =0

2:
	teq r0, r1
	strne r2, [r0], #4
	bne 2b

	bl start_shell

3:	
	swi #3
	b 3b
	
	.pool
