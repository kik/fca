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

read_2007_buffer:
	.long	0

read_2007:	
	ldrh	r1, loopy_v
	tst	REG_P_REST, #P_REST_PPU_32
	addeq	r3, r1, #1
	addne	r3, r1, #32
	strh	r3, loopy_v

	bic	r1, r1, #0xC000

	cmp	r1, #0x3F00
	bcs	read_palette

	ldr	r0, read_2007_buffer	

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



	SECTION_FAST
	ALIGN

@@@ 
@@@ 0000-2000を8つにわける
@@@ ひとつは0x400つまり64個
@@@ 
tile_map:
	.long	0, 0, 0, 0
	.long	0, 0, 0, 0


@@@ 
@@@ $2007経由でタイルを読む
@@@ 
@@@ r1	=> アドレス
@@@ r0	<= 結果
read_tile:
	mov	r2, r1, lsr #10
	adr	r3, tile_map
	ldr	r3, [r3, r2, lsl #2]
	ldrb	r1, [r3, r1]
	strb	r1, read_2007_buffer
	mov	pc, lr

@@@ 
@@@ $2007経由でタイルに書くのを実装しないといけない
@@@ 
write_tile:	mov	pc, lr



.macro	SET_TILE_BANK_LO	n
	ldr	r1, tile_map + (4 * \n)
	teq	r1, r11
	beq	1f

	str	r11, tile_map + (4 * \n)
	add	r0, r11, #(0x400 * \n)
	mov	r1, #0x06000000
	add	r1, r1, #(0x800 * \n)
	add	r2, r1, #0x10000
	bl	trans_tile_64
1:	
.endm

.macro	SET_TILE_BANK_HI	n
	ldr	r1, tile_map + (4 * \n)
	teq	r1, r11
	beq	1f

	str	r11, tile_map + (4 * \n)
	add	r0, r11, #(0x400 * \n)
	mov	r1, #0x06000000
	add	r1, r1, #(0x800 * \n)
	add	r2, r1, #0x10000
	add	r1, r1, #0x2000
	bl	trans_tile_64
1:	
.endm

	.globl	set_vram_bank_0to7
set_vram_bank_0to7:	
	stmfd	sp!, {r4-r11, lr}
	mov	r11, r0

	SET_TILE_BANK_LO	0
	SET_TILE_BANK_LO	1
	SET_TILE_BANK_LO	2
	SET_TILE_BANK_LO	3
	SET_TILE_BANK_HI	4
	SET_TILE_BANK_HI	5
	SET_TILE_BANK_HI	6
	SET_TILE_BANK_HI	7

	ldmfd	sp!, {r4-r11, pc}

	.globl	translate_tiles


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
@@@ r1			=> アドレス(000-3C0)
@@@ r2			=> マップ番号(0-3)
@@@ read_2007_buffer	<= 結果
read_map:	
	adr	r3, map_table_map
	ldr	r3, [r3, r2, lsl #2]
	ldrb	r1, [r3, r1, lsl #1]
	strb	r1, read_2007_buffer
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
@@@ r1			=> アドレス(3C0-400)
@@@ r2			=> マップ番号(0-3)
@@@ read_2007_buffer	<= 結果
read_attr:	
	and	r1, r1, #0x3F
	adr	r3, attr_table
	ldr	r3, [r3, r2, lsl #2]
	ldrb	r3, [r3, r1]
	strb	r3, read_2007_buffer
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
	@@ 画面を消す
	mov	r0, #0x0080
	mov	r1, #0x04000000
	strh	r0, [r1]
	@@ VBL 割り込みを有効に
	mov	r0, #0x0008
	strh	r0, [r1, #4]

	b	init_tile_trans_table
	mov	pc, lr


	.globl	ppu_start_frame
ppu_start_frame:
#if 1
	mov	r1, #0x04000000

	mov	r0, #0
	tst	REG_P_REST, #P_REST_DRAW_BG
	orrne	r0, r0, #0x0100
#endif
	tst	REG_P_REST, #(P_REST_DRAW_BG | P_REST_DRAW_SPR)
	orreq	r0, r0, #0x80
	strh	r0, [r1]
	moveq	pc, lr
#if 1
	mov	r0, #0x0400

	tst	REG_P_REST, #P_REST_BG_ADR
	orrne	r0, r0, #0x0004

	strh	r0, [r1, #0x8]
#endif
	ldr	r1, loopy_t
	str	r1, loopy_v
	mov	pc, lr

	.globl	ppu_start_vbl
	.globl	ppu_end_vbl
ppu_start_vbl:	
	orr	REG_P_REST, REG_P_REST, #P_REST_IN_VBL
	orr	REG_P_REST, REG_P_REST, #P_REST_SPR_HIT	
	mov	pc, lr

ppu_end_vbl:	
	bic	REG_P_REST, REG_P_REST, #(P_REST_IN_VBL | P_REST_SPR_HIT)
	mov	pc, lr

scr:	.long	0

	.globl	vbl_handler
vbl_handler:	
	mov	r0, #0x04000000

	mov	r1, #0x8
	strh	r1, [r0, #0x12]

	@@ DMA stop
	mov	r1, #0
	strh	r1, [r0, #0xBA]

	adr	r1, scroll_test + 2
	@@ DMA Ctrl
	strh	r1, [r0, #0xBA]	
	@@ DMA SRC
	str	r1, [r0, #0xB0]
	@@ BG0_Y
	add	r1, r0, #0x12	
	@@ DMA DST
	str	r1, [r0, #0xB4]
	mov	r1, #1
	@@ DMA Count
	strh	r1, [r0, #0xB8]
	@@ DST:	fixed
	@@ SRC:	inc
	mov	r1, #0x40 @| 0x180
	@@ Width: hword
	@@ Repeat
	@@ HBlank
	orr	r1, r1, #0x8000 | 0x2000 | 0x0200
	@@ DMA Ctrl
	strh	r1, [r0, #0xBA]	
	mov	pc, lr

scroll_test:	
	@@ skip 0
#define P(n) n, n, n, n + 1, n + 1, n + 1
	.short	P( 8), P(10), P(12), P(14)@ 1-4
	.short	P(16), P(18), P(20), P(22)@ 5-8
	.short	P(24), P(26), P(28), P(30)@ 9-12
	.short	P(32), P(34), P(36), P(38)@ 13-16
	.short	P(40), P(42), P(44), P(46)@ 17-20
	.short	P(48), P(50), P(52), P(54)@ 21-24
	.short	P(56), P(58), P(60), P(62)@ 25-28
	.short	P(64), P(66), P(68), P(70)@ 29-32

	.globl	read_high_reg
	.globl	read_save_ram
	.globl	write_high_reg
	.globl	write_save_ram
read_high_reg:	
read_save_ram:	
write_high_reg:	
write_save_ram:	
	mov	pc, lr

