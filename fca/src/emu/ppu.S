#include "nes.h"
#include "gba-regs.h"
#include "struct.h"

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
	and	r0, r0, #0xFF
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

	mov	r0, #GBA_DISP_CR_1D_SPR
	tst	REG_P_REST, #P_REST_DRAW_BG
	@@ BGを描く場合は BG_0 と BG_1 を有効に
	orrne	r0, r0, #(GBA_DISP_CR_ENB_BG0 | GBA_DISP_CR_ENB_BG1)
	tst	REG_P_REST, #P_REST_DRAW_SPR
	orrne	r0, r0, #GBA_DISP_CR_ENB_SPR

	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	@@ BGもSPRも描かない場合は画面をブランクにする
	@@ 白くなってしまうのでなんとかしないと
	@orreq	r0, r0, #GBA_DISP_CR_BLANK
	@@ これだと背景色でぬりつぶされるがまあいいだろう

	strh	r0, [r1, #GBA_DISP_CR]
	@@ BGもSPRも描かないならここでおわり
	ldmeqfd	sp!, {pc}

	@@ αブレンドを設定
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

	bl	update_tile
	bl	update_spr
#if 0
	bl	validate_tile
	bl	validate_spr
#endif

	ldmfd	sp!, {pc}

	.pool

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
	stmfd	sp!, {r4, lr}
	@@ まずHITをチェックする
	and	r1, REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR | P_REST_SPR_HIT)
	teq	r1, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	bleq	check_spr_hit

#if 0
	bne	1f
	ldrb	r1, nes_sprite_0
	add	r1, r1, #1
	sub	r2, r0, r1
	and	r2, r2, #255
	mov	r1, #8
	tst	REG_P_REST, #P_REST_SPR_SZ
	movne	r1, #16
	cmp	r2, r1
#if 0
	@@ 正確にHITを実装するにはvが必要だが
	@@ 今のルーチンははしょってるので必要ない
	@@ r0 = v, r1 = tx, r2 = spr offset
	ldrcc	r0, loopy_v
	ldrcc	r1, loopy_tx
#endif
	blcc	check_spr_hit
#endif
1:	
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

	ldrb	r4, gba_line_0
	add	r1, r4, #1
	strb	r1, gba_line_0
	cmp	r4, #160
	ldmcsfd	sp!, {r4, pc}

	adr	r1, scroll_value
	sub	r2, r2, r4, lsl #16
	str	r2, [r1, r4, lsl #3]

	bl	update_tile_per_line
	adr	r1, bg_cr_value
	add	r1, r1, r4, lsl #2
	strh	r0, [r1]
	ldmfd	sp!, {r4, pc}
2:	
3:	
4:	
5:	
	@@ 2..5は両方に描く
	add	r0, r0, #0x1000
	str	r0, loopy_v

	ldrb	r4, gba_line_0
	add	r1, r4, #1
	strb	r1, gba_line_0
	@@ 同じ値にする
	strb	r1, gba_line_1
	cmp	r4, #160
	ldmcsfd sp!, {r4, pc}

	adr	r1, scroll_value
	sub	r2, r2, r4, lsl #16
	str	r2, [r1, r4, lsl #3]!
	str	r2, [r1, #4]

	bl	update_tile_per_line
	adr	r1, bg_cr_value

	orr	r0, r0, r0, lsl #16
	str	r0, [r1, r4, lsl #2]
	ldmfd	sp!, {r4, pc}

6:	
	@@ 6はBG1にだけ描く
	add	r0, r0, #0x1000
	str	r0, loopy_v

	ldrb	r4, gba_line_1
	add	r1, r4, #1
	strb	r1, gba_line_1
	cmp	r4, #160
	ldmcsfd	sp!, {r4, pc}

	adr	r1, scroll_value + 4
	sub	r2, r2, r4, lsl #16
	str	r2, [r1, r4, lsl #3]

	bl	update_tile_per_line
	adr	r1, bg_cr_value + 2
	add	r1, r1, r4, lsl #2
	strh	r0, [r1]
	ldmfd	sp!, {r4, pc}

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

	ldrb	r4, gba_line_1
	add	r1, r4, #1
	strb	r1, gba_line_1
	cmp	r4, #160
	ldmcsfd	sp!, {r4, pc}

	adr	r1, scroll_value + 4
	sub	r2, r2, r4, lsl #16
	str	r2, [r1, r4, lsl #3]

	bl	update_tile_per_line
	adr	r1, bg_cr_value + 2
	add	r1, r1, r4, lsl #2
	strh	r0, [r1]
	ldmfd	sp!, {r4, pc}

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
	ldr	r1, =gba_sprite
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

	.globl	reset_ppu
reset_ppu:	
	mov	pc, lr
	


	.globl	ppu_start_vbl
ppu_start_vbl:	
	orr	REG_P_REST, REG_P_REST, #P_REST_IN_VBL
	mov	pc, lr

	.globl	ppu_end_vbl
ppu_end_vbl:	
	bic	REG_P_REST, REG_P_REST, #(P_REST_IN_VBL | P_REST_SPR_HIT)
	mov	pc, lr

	.globl leave_emu_ppu
	.globl	exit_ppu
leave_emu_ppu:	
exit_ppu:	
	mov	r0, #GBA_REG_BASE
	mov	r1, #0
	strh	r1, [r0, #GBA_DMAn_CR(0)]
	strh	r1, [r0, #GBA_DMAn_CR(1)]
	mov	pc, lr

	.globl	enter_emu_ppu
enter_emu_ppu:	
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
	ldr	r1, save_data_write
	teq	r1, #0
	moveq	pc, lr
	sub	r1, r1, #0x6000
	strb	r0, [r1, REG_ADDR]
	mov	pc, lr

save_data_write:	.long	0

	.pool

	SECTION_SLOW
	ALIGN


	.globl	init_save_ram
init_save_ram:
	ldopt	r0, EMU_OPT_save_file_read
	teq	r0, #0
	beq	2f

	adr	r1, save_ram
	mov	r2, #0x2000
1:	ldrb	r3, [r0], #1
	strb	r3, [r1], #1
	subs	r2, r2, #1
	bne	1b

2:	
	ldopt	r0, EMU_OPT_save_file_write
	ldr	r1, =save_data_write
	str	r0, [r1]
	teq	r0, #0
	moveq	pc, lr
	ldopt	r1, EMU_OPT_save_file_read
	teq	r0, r1
	moveq	r0, r1

	mov	r2, #0x2000
3:	ldrb	r3, [r1], #1
	strb	r3, [r0], #1
	subs	r2, r2, #1
	bne	3b

	mov	pc, lr
	.pool

	.globl	set_save_file_write
set_save_file_write:	
	ldr	r1, = save_data_write
	str	r0, [r1]
	
	adr	r1, save_ram
	mov	r2, #0x2000
1:	ldrb	r3, [r1], #1
	strb	r3, [r0], #1
	subs	r2, r2, #1
	bne	1b

	mov	pc, lr

	.pool

	.globl	save_ram
save_ram:	.fill	0x2000, 1, 0

