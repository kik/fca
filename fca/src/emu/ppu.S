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
	mov	r0, r0, ror #2
	
	eor	r2, r0, REG_P_REST, lsr #8
	bic	REG_P_REST, REG_P_REST, #P_REST_2000
	orr	REG_P_REST, REG_P_REST, r0, lsl #8

	@@ t:00001100 00000000=d:00000011
	ldrh	r1, loopy_t
	bic	r1, r1, #0x0C00
	orr	r1, r1, r0, lsr #20
	strh	r1, loopy_t

	@@ SPRの設定が変更されたか？
	tst	r2, #0x0C
	moveq	pc, lr

	tst	r2, #0x08
	bne	1f
	@@ SPRアドレスのみ更新
	tst	REG_P_REST, #P_REST_SPR_ADR
	bne	set_spr_adr_1
	b	set_spr_adr_0
1:	
	@@ SPRサイズが更新された
	tst	REG_P_REST, #P_REST_SPR_SZ
	bne	set_spr_8x16
	b	set_spr_8x8

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
@@@ VRAM の R/W レジスタ
@@@ 

@@@ 
@@@ 同時にロード・ストアできるようにloopy_t は loop_xの次におく
@@@ loopy_x は上3ビットを使う
@@@ 
	ALIGN
loopy_tx:	
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
	ldr	r1, loopy_tx
	mov	r1, r1, lsr #21
	orr	r1, r0, r1, lsl #8
	mov	r1, r1, lsl #13
	str	r1, loopy_tx
	mov	pc, lr

1:	@@ second write
	@@ t:00000011 11100000=d:11111000
	@@ t:01110000 00000000=d:00000111
	ldrh	r1, loopy_t
	bic	r1, r1, #0x3E0
	and	r2, r0, #0xF8
	orr	r2, r1, r2, lsl #2

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

read_2007_buffer:
	.byte	0
	ALIGN

read_2007:	
	ldrh	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r3, r1, #1
	addne	r3, r1, #32
	strh	r3, loopy_v

	bic	r1, r1, #0xC000

	cmp	r1, #0x3F00
	bcs	read_palette

	adr	r3, read_2007_buffer

	cmp	r1, #0x2000
	bcc	read_tile

	bic	r1, r1, #0x3000
	mov	r2, r1, lsr #10
	bic	r1, r1, #0xC00

	cmp	r1, #0x3C0
	bcs	read_attr
	b	read_map

@@@ 
@@@ $2007 に書き込み
@@@ 

write_2007:	
	ldrh	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r3, r1, #1
	addne	r3, r1, #32
	strh	r3, loopy_v

	bic	r1, r1, #0xC000

	cmp	r1, #0x3F00
	bcs	write_palette

	cmp	r1, #0x2000
	bcc	write_tile

	bic	r1, r1, #0x3000
	mov	r2, r1, lsr #10
	bic	r1, r1, #0xC00

	cmp	r1, #0x3C0
	bcs	write_attr
	b	write_map

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ 描画
@@@ 
@@@ といっても，ほとんどの部分はハードウェアにさせる
@@@ 
@@@ 描画の開始時にレジスタの設定をして
@@@ 
@@@ ラインごとにスクロールの値を記録する
@@@ 
@@@ 記録した値はGBAのHBLごとにレジスタに書き込まなければいけない
@@@ HBL毎にDMAを実行するのが簡単である。
@@@ 

@@@ 
@@@ 描画の開始
@@@ 
@@@ 
	.globl	ppu_start_frame
ppu_start_frame:
	mov	r1, #0x04000000
	mov	r0, #0

	@@ BGを描く場合は BG_0 を有効に
	tst	REG_P_REST, #P_REST_DRAW_BG
	orrne	r0, r0, #0x0100
	tst	REG_P_REST, #P_REST_DRAW_SPR
	orrne	r0, r0, #0x1000

	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	@@ BGもSPRも描かない場合は画面をブランクにする
	@@ 白くなってしまうのでなんとかしないと
	orreq	r0, r0, #0x80
	strh	r0, [r1]
	@@ BGもSPRも描かないならここでおわり
	moveq	pc, lr

	@@ BG_0 を設定する
	@@ 
	@@ タイルは0600_0000と0600_4000から選択する
	@@ 
	@@ マップは0600_2000に固定
	@@ 
	mov	r0, #0x4400
	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r0, r0, #0x0004	@ タイルを変更
	strh	r0, [r1, #0x8]

	ldr	r1, loopy_tx
	mov	r1, r1, lsr #16
	str	r1, loopy_v

	adr	r1, skip_table
	str	r1, nes_line

	b	validate_tile
	mov	pc, lr

@@@ 
@@@ ラインごとのX，Yのスクロールの値
@@@ 160ラインある。
@@@ 

scroll_value:	
	.fill	160, 4, 0

	ALIGN

nes_line:
	.long	0

	ALIGN

@@@ 
@@@ 1ライン描画したふりをする
@@@ 
@@@ 実際にはスクロール値を保存するだけ
@@@ 
@@@ NESのスクロール値は次の3つにばらばらに格納されている
@@@ 
@@@ loopy_x
@@@ 210
@@@ +++---X tile offset
@@@ 
@@@ loopy_t
@@@ FEDCBA9876543210
@@@ |||||||||||+++++---X tile index
@@@ ||||||+++++---Unused
@@@ |||||+---name table X
@@@ +++++---Unused
@@@ 
@@@ loopy_v
@@@ 
@@@ FEDCBA9876543210
@@@ |||||||||||+++++---Unused
@@@ ||||||+++++---Y tile index
@@@ |||||+---Unused
@@@ ||||+---name table Y
@@@ |+++---Y tile offset
@@@ +---Unused
@@@ 
@@@ ラインを書く前に loopy_v を下のように変更する
@@@ 
@@@ FEDCBA9876543210
@@@ |||||||||||+++++---X tile index
@@@ ||||||+++++---Y tile index
@@@ ||||++--- name table YX
@@@ |+++---Y tile offset
@@@ +---Unused
@@@ 
@@@ これをGBAのスクロール値に変えると
@@@ X
@@@ FEDCBA9876543210
@@@ |||||||||||||+++---X offset
@@@ ||||||||+++++---X index
@@@ |||||||+---name table #
@@@ +++++++---Unused
@@@ 
@@@ Y
@@@ FEDCBA9876543210
@@@ |||||||||||||+++---Y offset
@@@ ||||||||+++++---Y index
@@@ |||||||+---name table #
@@@ +++++++---Unused
@@@ 
@@@ Xはラインごとに変換しなければいけない
@@@ Yにこの値を使うと一番上のラインにこのラインが表示されるので
@@@ GBAのライン番号を引かなければならない
@@@ 
	.globl	draw_line

draw_line:
	ldr	r0, nes_line
	ldrb	r3, [r0], #1
	ldrb	r2, [r0]
	teq	r3, r2
	moveq	r3, #160
	str	r0, nes_line
	@@ r3 は GBA のライン番号(0-159)
	@@ 160以上 の場合はこのラインはスキップする

	@@ v:0000010000011111=t:0000010000011111
	@@ vを更新してXのスクロール値を得る
	ldr	r0, loopy_v
	ldr	r1, loopy_tx

	mov	r2,     #0x04100000
	orr	r2, r2, #0x000FE000

	@@ loopy_v & ~r2
	@@ loopy_t &  r2
	bic	r0, r0, r2, lsr #16
	and	r1, r1, r2

	@@ Yのスクロール値をr2におく
	orr	r2, r0, r0, lsr #10
	orr	r2, r2, r2, lsl #9
	mov	r2, r2, lsl #14
	sub	r2, r2, r3, lsl #16

	orr	r0, r0, r1, lsr #16
	@@ Xのスクロール値をr2におく
	orr	r2, r2, r1, lsr #13
	and	r1, r1, #0x04000000
	orr	r2, r2, r1, lsr #18

	cmp	r3, #160
	adr	r1, scroll_value
	strcc	r2, [r1, r3, lsl #2]

	@@ loopy_v を次のラインにして保存する
	add	r0, r0, #0x1000
	bic	r0, r0, #0x8000
	tst	r0, #0x7000
	@@ Y オフセットが 7→0のとき0
	bne	1f
	@@ Y をふやして
	add	r1, r0, #0x0020
	ands	r2, r1, #0x3E0
	@@ これが0になるのは元のYが31だった場合
	eoreq	r0, r0, #0x0800
	teqne	r2, #0x3C0
	@@ Yが29だった場合もZを立てる
	eoreq	r0, r0, #0x0800
	biceq	r0, r0, #0x3E0
	@@ Yが29でも31でもなかった場合
	movne	r0, r1
1:	str	r0, loopy_v
	mov	pc, lr

@@@ 
@@@ GBAのVBL割り込みをハンドルする
@@@ 
@@@ HBLごとのDMAを設定してスクロール値が勝手に更新されるようにする
@@@ ライン0のスクロールはここで設定する
@@@ 
	.globl	vbl_handler
vbl_handler:	
	mov	r0, #0x04000000

	adr	r2, scroll_value

	@@ ライン0のスクロール値を設定
	ldr	r1, [r2], #4
	str	r1, [r0, #0x10]
#if 1
	@@ DMA stop
	mov	r1, #0
	strh	r1, [r0, #0xBA]

	@@ DMA SRC ← &scroll_value[1]
	str	r2, [r0, #0xB0]

	@@ DMA DST ← BG0_XY
	add	r1, r0, #0x10	
	str	r1, [r0, #0xB4]

	@@ DMA Count ← 1
	mov	r1, #1
	strh	r1, [r0, #0xB8]

	@@ DMA Ctrl
	@@ DST:	fixed
	@@ SRC:	inc
	mov	r1, #0x60 @| 0x180
	@@ Width: word
	@@ Repeat
	@@ HBlank
	orr	r1, r1, #0x8000 | 0x2000 | 0x0400 | 0x0200
	strh	r1, [r0, #0xBA]	
#endif
	@@ 次にスプライトをDMAで転送する
	@@ DMA stop
	mov	r1, #0
	strh	r1, [r0, #0xC6]

	@@ DMA SRC ← sprite data
	adr	r1, gba_sprite
	str	r1, [r0, #0xBC]

	@@ DMA DST ← sprite ram
	mov	r1, #0x07000000
	str	r1, [r0, #0xC0]

	@@ DMA Count ← 1
	mov	r1, #64 * 2
	strh	r1, [r0, #0xC4]

	@@ DMA Ctrl
	@@ DST:	inc
	@@ SRC:	inc
	@@ Width: word
	mov	r1, #0x8400
	strh	r1, [r0, #0xC6]	

	mov	pc, lr

@@@ 
@@@ どのラインをスキップするか
@@@ スプライトの位置を決めるのにも使う
@@@ 
@@@ 0-159 = GBAのライン番号
@@@ 残り  = スキップ
@@@ 
@@@ 上下13ラインはスキップして，残りは1/4をスキップする
@@@ 
skip_table:	
#define P(n) n*6+2, n*6+3, n*6+3, n*6+4, n*6+5, n*6+6, n*6+6, n*6+7
	.byte	243, 244, 245, 246, 247, 248, 249, 250	@ 0
	.byte	251, 252, 253, 254, 255,   0,   1,   2	@ 8
	.byte	P( 0), P( 1)				@ 16 
	.byte	P( 2), P( 3), P( 4), P( 5)		@ 32
	.byte	P( 6), P( 7), P( 8), P( 9)		@ 64
	.byte	P(10), P(11), P(12), P(13)		@ 96
	.byte	P(14), P(15), P(16), P(17)		@128
	.byte	P(18), P(19), P(20), P(21)		@160
	.byte	P(22), P(23), P(24), P(25)		@192
	.byte	158, 159, 160, 160, 160, 160, 160, 160	@224
	.byte	160, 160, 160, 160, 160, 160, 160, 160	@232
	.byte	160, 160, 160, 160, 160, 160, 160, 160	@240
	.byte	160, 160, 160, 160, 160, 160, 160, 160	@248

#undef P

	ALIGN



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


@@@ 
@@@ スプライトDMA
@@@ 
write_4014:
	stmfd	sp!, {r4, r5, lr}	
	bl	spr_dma_adr
	@@ r0 = DMA src
	adr	r1, gba_sprite
	mov	r2, #64
1:	
	ldr	r3, [r0], #4
	@@ Y
	and	r5, r3, #255
	adr	r4, skip_table
	ldrb	r4, [r4, r5]
	strb	r4, [r1], #8

@	ldrh	r4, [r1, #-6]
@	and	r4, r4, #0xC000
@	orr	r4, r4, r3, lsr #24
	mov	r4, r3, lsr #24
	and	r5, r3, #0xC0 << 16
	orr	r4, r4, r5, lsr #10
	strh	r4, [r1, #-6]

	@@ test priority
	tst	r3, #0x20 << 16
	moveq	r4, #0
	movne	r4, #0x0400

	and	r5, r3, #0x03 << 16
	orr	r4, r4, r5, lsr #4

	tst	REG_P_REST, #P_REST_SPR_ADR
	moveq	r5, #0
	movne	r5, #0x100
	tst	REG_P_REST, #P_REST_SPR_SZ
	movne	r5, r3, lsr #16
	bicne	r3, r3, #0x01 << 24
	and	r5, r5, #0x100
	orr	r4, r4, r5
	and	r3, r3, #0xFF00
	orr	r4, r4, r3, lsr #8
	strh	r4, [r1, #-4]

	subs	r2, r2, #1
	bne	1b
	ldmfd	sp!, {r4, r5, pc}

gba_sprite:	
	.fill	64, 8, 0

	ALIGN
@@@ 
@@@ $2003 に書く
@@@ 

ppu_reg_2003:	.byte	0
	
	ALIGN

write_2003:	
	strb	r0, ppu_reg_2003
	mov	pc, lr

@@@ 
@@@ $2004 に書く
@@@ 

write_2004:
	ldrb	r1, ppu_reg_2003
	add	r2, r1, #1
	strb	r2, ppu_reg_2003

	mov	r2, r1, ror #2
	adr	r3, gba_sprite
	add	r3, r3, r2, lsl #3
	ldr	pc, [pc, r2, lsr #28]
	nop
	.long	write_spr_0
	.long	write_spr_1
	.long	write_spr_2
	.long	write_spr_3

write_spr_0:
	@@ Spr Y
	@@ TODO: 変換すること
	strb	r0, [r3]
	mov	pc, lr

write_spr_1:	
	@@ Tile #
	tst	REG_P_REST, #P_REST_SPR_SZ
	streqb	r0, [r3, #4]
	moveq	pc, lr

	@@ 8x16
	ldrh	r1, [r3, #4]
	and	r1, r1, #0xFC00
	movs	r0, r0, lsr #1
	orrcs	r1, r1, #0x100
	orr	r1, r1, r0, lsl #1

	strh	r1, [r3, #4]
	mov	pc, lr

write_spr_2:
	@@ Palette, Prio
	ldrb	r1, [r3, #5]
	bic	r1, r1, #0xFC
	orr	r1, r1, r0, lsl #4
	tst	r0, #0x20
	orrne	r1, r1, #0x04
	strb	r1, [r3, #5]
	@@ H flip, V flip
	ldrb	r1, [r3, #3]
	bic	r1, r1, #0x30
	and	r0, r0, #0xC0
	orr	r1, r1, r0, lsr #2
	strb	r1, [r3, #3]
	mov	pc, lr

write_spr_3:	
	@@ Spr X
	strb	r0, [r3, #2]
	mov	pc, lr

@@@
@@@ スプライトのサイズが8x16から8x8に変更された
@@@ 
set_spr_8x8:	
	adr	r0, gba_sprite
	mov	r2, #64
1:	
	ldrh	r1, [r0]
	bic	r1, r1, #0xC000
	strh	r1, [r0], #4
	ldrh	r1, [r0]
	tst	r1, #0x0100
	orrne	r1, r1, #1
	tst	REG_P_REST, #P_REST_SPR_ADR
	biceq	r1, r1, #0x0100
	orrne	r1, r1, #0x0100
	strh	r1, [r0], #4

	subs	r2, r2, #1
	bne	1b
	mov	pc, lr

@@@ 
@@@ スプライトのサイズが8x8から8x16に変更された
@@@ 
set_spr_8x16:	
	adr	r0, gba_sprite
	mov	r2, #64
1:	
	ldrh	r1, [r0]
	orr	r1, r1, #0x4000
	strh	r1, [r0], #4
	ldrh	r1, [r0]
	tst	r1, #0x0001
	biceq	r1, r1, #0x0100
	orrne	r1, r1, #0x0100
	bic	r1, r1, #1
	strh	r1, [r0], #4

	subs	r2, r2, #1
	bne	1b
	mov	pc, lr

@@@ 
@@@ スプライトのアドレスが0に変更された
@@@ 
set_spr_adr_0:	
	adr	r0, gba_sprite
	mov	r2, #32
1:	
	ldrh	r1, [r0, #4]!
	bic	r1, r1, #0x0100
	strh	r1, [r0], #4

	ldrh	r1, [r0, #4]!
	bic	r1, r1, #0x0100
	strh	r1, [r0], #4

	subs	r2, r2, #1
	bne	1b
	mov	pc, lr


set_spr_adr_1:	
	adr	r0, gba_sprite
	mov	r2, #32
1:	
	ldrh	r1, [r0, #4]!
	orr	r1, r1, #0x0100
	strh	r1, [r0], #4

	ldrh	r1, [r0, #4]!
	orr	r1, r1, #0x0100
	strh	r1, [r0], #4

	subs	r2, r2, #1
	bne	1b
	mov	pc, lr

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

	adr	r0, gba_sprite
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

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ タイルの変換
@@@ 
@@@ NESのタイルはVRAMの$0000-$1000と$1000-2000に置かれている
@@@ これはBGとSPRで共通に使われるので，GBAのBG用タイルとSPR用
@@@ タイルの両方にコピーしなければならない。
@@@ 
@@@ BGのタイルは
@@@ 0600_0000-0600_2000
@@@ 0600_4000-0600_6000
@@@ に置く
@@@ 
@@@ SPRのタイルは
@@@ 0601_0000-0601_2000
@@@ 0601_2000-0601_4000
@@@ に置く

@@@ 
@@@ タイル用のRAM
@@@ FF3などの一部のゲームはCHR-ROMを持たず，かわりにこれを使う
@@@ 
	SECTION_SLOW
	ALIGN
tile_ram:
	.fill	0x2000, 1, 0

	SECTION_FAST
	ALIGN

@@@ 
@@@ 0000-2000を8つにわける
@@@ ひとつは0x400つまり64個
@@@ 
tile_map:
	.long	tile_ram, tile_ram, tile_ram, tile_ram
	.long	tile_ram, tile_ram, tile_ram, tile_ram

@@@ 
@@@ Mapperによってタイルが変更された場合は
@@@ フレームごとに変更を確認する。前回のフレームで設定されていた
@@@ メモリマップをここに保存しておく
@@@ 
@@@ DQ1などはCHR-ROMにもデータをもっていて，VBLの間にそれを読もうとする
@@@ そこて，CHR-ROMの変更はフレームごとにチェックすることで，
@@@ 画面がちらつくのを防ぐ
@@@ 
tile_map_old:	
	.long	0, 0, 0, 0
	.long	0, 0, 0, 0

.macro	VALIDATE_LO	n
	ldr	r0, tile_map     + \n * 4
	ldr	r5, tile_map_old + \n * 4
	teq	r0, r5
	addeq	r1, r1, #0x800
	strne	r0, tile_map_old + \n * 4
	addne	r0, r0, #0x400 * \n
	addne	r2, r1, #0x10000
	blne	trans_tile_64
.endm

.macro	VALIDATE_HI	n
	ldr	r0, tile_map     + \n * 4
	ldr	r5, tile_map_old + \n * 4
	teq	r0, r5
	addeq	r1, r1, #0x800
	strne	r0, tile_map_old + \n * 4
	addne	r0, r0, #0x400 * \n
	addne	r2, r1, #0xE000
	blne	trans_tile_64
.endm

@@@ 
@@@ タイルのデータを有効にする
@@@ 
validate_tile:
	stmfd	sp!, {r4-r10, lr}
	mov	r1, #0x06000000
	VALIDATE_LO	0
	VALIDATE_LO	1
	VALIDATE_LO	2
	VALIDATE_LO	3
	add	r1, r1, #0x2000
	VALIDATE_HI	4
	VALIDATE_HI	5
	VALIDATE_HI	6
	VALIDATE_HI	7
	ldmfd	sp!, {r4-r10, pc}


@@@ 
@@@ $2007経由でタイルを読む
@@@ 
@@@ r1	=> アドレス
@@@ r0	<= *r3 = read_2007_buffer
@@@ *r3 <= 結果
read_tile:
	mov	r2, r1, lsr #10
	adr	r0, tile_map
	ldr	r0, [r0, r2, lsl #2]
	ldrb	r0, [r0, r1]
	swpb	r0, r0, [r3]
	mov	pc, lr

@@@ 
@@@ $2007経由でタイルに書く
@@@ 
write_tile:
	mov	r2, r1, lsr #10
	adr	r3, tile_map
	ldr	r3, [r3, r2, lsl #2]
	strb	r0, [r3, r1]
	mov	r0, #0
	adr	r3, tile_map_old
	str	r0, [r3, r2, lsl #2]
	mov	pc, lr


	.globl	set_vram_bank_0to7
set_vram_bank_0to7:	
	str	r0, tile_map + 4 * 0
	str	r0, tile_map + 4 * 1
	str	r0, tile_map + 4 * 2
	str	r0, tile_map + 4 * 3
	str	r0, tile_map + 4 * 4
	str	r0, tile_map + 4 * 5
	str	r0, tile_map + 4 * 6
	str	r0, tile_map + 4 * 7
	mov	pc, lr


@@@ 
@@@ タイルを64個変換する
@@@ 
@@@ r0	=> SRC
@@@ r1	=> DST1
@@@ r2	=> DST2
@@@ 
@@@ r0	<= SRC + 0x400
@@@ r1	<= DST1 + 0x800
@@@ r2	<= DST2 + 0x800
@@@ r3-r10 を壊す
@@@ 
.macro	TRANS_LINE	reg1, reg2, mask, shift
	and	r8, \reg1, #\mask
	ldr	r9, [r3, r8, \shift]
	and	r8, \reg2, #\mask
	ldr	r8, [r3, r8, \shift]
	orr	r8, r9, r8, lsl #1
	str	r8, [r1], #4
	str	r8, [r2], #4
.endm
trans_tile_64:	
	adr	r3, tile_translate_table

	mov	r10, #64
1:	
	@@ タイルをひとつロード
	@@ ROMからのロードはLDMを使ってシーケンシャルに
	@@ やると速い
	ldmia	r0!, {r4-r7}

	TRANS_LINE	r4, r6, 0x000000FF, lsl #2
	TRANS_LINE	r4, r6, 0x0000FF00, lsr #6
	TRANS_LINE	r4, r6, 0x00FF0000, lsr #14
	TRANS_LINE	r4, r6, 0xFF000000, lsr #22

	TRANS_LINE	r5, r7, 0x000000FF, lsl #2
	TRANS_LINE	r5, r7, 0x0000FF00, lsr #6
	TRANS_LINE	r5, r7, 0x00FF0000, lsr #14
	TRANS_LINE	r5, r7, 0xFF000000, lsr #22

	subs	r10, r10, #1
	bne	1b

	mov	pc, lr


	ALIGN
tile_translate_table:	
	.fill	256, 4, 0

	SECTION_SLOW
	ALIGN

@@@ 
@@@ タイルの変換はテーブルを使う
@@@ 
@@@    NES   =>  GBA
@@@ ABCDEFGH => 000H 000G 000F 000E 000D 000C 000B 000A
@@@ を行うテーブル(byte → word)を作っておく
@@@ 
init_tile_trans_table:	
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

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ パレットの変換
@@@ 
@@@ パレットは読み書きできるので，読むときにそなえてコピーを
@@@ とっておかなければならない。
@@@ それと同時にGBAのパレットRAMにも書き込む。
@@@ 

	ALIGN
bg_palette:
	.fill	0x16, 1, 0
spr_palette:	
	.fill	0x16, 1, 0
	
	ALIGN

@@@ 
@@@ $2007経由でパレットを読む
@@@ 
@@@ r1	=> VRAMアドレス 
@@@ r0	<= 結果
read_palette:	
	and	r1, r1, #0x1F
	adr	r0, bg_palette
	ldrb	r0, [r0, r1]
	mov	pc, lr

@@@ 
@@@ $2007経由でパレットに書く
@@@ 
@@@ r0	=> 書くバイト
@@@ r1	=> VRAMアドレス
@@@ 
@@@ GBAのパレットは0500_0000にあり
@@@ BGのパレットが256エントリ
@@@ SPRのパレットが256エントリある
@@@ 
@@@ NESのパレットは4*4で
@@@ GBAのパレットは16*16
@@@ 
write_palette:	
	@@ とりあえずコピーをとる
	and	r0, r0, #0x3F
	and	r1, r1, #0x1F
	adr	r2, bg_palette
	strb	r0, [r2, r1]
	@@ パレット0はミラーされている
	tst	r1, #0xF
	eoreq	r1, r1, #0x10
	streqb	r0, [r2, r1]
	biceq	r1, r1, #0x10

	@@ 色を変換する
	adr	r2, nes_palette
	ldr	r0, [r2, r0, lsl #2]

	@@ パレット位置を変換する
	adr	r2, palette_map
	ldr	r1, [r2, r1, lsl #2]
	strh	r0, [r1]

	mov	pc, lr

	ALIGN

palette_map:	
#define P(n)	0x05000000 + n
	.long	P(0x00),  P(0x02), P(0x04), P(0x06)
	.long	P(0x20),  P(0x22), P(0x24), P(0x26)
	.long	P(0x40),  P(0x42), P(0x44), P(0x46)
	.long	P(0x60),  P(0x62), P(0x64), P(0x66)
#undef P
#define P(n)	0x05000000 + n + 512
	.long	P(0x00),  P(0x02), P(0x04), P(0x06)
	.long	P(0x20),  P(0x22), P(0x24), P(0x26)
	.long	P(0x40),  P(0x42), P(0x44), P(0x46)
	.long	P(0x60),  P(0x62), P(0x64), P(0x66)
#undef P
	
	ALIGN

#include "palette.S"

	ALIGN


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ マップテーブルの変換
@@@ 
@@@ マップテーブルへの書き込みは直接VRAMに書く
@@@ 読み出しもVRAMから直接読む
@@@ 
@@@ 最大4つのマップテーブルが使える。4つの場合は
@@@ 2000-2400	=> 06002000
@@@ 2400-2800	=> 06002800
@@@ 2800-2C00	=> 06003000
@@@ 2C00-3000	=> 06003800
@@@ のように対応させる。
@@@ 
@@@ ミラーリングのためテーブルが必要
@@@ 
@@@ テーブルへのエントリは次のように変換する
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
@@@ このように変換した場合，マップへの書き込みは
@@@ VRAMへの1バイト書き込みになるので，読んでから書かないといけない
@@@ 


	ALIGN

map_table_map:	
	.long	0x06002000
	.long	0x06002800
	.long	0x06003000
	.long	0x06003800

	ALIGN

@@@ 
@@@ $2007経由でマップを読む
@@@ 
@@@ r1	=> アドレス(000-3C0)
@@@ r2	=> マップ番号(0-3)
@@@ r0	<= *r3 = read_2007_buffer
@@@ *r3	<= 結果
read_map:	
	adr	r0, map_table_map
	ldr	r0, [r0, r2, lsl #2]
	ldrb	r0, [r0, r1, lsl #1]
	swpb	r0, r0, [r3]
	mov	pc, lr

@@@ 
@@@ $2007経由でマップに書く
@@@ 
@@@ r0	=> 書くバイト
@@@ r1	=> アドレス(000-3C0)
@@@ r2	=> マップ番号(0-3)
write_map:	
	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #2]
	add	r1, r3, r1, lsl #1
	@@ ロードできるかな？
	ldrb	r2, [r1, #1]
	orr	r2, r0, r2, lsl #8
	strh	r2, [r1]
	mov	pc, lr


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ 属性テーブルの変換
@@@ 
@@@ これが一番めんどうな仕事である。
@@@ 
@@@ 
@@@ 属性が DDBBCCAA なら
@@@ 
@@@ AA AA BB BB
@@@ 
@@@ AA AA BB BB
@@@ 
@@@ CC CC DD DD
@@@ 
@@@ CC CC DD DD
@@@ 
@@@ のようになる。
@@@ 
@@@ 属性は読むことができるがVRAMから読むのは辛いので
@@@ 別に保存しておかなければならない
@@@ 

@@@ 
@@@ $2007経由で属性を読む
@@@ 
@@@ r1	=> アドレス(3C0-400)
@@@ r2	=> マップ番号(0-3)
@@@ r0	<= *r3 = read_2007_buffer
@@@ *r3	<= 結果
read_attr:	
	and	r1, r1, #0x3F
	adr	r0, attr_table
	ldr	r0, [r0, r2, lsl #2]
	ldrb	r0, [r0, r1]
	swpb	r0, r0, [r3]
	mov	pc, lr


@@@ 
@@@ $2007経由で属性を書く
@@@ 
@@@ r0	=> 書く値
@@@ r1	=> アドレス(3C0-400)
@@@ r2	=> マップ番号(0-3)
write_attr:	
	stmfd	sp!, {r4, lr}
	and	r1, r1, #0x3F
	adr	r3, attr_map
	ldr	r3, [r3, r2, lsl #2]
	strb	r0, [r3, r1]
	
	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #2]

	adr	r2, attr_index_map
	ldr	r2, [r2, r1, lsl #2]


	mov	r4, #0x3000
	orr	r4, r4, r4, lsl #16
	
	orr	r0, r0, r0, lsl #16
	@@ 
	@@ r0	00000000DDCCBBAA 00000000DDCCBBAA
	@@ r4	0011000000000000 0011000000000000

	@@ A	00AA000000000000 00AA000000000000
	and	r1, r4, r0, lsl #12

	ldr	lr, [r3, r2]!
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3]

	ldr	lr, [r3, #64]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #64]

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ B	00BB000000000000 00BB000000000000
	and	r1, r4, r0, lsl #10

	ldr	lr, [r3, #4]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #4]

	ldr	lr, [r3, #68]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #68]

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ C	00CC000000000000 00CC000000000000
	and	r1, r4, r0, lsl #8

	ldr	lr, [r3, #128]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #128]

	ldr	lr, [r3, #192]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #192]

	@@ 	00000000DDCCBBAA 00000000DDCCBBAA
	@@ D	00DD000000000000 00DD000000000000
	and	r1, r4, r0, lsl #6

	ldr	lr, [r3, #132]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #132]

	ldr	lr, [r3, #196]
	bic	lr, lr, r4
	orr	lr, lr, r1
	str	lr, [r3, #196]

	ldmfd	sp!, {r4, pc}

	ALIGN
attr_table:
	.fill	0x40, 1, 0
	.fill	0x40, 1, 0
	.fill	0x40, 1, 0
	.fill	0x40, 1, 0
	ALIGN
attr_map:
	.long	attr_table
	.long	attr_table + 0x40
	.long	attr_table + 0x80
	.long	attr_table + 0xC0
	ALIGN

@@@ 
@@@ 属性を適用するマップの左上の端のアドレス
@@@ 
attr_index_map:
#define P(y, x) ((y * 0x80 + x * 4) * 2)
	.long P(0,0), P(0,1), P(0,2), P(0,3), P(0,4), P(0,5), P(0,6), P(0,7)
	.long P(1,0), P(1,1), P(1,2), P(1,3), P(1,4), P(1,5), P(1,6), P(1,7)
	.long P(2,0), P(2,1), P(2,2), P(2,3), P(2,4), P(2,5), P(2,6), P(2,7)
	.long P(3,0), P(3,1), P(3,2), P(3,3), P(3,4), P(3,5), P(3,6), P(3,7)
	.long P(4,0), P(4,1), P(4,2), P(4,3), P(4,4), P(4,5), P(4,6), P(4,7)
	.long P(5,0), P(5,1), P(5,2), P(5,3), P(5,4), P(5,5), P(5,6), P(5,7)
	.long P(6,0), P(6,1), P(6,2), P(6,3), P(6,4), P(6,5), P(6,6), P(6,7)
	.long P(7,0), P(7,1), P(7,2), P(7,3), P(7,4), P(7,5), P(7,6), P(7,7)
#undef P

	ALIGN


	.globl	init_ppu
init_ppu:
	stmfd	sp!, {lr}
	@@ 画面を消す
	mov	r0, #0x0080
	mov	r1, #0x04000000
	strh	r0, [r1]
	@@ VBL 割り込みを有効に
	mov	r0, #0x0008
	strh	r0, [r1, #4]

	bl	init_tile_trans_table
	bl	init_gba_spr

	ldmfd	sp!, {pc}

	.globl	ppu_start_vbl
ppu_start_vbl:	
	orr	REG_P_REST, REG_P_REST, #P_REST_IN_VBL
	@orr	REG_P_REST, REG_P_REST, #P_REST_SPR_HIT	
	mov	pc, lr

	.globl	ppu_end_vbl
ppu_end_vbl:	
	bic	REG_P_REST, REG_P_REST, #(P_REST_IN_VBL | P_REST_SPR_HIT)
	mov	pc, lr


	.globl	read_high_reg
read_high_reg:	
	bic	r1, REG_ADDR, #0x4000
	teq	r1, #0x16
	beq	read_4016
	teq	r1, #0x17
	beq	read_4017
	mov	pc, lr

	.globl	write_high_reg
write_high_reg:	
	bic	r1, REG_ADDR, #0x4000
	teq	r1, #0x14
	beq	write_4014
	teq	r1, #0x16
	beq	write_4016
	mov	pc, lr


	.globl	read_save_ram
	.globl	write_save_ram
read_save_ram:	
	ldr	r1, = save_ram - 0x6000
	ldrb	r0, [r1, REG_ADDR]
	mov	pc, lr

write_save_ram:	
	ldr	r1, = save_ram - 0x6000
	strb	r0, [r1, REG_ADDR]
	mov	pc, lr

	.pool

	SECTION_SLOW
	ALIGN
save_ram:	.fill	0x2000, 1, 0
