
#define TEST(n)	mov	REG_CYCLE, #0+n
#define A(n)	mov	REG_A, #(n << 24)
#define X(n)	mov	REG_X, #0+n
#define Y(n)	mov	REG_Y, #0+n
#define S(n)	mov	REG_S, #0+n
#define OP(n)	mov	r0, #0+n
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
	@@ ADC
	
	TEST(0)
	A(0x10);OP(0x20);NC
	bl	ADC
	C_A(0x30);C_NZ;C_NC;C_NN;C_NV

	TEST(1)
	A(0);OP(0);C
	bl	ADC
	C_A(1);C_NZ;C_NC;C_NN;C_NV

	TEST(2)
	A(0xFF);OP(1);NC
	bl	ADC
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST(3)
	A(0xFF);OP(1);C
	bl	ADC
	C_A(1);C_NZ;C_C;C_NN;C_NV

	TEST(4)
	A(0x80);OP(1);NC
	bl	ADC
	C_A(0x81);C_NZ;C_NC;C_N;C_NV

	TEST(5)
	A(0x80);OP(0x80);NC
	bl	ADC
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST(6)
	A(0x7F);OP(0x7F);NC
	bl	ADC
	C_A(0xFE);C_NZ;C_NC;C_N;C_V

	@@ AND

	TEST(7)
	A(0x33);OP(0xCC);NC;NV
	bl	AND
	C_A(0);C_Z;C_NC;C_NN;C_NV
	
	TEST(8)
	A(0x33);OP(0xCC);C;V
	bl	AND
	C_A(0);C_Z;C_C;C_NN;C_V
	
	TEST(9)
	A(0xC3);OP(0xCC);C;NV
	bl	AND
	C_A(0xC0);C_NZ;C_C;C_N;C_NV

	TEST(10)
	A(0x3C);OP(0xCC);NC;V
	bl	AND
	C_A(0x0C);C_NZ;C_NC;C_NN;C_V

	@@ ASL
	
	TEST(11)
	OP(0x2);NV
	bl	ASL
	C_OP(0x04);C_NZ;C_NC;C_NN;C_NV

	TEST(12)
	OP(0x2);V
	bl	ASL
	C_OP(0x04);C_NZ;C_NC;C_NN;C_V

	TEST(13)
	OP(0x81);NV
	bl	ASL
	C_OP(0x02);C_NZ;C_C;C_NN;C_NV

	TEST(14)
	OP(0x0);NV
	bl	ASL
	C_OP(0x0);C_Z;C_NC;C_NN;C_NV

	TEST(15)
	OP(0xFF);NV
	bl	ASL
	C_OP(0xFE);C_NZ;C_C;C_N;C_NV

	@@ ASL_A

	TEST(16)
	A(0x2);NV
	bl	ASL_A
	C_A(0x04);C_NZ;C_NC;C_NN;C_NV

	TEST(17)
	A(0x2);V
	bl	ASL_A
	C_A(0x04);C_NZ;C_NC;C_NN;C_V

	TEST(18)
	A(0x81);NV
	bl	ASL_A
	C_A(0x02);C_NZ;C_C;C_NN;C_NV

	TEST(19)
	A(0x0);NV
	bl	ASL_A
	C_A(0x0);C_Z;C_NC;C_NN;C_NV

	TEST(20)
	A(0xFF);NV
	bl	ASL_A
	C_A(0xFE);C_NZ;C_C;C_N;C_NV

	@@ BIT

	TEST(21)
	A(0x33);OP(0xCC);NC
	bl	BIT
	C_A(0x33);C_Z;C_NC;C_N;C_V

	TEST(22)
	A(0x33);OP(0xCC);C
	bl	BIT
	C_A(0x33);C_Z;C_C;C_N;C_V

	TEST(23)
	A(0xC3);OP(0xCC);NC
	bl	BIT
	C_A(0xC3);C_NZ;C_NC;C_N;C_V

	TEST(24)
	A(0x33);OP(0x4C);NC
	bl	BIT
	C_A(0x33);C_Z;C_NC;C_NN;C_V

	TEST(25)
	A(0x33);OP(0x8C);NC
	bl	BIT
	C_A(0x33);C_Z;C_NC;C_N;C_NV

	@@ CMP

	TEST(26)
	A(0);OP(0);V
	bl	CMP
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST(27)
	A(0);OP(1);NV
	bl	CMP
	C_A(0);C_NZ;C_NC;C_N;C_NV

	TEST(28)
	A(2);OP(1);V
	bl	CMP
	C_A(2);C_NZ;C_C;C_NN;C_V

	TEST(29)
	A(0x81);OP(1);V
	bl	CMP
	C_A(0x81);C_NZ;C_C;C_N;C_V

	@@ CPX

	TEST(30)
	X(0);OP(0);V
	bl	CPX
	C_X(0);C_Z;C_C;C_NN;C_V

	TEST(31)
	X(0);OP(1);NV
	bl	CPX
	C_X(0);C_NZ;C_NC;C_N;C_NV

	TEST(32)
	X(2);OP(1);V
	bl	CPX
	C_X(2);C_NZ;C_C;C_NN;C_V

	TEST(33)
	X(0x81);OP(1);V
	bl	CPX
	C_X(0x81);C_NZ;C_C;C_N;C_V

	@@ CPY

	TEST(34)
	Y(0);OP(0);V
	bl	CPY
	C_Y(0);C_Z;C_C;C_NN;C_V

	TEST(35)
	Y(0);OP(1);NV
	bl	CPY
	C_Y(0);C_NZ;C_NC;C_N;C_NV

	TEST(36)
	Y(2);OP(1);V
	bl	CPY
	C_Y(2);C_NZ;C_C;C_NN;C_V

	TEST(37)
	Y(0x81);OP(1);V
	bl	CPY
	C_Y(0x81);C_NZ;C_C;C_N;C_V

	@@ DEC

	TEST(38)
	OP(1);C;V
	bl	DEC
	C_OP(0);C_Z;C_C;C_NN;C_V

	TEST(39)
	OP(1);NC;V
	bl	DEC
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST(40)
	OP(1);NC;NV
	bl	DEC
	C_OP(0);C_Z;C_NC;C_NN;C_NV

	TEST(41)
	OP(2);NC;V
	bl	DEC
	C_OP(1);C_NZ;C_NC;C_NN;C_V

	TEST(42)
	OP(0);NC;V
	bl	DEC
	C_OP(0xFF);C_NZ;C_NC;C_N;C_V

	TEST(43)
	OP(0x80);NC;V
	bl	DEC
	C_OP(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ DEX

	TEST(44)
	X(1);C;V
	bl	DEX
	C_X(0);C_Z;C_C;C_NN;C_V

	TEST(45)
	X(1);NC;V
	bl	DEX
	C_X(0);C_Z;C_NC;C_NN;C_V

	TEST(46)
	X(1);NC;NV
	bl	DEX
	C_X(0);C_Z;C_NC;C_NN;C_NV

	TEST(47)
	X(2);NC;V
	bl	DEX
	C_X(1);C_NZ;C_NC;C_NN;C_V

	TEST(48)
	X(0);NC;V
	bl	DEX
	C_X(0xFF);C_NZ;C_NC;C_N;C_V

	TEST(49)
	X(0x80);NC;V
	bl	DEX
	C_X(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ DEY

	TEST(50)
	Y(1);C;V
	bl	DEY
	C_Y(0);C_Z;C_C;C_NN;C_V

	TEST(51)
	Y(1);NC;V
	bl	DEY
	C_Y(0);C_Z;C_NC;C_NN;C_V

	TEST(52)
	Y(1);NC;NV
	bl	DEY
	C_Y(0);C_Z;C_NC;C_NN;C_NV

	TEST(53)
	Y(2);NC;V
	bl	DEY
	C_Y(1);C_NZ;C_NC;C_NN;C_V

	TEST(54)
	Y(0);NC;V
	bl	DEY
	C_Y(0xFF);C_NZ;C_NC;C_N;C_V

	TEST(55)
	Y(0x80);NC;V
	bl	DEY
	C_Y(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ EOR

	TEST(56)
	A(0x33);OP(0xCC);NC;NV
	bl	EOR
	C_A(0xFF);C_NZ;C_NC;C_N;C_NV
	
	TEST(57)
	A(0x33);OP(0xCC);C;V
	bl	EOR
	C_A(0xFF);C_NZ;C_C;C_N;C_V
	
	TEST(58)
	A(0xC3);OP(0xCC);C;NV
	bl	EOR
	C_A(0x0F);C_NZ;C_C;C_NN;C_NV

	TEST(59)
	A(0x3C);OP(0xCC);NC;V
	bl	EOR
	C_A(0xF0);C_NZ;C_NC;C_N;C_V

	@@ INC

	TEST(60)
	OP(0);C;V
	bl	INC
	C_OP(1);C_NZ;C_C;C_NN;C_V

	TEST(61)
	OP(0);NC;V
	bl	INC
	C_OP(1);C_NZ;C_NC;C_NN;C_V

	TEST(62)
	OP(0);NC;NV
	bl	INC
	C_OP(1);C_NZ;C_NC;C_NN;C_NV

	TEST(63)
	OP(0xFF);NC;V
	bl	INC
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST(64)
	OP(0x7F);NC;V
	bl	INC
	C_OP(0x80);C_NZ;C_NC;C_N;C_V

	TEST(65)
	OP(0x2F);NC;V
	bl	INC
	C_OP(0x30);C_NZ;C_NC;C_NN;C_V

	@@ INX

	TEST(66)
	X(0);C;V
	bl	INX
	C_X(1);C_NZ;C_C;C_NN;C_V

	TEST(67)
	X(0);NC;V
	bl	INX
	C_X(1);C_NZ;C_NC;C_NN;C_V

	TEST(68)
	X(0);NC;NV
	bl	INX
	C_X(1);C_NZ;C_NC;C_NN;C_NV

	TEST(69)
	X(0xFF);NC;V
	bl	INX
	C_X(0);C_Z;C_NC;C_NN;C_V

	TEST(70)
	X(0x7F);NC;V
	bl	INX
	C_X(0x80);C_NZ;C_NC;C_N;C_V

	TEST(71)
	X(0x2F);NC;V
	bl	INX
	C_X(0x30);C_NZ;C_NC;C_NN;C_V

	@@ INY

	TEST(72)
	Y(0);C;V
	bl	INY
	C_Y(1);C_NZ;C_C;C_NN;C_V

	TEST(73)
	Y(0);NC;V
	bl	INY
	C_Y(1);C_NZ;C_NC;C_NN;C_V

	TEST(74)
	Y(0);NC;NV
	bl	INY
	C_Y(1);C_NZ;C_NC;C_NN;C_NV

	TEST(75)
	Y(0xFF);NC;V
	bl	INY
	C_Y(0);C_Z;C_NC;C_NN;C_V

	TEST(76)
	Y(0x7F);NC;V
	bl	INY
	C_Y(0x80);C_NZ;C_NC;C_N;C_V

	TEST(77)
	Y(0x2F);NC;V
	bl	INY
	C_Y(0x30);C_NZ;C_NC;C_NN;C_V

	@@ LDA

	TEST(78)
	OP(0);C;V
	bl	LDA
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST(79)
	OP(0);NC;V
	bl	LDA
	C_A(0);C_Z;C_NC;C_NN;C_V

	TEST(80)
	OP(0);C;NV
	bl	LDA
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST(81)
	OP(1);C;V
	bl	LDA
	C_A(1);C_NZ;C_C;C_NN;C_V

	TEST(82)
	OP(0x7F);C;V
	bl	LDA
	C_A(0x7F);C_NZ;C_C;C_NN;C_V

	TEST(83)
	OP(0x80);C;V
	bl	LDA
	C_A(0x80);C_NZ;C_C;C_N;C_V

	@@ LDX

	TEST(84)
	OP(0);C;V
	bl	LDX
	C_X(0);C_Z;C_C;C_NN;C_V

	TEST(85)
	OP(0);NC;V
	bl	LDX
	C_X(0);C_Z;C_NC;C_NN;C_V

	TEST(86)
	OP(0);C;NV
	bl	LDX
	C_X(0);C_Z;C_C;C_NN;C_NV

	TEST(87)
	OP(1);C;V
	bl	LDX
	C_X(1);C_NZ;C_C;C_NN;C_V

	TEST(88)
	OP(0x7F);C;V
	bl	LDX
	C_X(0x7F);C_NZ;C_C;C_NN;C_V

	TEST(89)
	OP(0x80);C;V
	bl	LDX
	C_X(0x80);C_NZ;C_C;C_N;C_V

	@@ LDY

	TEST(90)
	OP(0);C;V
	bl	LDY
	C_Y(0);C_Z;C_C;C_NN;C_V

	TEST(91)
	OP(0);NC;V
	bl	LDY
	C_Y(0);C_Z;C_NC;C_NN;C_V

	TEST(92)
	OP(0);C;NV
	bl	LDY
	C_Y(0);C_Z;C_C;C_NN;C_NV

	TEST(93)
	OP(1);C;V
	bl	LDY
	C_Y(1);C_NZ;C_C;C_NN;C_V

	TEST(94)
	OP(0x7F);C;V
	bl	LDY
	C_Y(0x7F);C_NZ;C_C;C_NN;C_V

	TEST(95)
	OP(0x80);C;V
	bl	LDY
	C_Y(0x80);C_NZ;C_C;C_N;C_V

	@@ LSR

	TEST(96)
	OP(0x0);V
	bl	LSR
	C_OP(0x0);C_Z;C_NC;C_NN;C_V

	TEST(97)
	OP(0x0);NV
	bl	LSR
	C_OP(0x0);C_Z;C_NC;C_NN;C_NV

	TEST(98)
	OP(0x1);V
	bl	LSR
	C_OP(0x0);C_Z;C_C;C_NN;C_V

	TEST(99)
	OP(0xFF);V
	bl	LSR
	C_OP(0x7F);C_NZ;C_C;C_NN;C_V

	TEST(100)
	OP(0xFE);V
	bl	LSR
	C_OP(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ LSR_A

	TEST(101)
	A(0x0);V
	bl	LSR_A
	C_A(0x0);C_Z;C_NC;C_NN;C_V

	TEST(102)
	A(0x0);NV
	bl	LSR_A
	C_A(0x0);C_Z;C_NC;C_NN;C_NV

	TEST(103)
	A(0x1);V
	bl	LSR_A
	C_A(0x0);C_Z;C_C;C_NN;C_V

	TEST(104)
	A(0xFF);V
	bl	LSR_A
	C_A(0x7F);C_NZ;C_C;C_NN;C_V

	TEST(105)
	A(0xFE);V
	bl	LSR_A
	C_A(0x7F);C_NZ;C_NC;C_NN;C_V

	@@ ORA

	TEST(106)
	A(0x33);OP(0xCC);NC;NV
	bl	ORA
	C_A(0xFF);C_NZ;C_NC;C_N;C_NV
	
	TEST(107)
	A(0x33);OP(0xCC);C;V
	bl	ORA
	C_A(0xFF);C_NZ;C_C;C_N;C_V
	
	TEST(108)
	A(0xC3);OP(0xCC);C;NV
	bl	ORA
	C_A(0xCF);C_NZ;C_C;C_N;C_NV

	TEST(109)
	A(0x3C);OP(0);NC;V
	bl	ORA
	C_A(0x3C);C_NZ;C_NC;C_NN;C_V

	TEST(110)
	A(0);OP(0);NC;V
	bl	ORA
	C_A(0);C_Z;C_NC;C_NN;C_V

	@@ ROL

	TEST(111)
	OP(0);NC;V
	bl	ROL
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST(112)
	OP(0);NC;NV
	bl	ROL
	C_OP(0);C_Z;C_NC;C_NN;C_NV

	TEST(113)
	OP(0);C;V
	bl	ROL
	C_OP(1);C_NZ;C_NC;C_NN;C_V

	TEST(114)
	OP(0x80);NC;V
	bl	ROL
	C_OP(0);C_Z;C_C;C_NN;C_V

	TEST(115)
	OP(0x80);C;V
	bl	ROL
	C_OP(1);C_NZ;C_C;C_NN;C_V

	TEST(116)
	OP(1);NC;V
	bl	ROL
	C_OP(2);C_NZ;C_NC;C_NN;C_V

	TEST(117)
	OP(0x40);C;V
	bl	ROL
	C_OP(0x81);C_NZ;C_NC;C_N;C_V

	TEST(118)
	OP(0xFF);C;V
	bl	ROL
	C_OP(0xFF);C_NZ;C_C;C_N;C_V

	@@ ROL_A

	TEST(119)
	A(0);NC;V
	bl	ROL_A
	C_A(0);C_Z;C_NC;C_NN;C_V

	TEST(120)
	A(0);NC;NV
	bl	ROL_A
	C_A(0);C_Z;C_NC;C_NN;C_NV

	TEST(121)
	A(0);C;V
	bl	ROL_A
	C_A(1);C_NZ;C_NC;C_NN;C_V

	TEST(122)
	A(0x80);NC;V
	bl	ROL_A
	C_A(0);C_Z;C_C;C_NN;C_V

	TEST(123)
	A(0x80);C;V
	bl	ROL_A
	C_A(1);C_NZ;C_C;C_NN;C_V

	TEST(124)
	A(1);NC;V
	bl	ROL_A
	C_A(2);C_NZ;C_NC;C_NN;C_V

	TEST(125)
	A(0x40);C;V
	bl	ROL_A
	C_A(0x81);C_NZ;C_NC;C_N;C_V

	TEST(126)
	A(0xFF);C;V
	bl	ROL_A
	C_A(0xFF);C_NZ;C_C;C_N;C_V

	@@ ROR

	TEST(127)
	OP(0);NC;NV
	bl	ROR
	C_OP(0);C_Z;C_NC;C_NN;C_NV

	TEST(128)
	OP(0);NC;V
	bl	ROR
	C_OP(0);C_Z;C_NC;C_NN;C_V

	TEST(129)
	OP(0);C;NV
	bl	ROR
	C_OP(0x80);C_NZ;C_NC;C_N;C_NV

	TEST(130)
	OP(1);NC;NV
	bl	ROR
	C_OP(0);C_Z;C_C;C_NN;C_NV

	TEST(131)
	OP(2);C;NV
	bl	ROR
	C_OP(0x81);C_NZ;C_NC;C_N;C_NV

	@@ ROR_A

	TEST(132)
	A(0);NC;NV
	bl	ROR_A
	C_A(0);C_Z;C_NC;C_NN;C_NV

	TEST(133)
	A(0);NC;V
	bl	ROR_A
	C_A(0);C_Z;C_NC;C_NN;C_V

	TEST(134)
	A(0);C;NV
	bl	ROR_A
	C_A(0x80);C_NZ;C_NC;C_N;C_NV

	TEST(135)
	A(1);NC;NV
	bl	ROR_A
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST(136)
	A(2);C;NV
	bl	ROR_A
	C_A(0x81);C_NZ;C_NC;C_N;C_NV

	@@ SBC

	TEST(137)
	A(0);OP(0);C
	bl	SBC
	C_A(0);C_Z;C_C;C_NN;C_NV

	TEST(138)
	A(0);OP(0);NC
	bl	SBC
	C_A(0xFF);C_NZ;C_NC;C_N;C_NV

	TEST(139)
	A(0x23);OP(0x5);C
	bl	SBC
	C_A(0x1E);C_NZ;C_C;C_NN;C_NV

	TEST(140)
	A(0x23);OP(0x5);NC
	bl	SBC
	C_A(0x1D);C_NZ;C_C;C_NN;C_NV

	TEST(141)
	A(0x80);OP(1);C
	bl	SBC
	C_A(0x7F);C_NZ;C_C;C_NN;C_V

	TEST(142)
	A(0x20);OP(0x80);C
	bl	SBC
	C_A(0xA0);C_NZ;C_NC;C_N;C_V



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
