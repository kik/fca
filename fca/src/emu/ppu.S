#include "nes.h"
#include "gba-regs.h"

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
#if 0
	cmp	r1, #0x3C0
	bcs	read_attr
#endif
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
#if 0
	cmp	r1, #0x3C0
	bcs	write_attr
#endif
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
	stmfd	sp!, {lr}
	mov	r1, #GBA_REG_BASE

	mov	r0, #0
	tst	REG_P_REST, #P_REST_DRAW_BG
	@@ BGを描く場合は BG_0 を有効に
	orrne	r0, r0, #(GBA_DISP_CR_ENB_BG0 | GBA_DISP_CR_ENB_BG1)
	tst	REG_P_REST, #P_REST_DRAW_SPR
	orrne	r0, r0, #GBA_DISP_CR_ENB_SPR

	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	@@ BGもSPRも描かない場合は画面をブランクにする
	@@ 白くなってしまうのでなんとかしないと
	orreq	r0, r0, #GBA_DISP_CR_BLANK

	strh	r0, [r1, #GBA_DISP_CR]
	@@ BGもSPRも描かないならここでおわり
	moveq	pc, lr

	ldr	r0, =0x08080241
	str	r0, [r1, #0x50]

	ldr	r1, loopy_tx
	mov	r1, r1, lsr #16
	str	r1, loopy_v

@@@ 
@@@ さて，ここで画面の上部をどれだけ隠すかを決める
@@@ 10数ラインほど隠すのがよい
@@@          10987654321|
@@@ GBA                 01234567890123456789012345678
@@@                     |
@@@ BG0 上← 012345012345012345012345012345012345012345
@@@ BG1 上←   234567234567234567234567234567234567234567
@@@ NES
@@@ 
@@@ よってGBAの-11ラインから描画を始めたいわけだが
@@@ これだとスクロールYの値の変化で3ライン一気に飛ぶ場合があり
@@@ きれいにスクロールできない
@@@          10987654321|
@@@ GBA      |          01234567890123456789012345678
@@@          |          |
@@@ BG0 上← 012345012345012345012345012345012345012345
@@@ BG1 上←   234567234567234567234567234567234567234567
@@@ NES
@@@ Y off 0  |          |
@@@       1   |          |
@@@       2    |          |
@@@       3     |         *|
@@@       4      |         *|
@@@       5       |         *|
@@@       6       |          |
@@@       7       |          |*
@@@       8                   |
@@@ *の位置に修正する
@@@ 
	mov	r2, #256 - 11
	@@ NES Y offset
	and	r1, r1, #0x7000
	cmp	r1, #0x3000
	addcs	r2, r2, #1
	cmp	r1, #0x6000
	subcc	r2, r2, #1
	teq	r1, #0x7000
	subeq	r2, r2, #1
	strb	r2, gba_line_0
	strb	r2, gba_line_1

	bl	validate_tile
	bl	validate_spr

	ldmfd	sp!, {pc}

	.pool

#if 0
nes_line:
	.long	0
#endif
gba_line_0:
	.byte	0
gba_line_1:
	.byte	0

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

@@@ 
@@@ Y方向に画像を3/4に縮小しなければいけない
@@@ BG0・BG1にすこしずらして描いて
@@@ 合成することでRPGなどで字がつぶれるのを防ぐ
@@@ 
@@@ BG0  012345 012345
@@@ BG1  672345 672345
@@@ 

@@@ 
@@@ r0	=> 現在のライン番号
@@@ 
	.globl	draw_line

draw_line:
	@@ v:0000010000011111=t:0000010000011111
	ldr	r0, loopy_v
	ldr	r1, loopy_tx

	mov	r2,     #0x04100000
	orr	r2, r2, #0x000FE000

	@@ r0 = loopy_v  & ~r2
	@@ r1 = loopy_tx &  r2
	bic	r0, r0, r2, lsr #16
	and	r1, r1, r2

	@@ Yのスクロール値をr2におく
	orr	r2, r0, r0, lsr #10
	orr	r2, r2, r2, lsl #9
	mov	r2, r2, lsl #14

	@@ Xのスクロール値をr2におく
	orr	r2, r2, r1, lsr #13
	and	r3, r1, #0x04000000
	orr	r2, r2, r3, lsr #18
	add	r2, r2, #0x8

	@@ loopy_v を更新
	orr	r0, r0, r1, lsr #16

	@@ Yのオフセットで分岐
	and	r1, r0, #0x7000
	ldr	pc, [pc, r1, lsr #10]
	nop
	.long	0f, 1f, 2f, 3f
	.long	4f, 5f, 6f, 7f
0:
1:	
	@@ 0,1はBG0にだけ描く
	add	r0, r0, #0x1000
	str	r0, loopy_v

	ldrb	r0, gba_line_0
	add	r1, r0, #1
	strb	r1, gba_line_0
	cmp	r0, #160
	movcs	pc, lr

	adr	r1, scroll_value
	sub	r2, r2, r0, lsl #16
	str	r2, [r1, r0, lsl #3]

	adr	r1, bg_cr_value
	ldr	r2, screen_size
	orr	r2, r2, #GBA_BG_CR_MAP_ADDR(0x4)
	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r2, r2, #GBA_BG_CR_TILE_ADDR(1)
	add	r1, r1, r0, lsl #2
	strh	r2, [r1]

	mov	pc, lr

2:	
3:	
4:	
5:	
	@@ 2..5は両方に描く
	add	r0, r0, #0x1000
	str	r0, loopy_v

	ldrb	r0, gba_line_0
	add	r1, r0, #1
	strb	r1, gba_line_0
	@@ 同じ値にする
	strb	r1, gba_line_1
	cmp	r0, #160
	movcs	pc, lr

	adr	r1, scroll_value
	sub	r2, r2, r0, lsl #16
	str	r2, [r1, r0, lsl #3]!
	str	r2, [r1, #4]

	adr	r1, bg_cr_value
	ldr	r2, screen_size
	orr	r2, r2, #GBA_BG_CR_MAP_ADDR(0x4)
	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r2, r2, #GBA_BG_CR_TILE_ADDR(1)
	orr	r2, r2, r2, lsl #16
	str	r2, [r1, r0, lsl #2]

	mov	pc, lr

6:	
	@@ 6はBG1にだけ描く
	add	r0, r0, #0x1000
	str	r0, loopy_v

	ldrb	r0, gba_line_1
	add	r1, r0, #1
	strb	r1, gba_line_1
	cmp	r0, #160
	movcs	pc, lr

	adr	r1, scroll_value + 4
	sub	r2, r2, r0, lsl #16
	str	r2, [r1, r0, lsl #3]

	adr	r1, bg_cr_value + 2
	ldr	r2, screen_size
	orr	r2, r2, #GBA_BG_CR_MAP_ADDR(0x4)
	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r2, r2, #GBA_BG_CR_TILE_ADDR(1)
	add	r1, r1, r0, lsl #2
	strh	r2, [r1]
	mov	pc, lr

7:	
	bic	r0, r0, #0xF000
	@@ Y をふやして
	add	r1, r0, #0x0020
	ands	r3, r1, #0x3E0
	@@ これが0になるのは元のYが31だった場合
	eoreq	r0, r0, #0x0800
	teqne	r3, #0x3C0
	@@ Yが29だった場合もZを立てる
	eoreq	r0, r0, #0x0800
	biceq	r0, r0, #0x3E0
	streq	r0, loopy_v
	@@ Yが29でも31でもなかった場合
	strne	r1, loopy_v

	ldrb	r0, gba_line_1
	add	r1, r0, #1
	strb	r1, gba_line_1
	cmp	r0, #160
	movcs	pc, lr

	adr	r1, scroll_value + 4
	sub	r2, r2, r0, lsl #16
	str	r2, [r1, r0, lsl #3]

	adr	r1, bg_cr_value + 2
	ldr	r2, screen_size
	orr	r2, r2, #GBA_BG_CR_MAP_ADDR(0x4)
	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r2, r2, #GBA_BG_CR_TILE_ADDR(1)
	add	r1, r1, r0, lsl #2
	strh	r2, [r1]
	mov	pc, lr

@@@ 
@@@ ラインごとのBG_CR0・BG_CR1の設定
@@@ 

bg_cr_value:	
	.fill	160, 4, 0

@@@ 
@@@ ラインごとのX，Yのスクロールの値
@@@ 160ラインある。
@@@ 

scroll_value:	
	.fill	160, 8, 0

screen_size:	
	.long	0

	ALIGN

@@@ 
@@@ GBAのVBL割り込みをハンドルする
@@@ 
@@@ HBLごとのDMAを設定してスクロール値が勝手に更新されるようにする
@@@ ライン0のスクロールはここで設定する
@@@ 
	.globl	vbl_handler
vbl_handler:	
	mov	r0, #GBA_REG_BASE
	
	@@ スプライトの転送
	@@ DMA stop
	mov	r1, #0
	strh	r1, [r0, #GBA_DMAn_CR(0)]
	adr	r1, gba_sprite
	str	r1, [r0, #GBA_DMAn_SRC(0)]
	@@ DMA DST ← sprite ram
	mov	r1, #0x07000000
	str	r1, [r0, #GBA_DMAn_DST(0)]
	@@ DMA Count ← 64 * 4 * 2 byte
	mov	r1, #64 * 2
	strh	r1, [r0, #GBA_DMAn_SIZE(0)]
	mov	r1, #(GBA_DMA_DST_INCW|GBA_DMA_SRC_INCW|GBA_DMA_WORD|GBA_DMA_IMM|GBA_DMA_ENB)
	strh	r1, [r0, #GBA_DMAn_CR(0)]

	@@ スクロールレジスタの転送

	ldr	r2, =scroll_value
	add	r3, r0, #GBA_BGn_X(0)
	ldmia	r2!, {r0, r1}
	stmia	r3,  {r0, r1}

	mov	r0, #GBA_REG_BASE
	@@ DMA stop
	mov	r1, #0
	strh	r1, [r0, #GBA_DMAn_CR(0)]
	@@ DMA SRC ← &scroll_value[1]
	str	r2, [r0, #GBA_DMAn_SRC(0)]
	@@ DMA DST ← BG0_XY, BG1_XY
	str	r3, [r0, #GBA_DMAn_DST(0)]
	@@ DMA Count ← 2
	mov	r1, #2
	strh	r1, [r0, #GBA_DMAn_SIZE(0)]
	mov	r1, #(GBA_DMA_DST_INC | GBA_DMA_SRC_INCW)
	orr	r1, r1, #(GBA_DMA_WORD | GBA_DMA_REP | GBA_DMA_HBL | GBA_DMA_ENB)	
	strh	r1, [r0, #GBA_DMAn_CR(0)]	

	@@ BG_CRを転送する
	ldr	r1, =bg_cr_value
	ldr	r2, [r1], #4
	str	r2, [r0, #GBA_BGn_CR(0)]

	@@ DMA stop
	mov	r3, #0
	strh	r3, [r0, #GBA_DMAn_CR(1)]
	@@ DMA SRC ← &bg_cr_value[1]
	str	r1, [r0, #GBA_DMAn_SRC(1)]
	@@ DMA DST ← BG0_CR
	add	r1, r0, #GBA_BGn_CR(0)
	str	r1, [r0, #GBA_DMAn_DST(1)]
	@@ DMA Count ← 1
	mov	r1, #1
	strh	r1, [r0, #GBA_DMAn_SIZE(1)]

	mov	r1, #(GBA_DMA_DST_FIXED | GBA_DMA_SRC_INCW)
	orr	r1, r1, #(GBA_DMA_WORD | GBA_DMA_REP | GBA_DMA_HBL | GBA_DMA_ENB)
	strh	r1, [r0, #GBA_DMAn_CR(1)]	

	mov	pc, lr

	.pool 


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
	.globl	spr_dma
spr_dma:	
	stmfd	sp!, {r4, r5, lr}	
	@@ r0 = DMA src
	sub	REG_CYCLE, REG_CYCLE, #512
	sub	REG_CYCLE, REG_CYCLE, #2
	adr	r1, gba_sprite
	mov	r2, #64
1:	
	ldr	r3, [r0], #4
	@@ Y
	and	r5, r3, #255
#if 0
	adr	r4, skip_table
	ldrb	r4, [r4, r5]
#endif
	sub	r5, r5, #15
	add	r5, r5, r5, lsl #1
	mov	r5, r5, lsr #2
	strb	r5, [r1], #8

@	ldrh	r4, [r1, #-6]
@	and	r4, r4, #0xC000
@	orr	r4, r4, r3, lsr #24
	mov	r4, r3, lsr #24
	sub	r4, r4, #8
	bic	r4, r4, #0xFE00
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
	sub	r0, r0, #8
	ldrh	r1, [r3, #2]
	and	r1, r1, #0xFE00
	bic	r0, r0, #0xFE00
	orr	r0, r1, r0
	strh	r0, [r3, #2]
	mov	pc, lr

spr_old:	.long	0

validate_spr:	
	ldr	r0, spr_old
	eor	r1, r0, REG_P_REST
	str	REG_P_REST, spr_old

	@@ SPRの設定が変更されたか？
	tst	r1, #(P_REST_SPR_SZ | P_REST_SPR_ADR)
	moveq	pc, lr

	tst	r1, #P_REST_SPR_SZ
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

	.globl	get_tile_map
get_tile_map:	
	adr	r0, tile_map
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

	.globl	set_v_scroll
	.globl	set_h_scroll
	.globl	set_4_scroll

set_h_scroll:	
	mov	r0, #GBA_BG_CR_SIZE_512x256
	str	r0, screen_size

	mov	r0, #0x06000000
	adr	r1, map_table_map
	add	r0, r0, #0x2000
	str	r0, [r1]
	str	r0, [r1, #8]
	add	r0, r0, #0x800
	str	r0, [r1, #4]
	str	r0, [r1, #12]
	mov	pc, lr

set_v_scroll:	
	mov	r0, #GBA_BG_CR_SIZE_256x512
	str	r0, screen_size

	mov	r0, #0x06000000
	adr	r1, map_table_map
	add	r0, r0, #0x2000
	str	r0, [r1]
	str	r0, [r1, #4]
	add	r0, r0, #0x800
	str	r0, [r1, #8]
	str	r0, [r1, #12]
	mov	pc, lr

set_4_scroll:	
	mov	r0, #GBA_BG_CR_SIZE_512x512
	str	r0, screen_size

	mov	r0, #0x06000000
	adr	r1, map_table_map
	add	r0, r0, #0x2000
	str	r0, [r1]
	add	r0, r0, #0x800
	str	r0, [r1, #4]
	add	r0, r0, #0x800
	str	r0, [r1, #8]
	add	r0, r0, #0x800
	str	r0, [r1, #12]
	mov	pc, lr

@@@ 
@@@ $2007経由でマップまたは属性を読む
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
	@@ 属性テーブルに書こうとしている？
	cmp	r1, #0x3C0
	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #2]
	add	r3, r3, r1, lsl #1
	@@ ロードできるかな？
	ldrb	r2, [r3, #1]
	orr	r2, r0, r2, lsl #8
	strh	r2, [r3]
	movcc	pc, lr
	sub	r3, r3, r1, lsl #1
	b	write_attr


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

#if 0
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
#endif

@@@ 
@@@ $2007経由で属性を書く
@@@ 
@@@ r0	=> 書く値
@@@ r1	=> アドレス(3C0-400)
@@@ r2	=> マップ番号(0-3)
write_attr:	
	stmfd	sp!, {r4, lr}

	and	r1, r1, #0x3F
#if 0
	adr	r3, attr_map
	ldr	r3, [r3, r2, lsl #2]
	strb	r0, [r3, r1]
	
	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #2]
#endif
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

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ その他
@@@ 

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
	.globl	save_ram
save_ram:	.fill	0x2000, 1, 0
