#include "nes.h"

	SECTION_FAST
	ALIGN


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ スプライトの表示法
@@@ 
@@@ フレームの開始時にライン順にソートする(データ形式を変換する)
@@@ 各ラインごとにタイルのデータを一ライン変換してVRAMに送る
@@@ VRAMは循環するように使う
@@@ 
@@@ スプライトのデータ構造は
@@@ 
@@@ VRAMの開始アドレス(GBA) 32bits
@@@ VRAMの開始アドレス(FC)  16bits
@@@ 対応するスプライト(GBA) 32bits      8/16を切り替えるのに使う
@@@ 次のスプライト          32bits
@@@ 


@@@ 
@@@ 次に使うタイルの保存場所(スプライトのタイル番号)
@@@ 
gba_sprite_tile:	.long	0


	SECTION_SLOW
	ALIGN
@@@ 
@@@ 各ラインごとに表示するスプライトのリスト
@@@ 
sprite_sort_table:	.fill	256, 4, 0



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ スプライトの変換
@@@ 
@@@ スプライトも縦方向に縮小しなければならない。
@@@ スプライトRAMは読めないので元を保存する必要はない
@@@ ただし，SPR #0 はヒットフラグで使うので必要
@@@ 
@@@ NES
@@@ 0
@@@ 76543210
@@@ ++++++++---Y - 1
@@@ 
@@@ 1
@@@ 76543210
@@@ ++++++++---Tile #
@@@ 
@@@ 2
@@@ 76543210
@@@ ||||||++---Palette
@@@ |||+++---Unused
@@@ ||+---Priority (0=Front, 1=Behind)
@@@ |+---H flip
@@@ +---V flip
@@@ 
@@@ 3
@@@ 76543210
@@@ ++++++++---X
@@@ 
@@@ GBA
@@@ 
@@@ 0
@@@ FEDCBA9876543210
@@@ ||||||||++++++++---Y
@@@ |||||||+---R	<= 1
@@@ ||||||+---SD	<= 0
@@@ ||||++---Mode	<= 0
@@@ |||+---M		<= 0
@@@ ||+---C		<= 0
@@@ ++---Shape		<= 00 8x8, 01 8x16
@@@ 
@@@ 1
@@@ FEDCBA9876543210
@@@ |||||||+++++++++---X
@@@ ||+++++---Rot	<= NES VH
@@@ ++---Size		<= 0
@@@ 
@@@ 2
@@@ FEDCBA9876543210
@@@ ||||||++++++++++---Tile # 注意!!!
@@@ ||||++---Priority
@@@ ++++---Palette #
@@@ 
@@@ 
@@@ Tile # は面倒な変換をしなければならない
@@@ 
@@@ SPR_SZ	SPR_ADR		9876543210
@@@ 8x8		0		||++++++++---NES Tile#
@@@				++---00
@@@ 8x8		1		9876543210
@@@				||++++++++---NES Tile#
@@@				++---01
@@@ 8x16	*		9876543210
@@@				|||||||||+---0
@@@				||+++++++---NES Tile# & 0xFE
@@@				++---00(# & 1 == 0), 01(# & 1 == 1)

nes_sprite_0:	
nes_sprite:	.fill	64, 4, 0

	.globl	spr_dma
spr_dma:	
	sub	REG_CYCLE, REG_CYCLE, #512
	sub	REG_CYCLE, REG_CYCLE, #2
	adr	r1, nes_sprite
	mov	r2, #64
1:	ldr	r3, [r0], #4
	str	r3, [r1], #4
	subs	r2, r2, #1
	bne	1b
	mov	pc, lr

@@@ 
@@@ $2003 に書く
@@@ 

ppu_reg_2003:	.byte	0
	
	ALIGN
	.globl	write_2003

write_2003:	
	strb	r0, ppu_reg_2003
	mov	pc, lr

@@@ 
@@@ $2004 に書く
@@@ 

	.globl	write_2004

write_2004:
	ldrb	r1, ppu_reg_2003
	add	r2, r1, #1
	strb	r2, ppu_reg_2003

	adr	r3, nes_sprite
	strb	r0, [r3, r1]

	mov	pc, lr

	.globl	update_spr

update_spr:	
	stmfd	sp!, {r4, r5, lr}
	adr	r0, nes_sprite
	adr	r1, gba_sprite
	mov	r2, #64
1:	
	ldr	r3, [r0], #4
	@@ Y
	and	r5, r3, #255
	sub	r5, r5, #15
	add	r5, r5, r5, lsl #1
	mov	r5, r5, lsr #2
	strb	r5, [r1], #8

	mov	r5, #0
	tst	REG_P_REST, #P_REST_SPR_SZ
	movne	r5, #0x80
	strb	r5, [r1, #-7]

	mov	r4, r3, lsr #24
	sub	r4, r4, #8
	bic	r4, r4, #0xFE00
	and	r5, r3, #0xC0 << 16
	orr	r4, r4, r5, lsr #10
	strh	r4, [r1, #-6]

	@@ test priority
	tst	r3, #0x20 << 16
	moveq	r4, #0
	movne	r4, #0x0C00

	and	r5, r3, #0x03 << 16
	orr	r4, r4, r5, lsr #4

	tst	REG_P_REST, #P_REST_SPR_ADR
	moveq	r5, #0
	movne	r5, #0x200
	tst	REG_P_REST, #P_REST_SPR_SZ
	movne	r5, r3, lsl #1
	bicne	r3, r3, #0x0100
	and	r5, r5, #0x200
	orr	r4, r4, r5
	and	r3, r3, #0xFF00
	orr	r4, r4, r3, lsr #8
	strh	r4, [r1, #-4]

	subs	r2, r2, #1
	bne	1b
	ldmfd	sp!, {r4, r5, pc}

	.globl	gba_sprite

gba_sprite:	
	.fill	64, 8, 0


	.globl	init_gba_spr

init_gba_spr:	
	mov	r0, #0x07000000
	mov	r1, #128
	@@ 全てのスプライトを消す
	mov	r2, #160
	mov	r3, #0
1:
	str	r2, [r0], #4
	str	r3, [r0], #4
	subs	r1, r1, #1
	bne	1b

	ldr	r0, =gba_sprite
	mov	r1, #64
	@@ Rフラグを立てる
	mov	r2, #0x0100
1:	
	str	r3, [r0], #4
	str	r3, [r0], #4
	subs	r1, r1, #1
	bne	1b
#if 0
	@@ 
	@@ スプライトの縮小はなんか見た目がよくないので
	@@ はずしておく
	adr	r0, gba_sprite
	mov	r1, #0x0100	@ X Scale
	mov	r2, #0x00C0	@ Y Scale
	mov	r3, #0
	strh	r1, [r0, #6]
	strh	r3, [r0, #14]
	strh	r3, [r0, #22]
	strh	r2, [r0, #30]
	add	r0, r0, #32

	mov	r1, #0xFF00	@ X Scale (flip)
	mov	r2, #0x00C0	@ Y Scale
	mov	r3, #0
	strh	r1, [r0, #6]
	strh	r3, [r0, #14]
	strh	r3, [r0, #22]
	strh	r2, [r0, #30]
	add	r0, r0, #32

	mov	r1, #0x0100	@ X Scale
	mov	r2, #0xFF00	@ Y Scale (flip)
	orr	r2, r2, #0x40
	mov	r3, #0
	strh	r1, [r0, #6]
	strh	r3, [r0, #14]
	strh	r3, [r0, #22]
	strh	r2, [r0, #30]
	add	r0, r0, #32

	mov	r1, #0xFF00	@ X Scale (flip)
	mov	r2, #0xFF00	@ Y Scale (flip)
	orr	r2, r2, #0x40
	mov	r3, #0
	strh	r1, [r0, #6]
	strh	r3, [r0, #14]
	strh	r3, [r0, #22]
	strh	r2, [r0, #30]
#endif
	mov	pc, lr

@@@ 
@@@ HITフラグをチェックする
@@@ 
@@@ r0 <= ライン番号(0-239)
@@@ 
	.globl	check_spr_hit

check_spr_hit:	
	ldr	r3, nes_sprite_0
	add	r1, r3, #1
	sub	r2, r0, r1
	and	r2, r2, #255
	mov	r1, #8
	tst	REG_P_REST, #P_REST_SPR_SZ
	movne	r1, #16
	cmp	r2, r1
	movcs	pc, lr

	sub	r1, r1, #1
	@@ V Flip?
	tst	r3, #0x800000
	subne	r2, r1, r2	

	@@ Tile #
	and	r0, r3, #255 << 8
	mov	r1, #0
	tst	REG_P_REST, #P_REST_SPR_ADR
	movne	r1, #0x100
	tst	REG_P_REST, #P_REST_SPR_SZ
	andne	r1, r0, #0x100
	bicne	r0, r0, #0x100
	cmp	r2, #8
	addcs	r0, r0, #1
	subcs	r2, r2, #8
	add	r0, r1, r0, lsr #8
	orr	r0, r2, r0, lsl #4
	mov	r2, r0, lsr #10
	@@ 
	@@ ここでタイルを読む
	@@ 
	ldr	r1, =tile_map
	ldr	r2, [r1, r2, lsl #2]
	bic	r0, r0, #0xFC00
	ldrb	r0, [r2, r0]!
	ldrb	r2, [r2, #8]
	orrs	r2, r2, r0
	@@ ちょっと手抜き
	orrne	REG_P_REST, REG_P_REST, #P_REST_SPR_HIT
	mov	pc, lr


@@@ 
@@@ 途中まで書いたが面倒すぎる
@@@ 
#if 0
	ldmfdeq	sp!, {r4, r5}
	beq	check_spr_hit_ret

	@@ r2がスプライトのビットマップ
	tst	r3, #0x400000
	beq	1f
	@@ H flip
	mov	r4, #0
	tst	r2, #0x01;	orrne	r4, r4, #0x80
	tst	r2, #0x02;	orrne	r4, r4, #0x40
	tst	r2, #0x04;	orrne	r4, r4, #0x20
	tst	r2, #0x08;	orrne	r4, r4, #0x10
	tst	r2, #0x10;	orrne	r4, r4, #0x08
	tst	r2, #0x20;	orrne	r4, r4, #0x04
	tst	r2, #0x40;	orrne	r4, r4, #0x02
	tst	r2, #0x80;	orrne	r4, r4, #0x01
	mov	r2, r4
1:	
	mov	r4,     #0x04100000
	orr	r4, r4, #0x000FE000
	and	r1, r1, r4
	bic	r0, r0, r4, lsr #16

	@@ スプライトのX位置
	and	r4, r3, #0xFF << 24
	@@ X方向にスクロール
	add	r1, r1, r4, lsr #11
	tst	r1, r1, #0x20 << 16
	@@ name table Xを反転
	eorne	r1, r1, #0x0420 << 16
	orr	r0, r1, r0, lsl #16

	and	r1, r0, #0x0C00 << 16
	adr	r5, map_table_map
	ldr	r1, [r5, r1, lsr #24]
	bic	r5, r0, #0xFC00 << 16
	ldrb	r1, [r5, r1, lsr #15]
	and	r5, r0, #0x7000 << 16
	mov	r1, r1, lsl #4
	add	r1, r1, r5, lsr #28
	
	adr	r4, tile_map
	and	r5, r1, #0xFC00
	orr	REG_P_REST, REG_P_REST, #P_REST_SPR_HIT
	ldmfd	sp!, {r4, r5}
	b	check_spr_hit_ret
#endif

	.pool
