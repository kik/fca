#include "nes.h"


	SECTION_FAST
	ALIGN

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ PPUレジスタを読む
@@@ 
@@@ 
@@@ 

	.globl	read_ppu_reg
read_ppu_reg:	
	bic	r1, REG_ADDR, #0x2000
	teq	r1, #0x02
	beq	read_2002
	teq	r1, #0x07
	beq	read_2007
	mov	r0, #0x20
	mov	pc, lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ PPUレジスタに書く
@@@ 
@@@ 
@@@ 
	.globl	write_ppu_reg
write_ppu_reg:	
	bic	r1, REG_ADDR, #0x2000
	cmp	r1, #8
	ldrcc	pc, [pc, r1, lsl #2]
	mov	pc, lr
	.long write_2000, write_2001, write_2002, write_2003
	.long write_2004, write_2005, write_2006, write_2007


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ PPU の制御レジスタ
@@@ 
@@@ これらは REG_P_REST におかれる
@@@ 
@@@ P_REST[7]		$2005/$2006 トグルフラグ
@@@ P_REST[8-D]		$2000[2-7]
@@@ P_REST[E-F]		$2001[3-4]
@@@ P_REST[10-14]	$2002[4-7]
@@@ 
@@@ という配置になっている
@@@ 

@@@ 
@@@ $2000に書く
@@@ 
@@@ P_REST[8-D]		$2000[2-7]
@@@ 

write_2000:	
	mov	r1, r0, lsr #2
	bic	REG_P_REST, REG_P_REST, #P_REST_2000
	orr	REG_P_REST, REG_P_REST, r1, lsl #8

	@@ t:00001100 00000000=d:00000011
	ldrh	r1, loopy_t
	bic	r1, r1, #0x0C00
	and	r2, r0, #3
	orr	r1, r1, r2, lsl #10
	strh	r1, loopy_t

	mov	pc, lr

@@@ 
@@@ $2001 に書く
@@@ 
@@@ P_REST[E-F]		$2001[3-4]
@@@ 
write_2001:	
	and	r1, r0, #0x18
	bic	REG_P_REST, REG_P_REST, #P_REST_2001
	orr	REG_P_REST, REG_P_REST, r1, lsl #11
	mov	pc, lr

@@@ 
@@@ $2002 を読む
@@@ 
@@@ P_REST[10-14]	$2002[4-7]
@@@ 

read_2002:	
	bic	REG_P_REST, REG_P_REST, #P_REST_PPU_TOGGLE
	and	r0, REG_P_REST, #P_REST_2002
	mov	r0, r0, lsr #12
	bic	REG_P_REST, REG_P_REST, #P_REST_IN_VBL
	mov	pc, lr

@@@ 
@@@ $2002 には書けない
@@@ 
write_2002:	
	mov	pc, lr



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ スプライトの管理レジスタ
@@@ 

@@@ 
@@@ $2003 に書く
@@@ 

write_2003:	
#if 0
	strb	r0, ppu_reg_2003
#endif
	mov	pc, lr

@@@ 
@@@ $2004 に書く
@@@ 

write_2004:	
#if 0
	ldr	r2, =sprite_ram
	ldrb	r1, ppu_reg_2003
	strb	r0, [r2, r1]
	add	r1, r1, #1
	strb	r1, ppu_reg_2003
#endif
	mov	pc, lr





@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ VRAM の R/W レジスタ
@@@ 

@@@ 
@@@ 同時にロード・ストアできるようにloopy_t は loop_xの次におく
@@@ loopy_x は上3ビットを使う
@@@ 
	ALIGN
loopy_x:	.short	0
loopy_t:	.short	0
loopy_v:	.long	0

	ALIGN

@@@ 
@@@ $2005 に書く
@@@ 

write_2005:	
	tst	REG_P_REST, #P_REST_PPU_TOGGLE
	eor	REG_P_REST, REG_P_REST, #P_REST_PPU_TOGGLE

	bne	1f
	@@ first write
	@@ tx:0000000000011111.111=d:11111111
	ldr	r1, loopy_x
	mov	r1, r1, lsl #21
	orr	r1, r0, r1, lsl #8
	mov	r1, r1, lsl #21
	str	r1, loopy_x
	mov	pc, lr

1:	@@ second write
	@@ t:00000011 11100000=d:11111000
	@@ t:01110000 00000000=d:00000111
	ldrh	r1, loopy_t
	bic	r1, r1, #0x3E0
	and	r2, r0, #0xF8
	orr	r2, r2, r1, lsl #2

	bic	r2, r2, #0x7000
	and	r1, r0, #7
	orr	r2, r2, r1, lsl #12
	strh	r2, loopy_t
	mov	pc, lr

@@@ 
@@@ $2006 に書く
@@@ 

write_2006:	
	tst	REG_P_REST, #P_REST_PPU_TOGGLE
	eor	REG_P_REST, REG_P_REST, #P_REST_PPU_TOGGLE

	bne	1f
	@@ first write
	@@ t:00111111 00000000=d:00111111
	@@ t:11000000 00000000=0
	and	r1, r0, #0x3F
	strb	r1, loopy_t + 1
	mov	pc, lr

1:	@@ second write
	@@ t:0000000011111111=d:11111111
	@@ v=t
	ldrb	r2, loopy_t + 1
	orr	r2, r0, r2, lsl #8
	strh	r2, loopy_t
	strh	r2, loopy_v
	mov	pc, lr

@@@ 
@@@ $2007 の読み出し
@@@ 

read_2007:	
	ldrh	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r3, r1, #1
	addne	r3, r1, #32
	strh	r3, loopy_v
	bic	r1, r1, #0xC000
	adr	r0, 1f
	b	emu_printf

1:	.string "read 2007 %x\n"
	ALIGN

@@@ 
@@@ $2007 に書き込み
@@@ 

write_2007:	
	ldrh	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r3, r1, #1
	addne	r3, r1, #32
	strh	r3, loopy_v
	
	mov	pc, lr
	bic	r1, r1, #0xC000
	mov	r2, r0
	adr	r0, 1f
	b	emu_printf
	
1:	.string "write 2007 %x %x\n"
	ALIGN

#if 0
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ こっから下はしばらく外しておく
@@@ 


#if 0
#include "palette.S"

translate_palette:	
	mov	r0, #0x05000000
	adr	r1, bg_palette
	adr	r2, nes_palette
1:	
	ldrb	r3, [r1], #1
	ldr	r3, [r2, r3, lsl #2]
	strh	r3, [r0], #2
	ldrb	r3, [r1], #1
	ldr	r3, [r2, r3, lsl #2]
	strh	r3, [r0], #2
	ldrb	r3, [r1], #1
	ldr	r3, [r2, r3, lsl #2]
	strh	r3, [r0], #2
	ldrb	r3, [r1], #1
	ldr	r3, [r2, r3, lsl #2]
	strh	r3, [r0], #2

	adr	r3, bg_palette + 16
	teq	r3, r1
	addne	r0, r0, #24
	bne	1b
	mov	pc, lr

	ALIGN
bg_palette:	
	.fill	0x16, 1, 0
sprite_palette:	
	.fill	0x16, 1, 0

	ALIGN
read_palette:	
	and	r3, r1, #0x1F
	adr	r2, bg_palette
	ldrb	r0, [r2, r3]
	mov	pc, lr

write_palette:	
	and	r2, r0, #0x3F
	and	r1, r1, #0x1F
	adr	r3, bg_palette
	strb	r2, [r3, r1]
	tst	r1, #0xF
	eoreq	r1, r1, #0x10
	streqb	r2, [r3, r1]
	mov	pc, lr

	ALIGN
	.globl	name_trans_test
name_trans_test:
	mov	r0, #0x04000000
1:	
	ldrh	r1, [r0, #0x04]
	tst	r1, #1
	beq	1b

	adr	r1, map_table_0
	ldr	r2, [r1, #(map_dirty_0 - map_table_0)]
	teq	r2, #0
	beq	translate_palette
	mov	r2, #0
	str	r2, [r1, #(map_dirty_0 - map_table_0)]
	str	r1, [r0, #0xB0]	
	ldr	r1, =0x6003800
	str	r1, [r0, #0xB4]
	mov	r1, #32 * 30 / 2
	str	r1, [r0, #0xB8]
	mov	r1, #0x8400
	strh	r1, [r0, #0xBA]
#if 0
	mov	r1, #0x06000000
	add	r1, r1, #0x3800
	mov	r2, #32 * 30 / 2
1:	
	ldr	r3, [r0], #4
	subs	r2, r2, #1
	str	r3, [r1], #4
	bne	1b
#endif
	b	translate_palette
	mov	pc, lr

	.pool
#endif

@@@ 
@@@ マップテーブルと属性テーブルは書き込み時にGBAのマップテーブルに
@@@ 変換して保存する。これだとマップテーブルを読むのは簡単だけど
@@@ 属性を読むのはしんどいので属性は他所にも保存しておく
@@@ マップテーブルへの書き込みは直接VRAMに書く
@@@ そうしないと間に合わない
@@@ 
@@@ NES
@@@ 
@@@ 00
@@@ ||++---属性
@@@ ||||0000
@@@ |||||||| ++++++++---タイル番号
@@@ FEDCBA98 76543210
@@@ ||||||++-++++++++---タイル番号
@@@ ||||++---V・Hフリップ
@@@ ++++---パレット番号
@@@ 
@@@ GBA
@@@
@@@ chrテーブルは256づつふたつに分けなければならない
@@@ 0600_0000と
@@@ 0600_4000から始まるテーブルを使う
@@@ 
@@@ マップテーブルは最大4つ必要である
@@@ 0600_2000
@@@ 0600_2800
@@@ 0600_3000
@@@ 0600_3800
@@@ を使う
@@@ 

attr_table_0:	.fill	0x40, 1, 0
attr_table_1:	.fill	0x40, 1, 0
attr_table_2:	.fill	0x40, 1, 0
attr_table_3:	.fill	0x40, 1, 0

sprite_ram:	
	.fill	0x256, 1, 0




	ALIGN
	.globl	set_vram_bank_0to7
set_vram_bank_0to7:	
	adr	r1, chr_table_map
	str	r0, [r1, #0]
	str	r0, [r1, #4]
	str	r0, [r1, #8]
	str	r0, [r1, #0xC]
	str	r0, [r1, #0x10]
	str	r0, [r1, #0x14]
	str	r0, [r1, #0x18]
	str	r0, [r1, #0x1C]
	mov	pc, lr

	ALIGN
map_table_map:	
	.long	0x06002000
	.long	0x06002800
	.long	0x06003000
	.long	0x06003800

attr_table_map:	
	.long	attr_table_0
	.long	attr_table_1
	.long	attr_table_2
	.long	attr_table_3

chr_table_map:	
	.long	0, 0, 0, 0
	.long	0, 0, 0, 0

	ALIGN
	.globl	ppu_start_frame
ppu_start_frame:	
	@ldr	r1, loopy_t
	@str	r1, loopy_v
	ldr	r0, ppu_reg_2002
	orr	r0, r0, #0x40
	str	r0, ppu_reg_2002
	@mov	pc, lr
	b	name_trans_test

	.globl	read_2007
read_2007:	
	ldr	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r3, r1, #1
	addne	r3, r1, #32
	str	r3, loopy_v

	bic	r1, r1, #0xC000

	cmp	r1, #0x3F00
	bcs	read_palette

	ldrb	r0, read_2007_buffer
	cmp	r1, #0x2000
	bcc	read_chr

	bic	r1, r1, #0x3000
read_map:
	mov	r2, r1, lsr #10
	and	r1, r1, #0xC00
	cmp	r1, #0x3C0
	bcc	read_attr

	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #2]
	@@ これは正しく読めるのだろうか？
	ldrb	r1, [r3, r1, lsl #1]
	strb	r1, read_2007_buffer
	mov	pc, lr

read_attr:	
	and	r1, r1, #0x3F
	adr	r3, attr_table_map
	ldr	r3, [r3, r2, lsl #2]
	ldrb	r1, [r3, r1]
	strb	r1, read_2007_buffer
	mov	pc, lr

read_chr:
	mov	r2, r1, lsr #10
	adr	r3, chr_table_map
	ldr	r3, [r3, r2, lsl #2]
	ldrb	r1, [r3, r1]
	strb	r1, read_2007_buffer
	mov	pc, lr

	ALIGN
read_2007_buffer:	.byte	0


	ALIGN
	.globl	write_2007

write_2007:
	ldrh	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r2, r1, #1
	addne	r2, r1, #32
	strh	r2, loopy_v

	bic	r1, r1, #0xC000

	mov	r2, r0
	adr	r0, 1f
	b	emu_printf
1:	.string "write 2007 %x %x\n"

	cmp	r1, #0x3F00
	bcs	write_palette
	cmp	r1, #0x2000
	bcc	write_chr
	bic	r1, r1, #0x3000
write_map:	
	mov	r2, r1, lsr #10
	bic	r1, r1, #0xC00

	cmp	r1, #0x3C0
	bcs	write_attr

	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #4]
	add	r1, r3, r1, lsl #1
	@@ ロードできるのかな？
	ldrb	r2, [r1, #1]
	orr	r2, r0, r2, lsl #8
	strh	r2, [r1]

	mov	pc, lr

write_chr:	
	mov	pc, lr

write_attr:
	stmfd	sp!, {r4, lr}
	and	r1, r1, #0x3F
	adr	r3, attr_table_map
	ldr	r3, [r3, r2, lsl #4]
	strb	r0, [r3, r1]
	
	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #4]

	adr	r2, attr_index_table
	mov	r1, r1, lsl #1
	ldrh	r2, [r2, r1]

	mov	r4, #0x3000
	orr	r4, r4, r4, lsl #16
	
	orr	r0, r0, r0, lsl #16
	@@ 
	@@ A B	00000000DDCCBBAA 00000000DDCCBBAA
	@@ C D	FEDCBA9876543210 FEDCBA9876543210
	@@ 

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ A	00AA000000000000 00AA000000000000
	ldr	lr, [r3, r2]!
	bic	lr, lr, r4
	and	r1, r4, r0, lsl #12
	orr	lr, lr, r1
	str	lr, [r3]

	ldr	lr, [r3, #64]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #64]

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ B	00BB000000000000 00BB000000000000
	ldr	lr, [r3, #4]
	bic	lr, lr, r4
	and	r1, r4, r0, lsl #10
	orr	lr, lr, r1
	str	lr, [r3, #4]

	ldr	lr, [r3, #68]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #68]

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ C	00CC000000000000 00CC000000000000
	ldr	lr, [r3, #128]
	bic	lr, lr, r4
	and	r1, r4, r0, lsl #8
	orr	lr, lr, r1
	str	lr, [r3, #128]

	ldr	lr, [r3, #192]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #192]

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ D	00DD000000000000 00DD000000000000
	ldr	lr, [r3, #132]
	bic	lr, lr, r4
	and	r1, r4, r0, lsl #8
	orr	lr, lr, r1
	str	lr, [r3, #132]

	ldr	lr, [r3, #196]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #196]

	and	r0, r0, #0xFF
	ldmfd	sp!, {r4, pc}

attr_index_table:
#define P(x, y) ((x * 0x80 + y * 4) * 2)
	.short P(0,0), P(0,1), P(0,2), P(0,3), P(0,4), P(0,5), P(0,6), P(0,7)
	.short P(1,0), P(1,1), P(1,2), P(1,3), P(1,4), P(1,5), P(1,6), P(1,7)
	.short P(2,0), P(2,1), P(2,2), P(2,3), P(2,4), P(2,5), P(2,6), P(2,7)
	.short P(3,0), P(3,1), P(3,2), P(3,3), P(3,4), P(3,5), P(3,6), P(3,7)
	.short P(4,0), P(4,1), P(4,2), P(4,3), P(4,4), P(4,5), P(4,6), P(4,7)
	.short P(5,0), P(5,1), P(5,2), P(5,3), P(5,4), P(5,5), P(5,6), P(5,7)
	.short P(6,0), P(6,1), P(6,2), P(6,3), P(6,4), P(6,5), P(6,6), P(6,7)
	.short P(7,0), P(7,1), P(7,2), P(7,3), P(7,4), P(7,5), P(7,6), P(7,7)


	ALIGN
@@@ 
@@@ 同時にロード・ストアできるようにloopy_t は loop_xの次におく
@@@ loopy_x は上3ビットを使う
@@@ 
loopy_x:	.short	0
loopy_t:	.short	0
loopy_v:	.long	0

ppu_reg_2003:	.byte	0

	ALIGN

	ALIGN
	.globl	ppu_start_vbl
	.globl	ppu_end_vbl
ppu_start_vbl:	
	mov	r0, #1
	str	r0, vbl_state
	ldr	r0, ppu_reg_2002
	orr	r0, r0, #0x80
	str	r0, ppu_reg_2002
	mov	pc, lr

ppu_end_vbl:	
	mov	r0, #0
	str	r0, vbl_state
	ldr	r0, ppu_reg_2002
	and	r0, r0, #0x3F
	str	r0, ppu_reg_2002
	mov	pc, lr

vbl_state:	.long 0

	ALIGN

	.globl	read_2002
read_2002:	
	stmfd	sp!, {lr}
	mov	r0, #0
	str	r0, toggle_2005_2006
	ldr	r0, ppu_reg_2002
	and	r1, r0, #0x3F
	str	r1, ppu_reg_2002
	ldmfd	sp!, {pc}

1:	.string	"read ppu reg 2002 %x\n"



@@@ 
@@@ PPU の処理で一番大変なのが
@@@ NES のタイルを GBA のタイルに変換することである
@@@ 
@@@ p[0] = ABCDEFGH
@@@ p[8] = abcdefgh
@@@      ↓
@@@ 
@@@ 00hH00gG 00fF00eE 00dD00cC 00bB00aA
@@@ 
@@@ の形に変換しなければいけない
@@@ 
@@@ 
@@@ 
@@@ 
@@@ 
	SECTION_SLOW
	ALIGN
	.globl	init_ppu

init_ppu:
	@@ 
	@@ タイルの変換テーブルを初期化する
	@@ 
	ldr	r1, =tile_translate_table
	mov	r2, #0
1:	
	mov	r3, #0

	tst	r2, #0x80;  orrne	r3, r3, #0x00000001
	tst	r2, #0x40;  orrne	r3, r3, #0x00000010
	tst	r2, #0x20;  orrne	r3, r3, #0x00000100
	tst	r2, #0x10;  orrne	r3, r3, #0x00001000
	tst	r2, #0x08;  orrne	r3, r3, #0x00010000
	tst	r2, #0x04;  orrne	r3, r3, #0x00100000
	tst	r2, #0x02;  orrne	r3, r3, #0x01000000
	tst	r2, #0x01;  orrne	r3, r3, #0x10000000

	str	r3, [r1], #4
	add	r2, r2, #1
	teq	r2, #256
	bne	1b

	mov	pc, lr



	SECTION_FAST
	ALIGN

	.globl	translate_tiles

translate_tiles:
	stmfd	sp!, {r4-r6}	
	adr	r1, tile_translate_table
	ldr	r5, =0x06000000
	mov	r2, #256
1:	
	mov	r6, #8
2:	
	ldrb	r3, [r0]
	ldrb	r4, [r0, #8]
	ldr	r3, [r1, r3, lsl #2]
	ldr	r4, [r1, r4, lsl #2]
	orr	r3, r3, r4, lsl #1
	str	r3, [r5], #4

	add	r0, r0, #1
	subs	r6, r6, #1
	bne	2b

	add	r0, r0, #8
	subs	r2, r2, #1
	bne	1b

	ldr	r5, =0x06004000
	mov	r2, #256
1:	
	mov	r6, #8
2:	
	ldrb	r3, [r0]
	ldrb	r4, [r0, #8]
	ldr	r3, [r1, r3, lsl #2]
	ldr	r4, [r1, r4, lsl #2]
	orr	r3, r3, r4, lsl #1
	str	r3, [r5], #4

	add	r0, r0, #1
	subs	r6, r6, #1
	bne	2b

	add	r0, r0, #8
	subs	r2, r2, #1
	bne	1b

	ldmfd	sp!, {r4-r6}
	mov	pc, lr
	
	.pool
	ALIGN
tile_translate_table:	
	.fill	256, 4, 0
	
@@@ 
@@@ ここより上はしばらくはずしておく
@@@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#endif
	SECTION_FAST
	.globl	read_high_reg
	.globl	read_save_ram
	.globl	write_high_reg
	.globl	write_save_ram
read_high_reg:	
read_save_ram:	
write_high_reg:	
write_save_ram:	
	mov	pc, lr


	.globl	init_ppu
init_ppu:
	mov	pc, lr

	.globl	set_vram_bank_0to7
set_vram_bank_0to7:	
	mov	pc, lr

	.globl	ppu_start_frame
ppu_start_frame:	
	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	moveq	pc, lr
	ldr	r1, loopy_t
	str	r1, loopy_v
	mov	pc, lr

	.globl	ppu_start_vbl
	.globl	ppu_end_vbl
ppu_start_vbl:	
	orr	REG_P_REST, REG_P_REST, #P_REST_IN_VBL
	mov	pc, lr

ppu_end_vbl:	
	bic	REG_P_REST, REG_P_REST, #(P_REST_IN_VBL | P_REST_SPR_HIT)
	mov	pc, lr
