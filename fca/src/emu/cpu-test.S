
@#define TEST(n)	mov	REG_CYCLE, #(n)
.macro	TEST	m
	adr	r0, 1f
	mov	r1, #(\m)
	adr	lr, 2f
	b	emu_printf
1:	.string	"TEST %x\n"
	ALIGN
2:	mov	REG_CYCLE, #(\m)
.endm

#define A(n)	mov	REG_A, #(n << 24)
#define X(n)	mov	REG_X, #0+n
#define Y(n)	mov	REG_Y, #0+n
#define S(n)	mov	REG_S, #0+n
#define OP(n)	mov	r0, #(n)
#define AD(n)	ldr	REG_ADDR, =n

#define Z	orr	REG_P, REG_P, #ARM_Z_FLAG
#define N	orr	REG_P, REG_P, #ARM_N_FLAG
#define C	orr	REG_P, REG_P, #ARM_C_FLAG
#define V	orr	REG_P_REST, REG_P_REST, #P_REST_V_FLAG

#define NZ	bic	REG_P, REG_P, #ARM_Z_FLAG
#define NN	bic	REG_P, REG_P, #ARM_N_FLAG
#define NC	bic	REG_P, REG_P, #ARM_C_FLAG
#define NV	bic	REG_P_REST, REG_P_REST, #P_REST_V_FLAG

#define CHECK	bne	fail
#define C_A(n)	teq	REG_A, #(n << 24); CHECK
#define C_X(n)	teq	REG_X, #(n); CHECK
#define C_Y(n)	teq	REG_Y, #(n); CHECK
#define C_S(n)	teq	REG_S, #(n); CHECK
#define C_OP(n)	and	r0, r0, #0xFF; teq	r0, #(n); CHECK

#define C_Z	tst	REG_P, #ARM_Z_FLAG; beq	fail
#define C_N	tst	REG_P, #ARM_N_FLAG; beq	fail
#define C_V	tst	REG_P_REST, #P_REST_V_FLAG; beq	fail
#define C_C	tst	REG_P, #ARM_C_FLAG; beq	fail

#define C_NZ	tst	REG_P, #ARM_Z_FLAG; bne	fail
#define C_NN	tst	REG_P, #ARM_N_FLAG; bne	fail
#define C_NV	tst	REG_P_REST, #P_REST_V_FLAG; bne	fail
#define C_NC	tst	REG_P, #ARM_C_FLAG; bne	fail

	ALIGN
	.globl	run_cpu_test
run_cpu_test:	
	stmfd	sp!, {lr}	

	mov	REG_ADDR, #0
@@@ 
@@@	 LDA/LDX/LDY
@@@ 
	TEST	0
	OP(0);C;V
	OP_LDA
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST	1
	OP(0);NC;V
	OP_LDA
	C_A(0);C_Z;C_NC;C_NN;C_V

	TEST	2
	OP(0);C;NV
	OP_LDA
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST	3
	OP(1);C;V
	OP_LDA
	C_A(1);C_NZ;C_C;C_NN;C_V

	TEST	4
	OP(0x7F);C;V
	OP_LDA
	C_A(0x7F);C_NZ;C_C;C_NN;C_V

	TEST	5
	OP(0x80);C;V
	OP_LDA
	C_A(0x80);C_NZ;C_C;C_N;C_V

	@@ LDX

	TEST	6
	OP(0);C;V
	OP_LDX
	C_X(0);C_Z;C_C;C_NN;C_V

	TEST	7
	OP(0);NC;V
	OP_LDX
	C_X(0);C_Z;C_NC;C_NN;C_V

	TEST	8
	OP(0);C;NV
	OP_LDX
	C_X(0);C_Z;C_C;C_NN;C_NV

	TEST	9
	OP(1);C;V
	OP_LDX
	C_X(1);C_NZ;C_C;C_NN;C_V

	TEST	10
	OP(0x7F);C;V
	OP_LDX
	C_X(0x7F);C_NZ;C_C;C_NN;C_V

	TEST	11
	OP(0x80);C;V
	OP_LDX
	C_X(0x80);C_NZ;C_C;C_N;C_V

	@@ LDY

	TEST	12
	OP(0);C;V
	OP_LDY
	C_Y(0);C_Z;C_C;C_NN;C_V

	TEST	13
	OP(0);NC;V
	OP_LDY
	C_Y(0);C_Z;C_NC;C_NN;C_V

	TEST	14
	OP(0);C;NV
	OP_LDY
	C_Y(0);C_Z;C_C;C_NN;C_NV

	TEST	15
	OP(1);C;V
	OP_LDY
	C_Y(1);C_NZ;C_C;C_NN;C_V

	TEST	16
	OP(0x7F);C;V
	OP_LDY
	C_Y(0x7F);C_NZ;C_C;C_NN;C_V

	TEST	17
	OP(0x80);C;V
	OP_LDY
	C_Y(0x80);C_NZ;C_C;C_N;C_V

@@@ 
@@@ INC/INX/INY/DEC/DEX/DEY
@@@ 

	@@ INC

	TEST	18
	OP(0);C;V
	OP_INC
	C_OP(1);C_NZ;C_C;C_NN;C_V

	TEST	19
	OP(0);NC;V
	OP_INC
	C_OP(1);C_NZ;C_NC;C_NN;C_V

	TEST	20
	OP(0);NC;NV
	OP_INC
	C_OP(1);C_NZ;C_NC;C_NN;C_NV

	TEST	21
	OP(0xFF);NC;V
	OP_INC
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST	22
	OP(0x7F);NC;V
	OP_INC
	C_OP(0x80);C_NZ;C_NC;C_N;C_V

	TEST	23
	OP(0x2F);NC;V
	OP_INC
	C_OP(0x30);C_NZ;C_NC;C_NN;C_V

	@@ INX/INY

	TEST	24
	X(0);C;V
	OP_INXY	REG_X
	C_X(1);C_NZ;C_C;C_NN;C_V

	TEST	25
	X(0);NC;V
	OP_INXY	REG_X
	C_X(1);C_NZ;C_NC;C_NN;C_V

	TEST	26
	X(0);NC;NV
	OP_INXY	REG_X
	C_X(1);C_NZ;C_NC;C_NN;C_NV

	TEST	27
	X(0xFF);NC;V
	OP_INXY	REG_X
	C_X(0);C_Z;C_NC;C_NN;C_V

	TEST	28
	X(0x7F);NC;V
	OP_INXY	REG_X
	C_X(0x80);C_NZ;C_NC;C_N;C_V

	TEST	29
	X(0x2F);NC;V
	OP_INXY	REG_X
	C_X(0x30);C_NZ;C_NC;C_NN;C_V

	@@ DEC

	TEST	30
	OP(1);C;V
	OP_DEC
	C_OP(0);C_Z;C_C;C_NN;C_V

	TEST	31
	OP(1);NC;V
	OP_DEC
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST	32
	OP(1);NC;NV
	OP_DEC
	C_OP(0);C_Z;C_NC;C_NN;C_NV

	TEST	33
	OP(2);NC;V
	OP_DEC
	C_OP(1);C_NZ;C_NC;C_NN;C_V

	TEST	34
	OP(0);NC;V
	OP_DEC
	C_OP(0xFF);C_NZ;C_NC;C_N;C_V

	TEST	35
	OP(0x80);NC;V
	OP_DEC
	C_OP(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ DEX/DEY

	TEST	36
	X(1);C;V
	OP_DEXY	REG_X
	C_X(0);C_Z;C_C;C_NN;C_V

	TEST	37
	X(1);NC;V
	OP_DEXY	REG_X
	C_X(0);C_Z;C_NC;C_NN;C_V

	TEST	38
	X(1);NC;NV
	OP_DEXY	REG_X
	C_X(0);C_Z;C_NC;C_NN;C_NV

	TEST	39
	X(2);NC;V
	OP_DEXY	REG_X
	C_X(1);C_NZ;C_NC;C_NN;C_V

	TEST	40
	X(0);NC;V
	OP_DEXY	REG_X
	C_X(0xFF);C_NZ;C_NC;C_N;C_V

	TEST	41
	X(0x80);NC;V
	OP_DEXY	REG_X
	C_X(0x7F);C_NZ;C_NC;C_NN;C_V



@@@ 
@@@ ADC/SBC
@@@ 

	@@ ADC
	
	TEST	42
	A(0x10);OP(0x20);NC
	OP_ADC
	C_A(0x30);C_NZ;C_NC;C_NN;C_NV

	TEST	43
	A(0);OP(0);C
	OP_ADC
	C_A(1);C_NZ;C_NC;C_NN;C_NV

	TEST	44
	A(0xFF);OP(1);NC
	OP_ADC
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST	45
	A(0xFF);OP(1);C
	OP_ADC
	C_A(1);C_NZ;C_C;C_NN;C_NV

	TEST	46
	A(0x80);OP(1);NC
	OP_ADC
	C_A(0x81);C_NZ;C_NC;C_N;C_NV

	TEST	47
	A(0x80);OP(0x80);NC
	OP_ADC
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST	48
	A(0x7F);OP(0x7F);NC
	OP_ADC
	C_A(0xFE);C_NZ;C_NC;C_N;C_V

	@@ SBC

	TEST	49
	A(0);OP(0);C
	OP_SBC
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST	50
	A(0);OP(0);NC
	OP_SBC
	C_A(0xFF);C_NZ;C_NC;C_N;C_NV

	TEST	51
	A(0x23);OP(0x5);C
	OP_SBC
	C_A(0x1E);C_NZ;C_C;C_NN;C_NV

	TEST	52
	A(0x23);OP(0x5);NC
	OP_SBC
	C_A(0x1D);C_NZ;C_C;C_NN;C_NV

	TEST	53
	A(0x80);OP(1);C
	OP_SBC
	C_A(0x7F);C_NZ;C_C;C_NN;C_V

	TEST	54
	A(0x20);OP(0x80);C
	OP_SBC
	C_A(0xA0);C_NZ;C_NC;C_N;C_V

@@@ 
@@@ AND/EOR/ORA
@@@ 

	@@ AND

	TEST	55
	A(0x33);OP(0xCC);NC;NV
	OP_AND
	C_A(0);C_Z;C_NC;C_NN;C_NV
	
	TEST	56
	A(0x33);OP(0xCC);C;V
	OP_AND
	C_A(0);C_Z;C_C;C_NN;C_V
	
	TEST	57
	A(0xC3);OP(0xCC);C;NV
	OP_AND
	C_A(0xC0);C_NZ;C_C;C_N;C_NV

	TEST	58
	A(0x3C);OP(0xCC);NC;V
	OP_AND
	C_A(0x0C);C_NZ;C_NC;C_NN;C_V

	@@ EOR

	TEST	59
	A(0x33);OP(0xCC);NC;NV
	OP_EOR
	C_A(0xFF);C_NZ;C_NC;C_N;C_NV
	
	TEST	60
	A(0x33);OP(0xCC);C;V
	OP_EOR
	C_A(0xFF);C_NZ;C_C;C_N;C_V
	
	TEST	61
	A(0xC3);OP(0xCC);C;NV
	OP_EOR
	C_A(0x0F);C_NZ;C_C;C_NN;C_NV

	TEST	62
	A(0x3C);OP(0xCC);NC;V
	OP_EOR
	C_A(0xF0);C_NZ;C_NC;C_N;C_V

	@@ ORA

	TEST	63
	A(0x33);OP(0xCC);NC;NV
	OP_ORA
	C_A(0xFF);C_NZ;C_NC;C_N;C_NV
	
	TEST	64
	A(0x33);OP(0xCC);C;V
	OP_ORA
	C_A(0xFF);C_NZ;C_C;C_N;C_V
	
	TEST	65
	A(0xC3);OP(0xCC);C;NV
	OP_ORA
	C_A(0xCF);C_NZ;C_C;C_N;C_NV

	TEST	66
	A(0x3C);OP(0);NC;V
	OP_ORA
	C_A(0x3C);C_NZ;C_NC;C_NN;C_V

	TEST	67
	A(0);OP(0);NC;V
	OP_ORA
	C_A(0);C_Z;C_NC;C_NN;C_V

@@@ 
@@@ CMP/CPX/CPY
@@@ 
	@@ CMP

	TEST	68
	A(0);OP(0);V
	OP_CMP
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST	69
	A(0);OP(1);NV
	OP_CMP
	C_A(0);C_NZ;C_NC;C_N;C_NV

	TEST	70
	A(2);OP(1);V
	OP_CMP
	C_A(2);C_NZ;C_C;C_NN;C_V

	TEST	71
	A(0x81);OP(1);V
	OP_CMP
	C_A(0x81);C_NZ;C_C;C_N;C_V

	@@ CPX/CPY

	TEST	72
	X(0);OP(0);V
	OP_CPXY	REG_X
	C_X(0);C_Z;C_C;C_NN;C_V

	TEST	73
	X(0);OP(1);NV
	OP_CPXY	REG_X
	C_X(0);C_NZ;C_NC;C_N;C_NV

	TEST	74
	X(2);OP(1);V
	OP_CPXY	REG_X
	C_X(2);C_NZ;C_C;C_NN;C_V

	TEST	75
	X(0x81);OP(1);V
	OP_CPXY	REG_X
	C_X(0x81);C_NZ;C_C;C_N;C_V


@@@ 
@@@ BIT
@@@ 
	@@ BIT

	TEST	76
	A(0x33);OP(0xCC);NC
	OP_BIT
	C_A(0x33);C_Z;C_NC;C_N;C_V

	TEST	77
	A(0x33);OP(0xCC);C
	OP_BIT
	C_A(0x33);C_Z;C_C;C_N;C_V

	TEST	78
	A(0xC3);OP(0xCC);NC
	OP_BIT
	C_A(0xC3);C_NZ;C_NC;C_N;C_V

	TEST	79
	A(0x33);OP(0x4C);NC
	OP_BIT
	C_A(0x33);C_Z;C_NC;C_NN;C_V

	TEST	80
	A(0x33);OP(0x8C);NC
	OP_BIT
	C_A(0x33);C_Z;C_NC;C_N;C_NV

@@@ 
@@@ ASL/LSR
@@@ 
	@@ ASL
	
	TEST	81
	OP(0x2);NV
	OP_ASL
	C_OP(0x04);C_NZ;C_NC;C_NN;C_NV

	TEST	82
	OP(0x2);V
	OP_ASL
	C_OP(0x04);C_NZ;C_NC;C_NN;C_V

	TEST	83
	OP(0x81);NV
	OP_ASL
	C_OP(0x02);C_NZ;C_C;C_NN;C_NV

	TEST	84
	OP(0x0);NV
	OP_ASL
	C_OP(0x0);C_Z;C_NC;C_NN;C_NV

	TEST	85
	OP(0xFF);NV
	OP_ASL
	C_OP(0xFE);C_NZ;C_C;C_N;C_NV

	@@ ASL_A

	TEST	86
	A(0x2);NV
	OP_ASL_A
	C_A(0x04);C_NZ;C_NC;C_NN;C_NV

	TEST	87
	A(0x2);V
	OP_ASL_A
	C_A(0x04);C_NZ;C_NC;C_NN;C_V

	TEST	88
	A(0x81);NV
	OP_ASL_A
	C_A(0x02);C_NZ;C_C;C_NN;C_NV

	TEST	89
	A(0x0);NV
	OP_ASL_A
	C_A(0x0);C_Z;C_NC;C_NN;C_NV

	TEST	90
	A(0xFF);NV
	OP_ASL_A
	C_A(0xFE);C_NZ;C_C;C_N;C_NV


	@@ LSR

	TEST	91
	OP(0x0);V
	OP_LSR
	C_OP(0x0);C_Z;C_NC;C_NN;C_V

	TEST	92
	OP(0x0);NV
	OP_LSR
	C_OP(0x0);C_Z;C_NC;C_NN;C_NV

	TEST	93
	OP(0x1);V
	OP_LSR
	C_OP(0x0);C_Z;C_C;C_NN;C_V

	TEST	94
	OP(0xFF);V
	OP_LSR
	C_OP(0x7F);C_NZ;C_C;C_NN;C_V

	TEST	95
	OP(0xFE);V
	OP_LSR
	C_OP(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ LSR_A

	TEST	96
	A(0x0);V
	OP_LSR_A
	C_A(0x0);C_Z;C_NC;C_NN;C_V

	TEST	97
	A(0x0);NV
	OP_LSR_A
	C_A(0x0);C_Z;C_NC;C_NN;C_NV

	TEST	98
	A(0x1);V
	OP_LSR_A
	C_A(0x0);C_Z;C_C;C_NN;C_V

	TEST	99
	A(0xFF);V
	OP_LSR_A
	C_A(0x7F);C_NZ;C_C;C_NN;C_V

	TEST	100
	A(0xFE);V
	OP_LSR_A
	C_A(0x7F);C_NZ;C_NC;C_NN;C_V

@@@ 
@@@ ROL/ROR
@@@ 
	@@ ROL

	TEST	101
	OP(0);NC;V
	OP_ROL
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST	102
	OP(0);NC;NV
	OP_ROL
	C_OP(0);C_Z;C_NC;C_NN;C_NV

	TEST	103
	OP(0);C;V
	OP_ROL
	C_OP(1);C_NZ;C_NC;C_NN;C_V

	TEST	104
	OP(0x80);NC;V
	OP_ROL
	C_OP(0);C_Z;C_C;C_NN;C_V

	TEST	105
	OP(0x80);C;V
	OP_ROL
	C_OP(1);C_NZ;C_C;C_NN;C_V

	TEST	106
	OP(1);NC;V
	OP_ROL
	C_OP(2);C_NZ;C_NC;C_NN;C_V

	TEST	107
	OP(0x40);C;V
	OP_ROL
	C_OP(0x81);C_NZ;C_NC;C_N;C_V

	TEST	108
	OP(0xFF);C;V
	OP_ROL
	C_OP(0xFF);C_NZ;C_C;C_N;C_V

	@@ ROL_A

	TEST	109
	A(0);NC;V
	OP_ROL_A
	C_A(0);C_Z;C_NC;C_NN;C_V

	TEST	110
	A(0);NC;NV
	OP_ROL_A
	C_A(0);C_Z;C_NC;C_NN;C_NV

	TEST	111
	A(0);C;V
	OP_ROL_A
	C_A(1);C_NZ;C_NC;C_NN;C_V

	TEST	112
	A(0x80);NC;V
	OP_ROL_A
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST	113
	A(0x80);C;V
	OP_ROL_A
	C_A(1);C_NZ;C_C;C_NN;C_V

	TEST	114
	A(1);NC;V
	OP_ROL_A
	C_A(2);C_NZ;C_NC;C_NN;C_V

	TEST	115
	A(0x40);C;V
	OP_ROL_A
	C_A(0x81);C_NZ;C_NC;C_N;C_V

	TEST	116
	A(0xFF);C;V
	OP_ROL_A
	C_A(0xFF);C_NZ;C_C;C_N;C_V

	@@ ROR

	TEST	117
	OP(0);NC;NV
	OP_ROR
	C_OP(0);C_Z;C_NC;C_NN;C_NV

	TEST	118
	OP(0);NC;V
	OP_ROR
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST	119
	OP(0);C;NV
	OP_ROR
	C_OP(0x80);C_NZ;C_NC;C_N;C_NV

	TEST	120
	OP(1);NC;NV
	OP_ROR
	C_OP(0);C_Z;C_C;C_NN;C_NV

	TEST	121
	OP(2);C;NV
	OP_ROR
	C_OP(0x81);C_NZ;C_NC;C_N;C_NV

	@@ ROR_A

	TEST	122
	A(0);NC;NV
	OP_ROR_A
	C_A(0);C_Z;C_NC;C_NN;C_NV

	TEST	123
	A(0);NC;V
	OP_ROR_A
	C_A(0);C_Z;C_NC;C_NN;C_V

	TEST	124
	A(0);C;NV
	OP_ROR_A
	C_A(0x80);C_NZ;C_NC;C_N;C_NV

	TEST	125
	A(1);NC;NV
	OP_ROR_A
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST	126
	A(2);C;NV
	OP_ROR_A
	C_A(0x81);C_NZ;C_NC;C_N;C_NV



	adr	r0, 1f
	bl	emu_printf
2:	b	2b	
	ldmfd	sp!, {pc}
1:	.string "cpu test ok\n"
	ALIGN
fail:	
	stmfd	sp!, {r0-r14}
	mov	r1, REG_CYCLE
	adr	r0, 1f
	adr	lr, 2f
	ldr	pc,=printf
2:	ldmfd	sp!, {r0-r14}
3:	b	3b
1:	.string	"cpu test #%x failed\n"
	.pool
