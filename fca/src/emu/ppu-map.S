#include "nes.h"
#include "gba-regs.h"

	SECTION_FAST
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
	mov	r0, #0x06000000
	adr	r1, map_table_map
	add	r0, r0, #0x2000
	str	r0, [r1]
	str	r0, [r1, #8]
	add	r0, r0, #0x800
	str	r0, [r1, #4]
	str	r0, [r1, #12]

	mov	r0, #GBA_BG_CR_SIZE_512x256
	b	set_screen_size

set_v_scroll:	
	mov	r0, #0x06000000
	adr	r1, map_table_map
	add	r0, r0, #0x2000
	str	r0, [r1]
	str	r0, [r1, #4]
	add	r0, r0, #0x800
	str	r0, [r1, #8]
	str	r0, [r1, #12]

	mov	r0, #GBA_BG_CR_SIZE_256x512
	b	set_screen_size


set_4_scroll:	
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

	mov	r0, #GBA_BG_CR_SIZE_512x512
	b	set_screen_size

@@@ 
@@@ $2007経由でマップまたは属性を読む
@@@ 
@@@ r1	=> アドレス(000-3C0)
@@@ r2	=> マップ番号(0-3)
@@@ r0	<= *r3 = read_2007_buffer
@@@ *r3	<= 結果
	.globl	read_map

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
	.globl	write_map

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
	@b	write_attr
	@@ FALL THRU

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@ 
@@@ 属性テーブルの変換
@@@ 
@@@ めんどうな仕事である。
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
@@@ $2007経由で属性を書く
@@@ 
@@@ r0	=> 書く値
@@@ r1	=> アドレス(3C0-400)
@@@ r2	=> マップ番号(0-3)
write_attr:	
	stmfd	sp!, {r4, lr}

	and	r1, r1, #0x3F

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

